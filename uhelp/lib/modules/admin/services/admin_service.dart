import '../../../core/services/api_service.dart';
import '../../../config/api_config.dart';
import '../../../core/models/api_response.dart';
import '../../../core/models/pagination_model.dart';
import '../models/admin_model.dart';
import '../../../core/models/user_model.dart';

class AdminService {
  final ApiService _apiService = ApiService();

  // Get admin dashboard statistics
  Future<ApiResponse<AdminDashboardStats>> getDashboardStats() async {
    return await _apiService.get<AdminDashboardStats>(
      ApiConfig.adminDashboard,
      fromJson: (json) => AdminDashboardStats.fromJson(json),
    );
  }

  // Get all users with pagination and search
  Future<ApiResponse<PaginatedData<User>>> getUsers({
    String? search,
    int? roleId,
    int page = 1,
    int pageSize = 10,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    if (roleId != null) {
      queryParams['roleId'] = roleId.toString();
    }

    return await _apiService.get<PaginatedData<User>>(
      ApiConfig.adminUsers,
      queryParameters: queryParams,
      fromJson: (json) => PaginatedData.fromJson(
        json,
        (itemJson) => User.fromJson(itemJson),
      ),
    );
  }

  // Update user role
  Future<ApiResponse<void>> updateUserRole(int userId, int roleId) async {
    return await _apiService.put<void>(
      '${ApiConfig.adminUsers}/$userId/role',
      data: {
        'roleId': roleId,
      },
    );
  }

  // Log admin activity
  Future<ApiResponse<ActivityLog>> logActivity({
    required String action,
    required String entityType,
    required int entityId,
    String? details,
  }) async {
    return await _apiService.post<ActivityLog>(
      ApiConfig.adminActivityLogs,
      data: {
        'action': action,
        'entityType': entityType,
        'entityId': entityId,
        'details': details,
      },
      fromJson: (json) => ActivityLog.fromJson(json),
    );
  }
}