import '../../../core/models/location_model.dart';

class MapLocationData {
  final int id;
  final String code;
  final String name;
  final int activeProblems;
  final int activeItems;

  MapLocationData({
    required this.id,
    required this.code,
    required this.name,
    required this.activeProblems,
    required this.activeItems,
  });

  factory MapLocationData.fromJson(Map<String, dynamic> json) {
    return MapLocationData(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      activeProblems: json['active_problems'] ?? 0,
      activeItems: json['active_items'] ?? 0,
    );
  }
}

class LocationDetailData {
  final Location location;
  final List<ItemSummary> problems;
  final List<ItemSummary> lostItems;

  LocationDetailData({
    required this.location,
    this.problems = const [],
    this.lostItems = const [],
  });

  factory LocationDetailData.fromJson(Map<String, dynamic> json) {
    List<ItemSummary> problems = [];
    List<ItemSummary> lostItems = [];

    if (json['problems'] != null) {
      problems = (json['problems'] as List)
          .map((item) => ItemSummary.fromJson(item))
          .toList();
    }

    if (json['lostItems'] != null) {
      lostItems = (json['lostItems'] as List)
          .map((item) => ItemSummary.fromJson(item))
          .toList();
    }

    return LocationDetailData(
      location: Location.fromJson(json['location']),
      problems: problems,
      lostItems: lostItems,
    );
  }
}

class ItemSummary {
  final int id;
  final String title;
  final int statusId;
  final String statusName;
  final DateTime createdAt;
  final String? imageUrl;
  final String username;
  final int voteCount;
  final bool isFound; // only for lost items

  ItemSummary({
    required this.id,
    required this.title,
    required this.statusId,
    required this.statusName,
    required this.createdAt,
    this.imageUrl,
    required this.username,
    this.voteCount = 0,
    this.isFound = false,
  });

  factory ItemSummary.fromJson(Map<String, dynamic> json) {
    return ItemSummary(
      id: json['id'],
      title: json['title'],
      statusId: json['status_id'],
      statusName: json['status_name'],
      createdAt: DateTime.parse(json['created_at']),
      imageUrl: json['image_url'],
      username: json['username'],
      voteCount: json['vote_count'] ?? 0,
      isFound: json['is_found'] == 1 || json['is_found'] == true,
    );
  }
}

class SimilarProblemsResponse {
  final bool hasSimilarProblems;
  final List<ItemSummary> similarProblems;

  SimilarProblemsResponse({
    required this.hasSimilarProblems,
    required this.similarProblems,
  });

  factory SimilarProblemsResponse.fromJson(Map<String, dynamic> json) {
    return SimilarProblemsResponse(
      hasSimilarProblems: json['hasSimilarProblems'] ?? false,
      similarProblems: json['similarProblems'] != null
          ? (json['similarProblems'] as List)
              .map((item) => ItemSummary.fromJson(item))
              .toList()
          : [],
    );
  }
}