// app/middleware/auth_middleware.dart
import 'dart:convert';
import 'package:dedicated_cow_boy_admin/app/models/api_user_model.dart';
import 'package:dedicated_cow_boy_admin/app/new/auth_service.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Check if user is authenticated
    final authService = Get.find<AuthService>();

    if (!authService.isSignedIn) {
      // Redirect to login if not authenticated
      return const RouteSettings(name: '/sign-in');
    }

    return null; // Continue to the requested route
  }
}

// Storage helper for authentication data
class AuthStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _isSignedInKey = 'is_signed_in';
  static const String _tokenExpiryKey = 'token_expiry';

  // Store authentication data
  static Future<void> storeAuthData({
    required String token,
    required ApiUserModel user,
    DateTime? tokenExpiry,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      await prefs.setBool(_isSignedInKey, true);

      if (tokenExpiry != null) {
        await prefs.setString(_tokenExpiryKey, tokenExpiry.toIso8601String());
      }
    } catch (e) {
      debugPrint('Error storing auth data: $e');
      throw Exception('Failed to store authentication data');
    }
  }

  // Load authentication data
  static Future<Map<String, dynamic>?> loadAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final isSignedIn = prefs.getBool(_isSignedInKey) ?? false;
      if (!isSignedIn) return null;

      final token = prefs.getString(_tokenKey);
      final userDataString = prefs.getString(_userKey);
      final tokenExpiryString = prefs.getString(_tokenExpiryKey);

      if (token == null || userDataString == null) return null;

      // Check token expiry
      if (tokenExpiryString != null) {
        final tokenExpiry = DateTime.tryParse(tokenExpiryString);
        if (tokenExpiry != null && DateTime.now().isAfter(tokenExpiry)) {
          // Token expired, clear data
          await clearAuthData();
          return null;
        }
      }

      final userData = jsonDecode(userDataString) as Map<String, dynamic>;
      final user = ApiUserModel.fromJson(userData);

      return {
        'token': token,
        'user': user,
        'tokenExpiry':
            tokenExpiryString != null
                ? DateTime.tryParse(tokenExpiryString)
                : null,
      };
    } catch (e) {
      debugPrint('Error loading auth data: $e');
      await clearAuthData(); // Clear corrupted data
      return null;
    }
  }

  // Clear authentication data
  static Future<void> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      await prefs.remove(_tokenExpiryKey);
      await prefs.setBool(_isSignedInKey, false);
    } catch (e) {
      debugPrint('Error clearing auth data: $e');
    }
  }

  // Check if token exists
  static Future<bool> hasValidToken() async {
    try {
      final authData = await loadAuthData();
      return authData != null && authData['token'] != null;
    } catch (e) {
      return false;
    }
  }

  // Get stored token
  static Future<String?> getToken() async {
    try {
      final authData = await loadAuthData();
      return authData?['token'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Get stored user
  static Future<ApiUserModel?> getUser() async {
    try {
      final authData = await loadAuthData();
      return authData?['user'] as ApiUserModel?;
    } catch (e) {
      return null;
    }
  }

  // Update user data only
  static Future<void> updateUserData(ApiUserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Error updating user data: $e');
    }
  }
}

// Auth guard for protecting routes
class AuthGuard {
  static Future<bool> isAuthenticated() async {
    return await AuthStorage.hasValidToken();
  }

  static Future<void> requireAuth() async {
    if (!await isAuthenticated()) {
      Get.offAllNamed('/sign-in');
    }
  }

  static Future<void> redirectIfAuthenticated() async {
    if (await isAuthenticated()) {
      Get.offAllNamed('/home');
    }
  }
}
