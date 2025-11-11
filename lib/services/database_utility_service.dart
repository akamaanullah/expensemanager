import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility service to clear all collections in Firestore
/// ⚠️ WARNING: This will permanently delete ALL data from the database
/// Use only for testing/development purposes
class DatabaseUtilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Clear all collections (COMPLETE DATABASE EMPTY)
  /// ⚠️ DANGEROUS: This deletes everything permanently
  Future<void> clearAllCollections() async {
    try {
      print('⚠️ Starting to clear all collections...');
      
      // Collections to clear
      final collections = [
        'transactions',
        'categories',
        'loans',
        'notifications',
        'savedRecipients',
        'users', // ⚠️ This will delete all user accounts
      ];

      for (final collectionName in collections) {
        await _clearCollection(collectionName);
        print('✅ Cleared collection: $collectionName');
      }

      print('✅ All collections cleared successfully!');
    } catch (e) {
      print('❌ Error clearing collections: $e');
      throw Exception('Error clearing database: $e');
    }
  }

  /// Clear a specific collection
  Future<void> clearCollection(String collectionName) async {
    await _clearCollection(collectionName);
  }

  /// Internal method to clear a collection
  Future<void> _clearCollection(String collectionName) async {
    try {
      // Get all documents in the collection
      final snapshot = await _firestore.collection(collectionName).get();
      
      if (snapshot.docs.isEmpty) {
        print('Collection $collectionName is already empty');
        return;
      }

      // Delete in batches (Firestore batch limit is 500)
      const batchSize = 500;
      final batches = <WriteBatch>[];
      WriteBatch? currentBatch = _firestore.batch();
      int count = 0;

      for (var doc in snapshot.docs) {
        currentBatch!.delete(doc.reference);
        count++;

        if (count >= batchSize) {
          batches.add(currentBatch);
          currentBatch = _firestore.batch();
          count = 0;
        }
      }

      // Add remaining batch
      if (count > 0 && currentBatch != null) {
        batches.add(currentBatch);
      }

      // Commit all batches
      for (var batch in batches) {
        await batch.commit();
      }

      print('Deleted ${snapshot.docs.length} documents from $collectionName');
    } catch (e) {
      print('Error clearing collection $collectionName: $e');
      rethrow;
    }
  }

  /// Clear all collections EXCEPT users (keeps user accounts)
  Future<void> clearAllDataExceptUsers() async {
    try {
      print('⚠️ Starting to clear data (keeping users)...');
      
      // Collections to clear (excluding users)
      final collections = [
        'transactions',
        'categories',
        'loans',
        'notifications',
        'savedRecipients',
      ];

      for (final collectionName in collections) {
        await _clearCollection(collectionName);
        print('✅ Cleared collection: $collectionName');
      }

      print('✅ All data cleared (users preserved)!');
    } catch (e) {
      print('❌ Error clearing data: $e');
      throw Exception('Error clearing data: $e');
    }
  }
}


