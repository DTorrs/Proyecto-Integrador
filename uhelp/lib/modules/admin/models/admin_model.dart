class AdminDashboardStats {
  final int totalUsers;
  final List<StatusCount> problemsByStatus;
  final List<StatusCount> lostItems;
  final List<CategoryCount> problemsByCategory;
  final List<LocationCount> problemsByLocation;
  final List<ActivityLog> recentActivity;

  AdminDashboardStats({
    required this.totalUsers,
    required this.problemsByStatus,
    required this.lostItems,
    required this.problemsByCategory,
    required this.problemsByLocation,
    required this.recentActivity,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    // Parse problems by status
    List<StatusCount> problemsByStatus = [];
    if (json['problems'] != null && json['problems']['byStatus'] != null) {
      problemsByStatus = (json['problems']['byStatus'] as List)
          .map((item) => StatusCount.fromJson(item))
          .toList();
    }

    // Parse lost items
    List<StatusCount> lostItems = [];
    if (json['lostItems'] != null) {
      lostItems = (json['lostItems'] as List)
          .map((item) => StatusCount.fromJson(item))
          .toList();
    }

    // Parse problems by category
    List<CategoryCount> problemsByCategory = [];
    if (json['problems'] != null && json['problems']['byCategory'] != null) {
      problemsByCategory = (json['problems']['byCategory'] as List)
          .map((item) => CategoryCount.fromJson(item))
          .toList();
    }

    // Parse problems by location
    List<LocationCount> problemsByLocation = [];
    if (json['problems'] != null && json['problems']['byLocation'] != null) {
      problemsByLocation = (json['problems']['byLocation'] as List)
          .map((item) => LocationCount.fromJson(item))
          .toList();
    }

    // Parse recent activity
    List<ActivityLog> recentActivity = [];
    if (json['recentActivity'] != null) {
      recentActivity = (json['recentActivity'] as List)
          .map((item) => ActivityLog.fromJson(item))
          .toList();
    }

    return AdminDashboardStats(
      totalUsers: json['totalUsers'] ?? 0,
      problemsByStatus: problemsByStatus,
      lostItems: lostItems,
      problemsByCategory: problemsByCategory,
      problemsByLocation: problemsByLocation,
      recentActivity: recentActivity,
    );
  }
}

class StatusCount {
  final String name;
  final int count;
  final bool isFound; // Only for lost items

  StatusCount({
    required this.name,
    required this.count,
    this.isFound = false,
  });

  factory StatusCount.fromJson(Map<String, dynamic> json) {
    return StatusCount(
      name: json['name'] ?? '',
      count: json['count'] ?? 0,
      isFound: json['is_found'] == 1 || json['is_found'] == true,
    );
  }
}

class CategoryCount {
  final String name;
  final int count;

  CategoryCount({
    required this.name,
    required this.count,
  });

  factory CategoryCount.fromJson(Map<String, dynamic> json) {
    return CategoryCount(
      name: json['name'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class LocationCount {
  final String code;
  final String name;
  final int count;

  LocationCount({
    required this.code,
    required this.name,
    required this.count,
  });

  factory LocationCount.fromJson(Map<String, dynamic> json) {
    return LocationCount(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class ActivityLog {
  final int id;
  final String action;
  final String entityType;
  final int entityId;
  final String username;
  final String fullName;
  final DateTime createdAt;

  ActivityLog({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.username,
    required this.fullName,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'],
      action: json['action'] ?? '',
      entityType: json['entity_type'] ?? '',
      entityId: json['entity_id'] ?? 0,
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}