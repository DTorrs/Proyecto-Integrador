// lib/modules/announcements/services/announcement_service.dart
import 'dart:io';
import '../../../core/services/api_service.dart';
import '../../../config/api_config.dart';
import '../../../core/models/api_response.dart';
import '../../../core/models/pagination_model.dart';
import '../models/announcement_model.dart';

class AnnouncementService {
  final ApiService _apiService = ApiService();

  // Get all announcements
  Future<ApiResponse<PaginatedData<Announcement>>> getAnnouncements({
    bool activeOnly = false,
    int page = 1,
    int pageSize = 10,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      'activeOnly': activeOnly.toString(),
    };

    return await _apiService.get<PaginatedData<Announcement>>(
      ApiConfig.announcements,
      queryParameters: queryParams,
      fromJson: (json) => PaginatedData.fromJson(
        json,
        (itemJson) => Announcement.fromJson(itemJson),
      ),
    );
  }

  // Get active announcements
  Future<ApiResponse<PaginatedData<Announcement>>> getActiveAnnouncements({
    int page = 1,
    int pageSize = 10,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    return await _apiService.get<PaginatedData<Announcement>>(
      ApiConfig.activeAnnouncements,
      queryParameters: queryParams,
      fromJson: (json) => PaginatedData.fromJson(
        json,
        (itemJson) => Announcement.fromJson(itemJson),
      ),
    );
  }

  // Get announcement by ID
  Future<ApiResponse<Announcement>> getAnnouncementById(int announcementId) async {
    return await _apiService.get<Announcement>(
      '${ApiConfig.announcements}/$announcementId',
      fromJson: (json) {
        // Check if the announcement is in a nested object
        if (json.containsKey('announcement')) {
          return Announcement.fromJson(json['announcement']);
        }
        return Announcement.fromJson(json);
      },
    );
  }

  // Create a new announcement (staff/admin only)
  Future<ApiResponse<Announcement>> createAnnouncement({
    required String title,
    required String content,
    File? image,
    bool isActive = true,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Debug logs to identify the issue
      print('Creating announcement:');
      print('- Title: $title');
      print('- Content length: ${content.length}');
      print('- isActive: $isActive');
      print('- startDate: ${startDate?.toIso8601String()}');
      print('- endDate: ${endDate?.toIso8601String()}');
      print('- Has image: ${image != null}');
      
      // Prepare the data payload - convert boolean to string "true"/"false"
      final Map<String, dynamic> dataPayload = {
        'title': title,
        'content': content,
        'isActive': isActive ? 'true' : 'false', // Use string instead of boolean
      };

      // Add dates only if they are not null
      if (startDate != null) {
        dataPayload['startDate'] = startDate.toIso8601String();
      }
      
      if (endDate != null) {
        dataPayload['endDate'] = endDate.toIso8601String();
      }
      
      print('Data payload: $dataPayload');

      // If no image provided, use regular post
      if (image == null) {
        return await _apiService.post<Announcement>(
          ApiConfig.announcements,
          data: dataPayload,
          fromJson: (json) {
            print('Create announcement response: $json');
            // Check if the announcement is in a nested object
            if (json.containsKey('announcement')) {
              return Announcement.fromJson(json['announcement']);
            }
            return Announcement.fromJson(json);
          },
        );
      }

      // If image provided, use uploadFile method
      return await _apiService.uploadFile<Announcement>(
        ApiConfig.announcements,
        file: image,
        fieldName: 'image',
        data: dataPayload,
        fromJson: (json) {
          print('Create announcement with image response: $json');
          // Check if the announcement is in a nested object
          if (json.containsKey('announcement')) {
            return Announcement.fromJson(json['announcement']);
          }
          return Announcement.fromJson(json);
        },
      );
    } catch (e) {
      print('Error creating announcement: $e');
      return ApiResponse<Announcement>(
        success: false,
        message: 'Failed to create announcement: ${e.toString()}',
      );
    }
  }

  // Update an announcement (staff/admin only)
  Future<ApiResponse<Announcement>> updateAnnouncement({
    required int announcementId,
    String? title,
    String? content,
    File? image,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Prepare data payload with string representation of boolean
      final Map<String, dynamic> dataPayload = {};
      
      if (title != null) dataPayload['title'] = title;
      if (content != null) dataPayload['content'] = content;
      if (isActive != null) dataPayload['isActive'] = isActive ? 'true' : 'false';
      if (startDate != null) dataPayload['startDate'] = startDate.toIso8601String();
      if (endDate != null) dataPayload['endDate'] = endDate.toIso8601String();
      
      print('Update data payload: $dataPayload');

      // If no image provided, use regular put
      if (image == null) {
        return await _apiService.put<Announcement>(
          '${ApiConfig.announcements}/$announcementId',
          data: dataPayload,
          fromJson: (json) {
            print('Update announcement response: $json');
            // Check if the announcement is in a nested object
            if (json.containsKey('announcement')) {
              return Announcement.fromJson(json['announcement']);
            }
            return Announcement.fromJson(json);
          },
        );
      }

      // If image provided, use uploadFile method
      return await _apiService.uploadFile<Announcement>(
        '${ApiConfig.announcements}/$announcementId',
        file: image,
        fieldName: 'image',
        data: dataPayload,
        fromJson: (json) {
          print('Update announcement with image response: $json');
          // Check if the announcement is in a nested object
          if (json.containsKey('announcement')) {
            return Announcement.fromJson(json['announcement']);
          }
          return Announcement.fromJson(json);
        },
      );
    } catch (e) {
      print('Error updating announcement: $e');
      return ApiResponse<Announcement>(
        success: false,
        message: 'Failed to update announcement: ${e.toString()}',
      );
    }
  }

  // Delete an announcement (staff/admin only)
  Future<ApiResponse<void>> deleteAnnouncement(int announcementId) async {
    try {
      return await _apiService.delete<void>(
        '${ApiConfig.announcements}/$announcementId',
      );
    } catch (e) {
      print('Error deleting announcement: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Failed to delete announcement: ${e.toString()}',
      );
    }
  }
}

// Helper function to get min value
int min(int a, int b) {
  return a < b ? a : b;
}