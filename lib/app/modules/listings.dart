// Controller for managing listings
import 'package:dedicated_cow_boy_admin/app/utils/api_client.dart';
import 'package:dedicated_cow_boy_admin/app/new/auth_service.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Enhanced ListingWrapper with admin fields
class AdminListingWrapper {
  final dynamic listing;
  final String type;
  final String? id;
  final String? name;
  final String? userId;
  final List<String>? category;
  final DateTime? createdAt;
  final bool? isActive;
  final bool? isBanned;
  final bool? isRejected;
  final String? rejectionReason;
  final DateTime? updatedAt;
  final String? paymentStatus; // Added payment status

  AdminListingWrapper({
    required this.listing,
    required this.type,
    this.id,
    this.name,
    this.userId,
    this.category,
    this.createdAt,
    this.isActive,
    this.isBanned,
    this.isRejected,
    this.rejectionReason,
    this.updatedAt,
    this.paymentStatus, // Added payment status
  });

  factory AdminListingWrapper.fromApiData(Map<String, dynamic> data) {
    return AdminListingWrapper(
      listing: data,
      type: 'Business', // All listings from at_biz_dir are business type
      id: data['id']?.toString(),
      name: data['title']?['rendered'] ?? 'Unnamed Listing',
      userId: data['author']?.toString(),
      category: _getCategoryFromApi(data),
      createdAt: _parseDate(data['date']),
      isActive: _getIsActiveFromApi(data),
      isBanned: _getIsBannedFromApi(data),
      isRejected: _getIsRejectedFromApi(data),
      rejectionReason: _getRejectionReasonFromApi(data),
      updatedAt: _parseDate(data['modified']),
      paymentStatus: _getPaymentStatusFromApi(data),
    );
  }

  // Helper methods for API data parsing
  static DateTime? _parseDate(dynamic dateString) {
    if (dateString == null) return null;
    try {
      return DateTime.parse(dateString.toString());
    } catch (e) {
      return null;
    }
  }

  static List<String>? _getCategoryFromApi(Map<String, dynamic> data) {
    final categories = data['at_biz_dir-category'] as List?;
    if (categories != null && categories.isNotEmpty) {
      return categories.map((e) => e.toString()).toList();
    }
    return null;
  }

  static bool? _getIsActiveFromApi(Map<String, dynamic> data) {
    final status = data['status']?.toString();
    return status == 'publish';
  }

  static bool? _getIsBannedFromApi(Map<String, dynamic> data) {
    // Check if listing is banned based on meta data
    final meta = data['meta'];
    if (meta != null) {
      final listingStatus = meta['_listing_status']?.first?.toString();
      return listingStatus == 'banned';
    }
    return false;
  }

  static bool? _getIsRejectedFromApi(Map<String, dynamic> data) {
    final meta = data['meta'];
    if (meta != null) {
      final listingStatus = meta['_listing_status']?.first?.toString();
      return listingStatus == 'rejected';
    }
    return false;
  }

  static String? _getRejectionReasonFromApi(Map<String, dynamic> data) {
    final meta = data['meta'];
    if (meta != null) {
      return meta['_rejection_reason']?.first?.toString();
    }
    return null;
  }

  static String? _getPaymentStatusFromApi(Map<String, dynamic> data) {
    final meta = data['meta'];
    if (meta != null) {
      final orderCompleted = meta['_order_completed_date']?.first?.toString();
      if (orderCompleted != null && orderCompleted.isNotEmpty) {
        return 'paid';
      }
    }
    return 'pending';
  }

  String get status {
    if (isBanned == true) return 'Banned';
    if (isRejected == true) return 'Rejected';
    if (isActive == true) return 'Accepted';
    return 'Pending';
  }

  Color get statusColor {
    switch (status) {
      case 'Accepted':
        return Color(0xff364C63);
      case 'Pending':
        return Color(0xFFF2B342);
      case 'Rejected':
        return Colors.red;
      case 'Banned':
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }

  // Payment status color
  Color get paymentStatusColor {
    switch (paymentStatus?.toLowerCase()) {
      case 'paid':
        return Color(0xFFF2B342);
      case 'pending':
        return Color(0xff364C63);
      case 'failed':
        return Colors.red;
      default:
        return Color(0xff364C63);
    }
  }
}

// GetX Controller for Admin Listings Management
class AdminListingsController extends GetxController {
  // Observable variables
  final RxList<AdminListingWrapper> allListings = <AdminListingWrapper>[].obs;
  final RxList<AdminListingWrapper> filteredListings =
      <AdminListingWrapper>[].obs;
  final RxList<String> selectedListings = <String>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'All'.obs;
  final RxString selectedStatus = 'All'.obs;
  final RxString selectedPaymentStatus =
      'All'.obs; // Added payment status filter
  final RxString selectedDateFilter = 'Recent'.obs;
  final RxString sortBy = 'Recent'.obs;
  final RxInt currentPage = 1.obs;
  final RxBool hasMoreData = true.obs;

