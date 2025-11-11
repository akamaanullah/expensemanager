class TransactionModel {
  final String id;
  final String userId;
  final String type; // 'income' or 'expense'
  final String title;
  final String? description;
  final double amount;
  final String category;
  final DateTime date;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String originalCurrency; // Currency when transaction was created (e.g., 'PKR', 'USD')
  final double originalAmount; // Original amount in original currency
  final String? transactionId; // Unique transaction ID for receipts

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.description,
    required this.amount,
    required this.category,
    required this.date,
    required this.createdAt,
    this.updatedAt,
    this.originalCurrency = 'PKR', // Default to PKR
    double? originalAmountParam, // Will be set to amount if not provided
    this.transactionId,
  }) : originalAmount = (originalAmountParam ?? amount);

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'description': description,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'originalCurrency': originalCurrency,
      'originalAmount': originalAmount,
      'transactionId': transactionId,
    };
  }

  // Create from Firestore document
  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    // For backward compatibility, if originalCurrency/Amount not present, use current values
    final originalCurrency = map['originalCurrency'] ?? 'PKR';
    final originalAmount = (map['originalAmount'] ?? map['amount'] ?? 0).toDouble();
    
    // Generate transaction ID if not present (for backward compatibility)
    String? transactionId = map['transactionId'];
    if (transactionId == null) {
      transactionId = TransactionModel.generateTransactionId(id, DateTime.parse(map['date']));
    }
    
    return TransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      amount: (map['amount'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      date: DateTime.parse(map['date']),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      originalCurrency: originalCurrency,
      originalAmountParam: originalAmount,
      transactionId: transactionId,
    );
  }
  
  // Generate unique transaction ID
  static String generateTransactionId(String firestoreId, DateTime date) {
    // Format: TXN + YYYYMMDD + first 6 chars of firestore ID + HHMMSS
    final dateCode = '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    final timeCode = '${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}${date.second.toString().padLeft(2, '0')}';
    final idHash = firestoreId.substring(0, firestoreId.length > 6 ? 6 : firestoreId.length).toUpperCase();
    return 'TXN$dateCode$idHash$timeCode';
  }

  // Create copy with updated fields
  TransactionModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? description,
    double? amount,
    String? category,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? originalCurrency,
    double? originalAmount,
    String? transactionId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      originalCurrency: originalCurrency ?? this.originalCurrency,
      originalAmountParam: originalAmount ?? this.originalAmount,
      transactionId: transactionId ?? this.transactionId,
    );
  }
}

