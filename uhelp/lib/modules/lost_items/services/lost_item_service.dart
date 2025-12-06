import 'dart:io';
import '../../../core/services/api_service.dart';
import '../../../config/api_config.dart';
import '../../../core/models/api_response.dart';
import '../../../core/models/pagination_model.dart';
import '../../../core/models/status_model.dart';
import '../models/lost_item_model.dart';

class LostItemService {
  final ApiService _apiService = ApiService();

  // Get all lost items with filtering
  Future<ApiResponse<PaginatedData<LostItem>>> getLostItems({
    bool? isFound,
    int? statusId,
    int? locationId,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      if (isFound != null) queryParams['isFound'] = isFound.toString();
      if (statusId != null) queryParams['statusId'] = statusId.toString();
      if (locationId != null) queryParams['locationId'] = locationId.toString();

      print("Getting lost items with params: $queryParams");
      return await _apiService.get<PaginatedData<LostItem>>(
        ApiConfig.lostItems,
        queryParameters: queryParams,
        fromJson: (json) => PaginatedData.fromJson(
          json,
          (itemJson) => LostItem.fromJson(itemJson),
        ),
      );
    } catch (e) {
      print('Error fetching lost items: $e');
      print(StackTrace.current);
      return ApiResponse<PaginatedData<LostItem>>(
        success: false,
        message: 'Failed to fetch lost items: ${e.toString()}',
      );
    }
  }

  // Get lost item by ID
  Future<ApiResponse<LostItem>> getLostItemById(int itemId) async {
    try {
      print("Fetching lost item with ID: $itemId");
      final response = await _apiService.get<LostItem>(
        '${ApiConfig.lostItems}/$itemId',
        fromJson: (json) {
          print("Raw response data for item $itemId: $json");
          final item = LostItem.fromJson(json);
          print("Successfully parsed lost item with title: ${item.title}");
          // Debug the image URL specifically
          print("Image URL for item $itemId: ${item.imageUrl}");
          return item;
        },
      );
      
      if (response.success) {
        print("Lost item retrieved successfully");
        if (response.data != null) {
          print("Lost item title: ${response.data!.title}");
        } else {
          print("WARNING: Response success but data is null");
        }
      } else {
        print("Failed to retrieve lost item: ${response.message}");
      }
      
      return response;
    } catch (e) {
      print('Error fetching lost item details: $e');
      print(StackTrace.current);
      return ApiResponse<LostItem>(
        success: false,
        message: 'Failed to fetch lost item details: ${e.toString()}',
      );
    }
  }

  // Create a new lost item
  Future<ApiResponse<LostItem>> createLostItem({
    required String title,
    required String description,
    required int locationId,
    required String specificLocation,
    required bool isFound,
    required String contactInfo,
    File? image,
  }) async {
    try {
      print('===== CREANDO OBJETO PERDIDO =====');
      print('Título: $title');
      print('Ubicación ID: $locationId');
      print('Es encontrado: $isFound');
      print('Contacto: $contactInfo');
      
      if (image != null) {
        print('Archivo de imagen: ${image.path}');
        
        // Verificar la existencia del archivo
        if (!await image.exists()) {
          print('ERROR: El archivo no existe');
          return ApiResponse<LostItem>(
            success: false,
            message: 'La imagen seleccionada no existe o no es accesible',
          );
        }
        
        final fileSize = await image.length();
        print('Tamaño de imagen: ${fileSize} bytes');
        
        if (fileSize <= 0) {
          print('ERROR: La imagen está vacía');
          return ApiResponse<LostItem>(
            success: false,
            message: 'La imagen seleccionada está vacía o corrupta',
          );
        }
        
        // Preparar los datos como Map<String, dynamic> para formData
        final Map<String, dynamic> formData = {
          'title': title,
          'description': description,
          'locationId': locationId.toString(),
          'specificLocation': specificLocation,
          'isFound': isFound.toString(),
          'contactInfo': contactInfo,
        };
        
        print('Datos del formulario: $formData');
        
        return await _apiService.uploadFile<LostItem>(
          ApiConfig.lostItems,
          file: image,
          fieldName: 'image',
          data: formData,
          fromJson: (json) {
            print('Respuesta JSON: $json');
            return LostItem.fromJson(json);
          },
        );
      } else {
        print('Sin imagen adjunta, enviando solo datos');
        
        return await _apiService.post<LostItem>(
          ApiConfig.lostItems,
          data: {
            'title': title,
            'description': description,
            'locationId': locationId,
            'specificLocation': specificLocation,
            'isFound': isFound,
            'contactInfo': contactInfo,
          },
          fromJson: (json) {
            print('Respuesta JSON: $json');
            return LostItem.fromJson(json);
          },
        );
      }
    } catch (e) {
      print('ERROR al crear objeto perdido: $e');
      print(StackTrace.current);
      return ApiResponse<LostItem>(
        success: false,
        message: 'Error al reportar objeto: ${e.toString()}',
      );
    }
  }