  // Pagination
  static const int itemsPerPage = 20;
  int totalPages = 1;

  // Categories mapping based on listing types
  final Map<String, List<String>> categoriesStatic = {
    "Business & Services": [
      'Business & Services',
      "Western Retail Shops",
      "Boutiques",
      "Ranch Services",
      "All Other",
    ],
    "Home & Ranch Decor": ['Home & Ranch Decor', "Furniture", "Art", "Decor"],
    "Tack & Live Stock": [
      "Tack & Live Stock",
      "Tack",
      "Horses",
      "Livestock",
      "Miscellaneous",
    ],
    "Western Life & Events": [
      'Western Life & Events',
      "Rodeos",
      "Barrel Races",
      "Team Roping",
      "All Other Events",
    ],
    "Western Style": ["Womens", "Mens", "Kids", "Accessories"],
  };

  // Filter options
  final List<String> categories = [
    'All',
    'All Other',
    'Boutiques',
    'Ranch Services',
    'Western Retail Shops',
    'Art',
    'Decor',
    'Furniture',
    'Horses',
    'Livestock',
    'Miscellaneous',
    'Tack',
    'All Other Events',
    'Barrel Races',
    'Rodeos',
    'Team Roping',
    'Accessories',
    'Kids',
    'Mens',
    'Womens',
  ];

  final List<String> statusOptions = [
    'All',
    'Accepted',
    'Pending',
    'Rejected',
    'Banned',
  ];

  // Added payment status options
  final List<String> paymentStatusOptions = [
    'All',
    'Pending',
    'Paid',
    'Failed',
  ];

  final List<String> dateFilters = [
    'Recent',
    'This Week',
    'This Month',
    'Last 3 Months',
    'Older',
  ];

  final List<String> sortOptions = ['Recent', 'Oldest', 'A-Z', 'Z-A', 'Status'];

  @override
  void onInit() {
    super.onInit();

    // Set up reactive filtering
    ever(searchQuery, (_) => _applyFilters());
    ever(selectedCategory, (_) => _applyFilters());
    ever(selectedStatus, (_) => _applyFilters());
    ever(
      selectedPaymentStatus,
      (_) => _applyFilters(),
    ); // Added payment status filter
    ever(selectedDateFilter, (_) => _applyFilters());
    ever(sortBy, (_) => _applyFilters());

    // Test API connectivity and load listings after a delay
    Future.delayed(const Duration(milliseconds: 1000), () async {
      await _testApiConnectivity();
      loadListings();
    });
  }

