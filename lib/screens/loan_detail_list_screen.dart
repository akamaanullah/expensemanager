import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/loan_model.dart';
import 'loan_detail_screen.dart';
import 'package:intl/intl.dart';

class LoanDetailListScreen extends StatelessWidget {
  final String type; // 'given' or 'taken'
  final String title;

  const LoanDetailListScreen({
    super.key,
    required this.type,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final _firestoreService = FirestoreService();
    final _auth = FirebaseAuth.instance;
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
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder<List<LoanModel>>(
        stream: _firestoreService.getLoans(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final allLoans = snapshot.data ?? [];
          
          // Filter loans by type
          final filteredLoans = allLoans.where((loan) => loan.type == type).toList();

          if (filteredLoans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type == 'taken' ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ${type == 'taken' ? 'loans taken' : 'loans given'} yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type == 'taken'
                        ? 'You haven\'t taken any loans yet'
                        : 'You haven\'t given any loans yet',
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

          // Calculate total for each person
          final personTotals = <String, double>{};
          for (var entry in groupedLoans.entries) {
            final total = entry.value.fold<double>(
              0,
              (sum, loan) => sum + loan.amount,
            );
            personTotals[entry.key] = total;
          }

          // Sort by total amount (descending)
          final sortedPersons = personTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return Column(
            children: [
              // Total Summary Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          type == 'taken' ? Icons.arrow_downward : Icons.arrow_upward,
                          color: type == 'taken' ? Colors.orange : Colors.green,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Total ${type == 'taken' ? 'Taken' : 'Given'}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Rs. ${filteredLoans.fold<double>(0, (sum, loan) => sum + loan.amount).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: type == 'taken' ? Colors.orange : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${groupedLoans.length} ${groupedLoans.length == 1 ? 'person' : 'persons'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Person-wise List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sortedPersons.length,
                  itemBuilder: (context, index) {
                    final personName = sortedPersons[index].key;
                    final totalAmount = sortedPersons[index].value;
                    final personLoans = groupedLoans[personName]!;

                    return _buildPersonCard(
                      context,
                      personName,
                      totalAmount,
                      personLoans,
                      themeColor,
                      type == 'taken' ? Colors.orange : Colors.green,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPersonCard(
    BuildContext context,
    String personName,
    double totalAmount,
    List<LoanModel> loans,
    Color themeColor,
    Color amountColor,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
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
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: themeColor.withOpacity(0.1),
          child: Text(
            personName[0].toUpperCase(),
            style: TextStyle(
              color: themeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          personName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '${loans.length} ${loans.length == 1 ? 'transaction' : 'transactions'}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Rs. ${totalAmount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
          ],
        ),
        children: loans.map((loan) {
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: amountColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                type == 'taken' ? Icons.arrow_downward : Icons.arrow_upward,
                color: amountColor,
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoanDetailScreen(loan: loan),
                  ),
                );
              },
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
        }).toList(),
      ),
    );
  }
}



