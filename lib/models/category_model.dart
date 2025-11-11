class CategoryModel {
  final String id;
  final String userId;
  final String name;
  final String type; // 'income' or 'expense'
  final String icon; // Icon name or identifier
  final String? color; // Hex color code
  final bool isDefault; // Default categories cannot be deleted
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.icon,
    this.color,
    this.isDefault = false,
    required this.createdAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      icon: map['icon'] ?? '',
      color: map['color'],
      isDefault: map['isDefault'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

