// lib/core/services/auth_service.dart
import 'dart:convert';
import '../models/api_response.dart';
import '../models/user_model.dart';
import '../../config/api_config.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  // Login user - método actualizado
Future<ApiResponse<User>> login(String email, String password) async {
  try {
    // Mantener la estructura original de la llamada
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConfig.login,
      data: {
        'email': email,
        'password': password,
      },
      fromJson: (json) => json,
    );

    print('Login response: ${response.data}');

    if (response.success && response.data != null) {
      // Intentar extraer el usuario y token de la respuesta
      try {
        // Obtener data de la respuesta (que es un Map)
        final responseData = response.data!;
        
        // Si hay un campo 'data' que contiene el usuario y token
        if (responseData.containsKey('data')) {
          Map<String, dynamic> data = responseData['data'];
          
          // Extraer usuario y token
          if (data.containsKey('user') && data.containsKey('token')) {
            User user = User.fromJson(data['user']);
            String token = data['token'];
            
            // Guardar token y datos de usuario
            await _storageService.saveToken(token);
            await _storageService.saveUser(jsonEncode(user.toJson()));
            
            return ApiResponse<User>(
              success: true,
              message: 'Login successful',
              data: user,
            );
          }
        } 
        // Si el usuario y token están directamente en la respuesta
        else if (responseData.containsKey('user') && responseData.containsKey('token')) {
          User user = User.fromJson(responseData['user']);
          String token = responseData['token'];
          
          await _storageService.saveToken(token);
          await _storageService.saveUser(jsonEncode(user.toJson()));
          
          return ApiResponse<User>(
            success: true,
            message: 'Login successful',
            data: user,
          );
        }
        
        // Si no encontramos el formato esperado
        return ApiResponse<User>(
          success: false,
          message: 'Unexpected response format',
        );
      } catch (e) {
        print('Error processing login response: $e');
        return ApiResponse<User>(
          success: false,
          message: 'Error processing login response: ${e.toString()}',
        );
      }
    }

    return ApiResponse<User>(
      success: false,
      message: response.message,
    );
  } catch (e) {
    print('Login error: $e');
    return ApiResponse<User>(
      success: false,
      message: 'An unexpected error occurred: ${e.toString()}',
    );
  }
}

Future<ApiResponse<User>> register(String username, String email, String password, String fullName) async {
  try {
    final response = await _apiService.post<dynamic>(
      ApiConfig.register,
      data: {
        'username': username,
        'email': email,
        'password': password,
        'fullName': fullName,
      },
    );

    // Imprimir la respuesta completa para ver su estructura exacta
    print('Register complete response: ${response.toString()}');
    print('Register data type: ${response.data?.runtimeType}');
    print('Register data content: ${response.data}');

    if (response.success && response.data != null) {
      // Intentar extraer el usuario y token de cualquier estructura posible
      try {
        dynamic responseData = response.data;
        Map<String, dynamic> userData = {};
        String? token;

        // Caso 1: responseData es directamente la información del usuario
        if (responseData is Map<String, dynamic> && responseData.containsKey('username')) {
          userData = responseData;
          token = responseData['token'] as String?;
        }
        // Caso 2: responseData.data contiene la información del usuario
        else if (responseData is Map<String, dynamic> && 
                responseData.containsKey('data') && 
                responseData['data'] is Map<String, dynamic>) {
          dynamic data = responseData['data'];
          
          // Caso 2.1: data contiene user y token
          if (data.containsKey('user') && data.containsKey('token')) {
            userData = data['user'];
            token = data['token'] as String?;
          }
          // Caso 2.2: data es directamente el usuario
          else if (data.containsKey('username') || data.containsKey('email')) {
            userData = data;
            token = data['token'] as String?;
          }
        }
        // Caso 3: responseData contiene user y token por separado
        else if (responseData is Map<String, dynamic> && 
                responseData.containsKey('user') && 
                responseData.containsKey('token')) {
          userData = responseData['user'];
          token = responseData['token'] as String?;
        }
        
        // Si encontramos datos de usuario, crear objeto User
        if (userData.isNotEmpty) {
          User user = User.fromJson(userData);
          
          // Si hay token, guardarlo
          if (token != null && token.isNotEmpty) {
            await _storageService.saveToken(token);
            await _storageService.saveUser(jsonEncode(user.toJson()));
          }
          
          return ApiResponse<User>(
            success: true,
            message: 'Registration successful',
            data: user,
          );
        }
        
        // Si llegamos aquí, no pudimos encontrar el formato esperado
        return ApiResponse<User>(
          success: false,
          message: 'Unexpected response format. See logs for details.',
        );
      } catch (e) {
        print('Error processing registration response: $e');
        return ApiResponse<User>(
          success: false,
          message: 'Error processing response: ${e.toString()}',
        );
      }
    }

    return ApiResponse<User>(
      success: false,
      message: response.message,
    );
  } catch (e) {
    print('Registration error: $e');
    return ApiResponse<User>(
      success: false,
      message: 'An unexpected error occurred: ${e.toString()}',
    );
  }
}

  // Get current user profile
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final response = await _apiService.get<User>(
        ApiConfig.me,
        fromJson: (json) => User.fromJson(json),
      );

      if (response.success && response.data != null) {
        // Update stored user data
        await _storageService.saveUser(jsonEncode(response.data!.toJson()));
      }

      return response;
    } catch (e) {
      print('Get current user error: $e');
      return ApiResponse<User>(
        success: false,
        message: 'Failed to load user profile: ${e.toString()}',
      );
    }
  }

  // Change password
  Future<ApiResponse<void>> changePassword(String currentPassword, String newPassword) async {
    try {
      return await _apiService.put<void>(
        ApiConfig.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      print('Change password error: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Failed to change password: ${e.toString()}',
      );
    }
  }

  // Update user profile
  Future<ApiResponse<User>> updateProfile(String fullName) async {
    try {
      return await _apiService.put<User>(
        ApiConfig.userProfile,
        data: {
          'fullName': fullName,
        },
        fromJson: (json) => User.fromJson(json),
      );
    } catch (e) {
      print('Update profile error: $e');
      return ApiResponse<User>(
        success: false,
        message: 'Failed to update profile: ${e.toString()}',
      );
    }
  }

  // Logout user
  Future<void> logout() async {
    await _storageService.clearToken();
    await _storageService.clearUser();
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _storageService.getToken();
    return token != null && token.isNotEmpty;
  }

  // Get stored user data
  Future<User?> getStoredUser() async {
    final userData = await _storageService.getUser();
    if (userData != null && userData.isNotEmpty) {
      try {
        return User.fromJson(jsonDecode(userData));
      } catch (e) {
        print('Error parsing stored user data: $e');
        return null;
      }
    }
    return null;
  }
}