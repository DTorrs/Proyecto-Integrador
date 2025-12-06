// lib/modules/announcements/models/announcement_model.dart
class Announcement {
  final int id;
  final String title;
  final String content;
  final int userId;
  final String username;
  final String creatorName;
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final String? imageUrl;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.userId,
    required this.username,
    required this.creatorName,
    required this.isActive,
    required this.startDate,
    this.endDate,
    required this.createdAt,
    this.imageUrl,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    try {
      return Announcement(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
        username: json['username'] ?? '',
        creatorName: json['creator_name'] ?? json['username'] ?? '',
        isActive: json['is_active'] == 1 || json['is_active'] == true,
        startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : DateTime.now(),
        endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
        imageUrl: json['image_url'],
      );
    } catch (e) {
      print("Error parsing Announcement: $e");
      // Return a minimal valid Announcement in case of error
      return Announcement(
        id: 0,
        title: 'Error',
        content: 'Error parsing announcement',
        userId: 0,
        username: 'unknown',
        creatorName: 'unknown',
        isActive: false,
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
      );
    }
  }
}