  // Update a lost item
  Future<ApiResponse<LostItem>> updateLostItem({
    required int itemId,
    String? title,
    String? description,
    int? locationId,
    String? specificLocation,
    String? contactInfo,
    File? image,
  }) async {
    try {
      print("Updating lost item with ID: $itemId");
      final data = {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (locationId != null) 'locationId': locationId.toString(),
        if (specificLocation != null) 'specificLocation': specificLocation,
        if (contactInfo != null) 'contactInfo': contactInfo,
      };

      if (image != null) {
        return await _apiService.uploadFile<LostItem>(
          '${ApiConfig.lostItems}/$itemId',
          file: image,
          fieldName: 'image',
          data: data,
          fromJson: (json) => LostItem.fromJson(json),
        );
      } else {
        return await _apiService.put<LostItem>(
          '${ApiConfig.lostItems}/$itemId',
          data: data,
          fromJson: (json) => LostItem.fromJson(json),
        );
      }
    } catch (e) {
      print('Error updating lost item: $e');
      print(StackTrace.current);
      return ApiResponse<LostItem>(
        success: false,
        message: 'Failed to update lost item: ${e.toString()}',
      );
    }
  }

  // Delete a lost item
  Future<ApiResponse<void>> deleteLostItem(int itemId) async {
    try {
      print("Deleting lost item with ID: $itemId");
      final response = await _apiService.delete<void>(
        '${ApiConfig.lostItems}/$itemId',
      );
      
      print("Delete response: success=${response.success}, message=${response.message}");
      return response;
    } catch (e) {
      print('Error deleting lost item: $e');
      print(StackTrace.current);
      return ApiResponse<void>(
        success: false,
        message: 'Failed to delete lost item: ${e.toString()}',
      );
    }
  }

  // Update lost item status (staff/admin only) - MÉTODO CORREGIDO
  Future<ApiResponse<LostItem>> updateStatus(int itemId, int statusId, {File? idPhoto, File? claimPhoto}) async {
    try {
      print("===== ACTUALIZANDO ESTADO DE OBJETO =====");
      print("ID del objeto: $itemId");
      print("Nuevo estado: $statusId");
      
      // Verificar que el statusId es válido
      if (statusId < 1 || statusId > 4) {
        print("ERROR: statusId inválido: $statusId (debe estar entre 1-4)");
        return ApiResponse<LostItem>(
          success: false,
          message: 'Status ID debe estar entre 1 y 4',
        );
      }
      
      // IMPORTANTE: Usar la URL con el parámetro de consulta statusId
      final endpoint = '${ApiConfig.lostItems}/$itemId/status?statusId=$statusId';
      
      // Si el estado es "claimed" (3) y se proporcionaron las fotos
      if (statusId == 3 && idPhoto != null && claimPhoto != null) {
        // Verificar que las fotos existan
        if (!await idPhoto.exists() || await idPhoto.length() == 0) {
          print("ERROR: La foto del DNI no existe o está vacía");
          return ApiResponse<LostItem>(
            success: false,
            message: 'La foto del DNI no es válida',
          );
        }
        
        if (!await claimPhoto.exists() || await claimPhoto.length() == 0) {
          print("ERROR: La foto de entrega no existe o está vacía");
          return ApiResponse<LostItem>(
            success: false,
            message: 'La foto de entrega no es válida',
          );
        }
        
        print("Subiendo fotos para estado 'claimed'");
        print("URL con parámetro: $endpoint");
        print("Foto DNI: ${idPhoto.path}");
        print("Foto entrega: ${claimPhoto.path}");
        
        return await _apiService.uploadMultipleFiles<LostItem>(
          endpoint, // URL que ya incluye statusId como query parameter
          files: {
            'idPhoto': idPhoto,
            'claimPhoto': claimPhoto,
          },
          // También incluir en el body para compatibilidad
          data: {
            'statusId': statusId.toString(),
          },
          fromJson: (json) => LostItem.fromJson(json),
        );
      } else {
        print("Actualizando sin fotos");
        print("URL con parámetro: $endpoint");
        
        return await _apiService.put<LostItem>(
          endpoint, // URL que ya incluye statusId como query parameter
          data: {
            'statusId': statusId.toString(), // También enviar en el body por si acaso
          },
          fromJson: (json) => LostItem.fromJson(json),
        );
      }
    } catch (e, stackTrace) {
      print('ERROR actualizando estado: $e');
      print(stackTrace);
      return ApiResponse<LostItem>(
        success: false,
        message: 'Failed to update lost item status: ${e.toString()}',
      );
    }
  }

  // Get all lost item statuses
  Future<ApiResponse<List<Status>>> getStatuses() async {
    try {
      return await _apiService.get<List<Status>>(
        ApiConfig.lostItemStatuses,
        fromJson: (json) => (json['statuses'] as List)
            .map((status) => Status.fromJson(status))
            .toList(),
      );
    } catch (e) {
      print('Error fetching lost item statuses: $e');
      print(StackTrace.current);
      return ApiResponse<List<Status>>(
        success: false,
        message: 'Failed to fetch lost item statuses: ${e.toString()}',
        data: [],
      );
    }
  }
}