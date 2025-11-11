import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';

class DataExportService {
  final FirestoreService _firestoreService = FirestoreService();

  // Export all user transactions as CSV
  Future<String> exportAsCSV(String userId) async {
    try {
      // Get all transactions
      final transactions = await _getAllTransactions(userId);
      
      // Create CSV content
      final csvContent = StringBuffer();
      
      // Add header
      csvContent.writeln('Date,Type,Title,Description,Category,Amount');
      
      // Add data rows
      for (var transaction in transactions) {
        final date = transaction.date.toLocal().toString().split(' ')[0]; // YYYY-MM-DD
        final type = transaction.type;
        final title = _escapeCsvField(transaction.title);
        final description = _escapeCsvField(transaction.description ?? '');
        final category = _escapeCsvField(transaction.category);
        final amount = transaction.amount.toStringAsFixed(2);
        
        csvContent.writeln('$date,$type,$title,$description,$category,$amount');
      }
      
      // For web, return content directly
      if (kIsWeb) {
        return csvContent.toString();
      }
      
      // Save to file for mobile/desktop
      final file = await _saveToFile('expense_data.csv', csvContent.toString());
      return file.path;
    } catch (e) {
      throw Exception('Error exporting CSV: $e');
    }
  }

  // Export all user transactions as JSON
  Future<String> exportAsJSON(String userId) async {
    try {
      // Get all transactions
      final transactions = await _getAllTransactions(userId);
      
      // Convert to JSON
      final jsonData = {
        'exportDate': DateTime.now().toIso8601String(),
        'userId': userId,
        'totalTransactions': transactions.length,
        'transactions': transactions.map((t) => t.toMap()).toList(),
      };
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
      
      // For web, return content directly
      if (kIsWeb) {
        return jsonString;
      }
      
      // Save to file for mobile/desktop
      final file = await _saveToFile('expense_data.json', jsonString);
      return file.path;
    } catch (e) {
      throw Exception('Error exporting JSON: $e');
    }
  }

  // Get all transactions for a user
  Future<List<TransactionModel>> _getAllTransactions(String userId) async {
    try {
      // Get all transactions (we'll use a date range that covers all time)
      final now = DateTime.now();
      final startDate = DateTime(2000, 1, 1); // Very old date
      final endDate = DateTime(now.year + 10, 12, 31); // Future date
      
      return await _firestoreService.getTransactionsByDateRange(
        userId,
        startDate,
        endDate,
      );
    } catch (e) {
      throw Exception('Error fetching transactions: $e');
    }
  }

  // Escape CSV field (handle commas, quotes, newlines)
  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  // Save content to file
  Future<File> _saveToFile(String fileName, String content) async {
    try {
      // For web, we don't save to file system, we'll share directly
      if (kIsWeb) {
        // Create a temporary file-like object for web
        final bytes = utf8.encode(content);
        final xFile = XFile.fromData(
          bytes,
          mimeType: fileName.endsWith('.csv') ? 'text/csv' : 'application/json',
          name: fileName,
        );
        // Return a placeholder - web will use share directly
        throw UnsupportedError('Web uses direct share');
      }

      Directory? directory;
      
      // Get directory based on platform
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        // For desktop platforms
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not get directory');
      }

      // Create file path
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      
      // Write content to file
      await file.writeAsString(content);
      
      return file;
    } catch (e) {
      if (e is UnsupportedError) {
        rethrow;
      }
      throw Exception('Error saving file: $e');
    }
  }

  // Share file using share_plus
  Future<void> shareFile(String filePathOrContent, {String? fileName, String? mimeType}) async {
    try {
      if (kIsWeb) {
        // For web, share content directly
        final bytes = utf8.encode(filePathOrContent);
        final xFile = XFile.fromData(
          bytes,
          mimeType: mimeType ?? 'text/plain',
          name: fileName ?? 'expense_data.txt',
        );
        await Share.shareXFiles([xFile], text: 'My Expense Manager Data Export');
      } else {
        // For mobile/desktop, share file
        final file = File(filePathOrContent);
        if (!await file.exists()) {
          throw Exception('File does not exist');
        }

        final xFile = XFile(filePathOrContent);
        await Share.shareXFiles([xFile], text: 'My Expense Manager Data Export');
      }
    } catch (e) {
      throw Exception('Error sharing file: $e');
    }
  }

  // Export and share directly (combines export + share)
  Future<void> exportAndShare(String userId, {String format = 'CSV'}) async {
    try {
      String filePathOrContent;
      String fileName;
      String mimeType;
      
      if (format.toUpperCase() == 'JSON') {
        filePathOrContent = await exportAsJSON(userId);
        fileName = 'expense_data.json';
        mimeType = 'application/json';
      } else {
        filePathOrContent = await exportAsCSV(userId);
        fileName = 'expense_data.csv';
        mimeType = 'text/csv';
      }
      
      await shareFile(filePathOrContent, fileName: fileName, mimeType: mimeType);
    } catch (e) {
      throw Exception('Error exporting and sharing: $e');
    }
  }
}

