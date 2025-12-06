import '../../../core/models/user_model.dart';

class Problem {
  final int id;
  final String title;
  final String description;
  final int userId;
  final String username;
  final String reporterName;
  final int locationId;
  final String locationCode;
  final String locationName;
  final String specificLocation;
  final int categoryId;
  final String categoryName;
  final int statusId;
  final String statusName;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int voteCount;
  final List<ProblemComment> comments;
  bool userVoted;

  Problem({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    required this.username,
    required this.reporterName,
    required this.locationId,
    required this.locationCode,
    required this.locationName,
    required this.specificLocation,
    required this.categoryId,
    required this.categoryName,
    required this.statusId,
    required this.statusName,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.voteCount,
    required this.comments,
    this.userVoted = false,
  });

  factory Problem.fromJson(Map<String, dynamic> json) {
    print("Problem.fromJson: $json");
    try {
      // Extract the nested "problem" object if it exists
      final problemData = json.containsKey('problem') ? json['problem'] : json;
      
      List<dynamic> commentsList = problemData['comments'] ?? [];
      
      // Manejo de posibles valores nulos o tipos incorrectos
      int id = 0;
      if (problemData['id'] != null) {
        id = problemData['id'] is int ? problemData['id'] : int.tryParse(problemData['id'].toString()) ?? 0;
      }
      
      int userId = 0;
      if (problemData['user_id'] != null) {
        userId = problemData['user_id'] is int ? problemData['user_id'] : int.tryParse(problemData['user_id'].toString()) ?? 0;
      }
      
      int locationId = 0;
      if (problemData['location_id'] != null) {
        locationId = problemData['location_id'] is int ? problemData['location_id'] : int.tryParse(problemData['location_id'].toString()) ?? 0;
      }
      
      int categoryId = 0;
      if (problemData['category_id'] != null) {
        categoryId = problemData['category_id'] is int ? problemData['category_id'] : int.tryParse(problemData['category_id'].toString()) ?? 0;
      }
      
      int statusId = 0;
      if (problemData['status_id'] != null) {
        statusId = problemData['status_id'] is int ? problemData['status_id'] : int.tryParse(problemData['status_id'].toString()) ?? 0;
      }
      
      int voteCount = 0;
      if (problemData['vote_count'] != null) {
        voteCount = problemData['vote_count'] is int ? problemData['vote_count'] : int.tryParse(problemData['vote_count'].toString()) ?? 0;
      }
      
      return Problem(
        id: id,
        title: problemData['title'] ?? '',
        description: problemData['description'] ?? '',
        userId: userId,
        username: problemData['username'] ?? '',
        reporterName: problemData['reporter_name'] ?? problemData['username'] ?? '',
        locationId: locationId,
        locationCode: problemData['location_code'] ?? '',
        locationName: problemData['location_name'] ?? '',
        specificLocation: problemData['specific_location'] ?? '',
        categoryId: categoryId,
        categoryName: problemData['category_name'] ?? '',
        statusId: statusId,
        statusName: problemData['status_name'] ?? '',
        imageUrl: problemData['image_url'],
        createdAt: problemData['created_at'] != null ? DateTime.parse(problemData['created_at']) : DateTime.now(),
        updatedAt: problemData['updated_at'] != null ? DateTime.parse(problemData['updated_at'] ?? problemData['created_at']) : DateTime.now(),
        voteCount: voteCount,
        userVoted: problemData['userVoted'] ?? false,
        comments: commentsList.map((comment) => ProblemComment.fromJson(comment)).toList(),
      );
    } catch (e) {
      print("Error parsing Problem: $e");
      // Devolver un objeto Problem mínimo válido en caso de error
      return Problem(
        id: 0,
        title: 'Error',
        description: 'Error parsing problem',
        userId: 0,
        username: 'unknown',
        reporterName: 'unknown',
        locationId: 0,
        locationCode: '',
        locationName: '',
        specificLocation: '',
        categoryId: 0,
        categoryName: '',
        statusId: 0,
        statusName: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        voteCount: 0,
        comments: [],
      );
    }
  }

  String get locationDisplay => '$locationCode: $locationName';
}

class ProblemComment {
  final int id;
  final int reportId;
  final int userId;
  final String comment;
  final String username;
  final String fullName;
  final DateTime createdAt;

  ProblemComment({
    required this.id,
    required this.reportId,
    required this.userId,
    required this.comment,
    required this.username,
    required this.fullName,
    required this.createdAt,
  });

  factory ProblemComment.fromJson(Map<String, dynamic> json) {
    try {
      return ProblemComment(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
        reportId: json['report_id'] is int ? json['report_id'] : int.tryParse(json['report_id'].toString()) ?? 0,
        userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
        comment: json['comment'] ?? '',
        username: json['username'] ?? '',
        fullName: json['full_name'] ?? '',
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      );
    } catch (e) {
      print("Error parsing ProblemComment: $e");
      return ProblemComment(
        id: 0,
        reportId: 0,
        userId: 0,
        comment: 'Error parsing comment',
        username: 'unknown',
        fullName: 'unknown',
        createdAt: DateTime.now(),
      );
    }
  }
}