// app/services/auth_service.dart
import 'dart:async';

import 'package:dedicated_cow_boy_admin/app/models/api_user_model.dart';
import 'package:dedicated_cow_boy_admin/app/new/k.dart';
import 'package:dedicated_cow_boy_admin/app/utils/api_client.dart';
import 'package:dedicated_cow_boy_admin/app/utils/exceptions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthService extends GetxService {
  ApiUserModel? _currentUser;
  String? _currentToken;

  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Initialize service
  Future<AuthService> init() async {
    await initialize();
    return this;
  }

  // Stream controller for auth state changes
  final StreamController<ApiUserModel?> _authStateController =
      StreamController<ApiUserModel?>.broadcast();

  //ApiUserModel Getters
  ApiUserModel? get currentUser => _currentUser;
  String? get currentToken => _currentToken;
  bool get isSignedIn => _currentUser != null && _currentToken != null;
  Stream<ApiUserModel?> get authStateChanges => _authStateController.stream;

  // Initialize service
  Future<void> initialize() async {
    try {
      await _loadStoredAuth();

      // Validate stored token if exists
      if (_currentToken != null) {
        await _validateAndRefreshUser();
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      await _clearAuthData();
    }
  }

  // Sign In
  Future<ApiUserModel> signIn({
    required String email,
    required String password,
  }) async {
    // _validateEmail(email);
    _validatePassword(password);

    try {
      // Call sign in API
      final signInResponse = await ApiClient.signIn(
        email: email,
        password: password,
      );

      if (!signInResponse.success || signInResponse.data == null) {
        throw const AuthException(
          message: 'Sign in failed. Please try again.',
          code: 'sign-in-failed',
        );
      }

      final token = signInResponse.data!['jwt'] as String?;
      if (token == null || token.isEmpty) {
        throw const AuthException(
          message: 'Invalid authentication token received.',
          code: 'invalid-token',
        );
      }

      // Store token
      _currentToken = token;

      // Fetch user profile
      final userResponse = await ApiClient.getUserProfile(token);

      if (!userResponse.success || userResponse.data == null) {
        throw const AuthException(
          message: 'Failed to fetch user profile.',
          code: 'profile-fetch-failed',
        );
      }

      _currentUser = userResponse.data!;

      // Store authentication data with token expiry (24 hours from now)
      final tokenExpiry = DateTime.now().add(const Duration(hours: 24));
      await AuthStorage.storeAuthData(
        token: token,
        user: _currentUser!,
        tokenExpiry: tokenExpiry,
      );

      // Notify listeners
      _authStateController.add(_currentUser);

      return _currentUser!;
    } catch (e) {
      _currentUser = null;
      _currentToken = null;
      await _clearAuthData();
      rethrow;
    }
  }

  // Sign Up
  Future<ApiUserModel> signUp({
    required String email,
    required String password,
    required String displayName,
    required String facebookPageId,
  }) async {
    _validateEmail(email);
    _validatePassword(password);

    try {
      // Call sign up API
      final signUpResponse = await ApiClient.signUp(
        email: email,
        password: password,
        displayName: displayName,
        facebookPageId: facebookPageId,
      );

      if (!signUpResponse.success) {
        throw AuthException(
          message:
              signUpResponse.message ?? 'Sign up failed. Please try again.',
          code: 'sign-up-failed',
        );
      }

      // After successful sign up, automatically sign in
      return await signIn(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _clearAuthData();
      _currentUser = null;
      _currentToken = null;

      // Notify listeners
      _authStateController.add(null);
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    _validateEmail(email);

    try {
      final response = await ApiClient.resetPasswordRequest(email: email);

      if (!response.success) {
        throw AuthException(
          message: response.message ?? 'Failed to send reset password email.',
          code: 'reset-password-failed',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Change Password with Code
  Future<void> changePasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _validateEmail(email);
    _validatePassword(newPassword);

    try {
      final response = await ApiClient.changePassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );

      if (!response.success) {
        throw AuthException(
          message: response.message ?? 'Failed to change password.',
          code: 'change-password-failed',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update Profile
  Future<ApiUserModel> updateProfile({
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? description,
    String? url,
  }) async {
    if (_currentToken == null) {
      throw const AuthException(message: 'No user signed in.', code: 'no-user');
    }

    try {
      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name.trim();
      if (firstName != null) updateData['first_name'] = firstName.trim();
      if (lastName != null) updateData['last_name'] = lastName.trim();
      // if (email != null) {
      //   _validateEmail(email);
      //   updateData['email'] = email.trim();
      // }
      if (description != null) updateData['description'] = description.trim();
      if (url != null) updateData['url'] = url.trim();

      if (updateData.isEmpty) {
        throw const AuthException(
          message: 'No data provided for update.',
          code: 'no-update-data',
        );
      }

      final response = await ApiClient.updateUserProfile(
        token: _currentToken!,
        updateData: updateData,
      );

      if (!response.success || response.data == null) {
        throw AuthException(
          message: response.message ?? 'Failed to update profile.',
          code: 'profile-update-failed',
        );
      }

      _currentUser = response.data!;

      // Update stored user data
      await AuthStorage.updateUserData(_currentUser!);

      // Notify listeners
      _authStateController.add(_currentUser);

      return _currentUser!;
    } catch (e) {
      rethrow;
    }
  }

  Future updateUserProfileDetails({
    final Map<String, dynamic>? updateData,
  }) async {
    if (_currentToken == null) {
      throw const AuthException(message: 'No user signed in.', code: 'no-user');
    }

    try {
      if (updateData == null) {
        throw const AuthException(
          message: 'No data provided for update.',
          code: 'no-update-data',
        );
      }

      final response = await ApiClient.updateUserProfile(
        token: _currentToken!,
        updateData: updateData,
      );
      if (!response.success || response.data == null) {
        throw AuthException(
          message: response.message ?? 'Failed to update profile.',
          code: 'profile-update-failed',
        );
      }

      _currentUser = response.data!;

      // Update stored user data
      await AuthStorage.updateUserData(_currentUser!);

      // Notify listeners
      _authStateController.add(_currentUser);

      return _currentUser!;
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  // Refresh user data
  Future<ApiUserModel?> refreshUser() async {
    if (_currentToken == null) return null;

    try {
      final response = await ApiClient.getUserProfile(_currentToken!);

      if (response.success && response.data != null) {
        _currentUser = response.data!;
        await AuthStorage.updateUserData(_currentUser!);
        _authStateController.add(_currentUser);
        return _currentUser;
      }
    } catch (e) {
      debugPrint('Refresh user error: $e');
      // If token is invalid, sign out
      if (e is AuthException &&
          (e.code == 'invalid-credentials' ||
              e.code == 'access-denied' ||
              e.code == 'token-expired')) {
        await signOut();
      }
    }
    return null;
  }

  // Validate stored token and refresh user
  Future<void> _validateAndRefreshUser() async {
    if (_currentToken == null) return;

    try {
      await refreshUser();
    } catch (e) {
      debugPrint('Token validation failed: $e');
      await _clearAuthData();
      _currentUser = null;
      _currentToken = null;
      _authStateController.add(null);
    }
  }

  // Load stored authentication data
  Future<void> _loadStoredAuth() async {
    try {
      final authData = await AuthStorage.loadAuthData();

      if (authData != null) {
        _currentToken = authData['token'] as String?;
        _currentUser = authData['user'] as ApiUserModel?;

        // Notify listeners if we have valid data
        if (_currentUser != null) {
          _authStateController.add(_currentUser);
        }
      }
    } catch (e) {
      debugPrint('Error loading stored auth: $e');
    }
  }

  // Clear authentication data
  Future<void> _clearAuthData() async {
    try {
      await AuthStorage.clearAuthData();
    } catch (e) {
      debugPrint('Error clearing auth data: $e');
    }
  }

  // Validation methods
  void _validateEmail(String email) {
    if (email.isEmpty) {
      throw const AuthException(
        message: 'Email cannot be empty.',
        code: 'empty-email',
      );
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email.trim())) {
      throw const AuthException(
        message: 'Please enter a valid email address.',
        code: 'invalid-email',
      );
    }
  }

  void _validatePassword(String password) {
    if (password.isEmpty) {
      throw const AuthException(
        message: 'Password cannot be empty.',
        code: 'empty-password',
      );
    }

    if (password.length < 6) {
      throw const AuthException(
        message: 'Password must be at least 6 characters long.',
        code: 'password-too-short',
      );
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    if (_currentUser != null && _currentToken != null) {
      return true;
    }

    // Check stored auth data
    return await AuthStorage.hasValidToken();
  }

  // Dispose
  void dispose() {
    _authStateController.close();
  }
}

// Enhanced AuthValidator for REST API
class AuthValidator {
  static String? validateUsernameOrEmail(String? val, bool isEmail) {
    if (val == null || val.trim().isEmpty) {
      return '${isEmail ? 'Email' : 'Username'} is required';
    }

    final value = val.trim();

    // Email regex
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    // Username regex (letters, numbers, underscores, 3-20 chars for example)
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

    if (!emailRegex.hasMatch(value) && !usernameRegex.hasMatch(value)) {
      return 'Enter a valid email or username';
    }

    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    return null;
  }

  static String? validateConfirmPassword(
    String? password,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  static String? validateName(String? name, String fieldName) {
    if (name == null || name.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (name.trim().length < 2) {
      return '$fieldName must be at least 2 characters long';
    }

    if (name.trim().length > 30) {
      return '$fieldName must be less than 30 characters';
    }

    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(name.trim())) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  static String? validatePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'Phone number is required';
    }

    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 10) {
      return 'Please enter a valid phone number with at least 10 digits';
    }

    if (digitsOnly.length > 15) {
      return 'Phone number is too long (maximum 15 digits)';
    }

    return null;
  }
}
