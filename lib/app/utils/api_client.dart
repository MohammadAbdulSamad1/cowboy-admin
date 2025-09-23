// app/services/api_client.dart
import 'dart:convert';
import 'dart:io';
import 'package:dedicated_cow_boy_admin/app/models/api_user_model.dart';
import 'package:dedicated_cow_boy_admin/app/utils/exceptions.dart';
import 'package:http/http.dart' as http;

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    required this.statusCode,
  });
}

class ApiClient {
  static const String baseUrl = 'https://dedicatedcowboy.com';
  static const Duration requestTimeout = Duration(seconds: 30);

  // Headers
  static Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> _authHeaders(String token) => {
    ..._defaultHeaders,
    'Authorization': 'Bearer $token',
  };

  // Sign In
  static Future<ApiResponse<Map<String, dynamic>>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final value = email.trim();

      // Email regex
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

      // Check type
      final isEmail = emailRegex.hasMatch(value);
      final uri = Uri.parse('$baseUrl/?rest_route=/simple-jwt-login/v1/auth');

      final body = jsonEncode({
        if (!isEmail) 'username': email.trim(),
        if (isEmail) 'email': email.trim(),
        'password': password,
      });

      final response = await http.post(uri, body: body).timeout(requestTimeout);

      print(response.body);

      return _handleResponse<Map<String, dynamic>>(
        response,
        (data) => data as Map<String, dynamic>,
      );
    } on SocketException {
      throw const AuthException(
        message: 'No internet connection. Please check your network.',
        code: 'network-error',
      );
    } on http.ClientException {
      throw const AuthException(
        message: 'Network error. Please try again.',
        code: 'client-error',
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException(
        message: 'An unexpected error occurred during sign in.',
        code: 'unknown-error',
      );
    }
  }

  // Get User Profile
  static Future<ApiResponse<ApiUserModel>> getUserProfile(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/wp-json/wp/v2/users/me');

      final response = await http
          .get(uri, headers: _authHeaders(token))
          .timeout(requestTimeout);

      print(response.body);

      return ApiResponse<ApiUserModel>(
        success: true,
        data: ApiUserModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        ),
        statusCode: response.statusCode,
        message: jsonDecode(response.body)['message'],
      );
    } on SocketException {
      throw const AuthException(
        message: 'No internet connection. Please check your network.',
        code: 'network-error',
      );
    } on http.ClientException {
      throw const AuthException(
        message: 'Network error. Please try again.',
        code: 'client-error',
      );
    } catch (e) {
      print(e);
      if (e is AuthException) rethrow;
      throw AuthException(
        message: 'Failed to fetch user profile. ',
        code: 'profile-fetch-error $e',
      );
    }
  }

  // Sign Up
  static Future<ApiResponse<Map<String, dynamic>>> signUp({
    required String email,
    required String password,
    required String displayName,
    required String facebookPageId,
  }) async {
    try {
      final uri = Uri.parse(
        'https://dedicatedcowboy.com/?rest_route=/simple-jwt-login/v1/users&email=${Uri.encodeComponent(email.trim())}&password=${Uri.encodeComponent(password)}&user_login=${Uri.encodeComponent(displayName)}&display_name=${Uri.encodeComponent(displayName)}&facebook_page_id=${Uri.encodeComponent(facebookPageId)}',
      );

      final response = await http
          .post(uri, headers: _defaultHeaders)
          .timeout(requestTimeout);

      return _handleResponse<Map<String, dynamic>>(
        response,
        (data) => data as Map<String, dynamic>,
      );
    } on SocketException {
      throw const AuthException(
        message: 'No internet connection. Please check your network.',
        code: 'network-error',
      );
    } on http.ClientException {
      throw const AuthException(
        message: 'Network error. Please try again.',
        code: 'client-error',
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException(
        message: 'An unexpected error occurred during sign up.',
        code: 'unknown-error',
      );
    }
  }

  // Reset Password Request
  static Future<ApiResponse<Map<String, dynamic>>> resetPasswordRequest({
    required String email,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/?rest_route=/simple-jwt-login/v1/user/reset_password&email=${Uri.encodeComponent(email.trim())}',
      );

      final response = await http
          .post(uri, headers: _defaultHeaders)
          .timeout(requestTimeout);

      return _handleResponse<Map<String, dynamic>>(
        response,
        (data) => data as Map<String, dynamic>,
      );
    } on SocketException {
      throw const AuthException(
        message: 'No internet connection. Please check your network.',
        code: 'network-error',
      );
    } on http.ClientException {
      throw const AuthException(
        message: 'Network error. Please try again.',
        code: 'client-error',
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException(
        message: 'Failed to send reset password email.',
        code: 'reset-password-error',
      );
    }
  }

  // Change Password
  static Future<ApiResponse<Map<String, dynamic>>> changePassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/?rest_route=/simple-jwt-login/v1/user/reset_password&email=${Uri.encodeComponent(email.trim())}&code=${Uri.encodeComponent(code)}&new_password=${Uri.encodeComponent(newPassword)}',
      );

      final response = await http
          .post(uri, headers: _defaultHeaders)
          .timeout(requestTimeout);

      return _handleResponse<Map<String, dynamic>>(
        response,
        (data) => data as Map<String, dynamic>,
      );
    } on SocketException {
      throw const AuthException(
        message: 'No internet connection. Please check your network.',
        code: 'network-error',
      );
    } on http.ClientException {
      throw const AuthException(
        message: 'Network error. Please try again.',
        code: 'client-error',
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException(
        message: 'Failed to change password.',
        code: 'change-password-error',
      );
    }
  }

  // Update User Profile
  static Future<ApiResponse<ApiUserModel>> updateUserProfile({
    required String token,
    required Map<String, dynamic> updateData,
  }) async {
    try {
      print(updateData);
      final uri = Uri.parse('$baseUrl/wp-json/wp/v2/users/me');

      final response = await http
          .put(uri, headers: _authHeaders(token), body: jsonEncode(updateData))
          .timeout(requestTimeout);

      return _handleResponse<ApiUserModel>(
        response,
        (data) => ApiUserModel.fromJson(data as Map<String, dynamic>),
      );
    } on SocketException {
      throw const AuthException(
        message: 'No internet connection. Please check your network.',
        code: 'network-error',
      );
    } on http.ClientException {
      throw const AuthException(
        message: 'Network error. Please try again.',
        code: 'client-error',
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException(
        message: 'Failed to update user profile.',
        code: 'profile-update-error',
      );
    }
  }

  // Search Users
  static Future<ApiResponse<List<ApiUserModel>>> searchUsers({
    required String token,
    required String searchTerm,
    int page = 1,
    int perPage = 100,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/wp-json/wp/v2/users').replace(
        queryParameters: {
          'search': searchTerm,
          'page': page.toString(),
          'per_page': perPage.toString(),
          'context': 'edit', // Get full user data including meta
        },
      );

      final response = await http
          .get(uri, headers: _authHeaders(token))
          .timeout(requestTimeout);

      print('Search Users API Response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> usersJson = jsonDecode(response.body);
        final List<ApiUserModel> users =
            usersJson
                .map(
                  (userJson) =>
                      ApiUserModel.fromJson(userJson as Map<String, dynamic>),
                )
                .toList();

        return ApiResponse<List<ApiUserModel>>(
          success: true,
          data: users,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<List<ApiUserModel>>(
          success: false,
          data: null,
          statusCode: response.statusCode,
          message: 'Failed to search users',
        );
      }
    } on SocketException {
      throw const AuthException(
        message: 'No internet connection. Please check your network.',
        code: 'network-error',
      );
    } on http.ClientException {
      throw const AuthException(
        message: 'Network error. Please try again.',
        code: 'client-error',
      );
    } catch (e) {
      print('Error searching users: $e');
      if (e is AuthException) rethrow;
      throw AuthException(
        message: 'Failed to search users: $e',
        code: 'users-search-error',
      );
    }
  }

  // Get All Users
  static Future<ApiResponse<List<ApiUserModel>>> getAllUsers({
    String? token,
    int page = 1,
    int perPage = 100,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/wp-json/wp/v2/users').replace(
        queryParameters: {
          'page': page.toString(),
          'per_page': perPage.toString(),
          'context': 'edit', // Get full user data including meta
        },
      );

      final headers = token != null ? _authHeaders(token) : _defaultHeaders;

      final response = await http
          .get(uri, headers: headers)
          .timeout(requestTimeout);

      print('Users API Response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> usersJson = jsonDecode(response.body);
        final List<ApiUserModel> users =
            usersJson
                .map(
                  (userJson) =>
                      ApiUserModel.fromJson(userJson as Map<String, dynamic>),
                )
                .toList();

        return ApiResponse<List<ApiUserModel>>(
          success: true,
          data: users,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<List<ApiUserModel>>(
          success: false,
          data: null,
          statusCode: response.statusCode,
          message: 'Failed to fetch users',
        );
      }
    } on SocketException {
      throw const AuthException(
        message: 'No internet connection. Please check your network.',
        code: 'network-error',
      );
    } on http.ClientException {
      throw const AuthException(
        message: 'Network error. Please try again.',
        code: 'client-error',
      );
    } catch (e) {
      print('Error fetching users: $e');
      if (e is AuthException) rethrow;
      throw AuthException(
        message: 'Failed to fetch users: $e',
        code: 'users-fetch-error',
      );
    }
  }

  // Generic response handler
  static ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic) fromJson,
  ) {
    try {
      final Map<String, dynamic> data = jsonDecode(response.body);

      switch (response.statusCode) {
        case 200:
          if (data.containsKey('success')) {
            if (data['success'] == true) {
              final responseData =
                  data.containsKey('data') ? data['data'] : data;
              return ApiResponse<T>(
                success: true,
                data: fromJson(responseData),
                statusCode: response.statusCode,
                message: data['message'],
              );
            } else {
              throw AuthException(
                message: data['message'] ?? 'Request failed',
                code: 'api-error',
              );
            }
          } else {
            // No "success" field, just parse directly
            return ApiResponse<T>(
              success: true,
              data: fromJson(data),
              statusCode: response.statusCode,
              message: null,
            );
          }
        case 201:
          if (data.containsKey('success')) {
            if (data['success'] == true) {
              final responseData =
                  data.containsKey('data') ? data['data'] : data;
              return ApiResponse<T>(
                success: true,
                data: fromJson(responseData),
                statusCode: response.statusCode,
                message: data['message'],
              );
            } else {
              throw AuthException(
                message: data['message'] ?? 'Request failed',
                code: 'api-error',
              );
            }
          } else {
            // No "success" field, just parse directly
            return ApiResponse<T>(
              success: true,
              data: fromJson(data),
              statusCode: response.statusCode,
              message: null,
            );
          }
        case 400:
          throw AuthException(
            message: data['message'] ?? 'Bad request. Please check your input.',
            code: 'bad-request',
          );

        case 401:
          throw const AuthException(
            message:
                'Invalid credentials. Please check your email and password.',
            code: 'invalid-credentials',
          );

        case 403:
          throw const AuthException(
            message: 'Access denied. You don\'t have permission.',
            code: 'access-denied',
          );

        case 404:
          throw const AuthException(
            message: 'Account not found.',
            code: 'user-not-found',
          );

        case 409:
          throw const AuthException(
            message: 'Email already exists. Please use a different email.',
            code: 'email-already-exists',
          );

        case 422:
          throw AuthException(
            message: data['message'] ?? 'Invalid data provided.',
            code: 'validation-error',
          );

        case 429:
          throw const AuthException(
            message: 'Too many requests. Please try again later.',
            code: 'too-many-requests',
          );

        case 500:
        case 502:
        case 503:
        case 504:
          throw const AuthException(
            message: 'Server error. Please try again later.',
            code: 'server-error',
          );

        default:
          throw AuthException(
            message: data['message'] ?? 'An unexpected error occurred.',
            code: 'unknown-status-${response.statusCode}',
          );
      }
    } on FormatException {
      throw const AuthException(
        message: 'Invalid response format from server.',
        code: 'invalid-response',
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException(
        message: 'Failed to process server response.',
        code: 'response-processing-error',
      );
    }
  }
}
