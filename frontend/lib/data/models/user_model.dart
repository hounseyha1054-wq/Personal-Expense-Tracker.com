class UserModel {
  final String? id;
  final String firebaseUid;
  final String name;
  final String email;
  final String photoURL;
  final String preferredCurrency;
  final String preferredLanguage;
  final bool emailVerified;
  final DateTime? createdAt;

  UserModel({
    this.id,
    required this.firebaseUid,
    this.name = '',
    this.email = '',
    this.photoURL = '',
    this.preferredCurrency = 'USD',
    this.preferredLanguage = 'en',
    this.emailVerified = false,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'],
      firebaseUid: json['firebaseUid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      photoURL: json['photoURL'] ?? '',
      preferredCurrency: json['preferredCurrency'] ?? 'USD',
      preferredLanguage: json['preferredLanguage'] ?? 'en',
      emailVerified: json['emailVerified'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firebaseUid': firebaseUid,
      'name': name,
      'email': email,
      'photoURL': photoURL,
      'preferredCurrency': preferredCurrency,
      'preferredLanguage': preferredLanguage,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? photoURL,
    String? preferredCurrency,
    String? preferredLanguage,
    bool? emailVerified,
  }) {
    return UserModel(
      id: id,
      firebaseUid: firebaseUid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt,
    );
  }
}
