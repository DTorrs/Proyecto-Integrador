// lib/modules/notifications/models/notification_model.dart
class UserNotification {  // Renamed from 'Notification' to 'UserNotification'
  final int id;
  final int userId;
  final String title;
  final String message;
  final bool isRead;
  final String relatedType;
  final int relatedId;
  final DateTime createdAt;

  UserNotification({  // Updated constructor name
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.relatedType,
    required this.relatedId,
    required this.createdAt,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {  // Updated factory constructor
    return UserNotification(  // Updated constructor call
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      message: json['message'],
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      relatedType: json['related_type'],
      relatedId: json['related_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}