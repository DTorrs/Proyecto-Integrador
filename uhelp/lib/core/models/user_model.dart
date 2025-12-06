// lib/core/models/user_model.dart
class User {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String? profilePicture;
  final String role;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.profilePicture,
    required this.role,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
  print('Parsing User from JSON: $json');
  try {
    // Manejar los diferentes tipos posibles para el id
    int id;
    if (json['id'] is int) {
      id = json['id'];
    } else if (json['id'] is String) {
      id = int.tryParse(json['id']) ?? 0;
    } else {
      id = 0;  // Valor por defecto si no podemos parsearlo
    }
    
    return User(
      id: id,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      profilePicture: json['profile_picture'],
      role: json['role'] ?? 'student',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  } catch (e) {
    print('Error parsing User: $e');
    // En caso de error, proporcionar un objeto de usuario válido pero con valores por defecto
    return User(
      id: 0,
      username: 'unknown',
      email: 'unknown@example.com',
      fullName: 'Unknown User',
      role: 'student',
      createdAt: DateTime.now(),
    );
  }
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'profile_picture': profilePicture,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Check if user is admin or staff
  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isStaff => role.toLowerCase() == 'staff';
  bool get isStaffOrAdmin => isAdmin || isStaff;
}