import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';

class StorageService {
  // Save auth token
  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, token);
      print('Token saved successfully');
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  // Get auth token
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      return token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Clear auth token
  Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      print('Token cleared successfully');
    } catch (e) {
      print('Error clearing token: $e');
    }
  }

  // Save user data
  Future<void> saveUser(String userJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userKey, userJson);
      print('User data saved successfully');
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  // Get user data
  Future<String?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(AppConstants.userKey);
      return userData;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Clear user data
  Future<void> clearUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userKey);
      print('User data cleared successfully');
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }
  
  // Clear all data
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('All storage data cleared successfully');
    } catch (e) {
      print('Error clearing all data: $e');
    }
  }
}