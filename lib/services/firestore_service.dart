import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../models/category_model.dart';
import '../models/loan_model.dart';
import '../models/saved_recipient_model.dart';
import 'notification_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== TRANSACTIONS ====================

  // Create a new transaction
  Future<String> addTransaction(TransactionModel transaction) async {
    try {
      final docRef = await _firestore
          .collection('transactions')
          .add(transaction.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error adding transaction: $e');
    }
  }

  // Get all transactions for a user
  Stream<List<TransactionModel>> getTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get transactions by type (income/expense)
  Stream<List<TransactionModel>> getTransactionsByType(
    String userId,
    String type,
  ) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get transactions by date range
  Future<List<TransactionModel>> getTransactionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error fetching transactions: $e');
    }
  }

  // Get transaction by ID
  Future<TransactionModel?> getTransaction(String transactionId) async {
    try {
      final doc = await _firestore.collection('transactions').doc(transactionId).get();
      if (doc.exists) {
        return TransactionModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching transaction: $e');
    }
  }

  // Update transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _firestore
          .collection('transactions')
          .doc(transaction.id)
          .update({
        ...transaction.toMap(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error updating transaction: $e');
    }
  }

  // Delete transaction
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).delete();
    } catch (e) {
      throw Exception('Error deleting transaction: $e');
    }
  }

  // Get transaction totals
  Future<Map<String, double>> getTransactionTotals(String userId) async {
    try {
      final transactions = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();

      double totalIncome = 0;
      double totalExpense = 0;

      for (var doc in transactions.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0).toDouble();
        if (data['type'] == 'income') {
          totalIncome += amount;
        } else {
          totalExpense += amount;
        }
      }

      return {
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'totalBalance': totalIncome - totalExpense,
      };
    } catch (e) {
      throw Exception('Error calculating totals: $e');
    }
  }

  // ==================== USERS ====================

  // Create or update user
  // IMPORTANT: Preserves existing accountNumber if it exists
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.id);
      final existingDoc = await docRef.get();
      
      // Prepare user data
      Map<String, dynamic> userData = user.toMap();
      
      // If document exists and has accountNumber, preserve it
      if (existingDoc.exists) {
        final existingData = existingDoc.data();
        final existingAccountNumber = existingData?['accountNumber'];
        
        // Preserve existing accountNumber if it exists
        if (existingAccountNumber != null && existingAccountNumber.toString().isNotEmpty) {
          userData['accountNumber'] = existingAccountNumber;
        }
      }
      
      await docRef.set(userData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error creating/updating user: $e');
    }
  }

  // Get user by ID
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  // Stream user by ID (for real-time updates)
  Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromMap(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }

  // Update user preferences
  Future<void> updateUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      // First check if document exists
      final docRef = _firestore.collection('users').doc(userId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        // Document doesn't exist, create it with preferences
        // Get user email from Firebase Auth
        try {
          final user = FirebaseAuth.instance.currentUser;
          await docRef.set({
            'id': userId,
            'email': user?.email ?? '',
            'preferences': preferences,
            'createdAt': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));
        } catch (e) {
          throw Exception('Error creating user document: $e');
        }
      } else {
        // Document exists, update preferences
        await docRef.update({
        'preferences': preferences,
      });
      }
    } catch (e) {
      // If update fails, try set with merge as fallback
      try {
        await _firestore.collection('users').doc(userId).set({
          'preferences': preferences,
        }, SetOptions(merge: true));
      } catch (e2) {
        throw Exception('Error updating user preferences: $e2');
      }
    }
  }

  // ==================== CATEGORIES ====================

  // Add category
  Future<String> addCategory(CategoryModel category) async {
    try {
      final docRef = await _firestore
          .collection('categories')
          .add(category.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error adding category: $e');
    }
  }

  // Get categories for user
  Stream<List<CategoryModel>> getCategories(String userId, String type) {
    return _firestore
        .collection('categories')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection('categories').doc(categoryId).delete();
    } catch (e) {
      throw Exception('Error deleting category: $e');
    }
  }

  // ==================== LOANS ====================

  // Add loan
  Future<String> addLoan(LoanModel loan) async {
    try {
      final docRef = await _firestore
          .collection('loans')
          .add(loan.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error adding loan: $e');
    }
  }

  // Get all loans for a user
  Stream<List<LoanModel>> getLoans(String userId) {
    return _firestore
        .collection('loans')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final loans = snapshot.docs
              .map((doc) => LoanModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
          // Sort by date descending
          loans.sort((a, b) => b.date.compareTo(a.date));
          return loans;
        })
        .handleError((error) {
          // Handle errors gracefully
          print('Error in getLoans stream: $error');
          return <LoanModel>[];
        });
  }

  // Get loans by person
  Stream<List<LoanModel>> getLoansByPerson(String userId, String personName) {
    return _firestore
        .collection('loans')
        .where('userId', isEqualTo: userId)
        .where('personName', isEqualTo: personName)
        .snapshots()
        .map((snapshot) {
          final loans = snapshot.docs
              .map((doc) => LoanModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
          // Sort by date descending
          loans.sort((a, b) => b.date.compareTo(a.date));
          return loans;
        });
  }

  // Get all unique persons for a user
  Future<List<String>> getLoanPersons(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('loans')
          .where('userId', isEqualTo: userId)
          .get();

      final persons = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        persons.add(data['personName'] ?? '');
      }
      return persons.toList()..sort();
    } catch (e) {
      throw Exception('Error fetching loan persons: $e');
    }
  }

  // Calculate balance for a person
  Future<double> getPersonBalance(String userId, String personName) async {
    try {
      final loans = await _firestore
          .collection('loans')
          .where('userId', isEqualTo: userId)
          .where('personName', isEqualTo: personName)
          .get();

      double balance = 0;
      for (var doc in loans.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0).toDouble();
        if (data['type'] == 'taken') {
          balance += amount; // You owe them
        } else {
          balance -= amount; // They owe you
        }
      }
      return balance;
    } catch (e) {
      throw Exception('Error calculating person balance: $e');
    }
  }

  // Get loan totals
  Future<Map<String, double>> getLoanTotals(String userId) async {
    try {
      final loans = await _firestore
          .collection('loans')
          .where('userId', isEqualTo: userId)
          .get();

      double totalGiven = 0;
      double totalTaken = 0;

      for (var doc in loans.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0).toDouble();
        if (data['type'] == 'given') {
          totalGiven += amount;
        } else {
          totalTaken += amount;
        }
      }

      return {
        'totalGiven': totalGiven,
        'totalTaken': totalTaken,
        'netBalance': totalTaken - totalGiven, // Positive = you owe, Negative = they owe
      };
    } catch (e) {
      throw Exception('Error calculating loan totals: $e');
    }
  }

  // Update loan
  Future<void> updateLoan(LoanModel loan) async {
    try {
      await _firestore
          .collection('loans')
          .doc(loan.id)
          .update({
        ...loan.toMap(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error updating loan: $e');
    }
  }

  // Delete loan
  Future<void> deleteLoan(String loanId) async {
    try {
      await _firestore.collection('loans').doc(loanId).delete();
    } catch (e) {
      throw Exception('Error deleting loan: $e');
    }
  }

  // ==================== UTILITY ====================

  // Delete all user data (for account deletion)
  Future<void> deleteAllUserData(String userId) async {
    try {
      print('🗑️ Starting deleteAllUserData for userId: $userId');
      
      // Check authentication
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.uid != userId) {
        throw Exception('User not authenticated or userId mismatch');
      }
      print('✅ User authenticated: ${currentUser.uid}');
      
      // Firestore batch limit is 500 operations
      const maxBatchSize = 500;

      // Delete all transactions in batches
      print('📝 Deleting transactions...');
      var transactionsQuery = _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .limit(maxBatchSize);

      int transactionCount = 0;
      while (true) {
        final transactions = await transactionsQuery.get();
        if (transactions.docs.isEmpty) break;

        final batch = _firestore.batch();
        for (var doc in transactions.docs) {
          batch.delete(doc.reference);
          transactionCount++;
        }
        print('  Deleting batch of ${transactions.docs.length} transactions...');
        await batch.commit();
        print('  ✅ Deleted ${transactions.docs.length} transactions');

        if (transactions.docs.length < maxBatchSize) break;
        // Get next batch
        final lastDoc = transactions.docs.last;
        transactionsQuery = _firestore
            .collection('transactions')
            .where('userId', isEqualTo: userId)
            .startAfterDocument(lastDoc)
            .limit(maxBatchSize);
      }
      print('✅ All transactions deleted (total: $transactionCount)');

      // Delete all categories in batches
      // Note: Default categories can be deleted by owner during "Clear All Data"
      print('📁 Deleting categories...');
      var categoriesQuery = _firestore
          .collection('categories')
          .where('userId', isEqualTo: userId)
          .limit(maxBatchSize);

      int categoryCount = 0;
      int skippedCount = 0;
      while (true) {
        final categories = await categoriesQuery.get();
        if (categories.docs.isEmpty) break;

        // Separate default and non-default categories
        final defaultCategories = <DocumentSnapshot>[];
        final nonDefaultCategories = <DocumentSnapshot>[];

        for (var doc in categories.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null && (data['isDefault'] == true)) {
            defaultCategories.add(doc);
          } else {
            nonDefaultCategories.add(doc);
          }
        }

        // Delete non-default categories in batch
        if (nonDefaultCategories.isNotEmpty) {
          final batch = _firestore.batch();
          for (var doc in nonDefaultCategories) {
            batch.delete(doc.reference);
          }
          print('  Deleting batch of ${nonDefaultCategories.length} non-default categories...');
          try {
            await batch.commit();
            categoryCount += nonDefaultCategories.length;
            print('  ✅ Deleted ${nonDefaultCategories.length} non-default categories');
          } catch (e) {
            print('  ❌ Error deleting non-default categories: $e');
            // Try individual deletes
            for (var doc in nonDefaultCategories) {
              try {
                await doc.reference.delete();
                categoryCount++;
              } catch (e2) {
                print('  ❌ Error deleting category: $e2');
              }
            }
          }
        }

        // Delete default categories individually (rules may block batch)
        if (defaultCategories.isNotEmpty) {
          print('  Deleting ${defaultCategories.length} default categories individually...');
          for (var doc in defaultCategories) {
            try {
              await doc.reference.delete();
              categoryCount++;
              final data = doc.data() as Map<String, dynamic>?;
              final categoryName = data?['name'] ?? 'Unknown';
              print('  ✅ Deleted default category: $categoryName');
            } catch (e) {
              final data = doc.data() as Map<String, dynamic>?;
              final categoryName = data?['name'] ?? 'Unknown';
              print('  ⚠️ Cannot delete default category "$categoryName": $e');
              skippedCount++;
            }
          }
        }

        if (categories.docs.length < maxBatchSize) break;
        final lastDoc = categories.docs.last;
        categoriesQuery = _firestore
            .collection('categories')
            .where('userId', isEqualTo: userId)
            .startAfterDocument(lastDoc)
            .limit(maxBatchSize);
      }
      print('✅ Categories deletion complete (deleted: $categoryCount, skipped: $skippedCount)');

      // Delete all loans in batches
      print('💰 Deleting loans...');
      var loansQuery = _firestore
          .collection('loans')
          .where('userId', isEqualTo: userId)
          .limit(maxBatchSize);

      int loanCount = 0;
      while (true) {
        final loans = await loansQuery.get();
        if (loans.docs.isEmpty) break;

        final batch = _firestore.batch();
        for (var doc in loans.docs) {
          batch.delete(doc.reference);
          loanCount++;
        }
        print('  Deleting batch of ${loans.docs.length} loans...');
        await batch.commit();
        print('  ✅ Deleted ${loans.docs.length} loans');

        if (loans.docs.length < maxBatchSize) break;
        final lastDoc = loans.docs.last;
        loansQuery = _firestore
            .collection('loans')
            .where('userId', isEqualTo: userId)
            .startAfterDocument(lastDoc)
            .limit(maxBatchSize);
      }
      print('✅ All loans deleted (total: $loanCount)');

      // Delete saved recipients in batches
      print('👥 Deleting saved recipients...');
      var recipientsQuery = _firestore
          .collection('savedRecipients')
          .where('userId', isEqualTo: userId)
          .limit(maxBatchSize);

      int recipientCount = 0;
      while (true) {
        final recipients = await recipientsQuery.get();
        if (recipients.docs.isEmpty) break;

        final batch = _firestore.batch();
        for (var doc in recipients.docs) {
          batch.delete(doc.reference);
          recipientCount++;
        }
        print('  Deleting batch of ${recipients.docs.length} recipients...');
        await batch.commit();
        print('  ✅ Deleted ${recipients.docs.length} recipients');

        if (recipients.docs.length < maxBatchSize) break;
        final lastDoc = recipients.docs.last;
        recipientsQuery = _firestore
            .collection('savedRecipients')
            .where('userId', isEqualTo: userId)
            .startAfterDocument(lastDoc)
            .limit(maxBatchSize);
      }
      print('✅ All saved recipients deleted (total: $recipientCount)');

      // Delete notifications in batches
      print('🔔 Deleting notifications...');
      var notificationsQuery = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .limit(maxBatchSize);

      int notificationCount = 0;
      while (true) {
        final notifications = await notificationsQuery.get();
        if (notifications.docs.isEmpty) break;

        final batch = _firestore.batch();
        for (var doc in notifications.docs) {
          batch.delete(doc.reference);
          notificationCount++;
        }
        print('  Deleting batch of ${notifications.docs.length} notifications...');
        await batch.commit();
        print('  ✅ Deleted ${notifications.docs.length} notifications');

        if (notifications.docs.length < maxBatchSize) break;
        final lastDoc = notifications.docs.last;
        notificationsQuery = _firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .startAfterDocument(lastDoc)
            .limit(maxBatchSize);
      }
      print('✅ All notifications deleted (total: $notificationCount)');

      // Finally, delete user document
      print('👤 Deleting user document...');
      await _firestore.collection('users').doc(userId).delete();
      print('✅ User document deleted');
      print('🎉 All user data deleted successfully!');
    } catch (e) {
      print('❌ Error in deleteAllUserData: $e');
      print('Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');
        throw Exception('Firestore error (${e.code}): ${e.message ?? "Unknown error"}');
      }
      throw Exception('Error deleting user data: $e');
    }
  }

  // ==================== TRANSFER MONEY ====================

  // Search user by account number
  Future<UserModel?> getUserByAccountNumber(String accountNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('accountNumber', isEqualTo: accountNumber)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return UserModel.fromMap(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error searching user by account number: $e');
    }
  }

  // Transfer money between users
  Future<String> transferMoney({
    required String senderId,
    required String receiverId,
    required String receiverAccountNumber,
    required String receiverName,
    required double amount,
    required String description,
    required String currency,
  }) async {
    try {
      // Get sender details for notification
      final senderUser = await getUser(senderId);
      // Use displayName if available, otherwise email, otherwise 'Unknown'
      final senderName = senderUser?.displayName ?? 
                        (senderUser?.email != null ? senderUser!.email!.split('@')[0] : 'Unknown');
      // Get account number - ensure it's not null or empty
      final senderAccountNumber = (senderUser?.accountNumber != null && 
                                   senderUser!.accountNumber!.isNotEmpty)
          ? senderUser.accountNumber!
          : 'N/A';
      
      final batch = _firestore.batch();
      final now = DateTime.now();

      // Create transaction ID for both transactions
      final transactionIdBase = _firestore.collection('transactions').doc().id;

      // Transaction for sender (expense)
      final senderTransactionRef = _firestore.collection('transactions').doc();
      final senderTransactionId = TransactionModel.generateTransactionId(
        senderTransactionRef.id,
        now,
      );
      final senderTransaction = TransactionModel(
        id: senderTransactionRef.id,
        userId: senderId,
        title: 'Transfer to $receiverName',
        description: description,
        amount: amount,
        type: 'expense',
        category: 'Transfer',
        date: now,
        createdAt: now,
        updatedAt: now,
        transactionId: senderTransactionId,
      );
      batch.set(senderTransactionRef, senderTransaction.toMap());

      // Transaction for receiver (income)
      final receiverTransactionRef = _firestore.collection('transactions').doc();
      final receiverTransactionId = TransactionModel.generateTransactionId(
        receiverTransactionRef.id,
        now,
      );
      final receiverTransaction = TransactionModel(
        id: receiverTransactionRef.id,
        userId: receiverId,
        title: 'Received from Transfer',
        description: description,
        amount: amount,
        type: 'income',
        category: 'Transfer',
        date: now,
        createdAt: now,
        updatedAt: now,
        transactionId: receiverTransactionId,
      );
      batch.set(receiverTransactionRef, receiverTransaction.toMap());

      await batch.commit();

      // Send notification to receiver (non-blocking)
      try {
        final notificationService = NotificationService();
        await notificationService.sendTransferNotification(
          receiverId: receiverId,
          receiverName: receiverName,
          senderName: senderName,
          senderAccountNumber: senderAccountNumber,
          amount: amount,
          currency: currency,
        );
      } catch (e) {
        // Don't fail transfer if notification fails
        print('Error sending notification: $e');
      }

      // Return sender transaction ID for slip generation
      return senderTransactionRef.id;
    } catch (e) {
      throw Exception('Error transferring money: $e');
    }
  }

  // ==================== SAVED RECIPIENTS ====================

  // Add saved recipient
  Future<String> addSavedRecipient(SavedRecipientModel recipient) async {
    try {
      final docRef = await _firestore
          .collection('savedRecipients')
          .add(recipient.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error adding saved recipient: $e');
    }
  }

  // Get saved recipients for user
  Stream<List<SavedRecipientModel>> getSavedRecipients(String userId) {
    return _firestore
        .collection('savedRecipients')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final recipients = snapshot.docs
          .map((doc) => SavedRecipientModel.fromMap(doc.data(), doc.id))
          .toList();
      // Sort by lastTransferredAt (most recent first), then by savedAt
      recipients.sort((a, b) {
        if (a.lastTransferredAt != null && b.lastTransferredAt != null) {
          return b.lastTransferredAt!.compareTo(a.lastTransferredAt!);
        } else if (a.lastTransferredAt != null) {
          return -1;
        } else if (b.lastTransferredAt != null) {
          return 1;
        }
        return b.savedAt.compareTo(a.savedAt);
      });
      return recipients;
    });
  }

  // Check if recipient already exists
  Future<SavedRecipientModel?> getSavedRecipientByAccountNumber(
    String userId,
    String accountNumber,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('savedRecipients')
          .where('userId', isEqualTo: userId)
          .where('recipientAccountNumber', isEqualTo: accountNumber)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return SavedRecipientModel.fromMap(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error checking saved recipient: $e');
    }
  }

  // Update saved recipient (update lastTransferredAt)
  Future<void> updateSavedRecipient(String recipientId) async {
    try {
      await _firestore
          .collection('savedRecipients')
          .doc(recipientId)
          .update({
        'lastTransferredAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error updating saved recipient: $e');
    }
  }

  // Delete saved recipient
  Future<void> deleteSavedRecipient(String recipientId) async {
    try {
      await _firestore
          .collection('savedRecipients')
          .doc(recipientId)
          .delete();
    } catch (e) {
      throw Exception('Error deleting saved recipient: $e');
    }
  }
}

