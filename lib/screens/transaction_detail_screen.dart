import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../models/saved_recipient_model.dart';
import '../utils/category_utils.dart';
import 'add_transaction_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  bool _isDeleting = false;
  
  @override
  void initState() {
    super.initState();
    _loadTransferDetails();
  }
  
  String? _recipientAccountNumber;
  
  Future<void> _loadTransferDetails() async {
    // Extract account number from title if it's a transfer transaction
    if (widget.transaction.category == 'Transfer' && 
        widget.transaction.title.startsWith('Transfer to ')) {
      try {
        final user = _authService.currentUser;
        if (user != null) {
          // Try to get recipient from saved recipients
          final savedRecipients = await _firestoreService.getSavedRecipients(user.uid).first;
          final recipientName = widget.transaction.title.replaceFirst('Transfer to ', '');
          
          // Try to find recipient by name
          SavedRecipientModel? recipient;
          try {
            recipient = savedRecipients.firstWhere(
              (r) => r.recipientName == recipientName,
            );
          } catch (e) {
            // If not found by name, check if title contains account number (old format)
            if (widget.transaction.title.contains('ACC-')) {
              try {
                recipient = savedRecipients.firstWhere(
                  (r) => widget.transaction.title.contains(r.recipientAccountNumber),
                );
              } catch (e2) {
                // Not found, that's okay
              }
            }
          }
          
          if (recipient != null && mounted) {
            setState(() {
              _recipientAccountNumber = recipient!.recipientAccountNumber;
            });
          }
        }
      } catch (e) {
        // If we can't find recipient, that's okay
        print('Could not load recipient details: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final isCredit = transaction.type == 'income';
    final themeColor = Theme.of(context).colorScheme.primary;
    final categoryIcon = CategoryUtils.getCategoryIcon(transaction.category);
    // Check if it's a transfer transaction - check both category and title pattern
    final isTransferTransaction = transaction.category == 'Transfer' ||
                                  transaction.category.toLowerCase() == 'transfer' ||
                                  transaction.title.toLowerCase().contains('transfer to') ||
                                  transaction.title.toLowerCase().contains('received from transfer');

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
          'Transaction Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () => _downloadTransactionSlip(),
            tooltip: 'Download Receipt',
          ),
          if (!isTransferTransaction) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => _editTransaction(),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _isDeleting ? null : () => _showDeleteDialog(),
              tooltip: 'Delete',
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Amount Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isCredit
                      ? [
                          const Color(0xFF10B981),
                          const Color(0xFF10B981).withOpacity(0.8),
                        ]
                      : [
                          const Color(0xFFEF4444),
                          const Color(0xFFEF4444).withOpacity(0.8),
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isCredit ? Colors.green : Colors.red).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      categoryIcon,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    // Show amount without sign for all transactions
                    // The "Income"/"Expense" label already indicates the direction
                    '${transaction.originalCurrency}${transaction.originalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isCredit ? 'Income' : 'Expense',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Transaction Details Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transaction Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Title
                  _buildDetailRow(
                    icon: Icons.title,
                    label: 'Title',
                    value: transaction.title,
                  ),
                  const Divider(height: 32),
                  
                  // Category
                  _buildDetailRow(
                    icon: Icons.category,
                    label: 'Category',
                    value: transaction.category,
                  ),
                  
                  // Transfer Recipient Details (if transfer transaction)
                  if (transaction.category == 'Transfer' && 
                      transaction.title.startsWith('Transfer to ')) ...[
                    const Divider(height: 32),
                    _buildDetailRow(
                      icon: Icons.person,
                      label: 'Recipient',
                      value: transaction.title.replaceFirst('Transfer to ', ''),
                    ),
                    if (_recipientAccountNumber != null) ...[
                      const Divider(height: 32),
                      _buildDetailRow(
                        icon: Icons.account_circle,
                        label: 'Account Number',
                        value: _recipientAccountNumber!,
                      ),
                    ],
                  ],
                  
                  const Divider(height: 32),
                  
                  // Description
                  if (transaction.description != null && transaction.description!.isNotEmpty)
                    ...[
                      _buildDetailRow(
                        icon: Icons.description,
                        label: 'Description',
                        value: transaction.description!,
                      ),
                      const Divider(height: 32),
                    ],
                  
                  // Date
                  _buildDetailRow(
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value: CategoryUtils.formatDate(transaction.date),
                  ),
                  const Divider(height: 32),
                  
                  // Created At
                  _buildDetailRow(
                    icon: Icons.access_time,
                    label: 'Created',
                    value: CategoryUtils.formatDate(transaction.createdAt),
                  ),
                  
                  // Updated At (if exists)
                  if (transaction.updatedAt != null) ...[
                    const Divider(height: 32),
                    _buildDetailRow(
                      icon: Icons.update,
                      label: 'Last Updated',
                      value: CategoryUtils.formatDate(transaction.updatedAt!),
                    ),
                  ],
                ],
              ),
            ),

            // Action Buttons (only show for non-transfer transactions)
            if (!isTransferTransaction)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isDeleting ? null : () => _showDeleteDialog(),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _editTransaction,
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Info message for transfer transactions
            if (isTransferTransaction)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Transfer transactions cannot be edited or deleted.',
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.grey[700],
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _editTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          transactionType: widget.transaction.type,
          transaction: widget.transaction, // Pass transaction for editing
        ),
      ),
    );

    // If transaction was updated, pop and refresh
    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Transaction',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteTransaction();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadTransactionSlip() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating receipt...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Get user details
      final user = _authService.currentUser;
      UserModel? userModel;
      if (user != null) {
        userModel = await _firestoreService.getUser(user.uid);
      }

      // Generate PDF
      final pdf = await _generateReceiptPDF(userModel);
      
      // Save and share
      await _saveAndSharePDF(pdf);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<pw.Document> _generateReceiptPDF(UserModel? userModel) async {
    final pdf = pw.Document();
    final transaction = widget.transaction;
    final isCredit = transaction.type == 'income';
    final userName = userModel?.displayName ?? 
                     _authService.currentUser?.email?.split('@')[0] ?? 
                     'User';
    
    // Format dates
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final transactionDate = dateFormat.format(transaction.date);
    final transactionTime = timeFormat.format(transaction.date);
    final generatedDate = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    
    // Use saved Transaction ID from Firebase, or generate if not present
    final transactionId = transaction.transactionId ?? 
                          TransactionModel.generateTransactionId(transaction.id, transaction.date);
    
    // Use saved Account Number from Firebase, or generate if not present
    final accountNumber = userModel?.accountNumber ?? 
                         UserModel.generateAccountNumber(transaction.userId);
    
    // Status
    final status = 'Success';
    
    // Theme color (Indigo #6366F1)
    final themeColor = PdfColor.fromHex('#6366F1');
    
    // Load app icon before building PDF
    pw.ImageProvider? appIcon;
    try {
      final ByteData iconData = await rootBundle.load('assets/icon/app_icon.png');
      if (iconData.lengthInBytes > 0) {
        final Uint8List iconBytes = iconData.buffer.asUint8List();
        appIcon = pw.MemoryImage(iconBytes);
        print('App icon loaded successfully: ${iconBytes.length} bytes');
      } else {
        print('Warning: App icon file is empty');
      }
    } catch (e) {
      print('Error loading app icon: $e');
      print('Stack trace: ${StackTrace.current}');
      // Fallback will be handled in header
    }
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with App Icon
              _buildHeader(appIcon, themeColor),
              pw.SizedBox(height: 30),
              
              // Transaction Receipt Title
              pw.Center(
                child: pw.Text(
                  'TRANSACTION RECEIPT',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: themeColor,
                  ),
                ),
              ),
              pw.SizedBox(height: 30),
              
              // Transaction Details Box
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 1),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildReceiptRow('Transaction ID', transactionId, isBold: true),
                    pw.Divider(),
                    _buildReceiptRow('Date', transactionDate),
                    _buildReceiptRow('Time', transactionTime),
                    pw.Divider(),
                    _buildReceiptRow('Type', isCredit ? 'Credit' : 'Debit'),
                    _buildReceiptRow('Category', transaction.category),
                    pw.Divider(),
                    _buildReceiptRow('Title', transaction.title),
                    if (transaction.description != null && transaction.description!.isNotEmpty)
                      _buildReceiptRow('Description', transaction.description!),
                    pw.Divider(),
                    pw.SizedBox(height: 10),
                    _buildReceiptRow(
                      'Amount',
                      '${transaction.originalCurrency}${transaction.originalAmount.toStringAsFixed(2)}',
                      isBold: true,
                      fontSize: 18,
                      color: isCredit ? PdfColors.green700 : PdfColors.red700,
                    ),
                    pw.SizedBox(height: 10),
                    pw.Divider(),
                    _buildReceiptRow('Status', status, color: PdfColors.green700),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              
              // Account Holder Info
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Account Details',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    _buildReceiptRow('Account Holder', userName, fontSize: 12),
                    _buildReceiptRow('Account Number', accountNumber, fontSize: 12),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              
              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'This is a computer-generated receipt.',
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
                      'My Expense Manager',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(pw.ImageProvider? appIcon, PdfColor themeColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: themeColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          // App Icon
          if (appIcon != null)
            pw.Image(
              appIcon,
              width: 50,
              height: 50,
            )
          else
            // Fallback to text if icon not available
            pw.Container(
              width: 50,
              height: 50,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Center(
                child: pw.Text(
                  'MEM',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: themeColor,
                  ),
                ),
              ),
            ),
          pw.SizedBox(width: 15),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'My Expense Manager',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                'Transaction Receipt',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildReceiptRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 12,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: fontSize,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: color ?? PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndSharePDF(pw.Document pdf) async {
    final transaction = widget.transaction;
    final dateFormat = DateFormat('yyyyMMdd');
    final transactionDate = dateFormat.format(transaction.date);
    final transactionId = transaction.id.substring(0, 6).toUpperCase();
    final filename = 'Receipt_${transactionId}_$transactionDate.pdf';

    File? savedFile;
    String? savedPath;

    try {
      if (kIsWeb) {
        final output = await getTemporaryDirectory();
        savedFile = File('${output.path}/$filename');
        await savedFile.writeAsBytes(await pdf.save());
        savedPath = savedFile.path;
      } else if (Platform.isAndroid) {
        Directory? directory;
        
        try {
          directory = await getExternalStorageDirectory();
          if (directory != null) {
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
              downloadsPath = '/storage/emulated/0/Download';
            }
            
            final downloadsDir = Directory(downloadsPath);
            if (!await downloadsDir.exists()) {
              await downloadsDir.create(recursive: true);
            }
            
            savedFile = File('${downloadsDir.path}/$filename');
            await savedFile.writeAsBytes(await pdf.save());
            
            if (await savedFile.exists()) {
              savedPath = 'Download';
            } else {
              throw Exception('File was not created');
            }
          }
        } catch (e) {
          directory = await getExternalStorageDirectory();
          if (directory != null) {
            final receiptsDir = Directory('${directory.path}/Receipts');
            if (!await receiptsDir.exists()) {
              await receiptsDir.create(recursive: true);
            }
            savedFile = File('${receiptsDir.path}/$filename');
            await savedFile.writeAsBytes(await pdf.save());
            savedPath = 'Internal Storage/Android/data/com.zain.expensemanage/files/Receipts';
          }
        }
      } else if (Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        savedFile = File('${directory.path}/$filename');
        await savedFile.writeAsBytes(await pdf.save());
        savedPath = directory.path;
      } else {
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
                      'Receipt saved successfully!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  Platform.isAndroid 
                    ? (savedPath == 'Download' 
                        ? 'Saved to: Download/$filename'
                        : 'Saved to: Internal Storage/Receipts/$filename')
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
                  await Share.shareXFiles([xFile], text: 'Transaction Receipt');
                }
              },
            ),
          ),
        );
      }

      // Show share dialog
      if (savedFile != null && !kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          final shouldShare = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Receipt Saved'),
              content: Text(
                Platform.isAndroid
                  ? (savedPath == 'Download'
                      ? 'Receipt saved to Downloads folder.\n\nWould you like to share it?'
                      : 'Receipt saved successfully.\n\nWould you like to share it?')
                  : 'Receipt saved successfully.\n\nWould you like to share it?',
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
            await Share.shareXFiles([xFile], text: 'Transaction Receipt');
          }
        }
      } else if (kIsWeb && savedFile != null) {
        final xFile = XFile(savedFile.path);
        await Share.shareXFiles([xFile], text: 'Transaction Receipt');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteTransaction() async {
    setState(() {
      _isDeleting = true;
    });

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Deleting transaction...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await _firestoreService.deleteTransaction(widget.transaction.id);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pop(context); // Close detail screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting transaction: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }
}