  // Test API connectivity
  Future<void> _testApiConnectivity() async {
    try {
      print('Testing API connectivity...');
      final uri = Uri.parse(
        'https://dedicatedcowboy.com/wp-json/wp/v2/at_biz_dir?per_page=1',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      print('API test response: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('API is accessible');
      } else {
        print('API returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('API connectivity test failed: $e');
    }
  }

  // Load listings with pagination from WordPress API
  Future<void> loadListings({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      hasMoreData.value = true;
      allListings.clear();
    }

    if (isLoading.value || (!hasMoreData.value && !refresh)) return;

    isLoading.value = refresh;
    isLoadingMore.value = !refresh;

    try {
      // Get auth token with error handling
      AuthService? authService;
      try {
        authService = Get.find<AuthService>();
      } catch (e) {
        print('AuthService not found: $e');
        Get.snackbar(
          'Error',
          'Authentication service not available. Please restart the app.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      final token = authService.currentToken;
      print('Loading listings - Token: ${token != null ? 'exists' : 'null'}');

      if (token == null) {
        print('No authentication token found');
        Get.snackbar(
          'Error',
          'Authentication token not found. Please log in again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // Build API URL with parameters
      final baseUrl = 'https://dedicatedcowboy.com/wp-json/wp/v2/at_biz_dir';
      final queryParams = <String, String>{
        'page': currentPage.value.toString(),
        'per_page': itemsPerPage.toString(),
        'context': 'edit', // Get full data including meta
      };

      // Add search if provided
      if (searchQuery.value.isNotEmpty) {
        queryParams['search'] = searchQuery.value;
      }

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

      print('Making API call to: $uri');
      print('Query params: $queryParams');

      // Make API call
      final response = await ApiClient.makeRequest(
        uri: uri,
        method: 'GET',
        token: token,
      );

      print('API Response - Success: ${response.success}');
      print('API Response - Status Code: ${response.statusCode}');
      print('API Response - Message: ${response.message}');

      if (response.success && response.data != null) {
        final List<dynamic> listingsData = response.data as List<dynamic>;
        final List<AdminListingWrapper> newListings =
            listingsData
                .map(
                  (data) => AdminListingWrapper.fromApiData(
                    data as Map<String, dynamic>,
                  ),
                )
                .toList();

        if (refresh) {
          allListings.value = newListings;
        } else {
          allListings.addAll(newListings);
        }

        // Check if there are more pages - WordPress API doesn't provide total pages in response
        // We'll assume there are more pages if we got a full page of results
        hasMoreData.value = newListings.length == itemsPerPage;

        _applyFilters();
      } else {
        Get.snackbar(
          'Error',
          'Failed to load listings: ${response.message ?? 'Unknown error'}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('Error loading listings: $e');
      print('Error type: ${e.runtimeType}');

      String errorMessage = 'Failed to load listings';
      if (e.toString().contains('network-error')) {
        errorMessage = 'No internet connection. Please check your network.';
      } else if (e.toString().contains('response-processing-error')) {
        errorMessage = 'Server response error. Please try again.';
      } else if (e.toString().contains('authentication')) {
        errorMessage = 'Authentication failed. Please log in again.';
      } else {
        errorMessage = 'Failed to load listings: ${e.toString()}';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  void _applyFilters() {
    List<AdminListingWrapper> filtered = List.from(allListings);

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      filtered =
          filtered.where((listing) {
            final name = listing.name?.toLowerCase() ?? '';
            final categories =
                listing.category?.map((c) => c.toLowerCase()).toList() ?? [];
            final query = searchQuery.value.toLowerCase();

            return name.contains(query) ||
                categories.any((category) => category.contains(query));
          }).toList();
    }

    // Apply category filter
    if (selectedCategory.value != 'All') {
      filtered =
          filtered
              .where(
                (listing) =>
                    listing.category?.contains(selectedCategory.value) ?? false,
              )
              .toList();
    }

    // Apply status filter
    if (selectedStatus.value != 'All') {
      filtered =
          filtered
              .where((listing) => listing.status == selectedStatus.value)
              .toList();
    }

    // Apply payment status filter
    if (selectedPaymentStatus.value != 'All') {
      filtered =
          filtered
              .where(
                (listing) =>
                    listing.paymentStatus?.toLowerCase() ==
                    selectedPaymentStatus.value.toLowerCase(),
              )
              .toList();
    }

    // Apply date filter
    if (selectedDateFilter.value != 'Recent') {
      final now = DateTime.now();
      filtered =
          filtered.where((listing) {
            if (listing.createdAt == null) return false;

            switch (selectedDateFilter.value) {
              case 'This Week':
                return listing.createdAt!.isAfter(
                  now.subtract(Duration(days: 7)),
                );
              case 'This Month':
                return listing.createdAt!.isAfter(
                  now.subtract(Duration(days: 30)),
                );
              case 'Last 3 Months':
                return listing.createdAt!.isAfter(
                  now.subtract(Duration(days: 90)),
                );
              case 'Older':
                return listing.createdAt!.isBefore(
                  now.subtract(Duration(days: 90)),
                );
              default:
                return true;
            }
          }).toList();
    }

    // Apply sorting
    _applySorting(filtered);

    filteredListings.value = filtered;
  }

  void _applySorting(List<AdminListingWrapper> listings) {
    switch (sortBy.value) {
      case 'Recent':
        listings.sort(
          (a, b) => (b.createdAt ?? DateTime(2000)).compareTo(
            a.createdAt ?? DateTime(2000),
          ),
        );
        break;
      case 'Oldest':
        listings.sort(
          (a, b) => (a.createdAt ?? DateTime(2000)).compareTo(
            b.createdAt ?? DateTime(2000),
          ),
        );
        break;
      case 'A-Z':
        listings.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
        break;
      case 'Z-A':
        listings.sort((a, b) => (b.name ?? '').compareTo(a.name ?? ''));
        break;
      case 'Status':
        listings.sort((a, b) => a.status.compareTo(b.status));
        break;
    }
  }

  // Selection methods
  void toggleSelection(String id) {
    if (selectedListings.contains(id)) {
      selectedListings.remove(id);
    } else {
      selectedListings.add(id);
    }
    selectedListings.refresh();
    update();
  }

  void selectAll() {
    if (selectedListings.length == filteredListings.length) {
      selectedListings.clear();
    } else {
      selectedListings.value =
          filteredListings
              .map((listing) => listing.id!)
              .cast<String>()
              .toList();
    }
    selectedListings.refresh();
    update();
  }

  void clearSelection() {
    selectedListings.clear();
  }

  // Check if selected listings are all the same type for category update
  bool get canUpdateCategory {
    if (selectedListings.isEmpty) return false;

    final types =
        selectedListings
            .map(
              (id) => allListings.firstWhere(
                (l) => l.id == id,
                orElse:
                    () => AdminListingWrapper(listing: '', type: '', id: ''),
              ),
            )
            .where((listing) => listing.id != '')
            .map((listing) => listing.type)
            .toSet();

    return types.length == 1;
  }

  // Get categories for selected listing type
  List<String> getCategoriesForSelectedType() {
    if (selectedListings.isEmpty) return [];

    final firstListing = allListings.firstWhere(
      (l) => l.id == selectedListings.first,
    );
    return getCategoriesForType(firstListing.type);
  }

  List<String> getCategoriesForType(String type) {
    switch (type) {
      case 'Item':
        return [
          ...categoriesStatic["Home & Ranch Decor"]!,
          ...categoriesStatic["Tack & Live Stock"]!,
          ...categoriesStatic["Western Style"]!,
        ];
      case 'Event':
        return categoriesStatic["Western Life & Events"]!;
      case 'Business':
        return categoriesStatic["Business & Services"]!;
      default:
        return [];
    }
  }

  // Action methods - Updated to use WordPress API
  Future<void> activateListings(List<String> ids) async {
    await _updateListingsStatus(ids, {
      'status': 'publish',
      'meta': {'_listing_status': 'active', '_rejection_reason': ''},
    });
    clearSelection();
    Get.snackbar(
      'Success',
      '${ids.length} listing(s) activated',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Color(0xFFF2B342),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> deactivateListings(List<String> ids) async {
    await _updateListingsStatus(ids, {
      'status': 'draft',
      'meta': {'_listing_status': 'inactive'},
    });
    clearSelection();
    Get.snackbar(
      'Success',
      '${ids.length} listing(s) deactivated',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Color(0xFFF2B342),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> rejectListings(List<String> ids, String reason) async {
    await _updateListingsStatus(ids, {
      'status': 'draft',
      'meta': {'_listing_status': 'rejected', '_rejection_reason': reason},
    });
    clearSelection();
    Get.snackbar(
      'Success',
      '${ids.length} listing(s) rejected',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Color(0xFFF2B342),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> banListings(List<String> ids, String reason) async {
    await _updateListingsStatus(ids, {
      'status': 'draft',
      'meta': {'_listing_status': 'banned', '_rejection_reason': reason},
    });
    clearSelection();
    Get.snackbar(
      'Success',
      '${ids.length} listing(s) banned',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Color(0xFFF2B342),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  // Added payment status update method
  Future<void> updatePaymentStatus(List<String> ids, String status) async {
    await _updateListingsStatus(ids, {
      'meta': {
        '_payment_status': status,
        if (status == 'paid')
          '_order_completed_date': DateTime.now().toIso8601String(),
      },
    });
    clearSelection();
    Get.snackbar(
      'Success',
      '${ids.length} listing(s) payment status updated to $status',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Color(0xFFF2B342),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> updateListingCategories(
    List<String> ids,
    List<String> newCategories,
  ) async {
    try {
      final authService = Get.find<AuthService>();
      final token = authService.currentToken;

      if (token == null) {
        Get.snackbar(
          'Error',
          'Authentication token not found',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      // Update each listing via API
      for (String id in ids) {
        final uri = Uri.parse(
          'https://dedicatedcowboy.com/wp-json/wp/v2/at_biz_dir/$id',
        );

        final response = await ApiClient.makeRequest(
          uri: uri,
          method: 'POST',
          token: token,
          body: {'at_biz_dir-category': newCategories},
        );

        if (!response.success) {
          Get.snackbar(
            'Error',
            'Failed to update categories for listing $id: ${response.message}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
          return;
        }
      }

      // Refresh the listings to get updated data
      await loadListings(refresh: true);
      clearSelection();

      Get.snackbar(
        'Success',
        '${ids.length} listing(s) categories updated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update categories: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> deleteListings(List<String> ids) async {
    try {
      final authService = Get.find<AuthService>();
      final token = authService.currentToken;

      if (token == null) {
        Get.snackbar(
          'Error',
          'Authentication token not found',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      // Delete each listing via API
      for (String id in ids) {
        final uri = Uri.parse(
          'https://dedicatedcowboy.com/wp-json/wp/v2/at_biz_dir/$id',
        );

        final response = await ApiClient.makeRequest(
          uri: uri,
          method: 'DELETE',
          token: token,
        );

        if (!response.success) {
          Get.snackbar(
            'Error',
            'Failed to delete listing $id: ${response.message}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
          return;
        }
      }

      // Remove from local lists
      allListings.removeWhere((listing) => ids.contains(listing.id));
      _applyFilters();
      clearSelection();

      Get.snackbar(
        'Success',
        '${ids.length} listing(s) deleted',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete listings: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _updateListingsStatus(
    List<String> ids,
    Map<String, dynamic> updates,
  ) async {
    try {
      final authService = Get.find<AuthService>();
      final token = authService.currentToken;

      if (token == null) {
        Get.snackbar(
          'Error',
          'Authentication token not found',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      // Update each listing via API
      for (String id in ids) {
        final uri = Uri.parse(
          'https://dedicatedcowboy.com/wp-json/wp/v2/at_biz_dir/$id',
        );

        final response = await ApiClient.makeRequest(
          uri: uri,
          method: 'POST',
          token: token,
          body: updates,
        );

        if (!response.success) {
          Get.snackbar(
            'Error',
            'Failed to update listing $id: ${response.message}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
          return;
        }
      }

      // Refresh the listings to get updated data
      await loadListings(refresh: true);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update listings: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // Single item actions
  Future<void> toggleActiveStatus(String id) async {
    final listing = allListings.firstWhere((l) => l.id == id);
    final isCurrentlyActive = listing.isActive ?? false;

    await _updateListingsStatus(
      [id],
      {
        'status': isCurrentlyActive ? 'draft' : 'publish',
        'meta': {'_listing_status': isCurrentlyActive ? 'inactive' : 'active'},
      },
    );
  }

  // Search and filter methods
  void updateSearchQuery(String query) {
    searchQuery.value = query;
    // Trigger API search when query changes
    if (query.isNotEmpty) {
      searchListings(query);
    } else {
      loadListings(refresh: true);
    }
  }

  // Search listings using API
  Future<void> searchListings(String query) async {
    if (query.isEmpty) {
      await loadListings(refresh: true);
      return;
    }

    try {
      final authService = Get.find<AuthService>();
      final token = authService.currentToken;

      if (token == null) {
        Get.snackbar(
          'Error',
          'Authentication token not found',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      final baseUrl = 'https://dedicatedcowboy.com/wp-json/wp/v2/at_biz_dir';
      final queryParams = <String, String>{
        'search': query,
        'per_page': itemsPerPage.toString(),
        'context': 'edit',
      };

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

      final response = await ApiClient.makeRequest(
        uri: uri,
        method: 'GET',
        token: token,
      );

      if (response.success && response.data != null) {
        final List<dynamic> listingsData = response.data as List<dynamic>;
        final List<AdminListingWrapper> searchResults =
            listingsData
                .map(
                  (data) => AdminListingWrapper.fromApiData(
                    data as Map<String, dynamic>,
                  ),
                )
                .toList();

        allListings.value = searchResults;
        _applyFilters();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Search failed: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void updateCategoryFilter(String category) {
    selectedCategory.value = category;
  }

  void updateStatusFilter(String status) {
    selectedStatus.value = status;
  }

  void updatePaymentStatusFilter(String status) {
    selectedPaymentStatus.value = status;
  }

  void updateDateFilter(String dateFilter) {
    selectedDateFilter.value = dateFilter;
  }

  void updateSorting(String sort) {
    sortBy.value = sort;
  }

  // Refresh data
  @override
  Future<void> refresh() async {
    await loadListings(refresh: true);
  }

  // Load more data for pagination
  Future<void> loadMore() async {
    if (!hasMoreData.value || isLoadingMore.value) return;
    currentPage.value++;
    await loadListings();
  }

  // Pagination helpers
  int get totalPagesCount => totalPages;

  void goToPage(int page) {
    if (page >= 1) {
      currentPage.value = page;
      loadListings();
    }
  }
}

// Enhanced ManageListingsScreen with exact design match and proper functionality
class ManageListingsScreen extends StatelessWidget {
  const ManageListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminListingsController());

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(7),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        "Manage Listings",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Spacer(),
                      Obx(
                        () => Text(
                          "${controller.filteredListings.length} items",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search and Filters Row - Made responsive
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmallScreen = constraints.maxWidth < 1000;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          // Search Field
                          Container(
                            width: isSmallScreen ? double.infinity : 400,
                            height: 40,
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Color(0xFFE5E5E5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Color(0xFFD0D0D0)),
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: controller.updateSearchQuery,
                            ),
                          ),

                          // Category Filter
                          Obx(() {
                            return _buildDropdownFilter(
                              "Category: ${controller.selectedCategory.value}",
                              controller.categories,
                              controller.selectedCategory.value,
                              controller.updateCategoryFilter,
                              width: isSmallScreen ? 220 : null,
                            );
                          }),

                          // Date Posted Filter
                          Obx(() {
                            return _buildDropdownFilter(
                              "Date: ${controller.selectedDateFilter.value}",
                              controller.dateFilters,
                              controller.selectedDateFilter.value,
                              controller.updateDateFilter,
                              width: isSmallScreen ? 180 : null,
                            );
                          }),
                          Obx(() {
                            return _buildDropdownFilter(
                              "Status: ${controller.selectedStatus.value}",
                              controller.statusOptions,
                              controller.selectedStatus.value,
                              controller.updateStatusFilter,
                              width: isSmallScreen ? 180 : null,
                            );
                          }),
                          Obx(() {
                            return _buildDropdownFilter(
                              "Payment: ${controller.selectedPaymentStatus.value}",
                              controller.paymentStatusOptions,
                              controller.selectedPaymentStatus.value,
                              controller.updatePaymentStatusFilter,
                              width: isSmallScreen ? 180 : null,
                            );
                          }),

                          // Status Filter

                          // Payment Status Filter
                        ],
                      );
                    },
                  ),
                ),

                SizedBox(height: 20),

                // Table Section
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value &&
                        controller.filteredListings.isEmpty) {
                      return _buildShimmerLoading();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      child: Column(
                        children: [
                          // Table with fixed header
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width:
                                    MediaQuery.of(context).size.width < 1000
                                        ? 1800
                                        : MediaQuery.of(context).size.width -
                                            32,
                                child: Column(
                                  children: [
                                    // Fixed Table Header
                                    Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF364C63),
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(8),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Checkbox column - Fixed width
                                          SizedBox(
                                            width: 50,
                                            child: Obx(
                                              () => Checkbox(
                                                value:
                                                    controller
                                                            .selectedListings
                                                            .length ==
                                                        controller
                                                            .filteredListings
                                                            .length &&
                                                    controller
                                                        .filteredListings
                                                        .isNotEmpty,
                                                onChanged:
                                                    (_) =>
                                                        controller.selectAll(),
                                                fillColor:
                                                    WidgetStateProperty.all(
                                                      Colors.white,
                                                    ),
                                                checkColor: Color(0xFF364C63),
                                              ),
                                            ),
                                          ),
                                          // Title column - Wider
                                          SizedBox(
                                            width: 300,
                                            child: Padding(
                                              padding: EdgeInsets.only(left: 8),
                                              child: Text(
                                                "Title",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Seller column
                                          SizedBox(
                                            width: 200,
                                            child: Padding(
                                              padding: EdgeInsets.only(left: 8),
                                              child: Text(
                                                "Seller",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Category column
                                          SizedBox(
                                            width: 250,
                                            child: Padding(
                                              padding: EdgeInsets.only(left: 8),
                                              child: Text(
                                                "Category",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Status column
                                          SizedBox(
                                            width: 250,
                                            child: Padding(
                                              padding: EdgeInsets.only(left: 8),
                                              child: Text(
                                                "Status",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Payment Status column
                                          SizedBox(
                                            width: 350,
                                            child: Padding(
                                              padding: EdgeInsets.only(left: 8),
                                              child: Text(
                                                "Payment",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Action column
                                          SizedBox(
                                            width: 250,
                                            child: Padding(
                                              padding: EdgeInsets.only(left: 8),
                                              child: Text(
                                                "Action",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Scrollable Table Body
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Color(0xFFE0E0E0),
                                          ),
                                          borderRadius: BorderRadius.vertical(
                                            bottom: Radius.circular(8),
                                          ),
                                        ),
                                        child: ListView.builder(
                                          itemCount:
                                              controller
                                                  .filteredListings
                                                  .length,
                                          itemBuilder: (context, index) {
                                            final listing =
                                                controller
                                                    .filteredListings[index];
                                            final isSelected = controller
                                                .selectedListings
                                                .contains(listing.id);
                                            final isEven = index % 2 == 0;

                                            return _buildTableRow(
                                              listing,
                                              isSelected,
                                              isEven,
                                              controller,
                                              context,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Loading More Indicator
                          Obx(
                            () =>
                                controller.isLoadingMore.value
                                    ? Container(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(),
                                    )
                                    : SizedBox.shrink(),
                          ),
                        ],
                      ),
                    );
                  }),
                ),

                // Bottom Action Buttons
                Obx(
                  () =>
                      controller.selectedListings.isNotEmpty
                          ? Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildActionButton(
                                  "Approve",
                                  Color(0xFFF2B342),
                                  () => controller.activateListings(
                                    List.from(controller.selectedListings),
                                  ),
                                ),
                                SizedBox(width: 8),
                                _buildActionButton(
                                  "Remove",
                                  Color(0xFFF2B342),
                                  () => _showDeleteDialog(controller, context),
                                ),
                                SizedBox(width: 8),
                                // Payment status button
                                _buildActionButton(
                                  "Update Payment",
                                  Color(0xFFF2B342),
                                  () => _showUpdatePaymentDialog(
                                    controller,
                                    context,
                                  ),
                                ),
                                SizedBox(width: 8),
                                // Only show Category button if all selected items are same type
                                if (controller.canUpdateCategory)
                                  _buildActionButton(
                                    "Category",
                                    Color(0xFFF2B342),
                                    () => _showChangeCategoryDialog(
                                      controller,
                                      context,
                                    ),
                                  ),
                              ],
                            ),
                          )
                          : SizedBox.shrink(),
                ),

                Container(
                  padding: EdgeInsets.all(16),
                  child: _buildPagination(controller, context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          8,
          (index) => Container(
            margin: EdgeInsets.only(bottom: 8),
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 20,
                  margin: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 20,
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownFilter(
    String title,
    List<String> options,
    String selected,
    Function(String) onChanged, {
    double? width,
  }) {
    return Container(
      width: width,
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Color(0xFFE5E5E5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFD0D0D0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: Color(0xFFF2B342),
          value: selected,
          hint: Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          items:
              options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option, style: TextStyle(fontSize: 14)),
                );
              }).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
          icon: Icon(Icons.keyboard_arrow_down, size: 18),
        ),
      ),
    );
  }

  Widget _buildTableRow(
    AdminListingWrapper listing,
    bool isSelected,
    bool isEven,
    AdminListingsController controller,
    BuildContext context,
  ) {
    final hasPendingPayment = listing.paymentStatus?.toLowerCase() == 'pending';

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isEven ? Colors.white : Color(0xFFF5F5F5),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          SizedBox(
            width: 50,
            child: Checkbox(
              value: isSelected,
              onChanged: (_) => controller.toggleSelection(listing.id!),
              fillColor: WidgetStateProperty.all(
                isSelected ? Color(0xFFF2B342) : Colors.white,
              ),
              checkColor: Colors.white,
            ),
          ),
          // Title
          SizedBox(
            width: 300,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                listing.name ?? 'Unnamed ${listing.type}',
                style: TextStyle(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Seller
          UserNameWidget(userId: listing.userId ?? ''),
          // Category
          SizedBox(
            width: 250,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(listing.type, style: TextStyle(fontSize: 14)),
            ),
          ),
          // Status
          SizedBox(
            width: 250,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                listing.status,
                style: TextStyle(
                  fontSize: 14,
                  color: _getStatusColor(listing.status),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // Payment Status
          SizedBox(
            width: 250,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: listing.paymentStatusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: listing.paymentStatusColor),
                ),
                child: Text(
                  listing.paymentStatus?.toUpperCase() ?? 'PENDING',
                  style: TextStyle(
                    fontSize: 12,
                    color: listing.paymentStatusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          // Actions
          SizedBox(
            width: 250,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!hasPendingPayment)
                  InkWell(
                    onTap: () => _showEditDialog(listing, controller, context),
                    child: Container(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.edit,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                if (!hasPendingPayment) SizedBox(width: 8),
                InkWell(
                  onTap:
                      () =>
                          _showSingleDeleteDialog(listing, controller, context),
                  child: Container(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                if (hasPendingPayment)
                  InkWell(
                    onTap:
                        () => _showUpdatePaymentDialogForSingle(
                          listing,
                          controller,
                          context,
                        ),
                    child: Container(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.payment,
                        size: 18,
                        color: Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPagination(
    AdminListingsController controller,
    BuildContext context,
  ) {
    return Obx(() {
      if (controller.filteredListings.isEmpty) return SizedBox.shrink();

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          if (controller.currentPage.value > 1)
            _buildPageButton("Previous", false, () {
              controller.currentPage.value--;
              controller.loadListings();
            }),

          SizedBox(width: 8),

          // Page numbers
          for (int i = 1; i <= controller.totalPages.clamp(1, 5); i++)
            _buildPageButton(
              i.toString(),
              i == controller.currentPage.value,
              () => controller.goToPage(i),
            ),

          if (controller.totalPages > 5) ...[
            SizedBox(width: 8),
            Text(
              "...",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],

          SizedBox(width: 8),

          // Next button
          if (controller.hasMoreData.value)
            _buildPageButton("Next", false, () => controller.loadMore()),
        ],
      );
    });
  }

  Widget _buildPageButton(String text, bool isActive, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.grey[700] : Colors.white,
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'pending':
        return Color(0xFFF2B342);
      case 'rejected':
        return Colors.red;
      case 'banned':
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }

  // Updated dialogs with proper status handling
  void _showDeleteDialog(
    AdminListingsController controller,
    BuildContext context,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text("Remove Listings"),
        content: Text(
          "Are you sure you want to remove ${controller.selectedListings.length} listing(s)?",
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              controller.deleteListings(List.from(controller.selectedListings));
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Remove", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChangeCategoryDialog(
    AdminListingsController controller,
    BuildContext context,
  ) {
    final availableCategories = controller.getCategoriesForSelectedType();
    List<String> selectedCategories = [];

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Change Categories"),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Update categories for ${controller.selectedListings.length} listing(s)",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Select categories:",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: availableCategories.length,
                      itemBuilder: (context, index) {
                        final category = availableCategories[index];
                        final isSelected = selectedCategories.contains(
                          category,
                        );

                        return CheckboxListTile(
                          title: Text(category),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedCategories.add(category);
                              } else {
                                selectedCategories.remove(category);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: Text("Cancel")),
              ElevatedButton(
                onPressed:
                    selectedCategories.isNotEmpty
                        ? () {
                          controller.updateListingCategories(
                            List.from(controller.selectedListings),
                            selectedCategories,
                          );
                          Get.back();
                        }
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF2B342),
                ),
                child: Text("Update", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUpdatePaymentDialog(
    AdminListingsController controller,
    BuildContext context,
  ) {
    String selectedStatus = 'paid';

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Update Payment Status"),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Update payment status for ${controller.selectedListings.length} listing(s)",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFFE5E5E5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFD0D0D0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedStatus,
                        items:
                            ['paid', 'pending', 'failed'].map((status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status.toUpperCase()),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedStatus = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  controller.updatePaymentStatus(
                    List.from(controller.selectedListings),
                    selectedStatus,
                  );
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF2B342),
                ),
                child: Text("Update", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUpdatePaymentDialogForSingle(
    AdminListingWrapper listing,
    AdminListingsController controller,
    BuildContext context,
  ) {
    String selectedStatus = listing.paymentStatus ?? 'pending';

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Update Payment Status"),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Update payment status for ${listing.name}",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFFE5E5E5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFD0D0D0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedStatus,
                        items:
                            ['paid', 'pending', 'failed'].map((status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status.toUpperCase()),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedStatus = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  controller.updatePaymentStatus([listing.id!], selectedStatus);
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF2B342),
                ),
                child: Text("Update", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDialog(
    AdminListingWrapper listing,
    AdminListingsController controller,
    BuildContext context,
  ) {
    bool isActive = listing.isActive ?? false;
    bool isBanned = listing.isBanned ?? false;
    bool isRejected = listing.isRejected ?? false;
    String rejectionReason = listing.rejectionReason ?? '';

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Edit Listing Status"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Edit status for: ${listing.name}"),
                SizedBox(height: 16),

                CheckboxListTile(
                  title: Text("Active"),
                  subtitle: Text("Listing is visible and active"),
                  value: isActive,
                  onChanged: (bool? value) {
                    setState(() {
                      isActive = value ?? false;
                      if (isActive) {
                        isBanned = false;
                        isRejected = false;
                      }
                    });
                  },
                ),

                CheckboxListTile(
                  title: Text("Banned"),
                  subtitle: Text("Listing is banned from platform"),
                  value: isBanned,
                  onChanged: (bool? value) {
                    setState(() {
                      isBanned = value ?? false;
                      if (isBanned) {
                        isActive = false;
                        isRejected = false;
                      }
                    });
                  },
                ),

                CheckboxListTile(
                  title: Text("Rejected"),
                  subtitle: Text("Listing is rejected"),
                  value: isRejected,
                  onChanged: (bool? value) {
                    setState(() {
                      isRejected = value ?? false;
                      if (isRejected) {
                        isActive = false;
                        isBanned = false;
                      }
                    });
                  },
                ),

                if (isBanned || isRejected) ...[
                  SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Reason",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => rejectionReason = value,
                    controller: TextEditingController(text: rejectionReason),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  final updates = <String, dynamic>{
                    'status': isActive ? 'publish' : 'draft',
                    'meta': {
                      '_listing_status':
                          isActive
                              ? 'active'
                              : (isBanned
                                  ? 'banned'
                                  : (isRejected ? 'rejected' : 'inactive')),
                      if (isBanned || isRejected)
                        '_rejection_reason': rejectionReason,
                    },
                  };

                  controller._updateListingsStatus([listing.id!], updates);
                  Get.back();
                },
                child: Text("Update"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSingleDeleteDialog(
    AdminListingWrapper listing,
    AdminListingsController controller,
    BuildContext context,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text("Delete Listing"),
        content: Text("Are you sure you want to delete '${listing.name}'?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              controller.deleteListings([listing.id!]);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class UserNameWidget extends StatelessWidget {
  final String userId;

  const UserNameWidget({super.key, required this.userId});

  Future<String> _getUserName(String userId) async {
    if (userId.isEmpty) return "Unknown";

    try {
      final authService = Get.find<AuthService>();
      final token = authService.currentToken;

      if (token == null) return "Unknown";

      final uri = Uri.parse(
        'https://dedicatedcowboy.com/wp-json/wp/v2/users/$userId',
      );

      final response = await ApiClient.makeRequest(
        uri: uri,
        method: 'GET',
        token: token,
      );

      if (response.success && response.data != null) {
        final userData = response.data as Map<String, dynamic>;
        return userData['name'] ?? userData['display_name'] ?? "Unknown";
      }
    } catch (e) {
      print('Error fetching user name: $e');
    }

    return "Unknown";
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: FutureBuilder<String>(
          future: _getUserName(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text(
                "Loading...",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              );
            }
            if (snapshot.hasError) {
              return const Text(
                "Error",
                style: TextStyle(fontSize: 14, color: Colors.red),
              );
            }
            return Text(
              snapshot.data ?? "Unknown",
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
      ),
    );
  }
}
