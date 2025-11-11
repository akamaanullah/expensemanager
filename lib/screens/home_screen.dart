import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/transaction_model.dart';
import '../utils/category_utils.dart';
import '../utils/currency_helper.dart';
import 'add_transaction_screen.dart';
import 'all_transactions_screen.dart';
import 'settings_screen.dart';
import 'transaction_detail_screen.dart';
import 'loans_screen.dart';
import 'calculator_screen.dart';
import 'my_payees_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  bool _isBalanceVisible = true; // Default to visible

  @override
  void initState() {
    super.initState();
    // Check authentication on init
    _checkAuthentication();
  }

  void _checkAuthentication() {
    final user = _authService.currentUser;
    if (user == null) {
      // User not logged in, redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      });
    }
  }

  // Calculate totals with currency conversion
  Future<Map<String, dynamic>> _calculateConvertedTotals(
    List<TransactionModel> transactions,
    String? currency,
  ) async {
    double totalIncome = 0.0;
    double totalExpense = 0.0;
    final userCurrency = currency ?? await CurrencyHelper.getUserCurrency();

      for (var transaction in transactions) {
      // Convert amount based on user's currency preference
      final convertedAmount = await CurrencyHelper.getConvertedAmount(
        transaction,
        currency: userCurrency,
      );
      
      if (transaction.type == 'income') {
        totalIncome += convertedAmount;
      } else {
        totalExpense += convertedAmount;
      }
    }

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'totalBalance': totalIncome - totalExpense,
      'currency': userCurrency,
    };
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button from going back
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        // Handle Android back button - show exit dialog
        if (didPop) return;
        
        // Show exit confirmation dialog
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                  SystemNavigator.pop(); // Exit app
                },
                child: const Text('Exit', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        
        if (shouldExit == true) {
          SystemNavigator.pop(); // Exit app
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.primary,
          automaticallyImplyLeading: false, // Remove back button
          title: const Text(
            'Expense Manager',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh',
              onPressed: () {
                setState(() {
                  // Force rebuild to refresh data
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              tooltip: 'My Payees',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyPayeesScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.calculate, color: Colors.white),
              tooltip: 'Calculator',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CalculatorScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Total Balance Card - Dynamic from Firestore
            StreamBuilder<List<TransactionModel>>(
              stream: _authService.currentUser != null
                  ? _firestoreService.getTransactions(_authService.currentUser!.uid)
                  : null,
              builder: (context, transactionsSnapshot) {
                if (transactionsSnapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primaryContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }

                if (transactionsSnapshot.hasError) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Error: ${transactionsSnapshot.error}'),
                  );
                }

                final transactions = transactionsSnapshot.data ?? [];
                final userId = _authService.currentUser?.uid;
                
                // Listen to user preferences for real-time currency updates
                return StreamBuilder(
                  stream: userId != null 
                      ? _firestoreService.getUserStream(userId)
                      : null,
                  builder: (context, userSnapshot) {
                    // Get currency from user preferences (real-time)
                    final userCurrency = userSnapshot.data?.preferences?['currency'] ?? 'Rs.';
                    
                    // Calculate totals with currency conversion
                    return FutureBuilder<Map<String, dynamic>>(
                      future: _calculateConvertedTotals(transactions, userCurrency),
                      builder: (context, totalsSnapshot) {
                    if (totalsSnapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primaryContainer,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );
                    }

                        final totals = totalsSnapshot.data ?? {
                          'totalIncome': 0.0,
                          'totalExpense': 0.0,
                          'totalBalance': 0.0,
                          'currency': 'Rs.',
                        };
                        final totalIncome = totals['totalIncome'] as double;
                        final totalExpense = totals['totalExpense'] as double;
                        final totalBalance = totals['totalBalance'] as double;
                        final currency = totals['currency'] as String;

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Balance',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white70,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _isBalanceVisible = !_isBalanceVisible;
                              });
                            },
                            tooltip: _isBalanceVisible ? 'Hide Balance' : 'Show Balance',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isBalanceVisible
                            ? '${currency}${totalBalance.toStringAsFixed(2)}'
                            : '${currency}••••••',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Income',
                                      '${currency}${totalIncome.toStringAsFixed(2)}',
                              Icons.arrow_downward,
                              Colors.green[300]!,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Expense',
                                      '${currency}${totalExpense.toStringAsFixed(2)}',
                              Icons.arrow_upward,
                              Colors.red[300]!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                        );
                      },
                    );
                  },
                );
              },
            ),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      'Add Income',
                      Icons.add_circle_outline,
                      Colors.green,
                      () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddTransactionScreen(
                              transactionType: 'income',
                            ),
                          ),
                        );
                        // Refresh if transaction was added
                        if (result == true) {
                          setState(() {});
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionButton(
                      'Add Expense',
                      Icons.remove_circle_outline,
                      Colors.red,
                      () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddTransactionScreen(
                              transactionType: 'expense',
                            ),
                          ),
                        );
                        // Refresh if transaction was added
                        if (result == true) {
                          setState(() {});
                        }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: _buildQuickActionButton(
                      'Manage Loans',
                      Icons.account_balance_wallet,
                      Theme.of(context).colorScheme.primary,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoansScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Recent Transactions Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AllTransactionsScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Transaction List - Dynamic from Firestore
            StreamBuilder<List<TransactionModel>>(
              stream: _authService.currentUser != null
                  ? _firestoreService.getTransactions(_authService.currentUser!.uid)
                  : null,
              builder: (context, transactionsSnapshot) {
                if (transactionsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (transactionsSnapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Error: ${transactionsSnapshot.error}'),
                  );
                }

                final transactions = transactionsSnapshot.data ?? [];
                final userId = _authService.currentUser?.uid;
                
                // Listen to user preferences for real-time currency updates
                return StreamBuilder(
                  stream: userId != null 
                      ? _firestoreService.getUserStream(userId)
                      : null,
                  builder: (context, userSnapshot) {
                if (transactions.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your first transaction to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Show only recent 5 transactions
                final recentTransactions = transactions.take(5).toList();
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = recentTransactions[index];
                    return _buildTransactionItem(transaction);
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStatCard(String label, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  amount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final isCredit = transaction.type == 'income';
    final categoryIcon = CategoryUtils.getCategoryIcon(transaction.category);
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(
              transaction: transaction,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: (isCredit ? Colors.green : Colors.red).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              categoryIcon,
              color: isCredit ? Colors.green : Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description ?? transaction.category,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CategoryUtils.formatDate(transaction.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}${transaction.originalCurrency}${transaction.originalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCredit ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isCredit ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCredit ? 'Credit' : 'Debit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isCredit ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

