class LoanModel {
  final String id;
  final String userId;
  final String personName;
  final double amount;
  final String type; // 'given' or 'taken'
  final DateTime date;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  LoanModel({
    required this.id,
    required this.userId,
    required this.personName,
    required this.amount,
    required this.type,
    required this.date,
    this.description,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'personName': personName,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory LoanModel.fromMap(Map<String, dynamic> map) {
    return LoanModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      personName: map['personName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      type: map['type'] ?? 'taken',
      date: DateTime.parse(map['date']),
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  LoanModel copyWith({
    String? id,
    String? userId,
    String? personName,
    double? amount,
    String? type,
    DateTime? date,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}



