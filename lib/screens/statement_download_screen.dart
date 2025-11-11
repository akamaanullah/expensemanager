import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../utils/currency_helper.dart';

class StatementDownloadScreen extends StatefulWidget {
  const StatementDownloadScreen({super.key});

  @override
  State<StatementDownloadScreen> createState() => _StatementDownloadScreenState();
}

class _StatementDownloadScreenState extends State<StatementDownloadScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isGenerating = false;
  UserModel? _userModel;
  String _userCurrency = 'Rs.';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Default to last 30 days
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final userModel = await _firestoreService.getUser(user.uid);
      setState(() {
        _userModel = userModel;
        _userCurrency = userModel?.preferences?['currency'] ?? 'Rs.';
      });
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year - 5);
    final DateTime lastDate = _endDate ?? DateTime(now.year + 1);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now.subtract(const Duration(days: 30)),
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Start Date',
    );

    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.year, picked.month, picked.day);
        if (_endDate != null && _startDate!.isAfter(_endDate!)) {
          _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = _startDate ?? DateTime(now.year - 5);
    final DateTime lastDate = DateTime(now.year + 1);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select End Date',
    );

    if (picked != null) {
      setState(() {
        _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
  }

  Future<void> _generateAndDownloadStatement() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both start and end dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Fetch transactions
      final transactions = await _firestoreService.getTransactionsByDateRange(
        user.uid,
        _startDate!,
        _endDate!,
      );

      // Sort transactions by date (ascending for statement)
      transactions.sort((a, b) => a.date.compareTo(b.date));

      // Generate PDF
      final pdf = await _generatePDF(transactions);

      // Save and share
      await _saveAndSharePDF(pdf);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Statement generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating statement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<pw.Document> _generatePDF(List<TransactionModel> transactions) async {
    final pdf = pw.Document();
    final user = _authService.currentUser;
    final userName = _userModel?.displayName ?? user?.email?.split('@')[0] ?? 'User';
    final accountNumber = user?.uid.substring(0, 8).toUpperCase() ?? 'N/A';

    // Calculate opening balance (all transactions before start date)
    double openingBalance = 0;
    if (_startDate != null && user != null) {
      try {
        final allTransactions = await _firestoreService.getTransactions(user.uid).first;
        final beforeStart = allTransactions
            .where((t) => t.date.isBefore(_startDate!))
            .toList();
        for (var t in beforeStart) {
          final amount = await CurrencyHelper.getConvertedAmount(t, currency: _userCurrency);
          if (t.type == 'income') {
            openingBalance += amount;
          } else {
            openingBalance -= amount;
          }
        }
      } catch (e) {
        print('Error calculating opening balance: $e');
      }
    }

    // Pre-calculate converted amounts for all transactions
    final List<Map<String, dynamic>> convertedTransactions = [];
    double totalIncome = 0;
    double totalExpense = 0;
    double currentBalance = openingBalance;

    for (var transaction in transactions) {
      final convertedAmount = await CurrencyHelper.getConvertedAmount(transaction, currency: _userCurrency);
      
      if (transaction.type == 'income') {
        totalIncome += convertedAmount;
        currentBalance += convertedAmount;
      } else {
        totalExpense += convertedAmount;
        currentBalance -= convertedAmount;
      }

      convertedTransactions.add({
        'transaction': transaction,
        'convertedAmount': convertedAmount,
        'balance': currentBalance,
      });
    }

    final netBalance = totalIncome - totalExpense;
    final closingBalance = openingBalance + netBalance;

    // Format dates
    final dateFormat = DateFormat('dd MMM yyyy');
    final periodStart = dateFormat.format(_startDate!);
    final periodEnd = dateFormat.format(_endDate!);
    final generatedDate = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    
    // Load app icon before building PDF
    pw.ImageProvider? appIcon;
    try {
      final ByteData iconData = await rootBundle.load('assets/icon/app_icon.png');
      final Uint8List iconBytes = iconData.buffer.asUint8List();
      appIcon = pw.MemoryImage(iconBytes);
    } catch (e) {
      print('Error loading app icon: $e');
      // Fallback will be handled in header
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header with App Icon
            _buildHeader(userName, accountNumber, periodStart, periodEnd, appIcon),
            pw.SizedBox(height: 20),

            // Account Summary
            _buildAccountSummary(
              openingBalance,
              closingBalance,
              totalIncome,
              totalExpense,
              netBalance,
            ),
            pw.SizedBox(height: 20),

            // Transaction Table
            _buildTransactionTable(convertedTransactions),
            pw.SizedBox(height: 20),

            // Footer
            _buildFooter(generatedDate),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(String userName, String accountNumber, String periodStart, String periodEnd, pw.ImageProvider? appIcon) {
    final themeColor = PdfColor.fromHex('#6366F1');
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // App Icon and Title Row
          pw.Row(
            children: [
              // App Icon
              if (appIcon != null)
                pw.Image(
                  appIcon,
                  width: 40,
                  height: 40,
                )
              else
                // Fallback to text if icon not available
                pw.Container(
                  width: 40,
                  height: 40,
                  decoration: pw.BoxDecoration(
                    color: themeColor,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'MEM',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Text(
                  'ACCOUNT STATEMENT',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Account Holder:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(userName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text('Account Number:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(accountNumber, style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Statement Period:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('$periodStart to $periodEnd', style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildAccountSummary(
    double openingBalance,
    double closingBalance,
    double totalIncome,
    double totalExpense,
    double netBalance,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ACCOUNT SUMMARY',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildSummaryRow('Opening Balance', openingBalance, PdfColors.black),
          _buildSummaryRow('Total Income', totalIncome, PdfColors.green700),
          _buildSummaryRow('Total Expense', totalExpense, PdfColors.red700),
          _buildSummaryRow('Net Balance', netBalance, PdfColors.blue700),
          pw.Divider(),
          _buildSummaryRow('Closing Balance', closingBalance, PdfColors.blue900, isBold: true),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryRow(String label, double amount, PdfColor color, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 11, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(
            '${_userCurrency}${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTransactionTable(List<Map<String, dynamic>> convertedTransactions) {
    if (convertedTransactions.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        child: pw.Center(
          child: pw.Text(
            'No transactions found for the selected period',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
        ),
      );
    }

    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(4),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Description', isHeader: true),
            _buildTableCell('Debit', isHeader: true),
            _buildTableCell('Credit', isHeader: true),
            _buildTableCell('Balance', isHeader: true),
          ],
        ),
        // Transaction Rows
        ...convertedTransactions.map((item) {
          final transaction = item['transaction'] as TransactionModel;
          final convertedAmount = item['convertedAmount'] as double;
          final balance = item['balance'] as double;
          final isIncome = transaction.type == 'income';

          final description = '${transaction.title}${transaction.description != null ? ' - ${transaction.description}' : ''}';
          final category = transaction.category;

          return pw.TableRow(
            children: [
              _buildTableCell('${dateFormat.format(transaction.date)}\n${timeFormat.format(transaction.date)}'),
              _buildTableCell('$description\nCategory: $category'),
              _buildTableCell(
                isIncome ? '-' : '${_userCurrency}${convertedAmount.toStringAsFixed(2)}',
                color: isIncome ? PdfColors.black : PdfColors.red700,
              ),
              _buildTableCell(
                isIncome ? '${_userCurrency}${convertedAmount.toStringAsFixed(2)}' : '-',
                color: isIncome ? PdfColors.green700 : PdfColors.black,
              ),
              _buildTableCell('${_userCurrency}${balance.toStringAsFixed(2)}'),
            ],
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false, PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.blue900 : PdfColors.black),
        ),
      ),
    );
  }

  pw.Widget _buildFooter(String generatedDate) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'This is a computer-generated statement.',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Generated on: $generatedDate',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'For any queries, please contact support.',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndSharePDF(pw.Document pdf) async {
    // Generate filename
    final dateFormat = DateFormat('yyyyMMdd');
    final startStr = _startDate != null ? dateFormat.format(_startDate!) : '';
    final endStr = _endDate != null ? dateFormat.format(_endDate!) : '';
    final filename = 'Statement_${startStr}_to_$endStr.pdf';

    File? savedFile;
    String? savedPath;

    try {
      if (kIsWeb) {
        // For web, save to temporary and share
        final output = await getTemporaryDirectory();
        savedFile = File('${output.path}/$filename');
        await savedFile.writeAsBytes(await pdf.save());
        savedPath = savedFile.path;
      } else if (Platform.isAndroid) {
        // For Android, try multiple approaches to save to Downloads
        Directory? directory;
        
        try {
          // Method 1: Try to get Downloads folder using path_provider
          // This works for Android 9 and below, and some Android 10+ devices
          try {
            // Get external storage directory
            directory = await getExternalStorageDirectory();
            if (directory != null) {
              // Navigate to Downloads folder
              // Path format: /storage/emulated/0/Android/data/com.example.app/files
              // We need: /storage/emulated/0/Download
              final pathParts = directory.path.split('/');
              int androidIndex = -1;
              for (int i = 0; i < pathParts.length; i++) {
                if (pathParts[i] == 'Android') {
                  androidIndex = i;
                  break;
                }
              }
              
              String downloadsPath;
              if (androidIndex > 0) {
                downloadsPath = pathParts.sublist(0, androidIndex).join('/') + '/Download';
              } else {
                // Try common path
                downloadsPath = '/storage/emulated/0/Download';
              }
              
              final downloadsDir = Directory(downloadsPath);
              
              // Try to create directory (may fail on Android 10+ without permissions)
              try {
                if (!await downloadsDir.exists()) {
                  await downloadsDir.create(recursive: true);
                }
                
                // Try to write file
                savedFile = File('${downloadsDir.path}/$filename');
                await savedFile.writeAsBytes(await pdf.save());
                
                // Verify file was created
                if (await savedFile.exists()) {
                  savedPath = 'Download';
                  print('File saved successfully to Downloads: ${savedFile.path}');
                } else {
                  throw Exception('File was not created');
                }
              } catch (writeError) {
                print('Failed to write to Downloads folder: $writeError');
                // Fall through to app directory
                throw writeError;
              }
            }
          } catch (e) {
            print('Error accessing Downloads folder: $e');
            // Method 2: Save to app's external storage directory (accessible to user)
            // This directory is accessible via file manager
            directory = await getExternalStorageDirectory();
            if (directory != null) {
              // Create a subfolder for statements
              final statementsDir = Directory('${directory.path}/Statements');
              if (!await statementsDir.exists()) {
                await statementsDir.create(recursive: true);
              }
              
              savedFile = File('${statementsDir.path}/$filename');
              await savedFile.writeAsBytes(await pdf.save());
              savedPath = 'Internal Storage/Android/data/com.zain.expensemanage/files/Statements';
              print('File saved to app directory: ${savedFile.path}');
            } else {
              throw Exception('Could not get external storage directory');
            }
          }
        } catch (e) {
          // Method 3: Last resort - save to app documents (still accessible)
          try {
            directory = await getApplicationDocumentsDirectory();
            savedFile = File('${directory.path}/$filename');
            await savedFile.writeAsBytes(await pdf.save());
            savedPath = 'App Documents';
            print('File saved to app documents: ${savedFile.path}');
          } catch (e2) {
            // Final fallback: temporary directory
            final tempDir = await getTemporaryDirectory();
            savedFile = File('${tempDir.path}/$filename');
            await savedFile.writeAsBytes(await pdf.save());
            savedPath = 'Temporary';
            print('File saved to temporary: ${savedFile.path}');
          }
        }
      } else if (Platform.isIOS) {
        // For iOS, save to Documents directory
        final directory = await getApplicationDocumentsDirectory();
        savedFile = File('${directory.path}/$filename');
        await savedFile.writeAsBytes(await pdf.save());
        savedPath = directory.path;
      } else {
        // For other platforms
        final directory = await getApplicationDocumentsDirectory();
        savedFile = File('${directory.path}/$filename');
        await savedFile.writeAsBytes(await pdf.save());
        savedPath = directory.path;
      }

      // Show success message
      if (mounted && savedFile != null && savedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Statement saved successfully!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  Platform.isAndroid 
                    ? (savedPath == 'Download' 
                        ? 'Saved to: Download/$filename'
                        : savedPath == 'Internal Storage/Android/data/com.zain.expensemanage/files/Statements'
                          ? 'Saved to: Internal Storage/Statements/$filename\n(Check: Android/data/com.zain.expensemanage/files/Statements)'
                          : 'Saved to: $savedPath/$filename')
                    : 'Saved to: $savedPath/$filename',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Share',
              textColor: Colors.white,
              onPressed: () async {
                if (savedFile != null) {
                  final xFile = XFile(savedFile.path);
                  await Share.shareXFiles([xFile], text: 'Account Statement');
                }
              },
            ),
          ),
        );
      }

      // Also show share option
      if (savedFile != null && !kIsWeb) {
        // Small delay to let user see the success message
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Show share dialog
        if (mounted) {
          final shouldShare = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Statement Saved'),
              content: Text(
                Platform.isAndroid
                  ? (savedPath == 'Download'
                      ? 'Statement saved to Downloads folder.\n\nWould you like to share it?'
                      : savedPath == 'Internal Storage/Android/data/com.zain.expensemanage/files/Statements'
                        ? 'Statement saved to app folder.\nYou can find it in:\nAndroid/data/com.zain.expensemanage/files/Statements\n\nWould you like to share it?'
                        : 'Statement saved successfully.\n\nWould you like to share it?')
                  : 'Statement saved successfully.\n\nWould you like to share it?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Share'),
                ),
              ],
            ),
          );

          if (shouldShare == true && savedFile != null) {
            final xFile = XFile(savedFile.path);
            await Share.shareXFiles([xFile], text: 'Account Statement');
          }
        }
      } else if (kIsWeb && savedFile != null) {
        // For web, directly share
        final xFile = XFile(savedFile.path);
        await Share.shareXFiles([xFile], text: 'Account Statement');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: themeColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Download Statement',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select a date range to generate your account statement in bank statement format.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Date Range Selection
            Text(
              'Select Date Range',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),

            // Start Date
            InkWell(
              onTap: _selectStartDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: themeColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _startDate != null
                                ? DateFormat('dd MMM yyyy').format(_startDate!)
                                : 'Select start date',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // End Date
            InkWell(
              onTap: _selectEndDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: themeColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'End Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _endDate != null
                                ? DateFormat('dd MMM yyyy').format(_endDate!)
                                : 'Select end date',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Generate Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateAndDownloadStatement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isGenerating
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Generating Statement...'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Generate & Download Statement',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Features List
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statement Includes:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem('Account holder information'),
                  _buildFeatureItem('Opening and closing balance'),
                  _buildFeatureItem('All transactions with date and time'),
                  _buildFeatureItem('Debit and credit columns'),
                  _buildFeatureItem('Running balance for each transaction'),
                  _buildFeatureItem('Summary of income and expenses'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

