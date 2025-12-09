// lib/models/user.dart
class User {
  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? avatar;
  final DateTime createdAt;
  final bool isPremium;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.avatar,
    required this.createdAt,
    required this.isPremium,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'],
      avatar: json['avatar'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      isPremium: json['isPremium'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
      'isPremium': isPremium,
    };
  }
}