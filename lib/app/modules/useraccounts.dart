import 'dart:async';
import 'dart:convert';
import 'package:dedicated_cow_boy_admin/app/models/api_user_model.dart';
import 'package:dedicated_cow_boy_admin/app/modules/pro.dart';
import 'package:dedicated_cow_boy_admin/app/new/auth_service.dart';
import 'package:dedicated_cow_boy_admin/app/utils/api_client.dart';
import 'package:dedicated_cow_boy_admin/app/utils/exceptions.dart';
import 'package:dedicated_cow_boy_admin/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/instance_manager.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;

class UserAccountsScreen extends StatefulWidget {
  const UserAccountsScreen({super.key});

  @override
  State<UserAccountsScreen> createState() => _UserAccountsScreenState();
}

class _UserAccountsScreenState extends State<UserAccountsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  List<ApiUserModel> _users = [];
  List<ApiUserModel> _filteredUsers = [];
  bool _isLoading = true;
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  String _selectedUserType = 'All users';
  String _selectedStatus = 'All status';
  DateTime? _fromDate;
  DateTime? _toDate;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      // Get auth token from AuthService
      final authService = Get.find<AuthService>();
      final token = authService.currentToken;

      // Fetch users from WordPress API
      final response = await ApiClient.getAllUsers(
        token: token,
        perPage: 100, // Get more users per page
      );

      if (response.success && response.data != null) {
        _users = response.data!;
        _applyFilters();
      } else {
        Get.snackbar(
          'Error',
          'Failed to load users: ${response.message ?? 'Unknown error'}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Color(0xFFF2B342),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.error, color: Colors.white),
        );
      }
    } on AuthException catch (e) {
      Get.snackbar(
        'Authentication Error',
        'Authentication error: ${e.message}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error loading users: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    // Debounce the search to avoid too many API calls
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    final searchTerm = _searchController.text.trim();

    if (searchTerm.isEmpty) {
      // If search is empty, reload all users and apply filters
      await _loadUsers();
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get auth token from AuthService
      final authService = Get.find<AuthService>();
      final token = authService.currentToken;

      if (token == null) {
        Get.snackbar(
          'Error',
          'Authentication token not found',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Color(0xFFF2B342),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.error, color: Colors.white),
        );
        return;
      }

      // Search users via API
      final response = await ApiClient.searchUsers(
        token: token,
        searchTerm: searchTerm,
        perPage: 100,
      );

      if (response.success && response.data != null) {
        _users = response.data!;
        _applyFilters();
      } else {
        Get.snackbar(
          'Error',
          'Failed to search users: ${response.message ?? 'Unknown error'}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Color(0xFFF2B342),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.error, color: Colors.white),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error searching users: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<ApiUserModel> filtered =
        _users.where((user) {
          // Note: Search is now handled by API, so we skip local search filtering

          // User type filter - based on roles
          if (_selectedUserType != 'All users') {
            if (_selectedUserType == 'Seller') {
              // Check if user has seller-related roles or capabilities
              if (!user.roles.contains('seller') &&
                  !user.roles.contains('subscriber') &&
                  !user.hasCapability('edit_posts')) {
                return false;
              }
            } else if (_selectedUserType == 'Buyer') {
              // Check if user is a regular buyer (no special roles)
              if (user.roles.contains('seller') ||
                  user.roles.contains('administrator') ||
                  user.roles.contains('editor')) {
                return false;
              }
            }
          }

          // Status filter - based on email verification or other status
          if (_selectedStatus != 'All status') {
            final isActive = user.isEmailVerified;
            final status = isActive ? 'Active' : 'Inactive';
            if (status != _selectedStatus) return false;
          }

          // Date range filter
          if (_fromDate != null && user.registeredDate.isBefore(_fromDate!)) {
            return false;
          }
          if (_toDate != null &&
              user.registeredDate.isAfter(
                _toDate!.add(const Duration(days: 1)),
              )) {
            return false;
          }

          return true;
        }).toList();

    setState(() {
      _filteredUsers = filtered;
      _currentPage = 1;
    });
  }

  List<ApiUserModel> _getPaginatedUsers() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= _filteredUsers.length) return [];

    return _filteredUsers.sublist(
      startIndex,
      endIndex > _filteredUsers.length ? _filteredUsers.length : endIndex,
    );
  }

  int get _totalPages => (_filteredUsers.length / _itemsPerPage).ceil();

  Future<void> _selectDate(bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          _fromDateController.text = DateFormat('MM/dd/yyyy').format(picked);
        } else {
          _toDate = picked;
          _toDateController.text = DateFormat('MM/dd/yyyy').format(picked);
        }
      });
      _applyFilters();
    }
  }

  void _clearDates() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _fromDateController.clear();
      _toDateController.clear();
    });
    _applyFilters();
  }

  Future<void> _deleteUser(ApiUserModel user) async {
    final confirmed = await _showConfirmDialog(
      'Delete User',
      'Are you sure you want to delete ${user.name}?',
      user: user,
    );

    if (confirmed) {
      try {
        setState(() => _isLoading = true);

        final success = await DeleteUser(int.parse(user.id));

        if (success) {
          // Remove user from local list and refresh
          setState(() {
            _users.removeWhere((u) => u.id == user.id);
            _applyFilters();
          });

          // Show success message
          Get.snackbar(
            'Success',
            'User ${user.name} deleted successfully',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Color(0xFFF2B342),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
            icon: const Icon(Icons.check_circle, color: Colors.white),
          );
        } else {
          Get.snackbar(
            'Error',
            'Failed to delete user. Please try again.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Color(0xFFF2B342),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
            icon: const Icon(Icons.error, color: Colors.white),
          );
        }
      } catch (e) {
        Get.snackbar(
          'Error',
          'Error deleting user: $e',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Color(0xFFF2B342),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.error, color: Colors.white),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _editUser(ApiUserModel user) {
    _showUserDialog(user: user);
  }

  void _createUser() {
    _showUserDialog();
  }

  void _showUserDialog({ApiUserModel? user}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => UserFormDialog(
            user: user,
            onSave: (userData) async {
              try {
                if (user != null) {
                  // Show loading state
                  setState(() => _isLoading = true);

                  // Update existing user
                  final success = await UpdateUser(user.id, userData);

                  if (success) {
                    // Refresh the user list
                    await _loadUsers();
                    Get.snackbar(
                      'Success',
                      'User ${user.name} updated successfully',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: Color(0xFFF2B342),
                      colorText: Colors.white,
                      duration: const Duration(seconds: 3),
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                    );
                  } else {
                    Get.snackbar(
                      'Error',
                      'Failed to update user. Please try again.',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: Color(0xFFF2B342),
                      colorText: Colors.white,
                      duration: const Duration(seconds: 3),
                      icon: const Icon(Icons.error, color: Colors.white),
                    );
                  }
                } else {
                  // Create new user using sign-up API
                  setState(() => _isLoading = true);

                  try {
                    // Create user directly via WordPress API without switching auth context
                    final success = await _createUserDirectly(userData);

                    if (success) {
                      // Refresh the user list
                      await _loadUsers();
                      Get.snackbar(
                        'Success',
                        'User created successfully',
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Color(0xFFF2B342),
                        colorText: Colors.white,
                        duration: const Duration(seconds: 3),
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                        ),
                      );
                    } else {
                      Get.snackbar(
                        'Error',
                        'Failed to create user. Please try again.',
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Color(0xFFF2B342),
                        colorText: Colors.white,
                        duration: const Duration(seconds: 3),
                        icon: const Icon(Icons.error, color: Colors.white),
                      );
                    }
                  } catch (e) {
                    Get.snackbar(
                      'Error',
                      'Failed to create user: $e',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: Color(0xFFF2B342),
                      colorText: Colors.white,
                      duration: const Duration(seconds: 3),
                      icon: const Icon(Icons.error, color: Colors.white),
                    );
                  } finally {
                    setState(() => _isLoading = false);
                  }
                }
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Error saving user: $e',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Color(0xFFF2B342),
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                  icon: const Icon(Icons.error, color: Colors.white),
                );
              } finally {
                // Hide loading state
                setState(() => _isLoading = false);
              }
            },
          ),
    );
  }

  Future<bool> DeleteUser(int userid) async {
    // First, try to delete with reassignment to admin user (ID: 1)
    var uri = Uri.parse(
      "https://dedicatedcowboy.com/wp-json/wp/v2/users/$userid?force=true&reassign=1",
    );
    var request = http.Request('DELETE', uri);

    try {
      // 🔹 Add WordPress Auth (username + app password)
      const username = "18XLegend";
      const appPassword = "O9px KmDk isTg PgaW wysH FqL6";
      final basicAuth =
          'Basic ${base64Encode(utf8.encode('$username:$appPassword'))}';

      request.headers.addAll({
        'Authorization': basicAuth,
        'Accept': 'application/json',
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("User deleted successfully");
        return true;
      } else {
        print("Failed to delete user. Status: ${response.statusCode}");
        print("Response body: ${response.body}");

        // If reassignment fails, try without reassignment (delete posts)
        if (response.statusCode == 400) {
          print("Trying to delete user without reassignment...");
          return await _deleteUserWithoutReassignment(userid);
        }

        return false;
      }
    } catch (e) {
      print("Error deleting user: $e");
      return false;
    }
  }

  Future<bool> _deleteUserWithoutReassignment(int userid) async {
    var uri = Uri.parse(
      "https://dedicatedcowboy.com/wp-json/wp/v2/users/$userid?force=true&reassign=0",
    );
    var request = http.Request('DELETE', uri);

    try {
      const username = "18XLegend";
      const appPassword = "O9px KmDk isTg PgaW wysH FqL6";
      final basicAuth =
          'Basic ${base64Encode(utf8.encode('$username:$appPassword'))}';

      request.headers.addAll({
        'Authorization': basicAuth,
        'Accept': 'application/json',
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("User deleted successfully (posts deleted)");
        return true;
      } else {
        print(
          "Failed to delete user without reassignment. Status: ${response.statusCode}",
        );
        print("Response body: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error deleting user without reassignment: $e");
      return false;
    }
  }

  Future<bool> UpdateUser(String userid, Map<String, dynamic> userData) async {
    try {
      // First, update the basic user data
      final basicUpdateSuccess = await _updateBasicUserData(userid, userData);

      // Then, update the meta fields separately
      final metaUpdateSuccess = await _updateUserMetaFields(userid, userData);

      return basicUpdateSuccess && metaUpdateSuccess;
    } catch (e) {
      print("Error updating user: $e");
      return false;
    }
  }

  Future<bool> _updateBasicUserData(
    String userid,
    Map<String, dynamic> userData,
  ) async {
    var uri = Uri.parse(
      "https://dedicatedcowboy.com/wp-json/wp/v2/users/$userid",
    );
    var request = http.Request('POST', uri);

    try {
      // 🔹 Add WordPress Auth (username + app password)
      const username = "18XLegend";
      const appPassword = "O9px KmDk isTg PgaW wysH FqL6";
      final basicAuth =
          'Basic ${base64Encode(utf8.encode('$username:$appPassword'))}';

      request.headers.addAll({
        'Authorization': basicAuth,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      });

      // Prepare the basic user data for WordPress API
      final Map<String, dynamic> wpUserData = {
        'first_name': userData['firstName'] ?? '',
        'last_name': userData['lastName'] ?? '',
        'email': userData['email'] ?? '',
        'description': userData['about'] ?? '',
        'url': userData['website'] ?? '',
      };

      // Add password if provided
      if (userData['password'] != null &&
          userData['password'].toString().isNotEmpty) {
        wpUserData['password'] = userData['password'];
      }

      // Convert to JSON and set as request body
      request.body = jsonEncode(wpUserData);

      // Debug: Print the data being sent
      print("=== UPDATE BASIC USER DATA ===");
      print("Original userData: ${jsonEncode(userData)}");
      print("WordPress API data: ${jsonEncode(wpUserData)}");
      print("==============================");

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Basic user data updated successfully");
        return true;
      } else {
        print(
          "Failed to update basic user data. Status: ${response.statusCode}",
        );
        print("Response body: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error updating basic user data: $e");
      return false;
    }
  }

  Future<bool> _updateUserMetaFields(
    String userid,
    Map<String, dynamic> userData,
  ) async {
    // Try multiple approaches for updating meta fields
    final metaFields = {
      'phone': userData['phone'] ?? '',
      'address': userData['address'] ?? '',
      'business_name': userData['businessName'] ?? '',
      'business_address': userData['businessAddress'] ?? '',
      'professional_status': userData['professionalStatus'] ?? '',
      'industry': userData['industry'] ?? '',
      'is_online': userData['isOnline'] ?? false,
      'user_status': userData['isOnline'] == true ? 'active' : 'inactive',
      'is_active': userData['isOnline'] ?? false,
      'directorist_user_email_unverified':
          userData['isOnline'] == true ? null : '1',
      // Alternative field names for WordPress compatibility
      'user_phone': userData['phone'] ?? '',
      'user_address': userData['address'] ?? '',
      'company_name': userData['businessName'] ?? '',
      'company_address': userData['businessAddress'] ?? '',
      'user_professional_status': userData['professionalStatus'] ?? '',
      'user_industry': userData['industry'] ?? '',
    };

    // Try updating each meta field individually
    bool allSuccess = true;
    for (final entry in metaFields.entries) {
      if (entry.value != null && entry.value.toString().isNotEmpty) {
        final success = await _updateSingleMetaField(
          userid,
          entry.key,
          entry.value,
        );
        if (!success) {
          allSuccess = false;
          print("Failed to update meta field: ${entry.key}");
        }
      }
    }

    return allSuccess;
  }

  Future<bool> _updateSingleMetaField(
    String userid,
    String metaKey,
    dynamic metaValue,
  ) async {
    try {
      var uri = Uri.parse(
        "https://dedicatedcowboy.com/wp-json/wp/v2/users/$userid",
      );
      var request = http.Request('POST', uri);

      const username = "18XLegend";
      const appPassword = "O9px KmDk isTg PgaW wysH FqL6";
      final basicAuth =
          'Basic ${base64Encode(utf8.encode('$username:$appPassword'))}';

      request.headers.addAll({
        'Authorization': basicAuth,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      });

      // Try different approaches for meta field updates
      final Map<String, dynamic> metaData = {
        'meta': {metaKey: metaValue},
      };

      request.body = jsonEncode(metaData);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Meta field $metaKey updated successfully");
        return true;
      } else {
        print(
          "Failed to update meta field $metaKey. Status: ${response.statusCode}",
        );
        return false;
      }
    } catch (e) {
      print("Error updating meta field $metaKey: $e");
      return false;
    }
  }

  Future<bool> _createUserDirectly(Map<String, dynamic> userData) async {
    try {
      var uri = Uri.parse("https://dedicatedcowboy.com/wp-json/wp/v2/users");
      var request = http.Request('POST', uri);

      const username = "18XLegend";
      const appPassword = "O9px KmDk isTg PgaW wysH FqL6";
      final basicAuth =
          'Basic ${base64Encode(utf8.encode('$username:$appPassword'))}';

      request.headers.addAll({
        'Authorization': basicAuth,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      });

      // Prepare user data for WordPress API
      final Map<String, dynamic> wpUserData = {
        'username': userData['userName'] ?? userData['email'].split('@')[0],
        'email': userData['email'],
        'password': userData['password'],
        'first_name': userData['firstName'] ?? '',
        'last_name': userData['lastName'] ?? '',
        'description': userData['about'] ?? '',
        'url': userData['website'] ?? '',
        'roles': ['subscriber'], // Default role
      };

      // Add meta fields
      final Map<String, dynamic> metaFields = {
        'phone': userData['phone'] ?? '',
        'address': userData['address'] ?? '',
        'business_name': userData['businessName'] ?? '',
        'business_address': userData['businessAddress'] ?? '',
        'professional_status': userData['professionalStatus'] ?? '',
        'industry': userData['industry'] ?? '',
        'is_online': userData['isOnline'] ?? false,
        'user_status': userData['isOnline'] == true ? 'active' : 'inactive',
        'is_active': userData['isOnline'] ?? false,
        'directorist_user_email_unverified':
            userData['isOnline'] == true ? null : '1',
        'facebook_page_id': userData['facebookPageId'] ?? '',
      };

      wpUserData['meta'] = metaFields;

      request.body = jsonEncode(wpUserData);

      // Debug: Print the data being sent
      print("=== CREATE USER DATA ===");
      print("WordPress API data: ${jsonEncode(wpUserData)}");
      print("========================");

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("User created successfully");
        return true;
      } else {
        print("Failed to create user. Status: ${response.statusCode}");
        print("Response body: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error creating user: $e");
      return false;
    }
  }

  Future<bool> _showConfirmDialog(
    String title,
    String message, {
    ApiUserModel? user,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFF2B342),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFF2B342).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Color(0xFFF2B342).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFFF2B342),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This action cannot be undone.',
                              style: TextStyle(
                                color: Color(0xFFF2B342),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFF2B342),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet =
                constraints.maxWidth > 768 && constraints.maxWidth <= 1024;
            final isMobile = constraints.maxWidth <= 768;

            return Container(
              margin: EdgeInsets.all(isMobile ? 8 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const ProfileTopBar(),
                    Padding(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      child: Column(
                        children: [
                          _buildHeader(isMobile),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Color(0xffD9D9D9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                _buildSearchField(),
                                const SizedBox(height: 16),
                                _buildFilters(isMobile, isTablet),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _isLoading
                              ? _buildShimmerTable()
                              : _buildUserTable(isMobile, isTablet),
                          const SizedBox(height: 16),
                          _buildActionButtons(isMobile),
                          const SizedBox(height: 16),
                          _buildPagination(isMobile),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _loadUsers,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(isMobile ? 'Refresh' : 'Refresh Data'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFF2B342),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(bool isMobile) {
    if (_totalPages <= 1) return const SizedBox();

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        // Previous button
        if (_currentPage > 1)
          _pageButton(
            isMobile ? "‹" : "Previous",
            onTap: () {
              setState(() => _currentPage--);
            },
          ),

        // Page numbers
        ...List.generate(_totalPages, (index) {
          final pageNum = index + 1;
          if (_totalPages > 7) {
            if (pageNum <= 2 ||
                pageNum >= _totalPages - 1 ||
                (pageNum >= _currentPage - 1 && pageNum <= _currentPage + 1)) {
              return _pageButton(
                pageNum.toString(),
                selected: pageNum == _currentPage,
                onTap: () => setState(() => _currentPage = pageNum),
              );
            } else if (pageNum == 3 && _currentPage > 4) {
              return _pageButton("...");
            } else if (pageNum == _totalPages - 2 &&
                _currentPage < _totalPages - 3) {
              return _pageButton("...");
            }
          } else {
            return _pageButton(
              pageNum.toString(),
              selected: pageNum == _currentPage,
              onTap: () => setState(() => _currentPage = pageNum),
            );
          }
          return const SizedBox();
        }),

        // Next button
        if (_currentPage < _totalPages)
          _pageButton(
            isMobile ? "›" : "Next",
            onTap: () {
              setState(() => _currentPage++);
            },
          ),
      ],
    );
  }

  /// Reusable page button widget
  Widget _pageButton(
    String text, {
    bool selected = false,
    VoidCallback? onTap,
  }) {
    final isEllipsis = text == "...";

    return GestureDetector(
      onTap: isEllipsis ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey.shade400,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: selected ? Colors.white : Colors.black,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "User Management",
          style: TextStyle(
            fontSize: isMobile ? 20 : 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _createUser,
          icon: const Icon(Icons.add, size: 20),
          label: Text(isMobile ? 'Add' : 'Create User'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xff364C63),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 20,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search, color: Color(0xFF64748B)),
          hintText: "Search users by name, email, or phone...",
          hintStyle: TextStyle(color: Color(0xFF64748B)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilters(bool isMobile, bool isTablet) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  value: _selectedUserType,
                  items: ['All users', 'Seller', 'Buyer'],
                  onChanged: (value) {
                    setState(() => _selectedUserType = value!);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  value: _selectedStatus,
                  items: ['All status', 'Active', 'Inactive'],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value!);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateField("From Date", _fromDateController, true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField("To Date", _toDateController, false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _clearDates,
              icon: const Icon(Icons.clear, size: 18),
              label: const Text("Clear Dates"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF2B342),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          _buildDropdown(
            value: _selectedUserType,
            items: ['All users', 'Seller', 'Buyer'],
            onChanged: (value) {
              setState(() => _selectedUserType = value!);
              _applyFilters();
            },
          ),
          _buildDropdown(
            value: _selectedStatus,
            items: ['All status', 'Active', 'Inactive'],
            onChanged: (value) {
              setState(() => _selectedStatus = value!);
              _applyFilters();
            },
          ),
          _buildDateField("From Date", _fromDateController, true),
          _buildDateField("To Date", _toDateController, false),
          ElevatedButton.icon(
            onPressed: _clearDates,
            icon: const Icon(Icons.clear, size: 18),
            label: const Text("Clear Dates"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFF2B342),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<String>(
        dropdownColor: Color(0xFFF2B342),
        value: value,
        underline: const SizedBox(),
        isExpanded: true,
        onChanged: onChanged,
        items:
            items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
      ),
    );
  }

  Widget _buildDateField(
    String hint,
    TextEditingController controller,
    bool isFromDate,
  ) {
    return SizedBox(
      width: 180,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: TextField(
          controller: controller,
          readOnly: true,
          onTap: () => _selectDate(isFromDate),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: const Icon(
              Icons.calendar_today,
              size: 18,
              color: Color(0xFF64748B),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTable(bool isMobile, bool isTablet) {
    final paginatedUsers = _getPaginatedUsers();

    if (paginatedUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (isMobile) {
      return _buildMobileUserList(paginatedUsers);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1000),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Color(0xff364C63)),
            headingRowHeight: 56,
            dataRowHeight: 72,
            columnSpacing: 24,
            headingTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            columns: const [
              DataColumn(
                label: SizedBox(width: 120, child: Text("Date & Time")),
              ),
              DataColumn(
                label: SizedBox(width: 200, child: Text("User Details")),
              ),
              DataColumn(
                label: SizedBox(width: 180, child: Text("Email / Phone No.")),
              ),
              DataColumn(label: SizedBox(width: 100, child: Text("Type"))),
              DataColumn(label: SizedBox(width: 100, child: Text("Status"))),
              DataColumn(label: SizedBox(width: 120, child: Text("Actions"))),
            ],
            rows: paginatedUsers.map((user) => _buildUserRow(user)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileUserList(List<ApiUserModel> users) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildMobileUserCard(user);
      },
    );
  }

  Widget _buildMobileUserCard(ApiUserModel user) {
    // Determine user type based on roles
    String userType = 'Buyer';
    if (user.roles.contains('seller') || user.roles.contains('subscriber')) {
      userType = 'Seller';
    } else if (user.roles.contains('administrator') ||
        user.roles.contains('editor')) {
      userType = 'Admin';
    }

    final typeColor =
        userType == "Seller"
            ? Color(0xff364C63)
            : userType == "Admin"
            ? Color(0xFFF2B342)
            : Color(0xFFF2B342);
    final isActive = user.isEmailVerified;
    final statusColor = isActive ? Color(0xFFF2B342) : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage:
                      user.photoURL.isNotEmpty
                          ? NetworkImage(user.photoURL)
                          : null,
                  child:
                      user.photoURL.isEmpty
                          ? Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                          : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name.isNotEmpty ? user.name : user.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (user.username.isNotEmpty)
                        Text(
                          '@${user.username}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editUser(user),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteUser(user),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    userType,
                    style: TextStyle(
                      color: typeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(color: statusColor, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(user.email, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM dd, yyyy - HH:mm').format(user.registeredDate),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildUserRow(ApiUserModel user) {
    // Determine user type based on roles
    String userType = 'Buyer';
    if (user.roles.contains('seller') || user.roles.contains('subscriber')) {
      userType = 'Seller';
    } else if (user.roles.contains('administrator') ||
        user.roles.contains('editor')) {
      userType = 'Admin';
    }

    final typeColor =
        userType == "Seller"
            ? Color(0xFF0E8F07)
            : userType == "Admin"
            ? Color(0xFFF2B342)
            : Color(0xFFF2B342);
    final isActive = user.isEmailVerified;
    final statusColor = isActive ? Color(0xFFF2B342) : Color(0xff364C63);

    return DataRow(
      cells: [
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMM dd, yyyy').format(user.registeredDate),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                DateFormat('HH:mm').format(user.registeredDate),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage:
                    user.photoURL.isNotEmpty
                        ? NetworkImage(user.photoURL)
                        : null,
                child:
                    user.photoURL.isEmpty
                        ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isNotEmpty ? user.name : user.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.username.isNotEmpty)
                      Text(
                        '@${user.username}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.email, style: const TextStyle(fontSize: 12)),
              Text(
                'ID: ${user.id}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        DataCell(
          userType == ''
              ? Container(child: Center(child: Text('---')))
              : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  userType,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
        ),
        DataCell(
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Colors.black,
                ),
                onPressed: () => _editUser(user),
                tooltip: 'Edit User',
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.black,
                ),
                onPressed: () => _deleteUser(user),
                tooltip: 'Delete User',
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerTable() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(height: 56, color: Colors.grey[300]),
            ListView.builder(
              shrinkWrap: true,
              itemCount: 5,
              itemBuilder:
                  (context, index) => Container(
                    height: 72,
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    color: Colors.white,
                    child: Row(
                      children: List.generate(
                        6,
                        (i) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            height: 20,
                            color: Colors.grey[300],
                          ),
                        ),
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserFormDialog extends StatefulWidget {
  final ApiUserModel? user;
  final Function(Map<String, dynamic>) onSave;

  const UserFormDialog({super.key, this.user, required this.onSave});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _userNameController = TextEditingController();
  final _aboutController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _facebookPageIdController = TextEditingController();

  String _selectedProfessionalStatus = 'Buyer';
  String _selectedIndustry = 'Technology';
  bool _isOnline = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _updatePassword = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _firstNameController.text = widget.user!.firstName;
      _lastNameController.text = widget.user!.lastName;
      _emailController.text = widget.user!.email;
      _userNameController.text = widget.user!.username;
      _aboutController.text = widget.user!.description;
      _websiteController.text = widget.user!.url;

      // Determine user type based on roles
      if (widget.user!.roles.contains('seller') ||
          widget.user!.roles.contains('subscriber')) {
        _selectedProfessionalStatus = 'Seller';
      } else {
        _selectedProfessionalStatus = 'Buyer';
      }

      _isOnline = widget.user!.isEmailVerified;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _userNameController.dispose();
    _aboutController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _facebookPageIdController.dispose();
    super.dispose();
  }

  void _saveUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        Map<String, dynamic> userData = {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'email': _emailController.text.trim().toLowerCase(),
          'phone': _phoneController.text.trim(),
          'userName': _userNameController.text.trim(),
          'about': _aboutController.text.trim(),
          'address': _addressController.text.trim(),
          'website': _websiteController.text.trim(),
          'businessName': _businessNameController.text.trim(),
          'businessAddress': _businessAddressController.text.trim(),
          'professionalStatus': _selectedProfessionalStatus,
          'industry': _selectedIndustry,
          'isOnline': _isOnline,
          'facebookPageId': _facebookPageIdController.text.trim(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        if (widget.user == null) {
          // Creating new user - password is required
          userData.addAll({
            'password': _passwordController.text.trim(),
            'createdAt': DateTime.now().toIso8601String(),
            'emailVerified': false,
            'deviceId': '',
          });
        } else if (_updatePassword) {
          // Updating existing user password
          userData['password'] = _passwordController.text.trim();
        }

        await widget.onSave(userData);
        Navigator.of(context).pop();
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          return Container(
            width: isMobile ? constraints.maxWidth * 0.95 : 700,
            height: constraints.maxHeight * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xff364C63),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isEditing ? Icons.edit : Icons.person_add,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit User' : 'Create New User',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Form Content
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Basic Information Section
                          _buildSectionTitle('Basic Information', Icons.person),
                          const SizedBox(height: 16),

                          if (isMobile) ...[
                            _buildTextField(
                              controller: _firstNameController,
                              label: 'First Name',
                              required: isEditing ? false : true,
                              prefixIcon: Icons.person_outline,
                              enabled: !_isSaving,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _lastNameController,
                              label: 'Last Name',
                              required: isEditing ? false : true,
                              prefixIcon: Icons.person_outline,
                              enabled: !_isSaving,
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _firstNameController,
                                    label: 'First Name',
                                    required: isEditing ? false : true,
                                    prefixIcon: Icons.person_outline,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _lastNameController,
                                    label: 'Last Name',
                                    required: isEditing ? false : true,
                                    prefixIcon: Icons.person_outline,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 16),
                          if (!isEditing)
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              required: true,
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              enabled: !_isSaving,
                            ),

                          const SizedBox(height: 16),
                          if (isMobile) ...[
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _userNameController,
                              label: 'Username',
                              prefixIcon: Icons.alternate_email,
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _phoneController,
                                    label: 'Phone Number',
                                    prefixIcon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _userNameController,
                                    label: 'Username',
                                    prefixIcon: Icons.alternate_email,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Password Section
                          _buildSectionTitle(
                            isEditing ? 'Password Settings' : 'Security',
                            Icons.security,
                          ),

                          if (isEditing) ...[
                            const SizedBox(height: 12),
                            CheckboxListTile(
                              title: const Text('Update Password'),
                              subtitle: const Text(
                                'Check this to change the user\'s password',
                              ),
                              value: _updatePassword,
                              onChanged: (value) {
                                setState(() {
                                  _updatePassword = value ?? false;
                                  if (!_updatePassword) {
                                    _passwordController.clear();
                                    _confirmPasswordController.clear();
                                  }
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],

                          if (!isEditing || _updatePassword) ...[
                            const SizedBox(height: 16),
                            _buildPasswordField(
                              controller: _passwordController,
                              label: 'Password',
                              required: !isEditing,
                              showPassword: _showPassword,
                              onToggleVisibility:
                                  _isSaving
                                      ? null
                                      : () {
                                        setState(
                                          () => _showPassword = !_showPassword,
                                        );
                                      },
                            ),
                            const SizedBox(height: 16),
                            _buildPasswordField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              required: !isEditing,
                              showPassword: _showConfirmPassword,
                              onToggleVisibility:
                                  _isSaving
                                      ? null
                                      : () {
                                        setState(
                                          () =>
                                              _showConfirmPassword =
                                                  !_showConfirmPassword,
                                        );
                                      },
                              validator: (value) {
                                if ((!isEditing || _updatePassword) &&
                                    (value?.isEmpty ?? true)) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                          ],

                          // Facebook Page ID field for new users
                          if (!isEditing) ...[
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _facebookPageIdController,
                              label: 'Facebook Page ID (Optional)',
                              prefixIcon: Icons.facebook,
                              enabled: !_isSaving,
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Professional Information Section
                          _buildSectionTitle(
                            'Professional Information',
                            Icons.work,
                          ),
                          const SizedBox(height: 16),

                          // if (isMobile) ...[
                          //   _buildDropdownField(
                          //     value: _selectedProfessionalStatus,
                          //     label: 'User Type',
                          //     items: ['Buyer', 'Seller'],
                          //     onChanged: (value) {
                          //       setState(
                          //         () => _selectedProfessionalStatus = value!,
                          //       );
                          //     },
                          //   ),
                          //   const SizedBox(height: 16),
                          //   _buildDropdownField(
                          //     value: _selectedIndustry,
                          //     label: 'Industry',
                          //     items: [
                          //       'Technology',
                          //       'Healthcare',
                          //       'Finance',
                          //       'Education',
                          //       'Retail',
                          //       'Manufacturing',
                          //       'Agriculture',
                          //       'Construction',
                          //       'Transportation',
                          //       'Other',
                          //     ],
                          //     onChanged: (value) {
                          //       setState(() => _selectedIndustry = value!);
                          //     },
                          //   ),
                          // ] else ...[
                          //   Row(
                          //     children: [
                          //       Expanded(
                          //         child: _buildDropdownField(
                          //           value: _selectedProfessionalStatus,
                          //           label: 'User Type',
                          //           items: ['Buyer', 'Seller'],
                          //           onChanged: (value) {
                          //             setState(
                          //               () => _selectedProfessionalStatus =
                          //                   value!,
                          //             );
                          //           },
                          //         ),
                          //       ),
                          //       const SizedBox(width: 16),
                          //       Expanded(
                          //         child: _buildDropdownField(
                          //           value: _selectedIndustry,
                          //           label: 'Industry',
                          //           items: [
                          //             'Technology',
                          //             'Healthcare',
                          //             'Finance',
                          //             'Education',
                          //             'Retail',
                          //             'Manufacturing',
                          //             'Agriculture',
                          //             'Construction',
                          //             'Transportation',
                          //             'Other',
                          //           ],
                          //           onChanged: (value) {
                          //             setState(
                          //               () => _selectedIndustry = value!,
                          //             );
                          //           },
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // ],
                          if (_selectedProfessionalStatus == 'Seller') ...[
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _businessNameController,
                              label: 'Business Name',
                              prefixIcon: Icons.business,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _businessAddressController,
                              label: 'Business Address',
                              prefixIcon: Icons.location_on_outlined,
                              maxLines: 2,
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Additional Information Section
                          _buildSectionTitle(
                            'Additional Information',
                            Icons.info_outline,
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _addressController,
                            label: 'Address',
                            prefixIcon: Icons.home_outlined,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _websiteController,
                            label: 'Website',
                            prefixIcon: Icons.language,
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _aboutController,
                            label: 'About',
                            prefixIcon: Icons.description_outlined,
                            maxLines: 3,
                          ),

                          const SizedBox(height: 24),

                          // Status Section
                          _buildSectionTitle('Status', Icons.toggle_on),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: SwitchListTile(
                              title: const Text(
                                'Online Status',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                _isOnline
                                    ? 'User is currently active'
                                    : 'User is currently inactive',
                                style: TextStyle(
                                  color:
                                      _isOnline
                                          ? Color(0xff364C63)
                                          : Color(0xFFF2B342),
                                  fontSize: 13,
                                ),
                              ),
                              value: _isOnline,
                              activeColor: const Color(0xFFF2B342),
                              onChanged:
                                  _isSaving
                                      ? null
                                      : (value) =>
                                          setState(() => _isOnline = value),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Footer Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFC),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isSaving ? Colors.grey : Color(0xFFF2B342),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child:
                              _isSaving
                                  ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Updating...',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isEditing ? Icons.save : Icons.add,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isEditing
                                            ? 'Update User'
                                            : 'Create User',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF667EEA).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xff364C63), size: 20),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 210,
          child: Text(
            maxLines: 2,
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xff364C63), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator:
          validator ??
          (value) {
            if (required && (value?.isEmpty ?? true)) {
              return 'This field is required';
            }
            if (label.toLowerCase().contains('email') &&
                value?.isNotEmpty == true) {
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value!)) {
                return 'Please enter a valid email address';
              }
            }
            return null;
          },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    required bool showPassword,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !showPassword,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        prefixIcon: const Icon(Icons.lock_outline, size: 20),
        suffixIcon:
            onToggleVisibility != null
                ? IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: onToggleVisibility,
                )
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xff364C63), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator:
          validator ??
          (value) {
            if (required && (value?.isEmpty ?? true)) {
              return 'This field is required';
            }
            if (value?.isNotEmpty == true && value!.length < 6) {
              return 'Password must be at least 6 characters long';
            }
            return null;
          },
    );
  }
}

class ProfileTopBar extends StatelessWidget {
  const ProfileTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xffD9D9D9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              color: Color(0xFFF2B342),
              onSelected: (value) async {
                if (value == 'profile') {
                  final navController = Get.find<NavigationController>();
                  navController.navigateToProfile();
                } else if (value == 'logout') {
                  await FirebaseAuth.instance.signOut();
                  Get.offAllNamed('/auth');
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              offset: const Offset(0, 45),
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, size: 20),
                          SizedBox(width: 12),
                          Text('Profile'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 20),
                          SizedBox(width: 12),
                          Text('Log out'),
                        ],
                      ),
                    ),
                  ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(
                      Get.find<AuthService>().currentUser?.profile_image ?? '',
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Admin Dedicated Cowboy',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF2D3748),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
