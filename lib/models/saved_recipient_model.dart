class SavedRecipientModel {
  final String id;
  final String userId; // Owner's user ID
  final String recipientUserId; // Recipient's user ID
  final String recipientAccountNumber;
  final String recipientName;
  final String? recipientEmail;
  final DateTime savedAt;
  final DateTime? lastTransferredAt;

  SavedRecipientModel({
    required this.id,
    required this.userId,
    required this.recipientUserId,
    required this.recipientAccountNumber,
    required this.recipientName,
    this.recipientEmail,
    required this.savedAt,
    this.lastTransferredAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'recipientUserId': recipientUserId,
      'recipientAccountNumber': recipientAccountNumber,
      'recipientName': recipientName,
      'recipientEmail': recipientEmail,
      'savedAt': savedAt.toIso8601String(),
      'lastTransferredAt': lastTransferredAt?.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory SavedRecipientModel.fromMap(Map<String, dynamic> map, String id) {
    return SavedRecipientModel(
      id: id,
      userId: map['userId'] ?? '',
      recipientUserId: map['recipientUserId'] ?? '',
      recipientAccountNumber: map['recipientAccountNumber'] ?? '',
      recipientName: map['recipientName'] ?? '',
      recipientEmail: map['recipientEmail'],
      savedAt: DateTime.parse(map['savedAt']),
      lastTransferredAt: map['lastTransferredAt'] != null 
          ? DateTime.parse(map['lastTransferredAt']) 
          : null,
    );
  }

  // Create copy with updated fields
  SavedRecipientModel copyWith({
    String? id,
    String? userId,
    String? recipientUserId,
    String? recipientAccountNumber,
    String? recipientName,
    String? recipientEmail,
    DateTime? savedAt,
    DateTime? lastTransferredAt,
  }) {
    return SavedRecipientModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      recipientAccountNumber: recipientAccountNumber ?? this.recipientAccountNumber,
      recipientName: recipientName ?? this.recipientName,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      savedAt: savedAt ?? this.savedAt,
      lastTransferredAt: lastTransferredAt ?? this.lastTransferredAt,
    );
  }
}

