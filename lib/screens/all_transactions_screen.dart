import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/transaction_model.dart';
import '../utils/category_utils.dart';
import '../utils/currency_helper.dart';
import 'transaction_detail_screen.dart';
import 'statement_download_screen.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();
  String _selectedFilter = 'All'; // All, Income, Expense
  bool _isSearching = false;
  String _searchQuery = '';
  
  // Date range filter
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isDateFilterActive = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<TransactionModel>> _getFilteredStream() {
    final user = _authService.currentUser;
    if (user == null) return const Stream.empty();
    
    // If date filter is active, use date range query
    if (_isDateFilterActive && _startDate != null && _endDate != null) {
      // For date range, we need to fetch and filter manually
      return Stream.fromFuture(_getDateRangeTransactions(user.uid));
    }
    
    // Otherwise use existing type-based filters
    if (_selectedFilter == 'All') {
      return _firestoreService.getTransactions(user.uid);
    } else if (_selectedFilter == 'Income') {
      return _firestoreService.getTransactionsByType(user.uid, 'income');
    } else {
      return _firestoreService.getTransactionsByType(user.uid, 'expense');
    }
  }

  Future<List<TransactionModel>> _getDateRangeTransactions(String userId) async {
    try {
      // Get transactions in date range
      List<TransactionModel> transactions = await _firestoreService.getTransactionsByDateRange(
        userId,
        _startDate!,
        _endDate!,
      );
      
      // Apply type filter if not 'All'
      if (_selectedFilter != 'All') {
        final type = _selectedFilter.toLowerCase();
        transactions = transactions.where((t) => t.type == type).toList();
      }
      
      return transactions;
    } catch (e) {
      print('Error fetching date range transactions: $e');
      return [];
    }
  }

  List<TransactionModel> _filterTransactionsBySearch(List<TransactionModel> transactions) {
    if (_searchQuery.isEmpty) return transactions;
    
    final query = _searchQuery.toLowerCase();
    return transactions.where((transaction) {
      final title = transaction.title.toLowerCase();
      final category = transaction.category.toLowerCase();
      final description = transaction.description?.toLowerCase() ?? '';
      
      return title.contains(query) || 
             category.contains(query) || 
             description.contains(query);
    }).toList();
  }

  Map<String, List<TransactionModel>> _groupTransactionsByDate(List<TransactionModel> transactions) {
    final grouped = <String, List<TransactionModel>>{};
    
    for (var transaction in transactions) {
      final groupKey = CategoryUtils.getGroupKey(transaction.date);
      
      if (!grouped.containsKey(groupKey)) {
        grouped[groupKey] = [];
      }
      grouped[groupKey]!.add(transaction);
    }
    
    return grouped;
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
          'All Transactions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          // Download Statement button
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: 'Download Statement',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StatementDownloadScreen(),
                ),
              );
            },
          ),
          // Date filter button
          IconButton(
            icon: Stack(
              children: [
                Icon(
                  Icons.date_range,
                  color: _isDateFilterActive ? Colors.amber : Colors.white,
                ),
                if (_isDateFilterActive)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filter by Date Range',
            onPressed: () => _showDateRangePicker(),
          ),
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
        ],
        bottom: _isSearching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  color: themeColor,
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search by title, category, or description...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          // Date Range Filter Display (if active)
          if (_isDateFilterActive && _startDate != null && _endDate != null)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue[200]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date Range Filter',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[900],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.blue[700],
                    ),
                    onPressed: () {
                      setState(() {
                        _isDateFilterActive = false;
                        _startDate = null;
                        _endDate = null;
                      });
                    },
                    tooltip: 'Clear Date Filter',
                  ),
                ],
              ),
            ),
          
          // Filter Tabs
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(4),
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
              children: [
                Expanded(
                  child: _buildFilterButton('All', themeColor, () {
                    setState(() {
                      _selectedFilter = 'All';
                    });
                  }),
                ),
                Expanded(
                  child: _buildFilterButton('Income', const Color(0xFF10B981), () {
                    setState(() {
                      _selectedFilter = 'Income';
                    });
                  }),
                ),
                Expanded(
                  child: _buildFilterButton('Expense', const Color(0xFFEF4444), () {
                    setState(() {
                      _selectedFilter = 'Expense';
                    });
                  }),
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: _getFilteredStream(),
              builder: (context, transactionsSnapshot) {
                if (transactionsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (transactionsSnapshot.hasError) {
                  final error = transactionsSnapshot.error.toString();
                  final isIndexError = error.contains('index') || error.contains('FAILED_PRECONDITION');
                  
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isIndexError 
                                ? 'Index Required' 
                                : 'Error Loading Transactions',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isIndexError
                                ? 'Please create the required Firestore index. This may take a few minutes.'
                                : 'An error occurred while loading transactions.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (isIndexError) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'The index is being created. Please wait 2-5 minutes.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'You can check the status in Firebase Console → Firestore → Indexes',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                final transactions = transactionsSnapshot.data ?? [];
                
                // Apply search filter
                final filteredTransactions = _filterTransactionsBySearch(transactions);
                
                if (filteredTransactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty 
                              ? Icons.search_off 
                              : Icons.receipt_long,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try searching with different keywords'
                              : 'Start adding transactions to see them here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final groupedTransactions = _groupTransactionsByDate(filteredTransactions);
                
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: groupedTransactions.length,
                  itemBuilder: (context, index) {
                    final groupKey = groupedTransactions.keys.elementAt(index);
                    final groupTransactions = groupedTransactions[groupKey]!;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                          child: Text(
                            groupKey,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        // Transactions in this group
                        ...groupTransactions.map((transaction) {
                          return _buildTransactionItem(transaction);
                        }).toList(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showDateRangePicker() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year - 5);
    final DateTime lastDate = DateTime(now.year + 1);

    // Show start date picker
    final DateTime? pickedStart = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now.subtract(const Duration(days: 30)),
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Start Date',
    );

    if (pickedStart == null) return;

    // Show end date picker (must be after start date)
    final DateTime? pickedEnd = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (pickedStart.add(const Duration(days: 30))),
      firstDate: pickedStart,
      lastDate: lastDate,
      helpText: 'Select End Date',
    );

    if (pickedEnd == null) return;

    // Ensure end date is not before start date
    if (pickedEnd.isBefore(pickedStart)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End date must be after start date'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() {
      _startDate = DateTime(pickedStart.year, pickedStart.month, pickedStart.day);
      _endDate = DateTime(pickedEnd.year, pickedEnd.month, pickedEnd.day, 23, 59, 59);
      _isDateFilterActive = true;
    });
  }

  Widget _buildFilterButton(String label, Color color, VoidCallback onTap) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
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
              color: isCredit
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        transaction.description ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        transaction.category,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
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
                  color: isCredit
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isCredit
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444))
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCredit ? 'Credit' : 'Debit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isCredit
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
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

