import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/saved_recipient_model.dart';
import 'payee_details_screen.dart';

class AddNewPayeeScreen extends StatefulWidget {
  const AddNewPayeeScreen({super.key});

  @override
  State<AddNewPayeeScreen> createState() => _AddNewPayeeScreenState();
}

class _AddNewPayeeScreenState extends State<AddNewPayeeScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _accountNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSearching = false;
  String? _searchError;
  UserModel? _foundUser;
  bool _isSaving = false;

  @override
  void dispose() {
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _searchAccountNumber() async {
    final accountNumber = _accountNumberController.text.trim();

    if (accountNumber.isEmpty) {
      setState(() {
        _searchError = 'Please enter account number';
        _foundUser = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
      _foundUser = null;
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

      // Check if trying to add own account
      final currentUserModel = await _firestoreService.getUser(user.uid);
      if (currentUserModel?.accountNumber == accountNumber) {
        setState(() {
          _searchError = 'Cannot add your own account as payee';
          _isSearching = false;
        });
        return;
      }

      final recipient = await _firestoreService.getUserByAccountNumber(accountNumber);

      if (recipient == null) {
        setState(() {
          _searchError = 'Account number not found';
          _isSearching = false;
          _foundUser = null;
        });
      } else {
        setState(() {
          _foundUser = recipient;
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _searchError = 'Error searching account: $e';
        _isSearching = false;
      });
    }
  }

  Future<void> _savePayee() async {
    if (_foundUser == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) return;

      // Check if already saved
      final existingRecipient = await _firestoreService.getSavedRecipientByAccountNumber(
        user.uid,
        _foundUser!.accountNumber!,
      );

      if (existingRecipient != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This payee is already saved'),
              backgroundColor: Colors.orange,
            ),
          );
          // Navigate to payee details
          final payee = SavedRecipientModel(
            id: existingRecipient.id,
            userId: existingRecipient.userId,
            recipientUserId: existingRecipient.recipientUserId,
            recipientAccountNumber: existingRecipient.recipientAccountNumber,
            recipientName: existingRecipient.recipientName,
            recipientEmail: existingRecipient.recipientEmail,
            savedAt: existingRecipient.savedAt,
            lastTransferredAt: existingRecipient.lastTransferredAt,
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PayeeDetailsScreen(
                payee: payee,
                userModel: _foundUser!,
              ),
            ),
          );
        }
        return;
      }

      // Save new recipient
      final newRecipient = SavedRecipientModel(
        id: '',
        userId: user.uid,
        recipientUserId: _foundUser!.id,
        recipientAccountNumber: _foundUser!.accountNumber!,
        recipientName: _foundUser!.displayName ?? _foundUser!.email,
        recipientEmail: _foundUser!.email,
        savedAt: DateTime.now(),
      );

      final recipientId = await _firestoreService.addSavedRecipient(newRecipient);

      if (mounted) {
        final savedRecipient = SavedRecipientModel(
          id: recipientId,
          userId: newRecipient.userId,
          recipientUserId: newRecipient.recipientUserId,
          recipientAccountNumber: newRecipient.recipientAccountNumber,
          recipientName: newRecipient.recipientName,
          recipientEmail: newRecipient.recipientEmail,
          savedAt: newRecipient.savedAt,
          lastTransferredAt: null,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payee saved successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to payee details
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PayeeDetailsScreen(
              payee: savedRecipient,
              userModel: _foundUser!,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving payee: $e'),
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
        title: const Text(
          'Account Details',
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Account Number/IBAN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accountNumberController,
                decoration: InputDecoration(
                  hintText: 'Enter account number (e.g., ACC-1234-5678-9012)',
                  prefixIcon: const Icon(Icons.account_circle),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                textInputAction: TextInputAction.search,
                onFieldSubmitted: (_) => _searchAccountNumber(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter account number';
                  }
                  return null;
                },
              ),
              if (_searchError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _searchError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
              const SizedBox(height: 24),

              // Search Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
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
                      : const Icon(Icons.search),
                  label: Text(_isSearching ? 'Searching...' : 'Search'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // Found User Details
              if (_foundUser != null) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: themeColor, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildDetailRow('Name', _foundUser!.displayName ?? _foundUser!.email),
                      const SizedBox(height: 12),
                      _buildDetailRow('Account Number', _foundUser!.accountNumber ?? 'N/A'),
                      if (_foundUser!.email.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow('Email', _foundUser!.email),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _foundUser != null
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePayee,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

