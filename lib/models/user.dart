class User {
  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? avatar;
  final DateTime? createdAt;
  final bool? isPremium;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.avatar,
    this.createdAt,
    this.isPremium,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      avatar: json['avatar'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'avatar': avatar,
      'createdAt': createdAt?.toIso8601String(),
      'isPremium': isPremium ?? false,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? avatar,
    DateTime? createdAt,
    bool? isPremium,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
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