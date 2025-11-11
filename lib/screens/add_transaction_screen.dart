import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/transaction_model.dart';
import '../utils/currency_helper.dart';

class AddTransactionScreen extends StatefulWidget {
  final String? transactionType; // 'income' or 'expense'
  final TransactionModel? transaction; // For edit mode

  const AddTransactionScreen({
    super.key,
    this.transactionType,
    this.transaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  
  late final String _selectedType; // 'income' or 'expense'
  String _selectedCategory = 'Salary';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  String _currentCurrency = 'Rs.'; // User's current currency preference

  // Categories with icons
  final List<Map<String, dynamic>> incomeCategories = [
    {'name': 'Salary', 'icon': Icons.account_balance},
    {'name': 'Freelance', 'icon': Icons.work},
    {'name': 'Investment', 'icon': Icons.trending_up},
    {'name': 'Business', 'icon': Icons.business},
    {'name': 'Gift', 'icon': Icons.card_giftcard},
    {'name': 'Rental', 'icon': Icons.home},
    {'name': 'Other', 'icon': Icons.category},
  ];

  final List<Map<String, dynamic>> expenseCategories = [
    {'name': 'Food', 'icon': Icons.restaurant},
    {'name': 'Transport', 'icon': Icons.directions_car},
    {'name': 'Shopping', 'icon': Icons.shopping_bag},
    {'name': 'Bills', 'icon': Icons.receipt},
    {'name': 'Entertainment', 'icon': Icons.movie},
    {'name': 'Healthcare', 'icon': Icons.medical_services},
    {'name': 'Education', 'icon': Icons.school},
    {'name': 'Travel', 'icon': Icons.flight},
    {'name': 'Other', 'icon': Icons.category},
  ];

  @override
  void initState() {
    super.initState();
    
    // If editing existing transaction, populate fields
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _selectedType = t.type;
      _selectedCategory = t.category;
      _selectedDate = t.date;
      _amountController.text = t.amount.toStringAsFixed(2);
      _titleController.text = t.title;
      _descriptionController.text = t.description ?? '';
      _currentCurrency = t.originalCurrency;
    } else {
    // Set type from widget parameter, default to income if not provided
    _selectedType = widget.transactionType ?? 'income';
    
    // Set default category based on type
    if (_selectedType == 'income' && incomeCategories.isNotEmpty) {
      _selectedCategory = incomeCategories[0]['name'];
    } else if (_selectedType == 'expense' && expenseCategories.isNotEmpty) {
      _selectedCategory = expenseCategories[0]['name'];
      }
      
      // Load user's current currency preference
      _loadUserCurrency();
    }
  }

  Future<void> _loadUserCurrency() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userModel = await _firestoreService.getUser(user.uid);
        if (userModel?.preferences != null) {
          setState(() {
            _currentCurrency = userModel!.preferences!['currency'] ?? 'Rs.';
          });
        }
      }
    } catch (e) {
      print('Error loading user currency: $e');
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<String> _getCurrentCurrency() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userModel = await _firestoreService.getUser(user.uid);
        if (userModel?.preferences != null) {
          final currency = userModel!.preferences!['currency'] ?? 'Rs.';
          if (mounted) {
            setState(() {
              _currentCurrency = currency;
            });
          }
          return currency;
        }
      }
      return _currentCurrency;
    } catch (e) {
      print('Error getting current currency: $e');
      return _currentCurrency;
    }
  }

  IconData _getCurrencyIcon(String currency) {
    switch (currency) {
      case 'Rs.':
      case '₹':
        return Icons.currency_rupee;
      case '\$':
      case 'A\$':
      case 'C\$':
        return Icons.attach_money;
      case '€':
        return Icons.euro;
      case '£':
        return Icons.currency_pound;
      case '¥':
        return Icons.currency_yen;
      default:
        return Icons.currency_exchange;
    }
  }

  String _getCurrencyName(String currency) {
    switch (currency) {
      case 'Rs.':
        return 'Pakistani Rupee (PKR)';
      case '\$':
        return 'US Dollar (USD)';
      case '€':
        return 'Euro (EUR)';
      case '£':
        return 'British Pound (GBP)';
      case '¥':
        return 'Japanese Yen (JPY)';
      case '₹':
        return 'Indian Rupee (INR)';
      case 'A\$':
        return 'Australian Dollar (AUD)';
      case 'C\$':
        return 'Canadian Dollar (CAD)';
      default:
        return 'Unknown Currency';
    }
  }

  Future<String> _getUserDefaultCurrency() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userModel = await _firestoreService.getUser(user.uid);
        if (userModel?.preferences != null) {
          return userModel!.preferences!['currency'] ?? 'Rs.';
        }
      }
      return 'Rs.';
    } catch (e) {
      return 'Rs.';
    }
  }

  void _showCurrencySelectionDialog() {
    final currencies = [
      {'symbol': 'Rs.', 'name': 'Pakistani Rupee (PKR)', 'code': 'PKR'},
      {'symbol': '\$', 'name': 'US Dollar (USD)', 'code': 'USD'},
      {'symbol': '€', 'name': 'Euro (EUR)', 'code': 'EUR'},
      {'symbol': '£', 'name': 'British Pound (GBP)', 'code': 'GBP'},
      {'symbol': '¥', 'name': 'Japanese Yen (JPY)', 'code': 'JPY'},
      {'symbol': '₹', 'name': 'Indian Rupee (INR)', 'code': 'INR'},
      {'symbol': 'A\$', 'name': 'Australian Dollar (AUD)', 'code': 'AUD'},
      {'symbol': 'C\$', 'name': 'Canadian Dollar (CAD)', 'code': 'CAD'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: currencies.map((currency) {
              return _buildCurrencyOption(
                currency['symbol']!,
                currency['name']!,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(String symbol, String name) {
    final isSelected = _currentCurrency == symbol;
    return ListTile(
      leading: Icon(
        _getCurrencyIcon(symbol),
        color: isSelected 
            ? Theme.of(context).colorScheme.primary 
            : Colors.grey[600],
      ),
      title: Text(name),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () {
        setState(() {
          _currentCurrency = symbol;
        });
        Navigator.pop(context);
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _showSuccessDialog({
    required String title,
    required double amount,
    required String type,
    required String category,
  }) async {
    final isIncome = type == 'income';
    final accentColor = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final icon = isIncome ? Icons.arrow_downward : Icons.arrow_upward;
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 50,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                '${isIncome ? 'Income' : 'Expense'} Added!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Transaction Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: accentColor,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        FutureBuilder<String>(
                          future: _getCurrentCurrency(),
                          builder: (context, snapshot) {
                            final currency = snapshot.data ?? _currentCurrency;
                            return Text(
                              '$currency${amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    
                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    
                    // Category
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.category,
                              size: 16,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              category,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Message
              Text(
                'Your ${isIncome ? 'income' : 'expense'} has been recorded successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              
              // Close Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  void _showInsufficientBalanceDialog(double currentBalance, double expenseAmount) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final shortfall = expenseAmount - currentBalance;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 40,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              const Text(
                'Insufficient Balance',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              // Balance Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current Balance',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$_currentCurrency${currentBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Expense Amount',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$_currentCurrency${expenseAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Shortfall',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                          Text(
                            '$_currentCurrency${shortfall.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Message
              Text(
                'You cannot expense more than your available balance. Please add income first or reduce the expense amount.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              
              // Close Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Okay',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final amount = double.parse(_amountController.text.trim());
      final isEditMode = widget.transaction != null;
      
      // Validate expense amount against balance (only for new transactions)
      if (_selectedType == 'expense' && !isEditMode) {
        // Get all transactions and convert to expense currency for accurate balance check
        final transactionsStream = _firestoreService.getTransactions(user.uid);
        final transactionsSnapshot = await transactionsStream.first;
        
        double totalIncome = 0.0;
        double totalExpense = 0.0;
        
        // Convert all transactions to expense currency
        for (var transaction in transactionsSnapshot) {
          double convertedAmount;
          if (transaction.originalCurrency == _currentCurrency) {
            convertedAmount = transaction.originalAmount;
          } else {
            // Convert to expense currency
            convertedAmount = await CurrencyHelper.getConvertedAmount(
              transaction,
              currency: _currentCurrency,
            );
          }
          
          if (transaction.type == 'income') {
            totalIncome += convertedAmount;
          } else {
            totalExpense += convertedAmount;
          }
        }
        
        final currentBalance = totalIncome - totalExpense;
        
        if (amount > currentBalance) {
          if (mounted) {
            setState(() {
              _isSaving = false;
            });
            _showInsufficientBalanceDialog(currentBalance, amount);
          }
          return;
        }
      }
      
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim();
      final now = DateTime.now();

      // Get currency for transaction
      String originalCurrency = 'Rs.'; // Default
      if (!isEditMode) {
        // For new transactions, use the selected currency (or default to user preference)
        originalCurrency = _currentCurrency;
      } else {
        // For editing, keep original currency
        originalCurrency = widget.transaction!.originalCurrency;
      }

      // Generate transaction ID if creating new transaction
      String? transactionId;
      if (!isEditMode) {
        // Will be generated after Firestore creates the document
        // We'll update it after getting the Firestore document ID
        transactionId = null; // Will be set after document creation
      } else {
        // Keep existing transaction ID when editing
        transactionId = widget.transaction!.transactionId;
      }

      final transaction = TransactionModel(
        id: isEditMode ? widget.transaction!.id : '', // Use existing ID if editing
        userId: user.uid,
        type: _selectedType,
        title: title,
        description: description,
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
        createdAt: isEditMode ? widget.transaction!.createdAt : now, // Keep original creation date
        updatedAt: isEditMode ? now : null, // Set updatedAt only when editing
        originalCurrency: originalCurrency,
        originalAmountParam: isEditMode ? widget.transaction!.originalAmount : amount, // Keep original amount when editing
        transactionId: transactionId,
      );

      String? createdTransactionId;
      if (isEditMode) {
        await _firestoreService.updateTransaction(transaction);
      } else {
        // Create transaction and get the Firestore document ID
        createdTransactionId = await _firestoreService.addTransaction(transaction);
        
        // Generate and save transaction ID
        if (createdTransactionId != null) {
          final generatedTransactionId = TransactionModel.generateTransactionId(
            createdTransactionId,
            _selectedDate,
          );
          
          // Update transaction with the generated ID
          final updatedTransaction = transaction.copyWith(
            id: createdTransactionId,
            transactionId: generatedTransactionId,
          );
          await _firestoreService.updateTransaction(updatedTransaction);
        }
      }

      if (mounted) {
        // Show success dialog
        await _showSuccessDialog(
          title: title,
          amount: amount,
          type: _selectedType,
          category: _selectedCategory,
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving transaction: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = _selectedType == 'income';
    final currentCategories = isIncome ? incomeCategories : expenseCategories;
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
        title: Text(
          widget.transaction != null
              ? 'Edit ${isIncome ? 'Income' : 'Expense'}'
              : 'Add ${isIncome ? 'Income' : 'Expense'}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Amount Input
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getCurrencyIcon(_currentCurrency),
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Amount ($_currentCurrency)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        prefixText: '$_currentCurrency ',
                        prefixStyle: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        border: InputBorder.none,
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          fontSize: 32,
                          color: Colors.grey[300],
                          fontWeight: FontWeight.w300,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter valid amount';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Amount must be greater than 0';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Currency Selection (Optional)
              if (widget.transaction == null) // Only show for new transactions, not edit mode
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.currency_exchange,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Currency (Optional)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _showCurrencySelectionDialog(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getCurrencyIcon(_currentCurrency),
                                    size: 24,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  FutureBuilder<String>(
                                    future: _getUserDefaultCurrency(),
                                    builder: (context, snapshot) {
                                      final defaultCurrency = snapshot.data ?? 'Rs.';
                                      final isDefault = _currentCurrency == defaultCurrency;
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _getCurrencyName(_currentCurrency),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isDefault 
                                                ? 'Default currency'
                                                : 'Default: ${_getCurrencyName(defaultCurrency)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey[600],
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Title Input
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.title,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Title',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Enter transaction title',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter title';
                        }
                        if (value.trim().isEmpty) {
                          return 'Title cannot be empty';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Category Selection
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.category,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: currentCategories.length,
                      itemBuilder: (context, index) {
                        final category = currentCategories[index];
                        final categoryName = category['name'];
                        final categoryIcon = category['icon'];
                        final isSelected = _selectedCategory == categoryName;
                        final accentColor = isIncome
                            ? const Color(0xFF10B981) // Green
                            : const Color(0xFFEF4444); // Red

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = categoryName;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accentColor.withOpacity(0.1)
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? accentColor
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  categoryIcon,
                                  color: isSelected
                                      ? accentColor
                                      : Colors.grey[600],
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  categoryName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? accentColor
                                        : Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Date Selection
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey[400],
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Description Input
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.note,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Description (Optional)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Add any additional notes or details...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Save Button
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                width: double.infinity,
                height: 56,
                  child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    shadowColor: themeColor.withOpacity(0.3),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white, size: 22),
                            const SizedBox(width: 8),
                            const Text(
                              'Save Transaction',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}

