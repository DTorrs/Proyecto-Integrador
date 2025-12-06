import '../../../core/services/api_service.dart';
import '../../../config/api_config.dart';
import '../../../core/models/api_response.dart';
import '../../../core/models/pagination_model.dart';
import '../models/notification_model.dart';

class NotificationService {
  final ApiService _apiService = ApiService();

  // Get all notifications for the current user
  Future<ApiResponse<PaginatedData<UserNotification>>> getNotifications({  // Updated return type
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 10,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      'unreadOnly': unreadOnly.toString(),
    };

    return await _apiService.get<PaginatedData<UserNotification>>(  // Updated generic type
      ApiConfig.notifications,
      queryParameters: queryParams,
      fromJson: (json) => PaginatedData.fromJson(
        json,
        (itemJson) => UserNotification.fromJson(itemJson),  // Updated factory call
      ),
    );
  }

  // Mark a notification as read
  Future<ApiResponse<void>> markAsRead(int notificationId) async {
    return await _apiService.put<void>(
      '${ApiConfig.notifications}/$notificationId/read',
    );
  }

  // Mark all notifications as read
  Future<ApiResponse<void>> markAllAsRead() async {
    return await _apiService.put<void>(
      ApiConfig.markAllRead,
    );
  }

  // Get unread notification count
  Future<ApiResponse<int>> getUnreadCount() async {
    return await _apiService.get<int>(
      ApiConfig.unreadCount,
      fromJson: (json) => json['count'],
    );
  }

  // Delete a notification
  Future<ApiResponse<void>> deleteNotification(int notificationId) async {
    return await _apiService.delete<void>(
      '${ApiConfig.notifications}/$notificationId',
    );
  }
}