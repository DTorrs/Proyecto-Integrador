// lib/modules/problems/services/problem_service.dart
import 'dart:io';
import '../../../core/services/api_service.dart';
import '../../../config/api_config.dart';
import '../../../core/models/api_response.dart';
import '../../../core/models/pagination_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/status_model.dart';
import '../models/problem_model.dart';

class ProblemService {
  final ApiService _apiService = ApiService();
  
  // Get all problems with filtering
  Future<ApiResponse<PaginatedData<Problem>>> getProblems({
    int? categoryId,
    int? statusId,
    int? locationId,
    String? sortBy,
    int page = 1,
    int pageSize = 10,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (categoryId != null) queryParams['categoryId'] = categoryId.toString();
    if (statusId != null) queryParams['statusId'] = statusId.toString();
    if (locationId != null) queryParams['locationId'] = locationId.toString();
    if (sortBy != null) queryParams['sortBy'] = sortBy;

    return await _apiService.get<PaginatedData<Problem>>(
      ApiConfig.problems,
      queryParameters: queryParams,
      fromJson: (json) => PaginatedData.fromJson(
        json,
        (itemJson) => Problem.fromJson(itemJson),
      ),
    );
  }

  // Get problem by ID
  Future<ApiResponse<Problem>> getProblemById(int problemId) async {
    try {
      return await _apiService.get<Problem>(
        '${ApiConfig.problems}/$problemId',
        fromJson: (json) => Problem.fromJson(json),
      );
    } catch (e) {
      print('Error fetching problem details: $e');
      return ApiResponse<Problem>(
        success: false,
        message: 'Failed to fetch problem details: ${e.toString()}',
      );
    }
  }

  // Create a new problem
  Future<ApiResponse<Problem>> createProblem({
    required String title,
    required String description,
    required int locationId,
    required String specificLocation,
    required int categoryId,
    File? image,
  }) async {
    try {
      print('Creating problem with locationId: $locationId, categoryId: $categoryId');
      
      if (image != null) {
        return await _apiService.uploadFile<Problem>(
          ApiConfig.problems,
          file: image,
          fieldName: 'image',
          data: {
            'title': title,
            'description': description,
            'locationId': locationId.toString(),
            'specificLocation': specificLocation,
            'categoryId': categoryId.toString(),
          },
          fromJson: (json) {
            print('Create problem response: $json');
            return Problem.fromJson(json);
          },
        );
      } else {
        return await _apiService.post<Problem>(
          ApiConfig.problems,
          data: {
            'title': title,
            'description': description,
            'locationId': locationId,
            'specificLocation': specificLocation,
            'categoryId': categoryId,
          },
          fromJson: (json) {
            print('Create problem response: $json');
            return Problem.fromJson(json);
          },
        );
      }
    } catch (e) {
      print('Error creating problem: $e');
      return ApiResponse<Problem>(
        success: false,
        message: 'Failed to create problem: ${e.toString()}',
      );
    }
  }

  // Update a problem
  Future<ApiResponse<Problem>> updateProblem({
    required int problemId,
    String? title,
    String? description,
    int? locationId,
    String? specificLocation,
    int? categoryId,
    File? image,
  }) async {
    try {
      final data = {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (locationId != null) 'locationId': locationId.toString(),
        if (specificLocation != null) 'specificLocation': specificLocation,
        if (categoryId != null) 'categoryId': categoryId.toString(),
      };

      if (image != null) {
        return await _apiService.uploadFile<Problem>(
          '${ApiConfig.problems}/$problemId',
          file: image,
          fieldName: 'image',
          data: data,
          fromJson: (json) => Problem.fromJson(json),
        );
      } else {
        return await _apiService.put<Problem>(
          '${ApiConfig.problems}/$problemId',
          data: data,
          fromJson: (json) => Problem.fromJson(json),
        );
      }
    } catch (e) {
      print('Error updating problem: $e');
      return ApiResponse<Problem>(
        success: false,
        message: 'Failed to update problem: ${e.toString()}',
      );
    }
  }

  // Delete a problem
  Future<ApiResponse<void>> deleteProblem(int problemId) async {
    try {
      return await _apiService.delete<void>(
        '${ApiConfig.problems}/$problemId',
      );
    } catch (e) {
      print('Error deleting problem: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Failed to delete problem: ${e.toString()}',
      );
    }
  }

  // Vote for a problem
  Future<ApiResponse<Map<String, dynamic>>> voteProblem(int problemId) async {
    try {
      return await _apiService.post<Map<String, dynamic>>(
        '${ApiConfig.problems}/$problemId/vote',
        fromJson: (json) => json,
      );
    } catch (e) {
      print('Error voting for problem: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Failed to vote for problem: ${e.toString()}',
      );
    }
  }

  // Add a comment to a problem
  Future<ApiResponse<ProblemComment>> addComment(int problemId, String comment) async {
    try {
      return await _apiService.post<ProblemComment>(
        '${ApiConfig.problems}/$problemId/comments',
        data: {
          'comment': comment,
        },
        fromJson: (json) => ProblemComment.fromJson(json),
      );
    } catch (e) {
      print('Error adding comment: $e');
      return ApiResponse<ProblemComment>(
        success: false,
        message: 'Failed to add comment: ${e.toString()}',
      );
    }
  }

  // Delete a comment
  Future<ApiResponse<void>> deleteComment(int problemId, int commentId) async {
    try {
      return await _apiService.delete<void>(
        '${ApiConfig.problems}/$problemId/comments/$commentId',
      );
    } catch (e) {
      print('Error deleting comment: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Failed to delete comment: ${e.toString()}',
      );
    }
  }

  // Update problem status (staff/admin only)
  Future<ApiResponse<Problem>> updateStatus(int problemId, int statusId) async {
    try {
      return await _apiService.put<Problem>(
        '${ApiConfig.problems}/$problemId/status',
        data: {
          'statusId': statusId,
        },
        fromJson: (json) => Problem.fromJson(json),
      );
    } catch (e) {
      print('Error updating status: $e');
      return ApiResponse<Problem>(
        success: false,
        message: 'Failed to update status: ${e.toString()}',
      );
    }
  }

  // Get all problem categories
  Future<ApiResponse<List<Category>>> getCategories() async {
    try {
      return await _apiService.get<List<Category>>(
        ApiConfig.problemCategories,
        fromJson: (json) => (json['categories'] as List)
            .map((category) => Category.fromJson(category))
            .toList(),
      );
    } catch (e) {
      print('Error fetching categories: $e');
      return ApiResponse<List<Category>>(
        success: false,
        message: 'Failed to fetch categories: ${e.toString()}',
        data: [],
      );
    }
  }

  // Get all problem statuses
  Future<ApiResponse<List<Status>>> getStatuses() async {
    try {
      return await _apiService.get<List<Status>>(
        ApiConfig.problemStatuses,
        fromJson: (json) => (json['statuses'] as List)
            .map((status) => Status.fromJson(status))
            .toList(),
      );
    } catch (e) {
      print('Error fetching statuses: $e');
      return ApiResponse<List<Status>>(
        success: false,
        message: 'Failed to fetch statuses: ${e.toString()}',
        data: [],
      );
    }
  }
}