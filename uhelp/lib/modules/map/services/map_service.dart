import '../../../core/services/api_service.dart';
import '../../../config/api_config.dart';
import '../../../core/models/api_response.dart';
import '../../../core/models/location_model.dart';
import '../models/map_data_model.dart';

class MapService {
  final ApiService _apiService = ApiService();

  // Get all locations
  Future<ApiResponse<List<Location>>> getLocations() async {
    return await _apiService.get<List<Location>>(
      ApiConfig.locations,
      fromJson: (json) => (json['locations'] as List)
          .map((location) => Location.fromJson(location))
          .toList(),
    );
  }

  // Get map overview data (counts for each location)
  Future<ApiResponse<List<MapLocationData>>> getMapOverview() async {
    return await _apiService.get<List<MapLocationData>>(
      ApiConfig.mapOverview,
      fromJson: (json) => (json['mapData'] as List)
          .map((item) => MapLocationData.fromJson(item))
          .toList(),
    );
  }

  // Get problems for a specific location
  Future<ApiResponse<LocationDetailData>> getProblemsByLocation(int locationId) async {
    return await _apiService.get<LocationDetailData>(
      '${ApiConfig.locations}/$locationId/problems',
      fromJson: (json) => LocationDetailData.fromJson(json),
    );
  }

  // Get lost items for a specific location
  Future<ApiResponse<LocationDetailData>> getLostItemsByLocation(int locationId) async {
    return await _apiService.get<LocationDetailData>(
      '${ApiConfig.locations}/$locationId/lost-items',
      fromJson: (json) => LocationDetailData.fromJson(json),
    );
  }

  // Check for similar problems at a location
  Future<ApiResponse<SimilarProblemsResponse>> checkSimilarProblems({
    required int locationId, 
    required String title, 
    required String description,
  }) async {
    return await _apiService.post<SimilarProblemsResponse>(
      ApiConfig.checkSimilarProblems,
      data: {
        'locationId': locationId,
        'title': title,
        'description': description,
      },
      fromJson: (json) => SimilarProblemsResponse.fromJson(json),
    );
  }
}