import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/loan_model.dart';
import 'add_loan_screen.dart';
import 'loan_detail_screen.dart';
import 'loan_detail_list_screen.dart';
import 'package:intl/intl.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  final _firestoreService = FirestoreService();
  final _auth = FirebaseAuth.instance;
  
  String _searchQuery = '';
  String? _selectedPerson;
  List<String> _persons = [];
  Future<Map<String, double>>? _loanTotalsFuture;
  
  // Cache the stream to prevent recreation
  Stream<List<LoanModel>>? _loansStream;
  
  // Track expanded state for person cards
  final Set<String> _expandedPersons = {};

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _loanTotalsFuture = _firestoreService.getLoanTotals(user.uid);
      _loansStream = _firestoreService.getLoans(user.uid);
    }
    _loadPersons();
  }

  Future<void> _loadPersons() async {
    final user = _auth.currentUser;
    if (user != null) {
      final persons = await _firestoreService.getLoanPersons(user.uid);
      if (mounted) {
        setState(() {
          _persons = persons;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view loans')),
      );
    }

    final themeColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: themeColor,
        title: const Text(
          'Loans Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddLoanScreen(),
                ),
              );
              if (result == true) {
                _loadPersons();
                // Refresh loan totals
                final user = _auth.currentUser;
                if (user != null) {
                  setState(() {
                    _loanTotalsFuture = _firestoreService.getLoanTotals(user.uid);
                  });
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards - Use FutureBuilder directly
          _buildSummaryCards(user.uid, themeColor),

          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by person name...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Person Filter
                if (_persons.isNotEmpty)
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _persons.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: const Text('All'),
                              selected: _selectedPerson == null,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedPerson = null;
                                });
                              },
                            ),
                          );
                        }
                        final person = _persons[index - 1];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(person),
                            selected: _selectedPerson == person,
                            onSelected: (selected) {
                              setState(() {
                                _selectedPerson = selected ? person : null;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Loans List
          Expanded(
            child: RepaintBoundary(
              child: StreamBuilder<List<LoanModel>>(
                stream: _loansStream,
                builder: (context, snapshot) {
                  // Prevent infinite rebuilds by checking connection state properly
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final loans = snapshot.data ?? [];
                  
                  // Early return for empty list to prevent unnecessary rebuilds
                  if (loans.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No loans yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your first loan to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  // Filter by search query
                  final searchLower = _searchQuery.toLowerCase();
                  var filteredLoans = loans.where((loan) {
                    return loan.personName.toLowerCase().contains(searchLower);
                  }).toList();

                  // Filter by selected person
                  if (_selectedPerson != null) {
                    filteredLoans = filteredLoans.where((loan) {
                      return loan.personName == _selectedPerson;
                    }).toList();
                  }

                  if (filteredLoans.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty || _selectedPerson != null
                                ? 'No loans found'
                                : 'No loans yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty || _selectedPerson != null
                                ? 'Try different search or filter'
                                : 'Add your first loan to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Group by person
                  final groupedLoans = <String, List<LoanModel>>{};
                  for (var loan in filteredLoans) {
                    if (!groupedLoans.containsKey(loan.personName)) {
                      groupedLoans[loan.personName] = [];
                    }
                    groupedLoans[loan.personName]!.add(loan);
                  }

                  // Create stable list of person names to prevent rebuilds
                  final personNames = groupedLoans.keys.toList()..sort();

                  return RepaintBoundary(
                    child: ListView.builder(
                      key: ValueKey('loans_list_${personNames.length}_${_searchQuery}_${_selectedPerson}'),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: personNames.length,
                      itemBuilder: (context, index) {
                        final personName = personNames[index];
                        final personLoans = groupedLoans[personName]!;
                        
                        return RepaintBoundary(
                          key: ValueKey('person_card_$personName'),
                          child: _buildPersonLoanCard(
                            context,
                            personName,
                            personLoans,
                            user.uid,
                            themeColor,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(String userId, Color themeColor) {
    // Don't recreate future here - it's already initialized in initState
    return RepaintBoundary(
      child: FutureBuilder<Map<String, double>>(
        future: _loanTotalsFuture,
        builder: (context, snapshot) {
          // Only show loading on first load
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          
          // If no data and not loading, return empty
          if (!snapshot.hasData || snapshot.hasError) {
            return const SizedBox.shrink();
          }

        final totals = snapshot.data!;
        final totalGiven = totals['totalGiven'] ?? 0;
        final totalTaken = totals['totalTaken'] ?? 0;
        final netBalance = totals['netBalance'] ?? 0;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoanDetailListScreen(
                          type: 'given',
                          title: 'Loans Given',
                        ),
                      ),
                    );
                  },
                  child: _buildSummaryItem(
                    'Total Given',
                    totalGiven,
                    Colors.green,
                    Icons.arrow_upward,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.grey[300],
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoanDetailListScreen(
                          type: 'taken',
                          title: 'Loans Taken',
                        ),
                      ),
                    );
                  },
                  child: _buildSummaryItem(
                    'Total Taken',
                    totalTaken,
                    Colors.orange,
                    Icons.arrow_downward,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.grey[300],
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Net Balance',
                  netBalance.abs(),
                  netBalance >= 0 ? Colors.red : Colors.blue,
                  netBalance >= 0 ? Icons.remove_circle : Icons.add_circle,
                  isNet: true,
                  netBalance: netBalance,
                ),
              ),
            ],
          ),
        );
      },
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    double amount,
    Color color,
    IconData icon, {
    bool isNet = false,
    double? netBalance,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Column(
            children: [
              Text(
                isNet && netBalance != null
                    ? (netBalance >= 0 ? 'You owe' : 'You get')
                    : 'Rs. ${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              if (isNet && netBalance != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Rs. ${netBalance.abs().toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
          if (!isNet) ...[
            const SizedBox(height: 4),
            Icon(
              Icons.touch_app,
              size: 12,
              color: Colors.grey[400],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonLoanCard(
    BuildContext context,
    String personName,
    List<LoanModel> loans,
    String userId,
    Color themeColor,
  ) {
    // Calculate balance directly from loans list instead of FutureBuilder
    // This prevents rebuild issues
    double balance = 0;
    for (var loan in loans) {
      if (loan.type == 'taken') {
        balance += loan.amount; // You owe them
      } else {
        balance -= loan.amount; // They owe you
      }
    }
    final isOwed = balance > 0;
    final isExpanded = _expandedPersons.contains(personName);

    return Container(
      key: ValueKey('person_container_$personName'),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header (always visible)
          InkWell(
            onTap: () {
              if (mounted) {
                setState(() {
                  if (isExpanded) {
                    _expandedPersons.remove(personName);
                  } else {
                    _expandedPersons.add(personName);
                  }
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: themeColor.withOpacity(0.1),
                    child: Text(
                      personName[0].toUpperCase(),
                      style: TextStyle(
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          personName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${loans.length} ${loans.length == 1 ? 'transaction' : 'transactions'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        balance == 0
                            ? 'Settled'
                            : isOwed
                                ? 'You owe'
                                : 'You get',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Rs. ${balance.abs().toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isOwed ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          if (isExpanded) ...[
            const Divider(height: 1),
            // Pay Button (if balance exists)
            if (balance != 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddLoanScreen(
                            preSelectedPerson: personName,
                            personBalance: balance,
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        final user = _auth.currentUser;
                        if (user != null) {
                          _loanTotalsFuture = _firestoreService.getLoanTotals(user.uid);
                        }
                      }
                    },
                    icon: Icon(
                      isOwed ? Icons.payment : Icons.arrow_downward,
                      color: Colors.white,
                    ),
                    label: Text(
                      isOwed ? 'Pay ${personName}' : 'Receive from ${personName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOwed ? Colors.red : Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            // Loan items
            ...loans.asMap().entries.map((entry) {
              final index = entry.key;
              final loan = entry.value;
              return RepaintBoundary(
                key: ValueKey('loan_item_${loan.id}_$index'),
                child: _buildLoanItem(context, loan, themeColor),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildLoanItem(
    BuildContext context,
    LoanModel loan,
    Color themeColor, {
    Key? key,
  }) {
    final isTaken = loan.type == 'taken';
    final dateFormat = DateFormat('MMM dd, yyyy');

    return ListTile(
      key: key ?? ValueKey('loan_tile_${loan.id}'),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isTaken ? Colors.orange : Colors.green).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isTaken ? Icons.arrow_downward : Icons.arrow_upward,
          color: isTaken ? Colors.orange : Colors.green,
          size: 20,
        ),
      ),
      title: Text(
        'Rs. ${loan.amount.toStringAsFixed(0)}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateFormat.format(loan.date),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          if (loan.description != null && loan.description!.isNotEmpty)
            Text(
              loan.description!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: Text(
        isTaken ? 'Taken' : 'Given',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isTaken ? Colors.orange : Colors.green,
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoanDetailScreen(loan: loan),
          ),
        );
      },
    );
  }
}

