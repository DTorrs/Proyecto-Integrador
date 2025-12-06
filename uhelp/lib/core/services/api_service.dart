import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import '../../config/api_config.dart';
import '../models/api_response.dart';
import 'storage_service.dart';

class ApiService {
  late Dio _dio;
  final StorageService _storageService = StorageService();

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: Duration(milliseconds: 30000), // Aumentado a 30 segundos
      receiveTimeout: Duration(milliseconds: 30000), // Aumentado a 30 segundos
      contentType: 'application/json',
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token to request if available
        final token = await _storageService.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        // Log de depuración
        print('REQUEST[${options.method}] => PATH: ${options.path}');
        print('Headers: ${options.headers}');
        if (options.data != null) {
          print('Data: ${options.data}');
        }
        
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Log de respuesta para depuración
        print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (DioException error, handler) async {
        print('ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}');
        if (error.response?.data != null) {
          print('Error data: ${error.response?.data}');
        }
        
        if (error.response?.statusCode == 401) {
          // Handle token expiration - logout or refresh token
          await _storageService.clearToken();
          await _storageService.clearUser();
        }
        return handler.next(error);
      },
    ));
  }

  // Generic GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      print('Error inesperado en GET: $e');
      return ApiResponse<T>(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Generic POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      print('Error inesperado en POST: $e');
      return ApiResponse<T>(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Generic PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic data,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      print('Error inesperado en PUT: $e');
      return ApiResponse<T>(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Generic DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        queryParameters: queryParameters,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      print('Error inesperado en DELETE: $e');
      return ApiResponse<T>(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Multipart POST for file uploads
  Future<ApiResponse<T>> uploadFile<T>(
    String endpoint, {
    required File file,
    required String fieldName,
    Map<String, dynamic>? data,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      // Verificar si el archivo existe
      if (!await file.exists()) {
        print('ERROR: El archivo no existe: ${file.path}');
        return ApiResponse<T>(
          success: false,
          message: 'El archivo seleccionado no existe o no es accesible',
        );
      }

      // Verificar tamaño del archivo
      final fileSize = await file.length();
      if (fileSize <= 0) {
        print('ERROR: Archivo vacío: ${file.path}');
        return ApiResponse<T>(
          success: false,
          message: 'El archivo seleccionado está vacío',
        );
      }

      // Obtener el nombre y la extensión del archivo
      final fileName = path.basename(file.path);
      final fileExtension = path.extension(file.path).toLowerCase();
      
      // Determinar el tipo MIME
      String? mimeType;
      if (fileExtension == '.jpg' || fileExtension == '.jpeg') {
        mimeType = 'image/jpeg';
      } else if (fileExtension == '.png') {
        mimeType = 'image/png';
      } else if (fileExtension == '.gif') {
        mimeType = 'image/gif';
      } else {
        mimeType = 'application/octet-stream';
      }
      
      print('INFO: Subiendo archivo - Nombre: $fileName, Tamaño: $fileSize bytes, Tipo MIME: $mimeType');

      // Crear el MultipartFile
      MediaType? mediaType;
      if (mimeType != null) {
        final mimeTypeParts = mimeType.split('/');
        if (mimeTypeParts.length == 2) {
          mediaType = MediaType(mimeTypeParts[0], mimeTypeParts[1]);
        }
      }
      
      final multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: mediaType,
      );

      // Preparar los datos del formulario
      Map<String, dynamic> formDataMap = {
        fieldName: multipartFile,
      };
      
      // Añadir datos adicionales si se proporcionan
      if (data != null) {
        data.forEach((key, value) {
          formDataMap[key] = value.toString();
        });
      }
      
      // Crear el FormData
      FormData formData = FormData.fromMap(formDataMap);
      
      print('INFO: FormData creado con éxito: ${formData.fields.length} campos y ${formData.files.length} archivos');
      
      // Configurar opciones específicas para la subida de archivos
      final options = Options(
        contentType: 'multipart/form-data',
        headers: {
          'Accept': 'application/json',
        },
        responseType: ResponseType.json,
      );

      // Realizar la solicitud
      final response = await _dio.post(
        endpoint,
        data: formData,
        options: options,
        onSendProgress: (sent, total) {
          final progress = (sent / total * 100).toStringAsFixed(2);
          print('Progreso de subida: $progress%');
        },
      );

      print('INFO: Respuesta recibida - Código: ${response.statusCode}');
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      print('ERROR DIO: ${e.type} - ${e.message}');
      print('REQUEST: ${e.requestOptions.uri}');
      if (e.response != null) {
        print('RESPONSE CODE: ${e.response?.statusCode}');
        print('RESPONSE DATA: ${e.response?.data}');
      }
      return _handleError<T>(e);
    } catch (e) {
      print('ERROR GENERAL: ${e.toString()}');
      return ApiResponse<T>(
        success: false,
        message: 'Error al subir el archivo: ${e.toString()}',
      );
    }
  }

  // MÉTODO CORREGIDO: Subida de múltiples archivos
  Future<ApiResponse<T>> uploadMultipleFiles<T>(
    String endpoint, {
    required Map<String, File> files,
    Map<String, dynamic>? data,
    T Function(Map<String, dynamic>)? fromJson,
    String method = 'PUT',
  }) async {
    try {
      print('====== SUBIDA MÚLTIPLE DE ARCHIVOS ======');
      print('Endpoint: $endpoint');
      print('Método: $method');
      print('Archivos a subir: ${files.length}');
      
      // Verificar que todos los archivos existan
      for (final entry in files.entries) {
        final file = entry.value;
        final fieldName = entry.key;
        
        print('Verificando archivo "$fieldName": ${file.path}');
        
        // Verificar existencia
        if (!await file.exists()) {
          print('ERROR: El archivo "$fieldName" no existe: ${file.path}');
          return ApiResponse<T>(
            success: false,
            message: 'El archivo "$fieldName" no existe o no es accesible',
          );
        }

        // Verificar tamaño
        final fileSize = await file.length();
        if (fileSize <= 0) {
          print('ERROR: Archivo "$fieldName" vacío: ${file.path}');
          return ApiResponse<T>(
            success: false,
            message: 'El archivo "$fieldName" está vacío',
          );
        }
        
        print('Archivo "$fieldName" verificado - Tamaño: $fileSize bytes');
      }

      // Crear FormData manualmente
      FormData formData = FormData();
      
      // Añadir los archivos al FormData
      for (final entry in files.entries) {
        final file = entry.value;
        final fieldName = entry.key;
        final fileName = path.basename(file.path);
        final fileExtension = path.extension(file.path).toLowerCase();
        
        // Determinar tipo MIME
        String? mimeType;
        if (fileExtension == '.jpg' || fileExtension == '.jpeg') {
          mimeType = 'image/jpeg';
        } else if (fileExtension == '.png') {
          mimeType = 'image/png';
        } else if (fileExtension == '.gif') {
          mimeType = 'image/gif';
        } else {
          mimeType = 'application/octet-stream';
        }
        
        print('Tipo MIME para "$fieldName": $mimeType');
        
        // Crear MediaType
        MediaType? mediaType;
        if (mimeType != null) {
          final mimeTypeParts = mimeType.split('/');
          if (mimeTypeParts.length == 2) {
            mediaType = MediaType(mimeTypeParts[0], mimeTypeParts[1]);
          }
        }
        
        // Crear MultipartFile
        final multipartFile = await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: mediaType,
        );
        
        // Añadir archivo al FormData con el nombre de campo específico
        formData.files.add(MapEntry(fieldName, multipartFile));
        
        print('Archivo "$fieldName" añadido al FormData - Nombre: $fileName');
      }
      
      // Añadir datos adicionales como campos de texto
      if (data != null) {
  data.forEach((key, value) {
    if (value != null) {
      // Asegurar que todos los valores se conviertan a string
      String stringValue = value.toString();
      formData.fields.add(MapEntry(key, stringValue));
      print('Campo añadido al FormData: $key = $stringValue');
    } else {
      print('ADVERTENCIA: Valor nulo para el campo $key, se omitirá');
    }
  });
}
      
      print('FormData preparado - ${formData.fields.length} campos, ${formData.files.length} archivos');
      
      // Configurar opciones
      final options = Options(
        contentType: 'multipart/form-data',
        headers: {
          'Accept': 'application/json',
        },
        responseType: ResponseType.json,
      );

      // Ejecutar la solicitud según el método especificado
      Response response;
      if (method.toUpperCase() == 'POST') {
        print('Enviando solicitud POST multipart...');
        response = await _dio.post(
          endpoint,
          data: formData,
          options: options,
          onSendProgress: (sent, total) {
            final progress = (sent / total * 100).toStringAsFixed(2);
            print('Progreso de subida: $progress%');
          },
        );
      } else {
        print('Enviando solicitud PUT multipart...');
        response = await _dio.put(
          endpoint,
          data: formData,
          options: options,
          onSendProgress: (sent, total) {
            final progress = (sent / total * 100).toStringAsFixed(2);
            print('Progreso de subida: $progress%');
          },
        );
      }

      print('Respuesta recibida - Código: ${response.statusCode}');
      if (response.data != null) {
        print('Datos de respuesta: ${response.data}');
      }
      
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      print('ERROR DIO EN SUBIDA MÚLTIPLE: ${e.type} - ${e.message}');
      print('REQUEST URI: ${e.requestOptions.uri}');
      print('REQUEST DATA TYPE: ${e.requestOptions.data.runtimeType}');
      if (e.response != null) {
        print('RESPONSE CODE: ${e.response?.statusCode}');
        print('RESPONSE DATA: ${e.response?.data}');
      }
      return _handleError<T>(e);
    } catch (e, stackTrace) {
      print('ERROR GENERAL EN SUBIDA MÚLTIPLE: ${e.toString()}');
      print('STACK TRACE: $stackTrace');
      return ApiResponse<T>(
        success: false,
        message: 'Error al subir los archivos: ${e.toString()}',
      );
    }
  }

  // Handle successful API response
  ApiResponse<T> _handleResponse<T>(
    Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    final responseData = response.data;
    try {
      if (responseData is Map<String, dynamic>) {
        // First check if the response has 'data' field directly
        if (fromJson != null) {
          try {
            // If the response itself contains the data needed for fromJson
            if (responseData.containsKey('data')) {
              return ApiResponse.fromJson(responseData, fromJson);
            } 
            // If the response is the data
            else if (fromJson != null) {
              final data = fromJson(responseData);
              return ApiResponse<T>(
                success: responseData['success'] ?? true,
                message: responseData['message'] ?? 'Request successful',
                data: data,
              );
            }
          } catch (e) {
            print('ERROR en la deserialización: $e');
            print('Datos recibidos: $responseData');
            return ApiResponse<T>(
              success: false,
              message: 'Error al procesar la respuesta: ${e.toString()}',
            );
          }
        }
        return ApiResponse<T>(
          success: responseData['success'] ?? true,
          message: responseData['message'] ?? 'No message provided',
          data: responseData['data'] as T?,
          error: responseData['error'],
        );
      }
      print('Respuesta no es Map: ${response.data.runtimeType}');
      return ApiResponse<T>(
        success: true,
        message: 'Request successful',
        data: null,
      );
    } catch (e) {
      print('ERROR en _handleResponse: $e');
      return ApiResponse<T>(
        success: false,
        message: 'Error al procesar la respuesta del servidor: ${e.toString()}',
      );
    }
  }

  // Handle API errors
  ApiResponse<T> _handleError<T>(DioException error) {
    String message = 'Something went wrong. Please try again.';
    dynamic errorData;
    
    if (error.response != null) {
      if (error.response!.data is Map<String, dynamic>) {
        message = error.response!.data['message'] ?? message;
        errorData = error.response!.data;
      } else if (error.response!.data is String) {
        message = error.response!.data;
      }
    } else if (error.type == DioExceptionType.connectionTimeout) {
      message = 'Connection timeout. Please check your internet connection.';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      message = 'Server is taking too long to respond. Please try again later.';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'No internet connection. Please check your network.';
    } else if (error.type == DioExceptionType.badResponse) {
      message = 'Bad response from server. Status: ${error.response?.statusCode}';
    }
    
    print('HANDLED ERROR: $message');
    return ApiResponse<T>(
      success: false,
      message: message,
      error: errorData,
    );
  }
}