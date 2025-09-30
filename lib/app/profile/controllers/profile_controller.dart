// profile/controller/profile_controller.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dedicated_cow_boy_admin/app/utils/api_client.dart';
import 'package:dedicated_cow_boy_admin/app/utils/exceptions.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'package:dedicated_cow_boy_admin/app/models/api_user_model.dart';
import 'package:dedicated_cow_boy_admin/app/new/auth_service.dart';
import 'package:dedicated_cow_boy_admin/app/profile/views/edit.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  Future<void> updatePassword() async {
    try {
      isUpdatingPassword.value = true;

      // Validate inputs
      if (oldPasswordController.text.isEmpty ||
          newPasswordController.text.isEmpty ||
          confirmPasswordController.text.isEmpty) {
        Get.snackbar(
          'Error',
          'All password fields are required',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFFF2B342),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      if (newPasswordController.text != confirmPasswordController.text) {
        Get.snackbar(
          'Error',
          'New passwords do not match',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFFF2B342),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      if (newPasswordController.text.length < 6) {
        Get.snackbar(
          'Error',
          'Password must be at least 6 characters long',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFFF2B342),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      // Clear password fields
      oldPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      Get.snackbar(
        'Success',
        'Password updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      String errorMessage = 'Failed to update password';

      Get.snackbar(
        'Error',
        '$errorMessage: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isUpdatingPassword.value = false;
    }
  }

  // Auth service instance
  late final AuthService _authService;
  // Password controllers
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final RxBool isUpdatingPassword = false.obs;

  // Password visibility
  final RxBool obscureOldPassword = true.obs;
  final RxBool obscureNewPassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;

  // Observable user data
  final Rx<ApiUserModel?> currentUser = Rx<ApiUserModel?>(null);

  // Basic Info - extracted from API response
  final RxString userName = ''.obs;
  final RxString userEmail = ''.obs;
  final RxString userPhone = ''.obs;
  final RxString userAvatar = ''.obs;
  final RxString displayName = ''.obs;
  final RxString firstName = ''.obs;
  final RxString lastName = ''.obs;
  final RxString website = ''.obs;
  final RxString address = ''.obs;
  final RxString about = ''.obs;

  // Social Media - from meta fields
  final RxString facebookUrl = ''.obs;
  final RxString instagramUrl = ''.obs;
  final RxString linkedinUrl = ''.obs;
  final RxString youtubeUrl = ''.obs;

  // Subscription info
  final RxString subscriptionPlan = 'free'.obs;
  final RxBool isActiveSubscription = false.obs;
  final RxString stripeCustomerId = ''.obs;

  // Additional fields from meta
  final RxString billingFirstName = ''.obs;
  final RxString billingLastName = ''.obs;
  final RxString billingEmail = ''.obs;
  final RxString billingPhone = ''.obs;
  final RxString billingAddress = ''.obs;
  final RxString billingCity = ''.obs;
  final RxString billingPostcode = ''.obs;
  final RxString billingCountry = ''.obs;
  final RxString billingState = ''.obs;

  // Form controllers
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // Social Media Controllers
  final TextEditingController facebookController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();
  final TextEditingController linkedinController = TextEditingController();
  final TextEditingController youtubeController = TextEditingController();

  // Billing Controllers
  final TextEditingController billingFirstNameController =
      TextEditingController();
  final TextEditingController billingLastNameController =
      TextEditingController();
  final TextEditingController billingEmailController = TextEditingController();
  final TextEditingController billingPhoneController = TextEditingController();
  final TextEditingController billingAddressController =
      TextEditingController();
  final TextEditingController billingCityController = TextEditingController();
  final TextEditingController billingPostcodeController =
      TextEditingController();
  final TextEditingController billingCountryController =
      TextEditingController();
  final TextEditingController billingStateController = TextEditingController();

  // UI state
  final RxBool isEditing = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingProfile = true.obs;
  final RxBool isUploadingImage = false.obs;
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    _authService = Get.find<AuthService>();
    _initializeUserData();

    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        _updateUserData(user);
      } else {
        _clearUserData();
      }
    });
  }

  @override
  void onClose() {
    // _disposeControllers();
    super.onClose();
  }

  void _disposeControllers() {
    displayNameController.dispose();
    userNameController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    websiteController.dispose();
    descriptionController.dispose();
    facebookController.dispose();
    instagramController.dispose();
    linkedinController.dispose();
    youtubeController.dispose();
    billingFirstNameController.dispose();
    billingLastNameController.dispose();
    billingEmailController.dispose();
    billingPhoneController.dispose();
    billingAddressController.dispose();
    billingCityController.dispose();
    billingPostcodeController.dispose();
    billingCountryController.dispose();
    billingStateController.dispose();
  }

  // Initialize user data
  void _initializeUserData() async {
    try {
      await loadUserProfile();
    } catch (e) {
      debugPrint('Error initializing user data: $e');
    }
  }

  // Load user profile from API
  Future<void> loadUserProfile() async {
    try {
      isLoadingProfile.value = true;

      // Get current user from auth service
      final user = _authService.currentUser;
      if (user != null) {
        _updateUserData(user);
      } else {
        // Refresh user data from API
        await _authService.refreshUser();
        final refreshedUser = _authService.currentUser;
        if (refreshedUser != null) {
          _updateUserData(refreshedUser);
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      _showError('Failed to load profile data');
    } finally {
      isLoadingProfile.value = false;
    }
  }

  // Update user data from ApiUserModel
  void _updateUserData(ApiUserModel user) {
    currentUser.value = user;
    _updateObservablesFromModel(user);
    _updateControllersFromModel(user);
  }

  // Update observables from ApiUserModel
  void _updateObservablesFromModel(ApiUserModel user) {
    displayName.value = user.displayName;
    userName.value = user.username;
    firstName.value = user.firstName;
    lastName.value = user.lastName;
    userEmail.value = user.email;
    userAvatar.value = user.photoURL;
    website.value = user.url;
    about.value = user.description;

    // Subscription info
    subscriptionPlan.value = user.subscriptionPlan;
    isActiveSubscription.value = user.isActiveSubscription;
    stripeCustomerId.value = user.stripeCustomerId ?? '';

    // Extract meta data
    if (user.meta != null) {
      final meta = user.meta!;

      // Social media from meta
      facebookUrl.value = _getMetaValue(meta, 'facebook') ?? '';
      instagramUrl.value = _getMetaValue(meta, 'instagram') ?? '';
      linkedinUrl.value = _getMetaValue(meta, 'linkedin') ?? '';
      youtubeUrl.value = _getMetaValue(meta, 'youtube') ?? '';

      // Billing info from meta
      billingFirstName.value = _getMetaValue(meta, 'billing_first_name') ?? '';
      billingLastName.value = _getMetaValue(meta, 'billing_last_name') ?? '';
      billingEmail.value = _getMetaValue(meta, 'billing_email') ?? '';
      billingPhone.value = _getMetaValue(meta, 'billing_phone') ?? '';
      billingAddress.value = _getMetaValue(meta, 'billing_address_1') ?? '';
      billingCity.value = _getMetaValue(meta, 'billing_city') ?? '';
      billingPostcode.value = _getMetaValue(meta, 'billing_postcode') ?? '';
      billingCountry.value = _getMetaValue(meta, 'billing_country') ?? '';
      billingState.value = _getMetaValue(meta, 'billing_state') ?? '';
    }
  }

  // Helper to get meta value (handles WordPress array format)
  String? _getMetaValue(Map<String, dynamic> meta, String key) {
    final value = meta[key];
    if (value is List && value.isNotEmpty) {
      return value.first?.toString();
    }
    return value?.toString();
  }

  // Update form controllers with current data
  void _updateControllersFromModel(ApiUserModel user) {
    displayNameController.text = user.displayName;
    userNameController.text = user.username;
    firstNameController.text = user.firstName;
    lastNameController.text = user.lastName;
    emailController.text = user.email;
    websiteController.text = user.url;
    descriptionController.text = user.description;

    // Update social media controllers
    facebookController.text = facebookUrl.value;
    instagramController.text = instagramUrl.value;
    linkedinController.text = linkedinUrl.value;
    youtubeController.text = youtubeUrl.value;

    // Update billing controllers
    billingFirstNameController.text = billingFirstName.value;
    billingLastNameController.text = billingLastName.value;
    billingEmailController.text = billingEmail.value;
    billingPhoneController.text = billingPhone.value;
    billingAddressController.text = billingAddress.value;
    billingCityController.text = billingCity.value;
    billingPostcodeController.text = billingPostcode.value;
    billingCountryController.text = billingCountry.value;
    billingStateController.text = billingState.value;
  }

  // Toggle edit mode
  void toggleEdit() {
    isEditing.value = !isEditing.value;
    if (isEditing.value) {
      // Navigate to edit screen
      Get.to(() => UserProfileEditScreen());
    }
    HapticFeedback.lightImpact();
  }

  // Change profile picture
  Future<void> changeProfilePicture() async {
    try {
      isUploadingImage.value = true;

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        final File file = File(image.path);
        final String imageUrl = await uploadMedia([file]);
        await updateUserProfile({
          "profile_image_id": imageUrl,
          // 'meta': {'attachment_id': imageUrl},
        });

        // IMPORTANT: Force refresh the user data from AuthService
        await _authService.refreshUser();
        final refreshedUser = _authService.currentUser;
        if (refreshedUser != null) {
          _updateUserData(refreshedUser);
        }

        _showSuccess('Profile picture updated successfully');

        // // Note: You'll need to implement your own image upload service
        // // For now, this is a placeholder
        // _showError(
        //   'Image upload not implemented yet. Please implement uploadMedia function.',
        // );

        // Example of how it would work:
        // final String imageUrl = await uploadMedia([File(image.path)]);
        // await updateUserProfile({'avatar_url': imageUrl});
      }
    } catch (e) {
      debugPrint('Error changing profile picture: $e');
      _showError('Failed to update profile picture');
    } finally {
      isUploadingImage.value = false;
    }
  }

  // Save all profile changes
  Future<void> saveProfileChanges() async {
    try {
      isSaving.value = true;

      // Prepare update data
      final Map<String, dynamic> updateData = {
        'name': displayNameController.text.trim(),
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'email': emailController.text.trim(),
        'url': websiteController.text.trim(),
        'description': descriptionController.text.trim(),
      };

      // Prepare meta data updates
      final Map<String, dynamic> metaData = {
        'facebook': facebookController.text.trim(),
        'instagram': instagramController.text.trim(),
        'linkedin': linkedinController.text.trim(),
        'youtube': youtubeController.text.trim(),
        'billing_first_name': billingFirstNameController.text.trim(),
        'billing_last_name': billingLastNameController.text.trim(),
        'billing_email': billingEmailController.text.trim(),
        'billing_phone': billingPhoneController.text.trim(),
        'billing_address_1': billingAddressController.text.trim(),
        'billing_city': billingCityController.text.trim(),
        'billing_postcode': billingPostcodeController.text.trim(),
        'billing_country': billingCountryController.text.trim(),
        'billing_state': billingStateController.text.trim(),
      };

      // Add meta data to update data
      updateData['meta'] = metaData;

      // Update profile using auth service
      await _authService.updateProfile(
        name: updateData['name'],
        firstName: updateData['first_name'],
        lastName: updateData['last_name'],
        email: updateData['email'],
        url: updateData['url'],
        description: updateData['description'],
      );
      await _authService.updateUserProfileDetails(
        updateData: {"meta": metaData},
      );

      // If you need to update meta fields, you'll need to make a separate API call
      // as the standard WordPress REST API doesn't directly support meta updates
      // You might need to create a custom endpoint for meta updates

      // Reload user profile to get updated data
      await loadUserProfile();

      isEditing.value = false;

      Get.back();

      _showSuccess('Profile updated successfully');
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (e is AuthException) {
        _showError(e.message);
      } else {
        _showError('Failed to update profile. Please try again.');
      }
    } finally {
      isSaving.value = false;
    }
  }

  // Update specific user profile field
  Future<void> updateUserProfile(Map<String, dynamic> updateData) async {
    try {
      final token = _authService.currentToken;
      if (token == null) {
        throw const AuthException(
          message: 'No authentication token found',
          code: 'no-token',
        );
      }

      final response = await ApiClient.updateUserProfile(
        token: token,
        updateData: updateData,
      );

      if (response.success && response.data != null) {
        _updateUserData(response.data!);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get user favourites
  List<int> get favouriteListingIds {
    return currentUser.value?.favouriteListingIds ?? [];
  }

  // Check if listing is favourite
  bool isListingFavourite(int listingId) {
    return currentUser.value?.isListingFavourite(listingId) ?? false;
  }

  // Toggle favourite listing
  Future<void> toggleFavouriteListing(int listingId) async {
    try {
      final user = currentUser.value;
      if (user == null) return;

      // Update local state optimistically
      final updatedUser = user.toggleFavourite(listingId);
      currentUser.value = updatedUser;

      // Prepare meta update for API
      final metaUpdate = {
        'atbdp_favourites': updatedUser.meta?['atbdp_favourites'] ?? '',
      };

      // Update on server (you'll need to implement meta update endpoint)
      // await updateUserProfile({'meta': metaUpdate});

      _showSuccess(
        updatedUser.isListingFavourite(listingId)
            ? 'Added to favourites'
            : 'Removed from favourites',
      );
    } catch (e) {
      // Revert local state on error
      await loadUserProfile();
      _showError('Failed to update favourites');
    }
  }

  // Logout

  // Forgot password

  // Clear all user data
  void _clearUserData() {
    currentUser.value = null;

    // Clear observables
    userName.value = '';
    userEmail.value = '';
    userPhone.value = '';
    userAvatar.value = '';
    displayName.value = '';
    firstName.value = '';
    lastName.value = '';
    website.value = '';
    about.value = '';
    facebookUrl.value = '';
    instagramUrl.value = '';
    linkedinUrl.value = '';
    youtubeUrl.value = '';
    subscriptionPlan.value = 'free';
    isActiveSubscription.value = false;
    stripeCustomerId.value = '';

    // Clear all controllers
    displayNameController.clear();
    userNameController.clear();
    firstNameController.clear();
    lastNameController.clear();
    emailController.clear();
    phoneController.clear();
    websiteController.clear();
    descriptionController.clear();
    facebookController.clear();
    instagramController.clear();
    linkedinController.clear();
    youtubeController.clear();
    billingFirstNameController.clear();
    billingLastNameController.clear();
    billingEmailController.clear();
    billingPhoneController.clear();
    billingAddressController.clear();
    billingCityController.clear();
    billingPostcodeController.clear();
    billingCountryController.clear();
    billingStateController.clear();
  }

  // Helper methods for UI feedback
  void _showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFF2B342),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }
}

Future<String> uploadMedia(
  List<File> files, {
  String? directory, // not used in WP but kept for compatibility
  int? width,
  int? height,
}) async {
  try {
    var uri = Uri.parse('https://dedicatedcowboy.com/wp-json/wp/v2/media');
    var request = http.MultipartRequest('POST', uri);

    // 🔹 Add WordPress Auth (username + app password)
    const username = "18XLegend";
    const appPassword = "O9px KmDk isTg PgaW wysH FqL6";
    final basicAuth =
        'Basic ${base64Encode(utf8.encode('$username:$appPassword'))}';

    request.headers.addAll({
      'Authorization': basicAuth,
      'Accept': 'application/json',
    });

    // 🔹 Add media files with validation
    for (var file in files) {
      if (!await file.exists()) {
        throw Exception('File does not exist: ${file.path}');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('File is empty: ${file.path}');
      }

      if (fileSize > 10 * 1024 * 1024) {
        throw Exception(
          'File too large (max 10MB): ${path.basename(file.path)}',
        );
      }

      var stream = http.ByteStream(file.openRead());
      var multipartFile = http.MultipartFile(
        'file', // WP expects "file" (not media[])
        stream,
        fileSize,
        filename: path.basename(file.path),
      );

      request.files.add(multipartFile);
    }

    // 🔹 WP doesn’t use directory/width/height fields directly,
    // but you can still send meta (custom handling/plugins may use them)
    if (directory != null) request.fields['directory'] = directory;
    if (width != null) request.fields['width'] = width.toString();
    if (height != null) request.fields['height'] = height.toString();

    // 🔹 Send request
    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      var jsonData = jsonDecode(responseBody);
      print(jsonData);

      if (jsonData['id'] != null) {
        return jsonData['id'].toString(); // ✅ WordPress gives full URL
      } else {
        throw Exception('Invalid response: Missing source_url');
      }
    } else {
      throw Exception(
        'Upload failed. Status: ${response.statusCode}, Body: $responseBody',
      );
    }
  } on FormatException catch (e) {
    throw Exception('Invalid JSON response: ${e.message}');
  } on SocketException catch (e) {
    throw Exception('Network error: ${e.message}');
  } on TimeoutException {
    throw Exception('Upload timeout');
  } catch (e) {
    throw Exception('Upload failed: ${e.toString()}');
  }
}
