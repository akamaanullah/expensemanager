import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/saved_recipient_model.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'transaction_detail_screen.dart';

class TransferMoneyScreen extends StatefulWidget {
  const TransferMoneyScreen({super.key});

  @override
  State<TransferMoneyScreen> createState() => _TransferMoneyScreenState();
}

class _TransferMoneyScreenState extends State<TransferMoneyScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _accountNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _amountFieldKey = GlobalKey();

  UserModel? _selectedRecipient;
  bool _isSearching = false;
  bool _isTransferring = false;
  String? _searchError;
  String _currentCurrency = 'Rs.';
  UserModel? _currentUserModel;
  bool _saveAsPayee = false; // Checkbox for saving recipient

  @override
  void initState() {
    super.initState();
    _loadUserCurrency();
  }

  Future<void> _loadUserCurrency() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        _currentUserModel = await _firestoreService.getUser(user.uid);
        if (_currentUserModel?.preferences != null) {
          setState(() {
            _currentCurrency = _currentUserModel!.preferences!['currency'] ?? 'Rs.';
          });
        }
      }
    } catch (e) {
      print('Error loading user currency: $e');
    }
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _searchAccountNumber() async {
    final accountNumber = _accountNumberController.text.trim();
    
    if (accountNumber.isEmpty) {
      setState(() {
        _searchError = 'Please enter account number';
        _selectedRecipient = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
      _selectedRecipient = null;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        setState(() {
          _searchError = 'User not logged in';
          _isSearching = false;
        });
        return;
      }

      // Check if trying to send to own account
      if (_currentUserModel?.accountNumber == accountNumber) {
        setState(() {
          _searchError = 'Cannot transfer to your own account';
          _isSearching = false;
        });
        return;
      }

      final recipient = await _firestoreService.getUserByAccountNumber(accountNumber);
      
      if (recipient == null) {
        setState(() {
          _searchError = 'Account number not found';
          _isSearching = false;
          _selectedRecipient = null;
        });
      } else {
        setState(() {
          _selectedRecipient = recipient;
          _isSearching = false;
          _searchError = null;
        });
        // Scroll to amount field after successful search
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _amountFieldKey.currentContext != null) {
            Scrollable.ensureVisible(
              _amountFieldKey.currentContext!,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    } catch (e) {
      setState(() {
        _searchError = 'Error searching account: $e';
        _isSearching = false;
      });
    }
  }

  Future<void> _transferMoney() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRecipient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please search and select a recipient'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get sender's balance
    final sender = _authService.currentUser;
    if (sender == null) return;

    final totals = await _firestoreService.getTransactionTotals(sender.uid);
    final senderBalance = totals['totalBalance'] ?? 0.0;

    if (senderBalance < amount) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Insufficient Balance'),
          content: Text(
            'Your current balance is $_currentCurrency ${senderBalance.toStringAsFixed(2)}\n'
            'You need $_currentCurrency ${(amount - senderBalance).toStringAsFixed(2)} more to complete this transfer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Confirm transfer
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Transfer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send: $_currentCurrency ${amount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('To: ${_selectedRecipient!.displayName ?? _selectedRecipient!.email}'),
            Text('Account: ${_selectedRecipient!.accountNumber}'),
            if (_descriptionController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Description: ${_descriptionController.text}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isTransferring = true;
    });

    try {
      // Save recipient only if "Save as Payee" is checked
      if (_saveAsPayee) {
        try {
          final existingRecipient = await _firestoreService.getSavedRecipientByAccountNumber(
            sender.uid,
            _selectedRecipient!.accountNumber!,
          );

          if (existingRecipient == null) {
            // Save new recipient
            final newRecipient = SavedRecipientModel(
              id: '', // Will be generated by Firestore
              userId: sender.uid,
              recipientUserId: _selectedRecipient!.id,
              recipientAccountNumber: _selectedRecipient!.accountNumber!,
              recipientName: _selectedRecipient!.displayName ?? _selectedRecipient!.email,
              recipientEmail: _selectedRecipient!.email,
              savedAt: DateTime.now(),
            );
            await _firestoreService.addSavedRecipient(newRecipient);
          } else {
            // Update last transferred date
            await _firestoreService.updateSavedRecipient(existingRecipient.id);
          }
        } catch (e) {
          // If saving recipient fails (e.g., permission error), continue with transfer
          print('Warning: Could not save recipient: $e');
          // Transfer will still proceed
        }
      }

      // Perform transfer (this is the main operation)
      final description = _descriptionController.text.trim().isEmpty
          ? 'Money transfer'
          : _descriptionController.text.trim();

      final transactionId = await _firestoreService.transferMoney(
        senderId: sender.uid,
        receiverId: _selectedRecipient!.id,
        receiverAccountNumber: _selectedRecipient!.accountNumber!,
        receiverName: _selectedRecipient!.displayName ?? _selectedRecipient!.email,
        amount: amount,
        description: description,
        currency: _currentCurrency,
      );

      // Get the created transaction
      final transaction = await _firestoreService.getTransaction(transactionId);

      // Capture recipient data before resetting (for dialog and slip)
      final recipientName = _selectedRecipient!.displayName ?? _selectedRecipient!.email;
      final recipientAccountNumber = _selectedRecipient!.accountNumber ?? 'N/A';
      final recipientId = _selectedRecipient!.id;
      final recipientEmail = _selectedRecipient!.email;

      if (mounted) {
        // Reset form first (before showing dialog)
        _accountNumberController.clear();
        _amountController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedRecipient = null;
          _isTransferring = false;
          _saveAsPayee = false; // Reset checkbox
        });

        // Show success dialog with option to view slip
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('Transfer Successful'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount: $_currentCurrency ${amount.toStringAsFixed(2)}'),
                const SizedBox(height: 4),
                Text('To: $recipientName'),
                const SizedBox(height: 4),
                Text('Account: $recipientAccountNumber'),
                if (transaction != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Transaction ID: ${transaction.transactionId ?? "N/A"}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  if (transaction != null) {
                    // Create recipient model from captured data
                    final recipientForSlip = UserModel(
                      id: recipientId,
                      email: recipientEmail,
                      displayName: recipientName,
                      createdAt: DateTime.now(),
                      accountNumber: recipientAccountNumber != 'N/A' ? recipientAccountNumber : null,
                    );
                    _downloadAndShareTransferSlip(transaction, recipientForSlip);
                  }
                },
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share Slip'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTransferring = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transfer failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadAndShareTransferSlip(
    TransactionModel transaction,
    UserModel recipient,
  ) async {
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
                  Text('Generating transfer slip...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Generate PDF
      final pdf = await _generateTransferSlipPDF(transaction, recipient);

      // Save and share
      await _saveAndSharePDF(pdf, 'transfer_slip_${transaction.transactionId}.pdf');

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating slip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Uint8List> _generateTransferSlipPDF(
    TransactionModel transaction,
    UserModel recipient,
  ) async {
    final pdf = pw.Document();
    final themeColor = PdfColor.fromHex('#6366F1');
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(themeColor),
              pw.SizedBox(height: 20),

              // Title
              pw.Center(
                child: pw.Text(
                  'TRANSFER RECEIPT',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: themeColor,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Transaction Details
              _buildDetailRow('Transaction ID', transaction.transactionId ?? 'N/A'),
              _buildDetailRow('Date', dateFormat.format(transaction.date)),
              _buildDetailRow('Status', 'Completed'),
              pw.SizedBox(height: 15),

              // Sender Details
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'From',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    _buildDetailRow('Name', _currentUserModel?.displayName ?? _currentUserModel?.email ?? 'N/A'),
                    _buildDetailRow('Account Number', _currentUserModel?.accountNumber ?? 'N/A'),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),

              // Receiver Details
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'To',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    _buildDetailRow('Name', recipient.displayName ?? recipient.email),
                    _buildDetailRow('Account Number', recipient.accountNumber ?? 'N/A'),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),

              // Amount
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: themeColor, width: 2),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Amount Transferred',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '$_currentCurrency ${transaction.amount.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),

              // Description
              if (transaction.description != null && transaction.description!.isNotEmpty)
                _buildDetailRow('Description', transaction.description!),

              pw.Spacer(),

              // Footer
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                'This is a computer-generated receipt.',
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
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(PdfColor themeColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: themeColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
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
                'Transfer Receipt',
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

  pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndSharePDF(Uint8List pdfBytes, String fileName) async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await _getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getTemporaryDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      // Share the file
      final xFile = XFile(file.path);
      await Share.shareXFiles(
        [xFile],
        text: 'Transfer Receipt from My Expense Manager',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transfer slip saved and shared: ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
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

  Future<Directory?> _getExternalStorageDirectory() async {
    try {
      if (Platform.isAndroid) {
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          // Try to save to Downloads folder
          final downloadsPath = '/storage/emulated/0/Download';
          final downloadsDir = Directory(downloadsPath);
          if (await downloadsDir.exists()) {
            return downloadsDir;
          }
          // Fallback to app-specific external directory
          return directory;
        }
      }
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      return await getApplicationDocumentsDirectory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: themeColor,
        title: const Text(
          'Transfer Money',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: user == null
          ? const Center(
              child: Text('Please login to transfer money'),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account Number Search - Moved to Top
                    const Text(
                      'Search by Account Number',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: TextFormField(
                            controller: _accountNumberController,
                            decoration: InputDecoration(
                              hintText: 'Account number (e.g., ACC-1234-5678-9012)',
                              prefixIcon: const Icon(Icons.account_circle),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            textInputAction: TextInputAction.search,
                            onFieldSubmitted: (_) => _searchAccountNumber(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: themeColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: _isSearching ? null : _searchAccountNumber,
                            icon: _isSearching
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.search, color: Colors.white),
                            tooltip: 'Search',
                          ),
                        ),
                      ],
                    ),
                    if (_searchError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _searchError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                    
                    // Saved Recipients Section - Below Search
                    const SizedBox(height: 24),
                    StreamBuilder<List<SavedRecipientModel>>(
                      stream: _firestoreService.getSavedRecipients(user.uid),
                      builder: (context, snapshot) {
                        // Handle errors gracefully (permission errors)
                        if (snapshot.hasError) {
                          // Permission error - don't show saved recipients section
                          return const SizedBox.shrink();
                        }
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Saved Payees',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, index) {
                                  final recipient = snapshot.data![index];
                                  return _buildSavedRecipientListItem(recipient);
                                },
                              ),
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 24),
                            ],
                          );
                        } else {
                          // Show message if no saved payees
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Saved Payees',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'No saved payees. Search and add a new payee above.',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 24),
                            ],
                          );
                        }
                      },
                    ),
                    
                    // Selected Recipient Card - Show when payee is selected
                    if (_selectedRecipient != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedRecipient!.displayName ?? _selectedRecipient!.email,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Account: ${_selectedRecipient!.accountNumber}',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            CheckboxListTile(
                              value: _saveAsPayee,
                              onChanged: (value) {
                                setState(() {
                                  _saveAsPayee = value ?? false;
                                });
                              },
                              title: const Text(
                                'Save as Payee',
                                style: TextStyle(fontSize: 14),
                              ),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Amount
                    const Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: _amountFieldKey,
                      controller: _amountController,
                      decoration: InputDecoration(
                        hintText: 'Enter amount',
                        prefixText: '$_currentCurrency ',
                        prefixIcon: const Icon(Icons.currency_rupee),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Description
                    const Text(
                      'Description (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: 'Add a note about this transfer',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // Transfer Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isTransferring ? null : _transferMoney,
                        icon: _isTransferring
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send, size: 24),
                        label: Text(
                          _isTransferring ? 'Processing...' : 'Transfer Money',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSavedRecipientListItem(SavedRecipientModel recipient) {
    final themeColor = Theme.of(context).colorScheme.primary;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRecipient = UserModel(
              id: recipient.recipientUserId,
              email: recipient.recipientEmail ?? '',
              displayName: recipient.recipientName,
              createdAt: DateTime.now(),
              accountNumber: recipient.recipientAccountNumber,
            );
            _accountNumberController.text = recipient.recipientAccountNumber;
            _saveAsPayee = false; // Reset checkbox when selecting from list
            _searchError = null; // Clear any previous errors
          });
          // Scroll to amount field after selection
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && _amountFieldKey.currentContext != null) {
              Scrollable.ensureVisible(
                _amountFieldKey.currentContext!,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: themeColor.withOpacity(0.1),
                radius: 24,
                child: Icon(Icons.person, color: themeColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipient.recipientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipient.recipientAccountNumber,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: Colors.grey,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Remove Recipient'),
                      content: Text('Remove ${recipient.recipientName} from saved recipients?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            _firestoreService.deleteSavedRecipient(recipient.id);
                            Navigator.pop(context);
                          },
                          child: const Text('Remove', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

