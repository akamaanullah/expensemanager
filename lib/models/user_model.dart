class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? preferences;
  final String? accountNumber; // Unique account number
  final String? fcmToken; // Firebase Cloud Messaging token for notifications

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.preferences,
    this.accountNumber,
    this.fcmToken,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'preferences': preferences ?? {},
      'accountNumber': accountNumber,
      'fcmToken': fcmToken,
    };
  }

  // Create from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      lastLoginAt: map['lastLoginAt'] != null 
          ? DateTime.parse(map['lastLoginAt']) 
          : null,
      preferences: map['preferences'] as Map<String, dynamic>?,
      accountNumber: map['accountNumber'],
      fcmToken: map['fcmToken'],
    );
  }

  // Create copy with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
    String? accountNumber,
    String? fcmToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      accountNumber: accountNumber ?? this.accountNumber,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
  
  // Generate unique account number (deterministic - same userId always generates same number)
  static String generateAccountNumber(String userId) {
    // Format: ACC-XXXX-XXXX-XXXX (proper format like bank accounts)
    // ACC + 4 digits hash + 4 digits hash2 + 4 digits hash3
    // All based on userId - NO timestamp to ensure consistency
    final hashCode1 = userId.hashCode.abs();
    final hashCode2 = (userId.hashCode * 31).abs();
    final hashCode3 = (userId.hashCode * 97).abs(); // Different multiplier for third part
    
    final part1 = (hashCode1 % 10000).toString().padLeft(4, '0');
    final part2 = (hashCode2 % 10000).toString().padLeft(4, '0');
    final part3 = (hashCode3 % 10000).toString().padLeft(4, '0');
    
    return 'ACC-$part1-$part2-$part3';
  }
}

