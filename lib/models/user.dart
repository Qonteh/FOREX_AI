import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String email;
  final String name;
  final String? phoneNumber; // ADD PHONE NUMBER FIELD BRO!
  final String? avatar;
  final DateTime? createdAt;
  final bool? isPremium;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber, // INCLUDE IN CONSTRUCTOR
    this.avatar,
    this.createdAt,
    this.isPremium,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber, // ADD TO COPYWITH METHOD
    String? avatar,
    DateTime? createdAt,
    bool? isPremium,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber, // INCLUDE HERE TOO
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  // HELPER METHODS FOR PHONE NUMBER
  bool get hasPhoneNumber => phoneNumber != null && phoneNumber!.isNotEmpty;
  
  String get displayPhoneNumber => phoneNumber ?? 'Not provided';
  
  // FORMAT PHONE NUMBER FOR DISPLAY
  String get formattedPhoneNumber {
    if (phoneNumber == null || phoneNumber!.isEmpty) {
      return 'Not provided';
    }
    
    // Basic formatting for display
    final phone = phoneNumber!;
    if (phone.startsWith('+')) {
      return phone;
    }
    return '+$phone';
  }
}