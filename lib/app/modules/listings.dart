// Controller for managing listings with enhanced filtering
import 'package:dedicated_cow_boy_admin/app/models/model.dart';
import 'package:dedicated_cow_boy_admin/app/modules/useraccounts.dart';
import 'package:dedicated_cow_boy_admin/app/modules/widgets.dart';
import 'package:dedicated_cow_boy_admin/app/utils/api_client.dart';
import 'package:dedicated_cow_boy_admin/app/new/auth_service.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// GetX Controller for Admin Listings Management
class AdminListingsController extends GetxController {
  // Observable variables
  final RxList<UnifiedListing> allListings = <UnifiedListing>[].obs;
  final RxList<UnifiedListing> filteredListings = <UnifiedListing>[].obs;
  final RxList<String> selectedListings = <String>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'All'.obs;
  final RxString selectedStatus = 'All'.obs;
  final RxString selectedListingType = 'All'.obs;
  final RxString selectedDateFilter = 'All'.obs;
  final RxString sortBy = 'date'.obs;
  final RxString sortOrder = 'DESC'.obs;
  final RxInt currentPage = 1.obs;
  final RxBool hasMoreData = true.obs;
  final RxInt totalItems = 0.obs;
  final RxInt totalPages = 0.obs;

  // Pagination
  static const int itemsPerPage = 20;

  // Filter options
  final List<String> statusOptions = [
    'All',
    'publish',
    'draft',
    'pending',
    'private',
  ];

  final List<String> listingTypeOptions = ['All', 'Business', 'Item', 'Event'];

  final List<String> dateFilters = [
    'All',
    'Today',
    'This Week',
    'This Month',
    'Last 3 Months',
  ];

  final List<String> sortOptions = ['date', 'modified', 'title'];

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

  @override
  void onInit() {
    super.onInit();

    // Set up reactive filtering - but don't trigger on page changes
    ever(searchQuery, (_) => _debounceSearch());
    ever(selectedCategory, (_) => _resetAndLoad());
    ever(selectedStatus, (_) => _resetAndLoad());
    ever(selectedListingType, (_) => _resetAndLoad());
    ever(selectedDateFilter, (_) => _resetAndLoad());
    ever(sortBy, (_) => _resetAndLoad());
    ever(sortOrder, (_) => _resetAndLoad());

    // Initial load with loading state
    Future.delayed(const Duration(milliseconds: 100), () {
      loadListings(refresh: true);
    });
  }

  // Debounced search to avoid too many API calls
  void _debounceSearch() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (searchQuery.value.isNotEmpty) {
        _resetAndLoad();
      } else if (allListings.isEmpty) {
        _resetAndLoad();
      }
    });
  }

  void _resetAndLoad() {
    currentPage.value = 1;
    hasMoreData.value = true;
    loadListings(refresh: true);
  }

  // Load listings with pagination and filters from WordPress API
  Future<void> loadListings({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      hasMoreData.value = true;
      allListings.clear();
      filteredListings.clear();
      selectedListings.clear();
    }

    if (isLoading.value || (!hasMoreData.value && !refresh)) return;

    // Set loading state
    if (refresh || currentPage.value == 1) {
      isLoading.value = true;
      isLoadingMore.value = false;
    } else {
      isLoading.value = false;
      isLoadingMore.value = true;
    }

    try {
      // Get auth token
      AuthService? authService;
      try {
        authService = Get.find<AuthService>();
      } catch (e) {
        print('AuthService not found: $e');
        _showError(
          'Authentication service not available. Please restart the app.',
        );
        return;
      }

      final token = authService.currentToken;
      if (token == null) {
        print('No authentication token found');
        _showError('Authentication token not found. Please log in again.');
        return;
      }

      // Build API URL with filters
      final baseUrl = 'https://dedicatedcowboy.com/wp-json/wp/v2/all_listings';
      final queryParams = <String, String>{
        'page': currentPage.value.toString(),
        'per_page': itemsPerPage.toString(),
        'orderby': sortBy.value,
        'order': sortOrder.value,
      };

      // Add search filter
      if (searchQuery.value.isNotEmpty) {
        queryParams['search'] = searchQuery.value;
      }

      // Add status filter
      if (selectedStatus.value != 'All') {
        queryParams['status'] = selectedStatus.value;
      }

      // Add listing type filter
      if (selectedListingType.value != 'All') {
        final typeId = _getListingTypeId(selectedListingType.value);
        if (typeId != null) {
          queryParams['listing_type'] = typeId.toString();
        }
      }

      // Add category filter
      if (selectedCategory.value != 'All') {
        queryParams['category'] = selectedCategory.value;
      }

      // Add date filter
      if (selectedDateFilter.value != 'All') {
        final dateRange = _getDateRange(selectedDateFilter.value);
        if (dateRange != null) {
          if (dateRange['after'] != null) {
            queryParams['date_after'] = dateRange['after']!;
          }
          if (dateRange['before'] != null) {
            queryParams['date_before'] = dateRange['before']!;
          }
        }
      }

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

      print('Making API call to: $uri');
      print('Current page: ${currentPage.value}');

      // Make API call
      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('API Response - Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Parse pagination headers
        final totalItemsHeader = response.headers['x-wp-total'];
        final totalPagesHeader = response.headers['x-wp-totalpages'];

        if (totalItemsHeader != null) {
          totalItems.value = int.tryParse(totalItemsHeader) ?? 0;
        }
        if (totalPagesHeader != null) {
          totalPages.value = int.tryParse(totalPagesHeader) ?? 1;
        }

        print(
          'Total items: ${totalItems.value}, Total pages: ${totalPages.value}',
        );

        final List<dynamic> listingsData =
            json.decode(response.body) as List<dynamic>;
        final List<UnifiedListing> newListings =
            listingsData
                .map(
                  (data) =>
                      UnifiedListing.fromJson(data as Map<String, dynamic>),
                )
                .toList();

        // For pagination, replace data instead of appending
        allListings.value = newListings;
        filteredListings.value = List.from(allListings);

        // Check if there are more pages
        hasMoreData.value = currentPage.value < totalPages.value;

        print(
          'Loaded ${newListings.length} listings for page ${currentPage.value}',
        );
      } else if (response.statusCode == 401) {
        _showError('Authentication failed. Please log in again.');
      } else if (response.statusCode == 400) {
        // Bad request - might be invalid page number
        if (currentPage.value > 1) {
          currentPage.value = 1;
          await loadListings(refresh: true);
        } else {
          _showError('Failed to load listings. Status: ${response.statusCode}');
        }
      } else {
        _showError('Failed to load listings. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading listings: $e');

      String errorMessage = 'Failed to load listings';
      if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout. Please check your connection.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'No internet connection. Please check your network.';
      } else {
        errorMessage = 'Failed to load listings: ${e.toString()}';
      }

      _showError(errorMessage);
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  // Helper method to get listing type ID
  int? _getListingTypeId(String type) {
    switch (type) {
      case 'Business':
        return 130;
      case 'Item':
        return 131;
      case 'Event':
        return 335;
      default:
        return null;
    }
  }

  // Helper method to get date range
  Map<String, String>? _getDateRange(String filter) {
    final now = DateTime.now();
    String? after;
    String? before;

    switch (filter) {
      case 'Today':
        after = DateTime(now.year, now.month, now.day).toIso8601String();
        break;
      case 'This Week':
        after = now.subtract(Duration(days: 7)).toIso8601String();
        break;
      case 'This Month':
        after = DateTime(now.year, now.month, 1).toIso8601String();
        break;
      case 'Last 3 Months':
        after = DateTime(now.year, now.month - 3, now.day).toIso8601String();
        break;
      default:
        return null;
    }

    return {'after': after, 'before': before.toString()};
  }

  // Selection methods
  void toggleSelection(String id) {
    if (selectedListings.contains(id)) {
      selectedListings.remove(id);
    } else {
      selectedListings.add(id);
    }
    // Force update
    selectedListings.refresh();
  }

  void selectAll() {
    if (selectedListings.length == filteredListings.length) {
      selectedListings.clear();
    } else {
      selectedListings.value =
          filteredListings.map((listing) => listing.id.toString()).toList();
    }
    // Force update
    selectedListings.refresh();
  }

  void clearSelection() {
    selectedListings.clear();
  }

  // Update listing status (publish/draft)
  Future<void> updateListingStatus(int id, String status) async {
    try {
      final authService = Get.find<AuthService>();
      final token = authService.currentToken;

      if (token == null) {
        _showError('Authentication token not found');
        return;
      }

      final response = await http
          .put(
            Uri.parse(
              'https://dedicatedcowboy.com/wp-json/wp/v2/at_biz_dir/$id',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        _showSuccess('Listing status updated to $status');
        await loadListings(refresh: true);
      } else {
        _showError('Failed to update status: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Failed to update status: $e');
    }
  }

  // Update listing details
  Future<void> updateListing(int id, Map<String, dynamic> body) async {
    try {
      final authService = Get.find<AuthService>();
      final token = authService.currentToken;

      if (token == null) {
        _showError('Authentication token not found');
        return;
      }

      final response = await http
          .put(
            Uri.parse(
              'https://dedicatedcowboy.com/wp-json/wp/v2/at_biz_dir/$id',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        _showSuccess('Listing updated successfully');
        await loadListings(refresh: true);
      } else {
        _showError('Failed to update listing: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Failed to update listing: $e');
    }
  }

  // Delete single listing
  Future<void> deleteListing(int id) async {
    try {
      final authService = Get.find<AuthService>();
      final token = authService.currentToken;

      if (token == null) {
        _showError('Authentication token not found');
        return;
      }

      final response = await http
          .delete(
            Uri.parse(
              'https://dedicatedcowboy.com/wp-json/wp/v2/at_biz_dir/$id',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        allListings.removeWhere((listing) => listing.id == id);
        filteredListings.removeWhere((listing) => listing.id == id);
        _showSuccess('Listing deleted successfully');
      } else {
        _showError('Failed to delete listing: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Failed to delete listing: $e');
    }
  }

  // Delete multiple listings
  Future<void> deleteListings(List<String> ids) async {
    try {
      final authService = Get.find<AuthService>();
      final token = authService.currentToken;

      if (token == null) {
        _showError('Authentication token not found');
        return;
      }

      for (String id in ids) {
        final response = await http
            .delete(
              Uri.parse(
                'https://dedicatedcowboy.com/wp-json/wp/v2/at_biz_dir/$id',
              ),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode != 200) {
          _showError('Failed to delete listing $id');
          return;
        }
      }

      allListings.removeWhere((listing) => ids.contains(listing.id.toString()));
      filteredListings.removeWhere(
        (listing) => ids.contains(listing.id.toString()),
      );
      clearSelection();
      _showSuccess('${ids.length} listing(s) deleted successfully');
    } catch (e) {
      _showError('Failed to delete listings: $e');
    }
  }

  // Bulk status update
  Future<void> bulkUpdateStatus(List<String> ids, String status) async {
    try {
      final authService = Get.find<AuthService>();
      final token = authService.currentToken;

      if (token == null) {
        _showError('Authentication token not found');
        return;
      }

      for (String id in ids) {
        final response = await http
            .put(
              Uri.parse(
                'https://dedicatedcowboy.com/wp-json/wp/v2/at_biz_dir/$id',
              ),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'status': status}),
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode != 200) {
          _showError('Failed to update listing $id');
          return;
        }
      }

      clearSelection();
      _showSuccess('${ids.length} listing(s) updated to $status');
      await loadListings(refresh: true);
    } catch (e) {
      _showError('Failed to update listings: $e');
    }
  }

  // Filter update methods
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void updateCategoryFilter(String category) {
    selectedCategory.value = category;
  }

  void updateStatusFilter(String status) {
    selectedStatus.value = status;
  }

  void updateListingTypeFilter(String type) {
    selectedListingType.value = type;
  }

  void updateDateFilter(String dateFilter) {
    selectedDateFilter.value = dateFilter;
  }

  void updateSorting(String sort) {
    sortBy.value = sort;
  }

  void updateSortOrder(String order) {
    sortOrder.value = order;
  }

  // Pagination helpers
  Future<void> loadMore() async {
    if (!hasMoreData.value || isLoadingMore.value) return;
    currentPage.value++;
    await loadListings();
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages.value && page != currentPage.value) {
      currentPage.value = page;
      selectedListings.clear(); // Clear selection on page change
      loadListings(refresh: false); // Don't clear all data, just load new page
    }
  }

  // Refresh data
  @override
  Future<void> refresh() async {
    await loadListings(refresh: true);
  }

  // Helper methods for notifications
  void _showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Color(0xFFF2B342),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Color(0xFFF2B342),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }
}

// Enhanced ManageListingsScreen with proper functionality
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
                const ProfileTopBar(),
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
                          "${controller.totalItems.value} total items | Page ${controller.currentPage.value} of ${controller.totalPages.value}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: () => controller.loadListings(refresh: true),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                ),

                // Search and Filters Row
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
                                hintText: 'Search listings...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                suffixIcon: Icon(Icons.search, size: 20),
                              ),
                              onChanged: controller.updateSearchQuery,
                            ),
                          ),

                          // Listing Type Filter
                          Obx(() {
                            return _buildDropdownFilter(
                              "Type: ${controller.selectedListingType.value}",
                              controller.listingTypeOptions,
                              controller.selectedListingType.value,
                              controller.updateListingTypeFilter,
                              width: isSmallScreen ? 180 : null,
                            );
                          }),

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

                          // Status Filter
                          Obx(() {
                            return _buildDropdownFilter(
                              "Status: ${controller.selectedStatus.value}",
                              controller.statusOptions,
                              controller.selectedStatus.value,
                              controller.updateStatusFilter,
                              width: isSmallScreen ? 180 : null,
                            );
                          }),

                          // Date Filter
                          Obx(() {
                            return _buildDropdownFilter(
                              "Date: ${controller.selectedDateFilter.value}",
                              controller.dateFilters,
                              controller.selectedDateFilter.value,
                              controller.updateDateFilter,
                              width: isSmallScreen ? 180 : null,
                            );
                          }),

                          // Sort By
                          Obx(() {
                            return _buildDropdownFilter(
                              "Sort: ${controller.sortBy.value}",
                              controller.sortOptions,
                              controller.sortBy.value,
                              controller.updateSorting,
                              width: isSmallScreen ? 150 : null,
                            );
                          }),

                          // Sort Order
                          Obx(() {
                            return Container(
                              height: 40,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  controller.updateSortOrder(
                                    controller.sortOrder.value == 'DESC'
                                        ? 'ASC'
                                        : 'DESC',
                                  );
                                },
                                icon: Icon(
                                  controller.sortOrder.value == 'DESC'
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  size: 16,
                                ),
                                label: Text(controller.sortOrder.value),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFE5E5E5),
                                  foregroundColor: Colors.black87,
                                  elevation: 0,
                                ),
                              ),
                            );
                          }),
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

                    if (controller.filteredListings.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No listings found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
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
                                        ? 1600
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
                                          // Checkbox column
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
                                          // Title column
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
                                          // Type column
                                          SizedBox(
                                            width: 150,
                                            child: Padding(
                                              padding: EdgeInsets.only(left: 8),
                                              child: Text(
                                                "Type",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Author column
                                          SizedBox(
                                            width: 200,
                                            child: Padding(
                                              padding: EdgeInsets.only(left: 8),
                                              child: Text(
                                                "Author",
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
                                            width: 150,
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
                                          // Date column
                                          SizedBox(
                                            width: 200,
                                            child: Padding(
                                              padding: EdgeInsets.only(left: 8),
                                              child: Text(
                                                "Date",
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
                                                "Actions",
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
                                                .contains(
                                                  listing.id.toString(),
                                                );
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
                                  "Publish",
                                  Color(0xFFF2B342),
                                  () => controller.bulkUpdateStatus(
                                    List.from(controller.selectedListings),
                                    'publish',
                                  ),
                                ),
                                SizedBox(width: 8),
                                _buildActionButton(
                                  "Draft",
                                  Colors.grey,
                                  () => controller.bulkUpdateStatus(
                                    List.from(controller.selectedListings),
                                    'draft',
                                  ),
                                ),
                                SizedBox(width: 8),
                                _buildActionButton(
                                  "Delete",
                                  Colors.red,
                                  () => _showBulkDeleteDialog(
                                    controller,
                                    context,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : SizedBox.shrink(),
                ),

                // Pagination
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
    UnifiedListing listing,
    bool isSelected,
    bool isEven,
    AdminListingsController controller,
    BuildContext context,
  ) {
    return Obx(() {
      // Re-check selection state inside Obx for reactivity
      final currentlySelected = controller.selectedListings.contains(
        listing.id.toString(),
      );

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
                value: currentlySelected,
                onChanged: (_) {
                  controller.toggleSelection(listing.id.toString());
                },
                fillColor: WidgetStateProperty.all(
                  currentlySelected ? Color(0xFFF2B342) : Colors.white,
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
                  listing.title ?? 'Unnamed Listing',
                  style: TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Type
            SizedBox(
              width: 150,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  listing.listingType,
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
            // Author
            SizedBox(
              width: 200,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'ID: ${listing.author ?? 'N/A'}',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
            // Status
            SizedBox(
              width: 150,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      listing.status ?? 'draft',
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getStatusColor(listing.status ?? 'draft'),
                    ),
                  ),
                  child: Text(
                    (listing.status ?? 'draft').toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(listing.status ?? 'draft'),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            // Date
            SizedBox(
              width: 200,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  _formatDate(listing.date),
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
            // Actions
            SizedBox(
              width: 250,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.view_list, size: 18, color: Colors.blue),
                    onPressed: () {
                      Get.dialog(
                        Center(
                          child: Container(
                            width: 500,

                            child: UnifiedDetailScreen(listing: listing),
                          ),
                        ),
                      );
                    },
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, size: 18, color: Colors.blue),
                    onPressed:
                        () => _showEditDialog(listing, controller, context),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: Icon(
                      listing.status == 'publish'
                          ? Icons.unpublished
                          : Icons.publish,
                      size: 18,
                      color: Color(0xFFF2B342),
                    ),
                    onPressed:
                        () => controller.updateListingStatus(
                          listing.id!,
                          listing.status == 'publish' ? 'draft' : 'publish',
                        ),
                    tooltip:
                        listing.status == 'publish'
                            ? 'Set to Draft'
                            : 'Publish',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      size: 18,
                      color: Color(0xFFF2B342),
                    ),
                    onPressed:
                        () => _showDeleteDialog(listing, controller, context),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
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
      if (controller.totalPages.value <= 1) return SizedBox.shrink();

      final currentPage = controller.currentPage.value;
      final totalPages = controller.totalPages.value;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // First page
          if (currentPage > 1)
            _buildPageButton("First", false, () => controller.goToPage(1)),

          SizedBox(width: 8),

          // Previous button
          if (currentPage > 1)
            _buildPageButton(
              "Previous",
              false,
              () => controller.goToPage(currentPage - 1),
            ),

          SizedBox(width: 8),

          // Page numbers
          for (
            int i = (currentPage - 2).clamp(1, totalPages);
            i <= (currentPage + 2).clamp(1, totalPages);
            i++
          )
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: _buildPageButton(
                i.toString(),
                i == currentPage,
                () => controller.goToPage(i),
              ),
            ),

          SizedBox(width: 8),

          // Next button
          if (currentPage < totalPages)
            _buildPageButton(
              "Next",
              false,
              () => controller.goToPage(currentPage + 1),
            ),

          SizedBox(width: 8),

          // Last page
          if (currentPage < totalPages)
            _buildPageButton(
              "Last",
              false,
              () => controller.goToPage(totalPages),
            ),
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
          color: isActive ? Color(0xFF364C63) : Colors.white,
          border: Border.all(color: Color(0xFF364C63)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Color(0xFF364C63),
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'publish':
        return Color(0xFFF2B342);
      case 'draft':
        return Color(0xFFF2B342);
      case 'pending':
        return Color(0xFFF2B342);
      case 'private':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  void _showEditDialog(
    UnifiedListing listing,
    AdminListingsController controller,
    BuildContext context,
  ) {
    final titleController = TextEditingController(text: listing.title);
    final contentController = TextEditingController(text: listing.cleanContent);
    final priceController = TextEditingController(text: listing.price);
    final emailController = TextEditingController(text: listing.email);
    final phoneController = TextEditingController(text: listing.phone);
    final addressController = TextEditingController(text: listing.address);

    Get.dialog(
      AlertDialog(
        title: Text("Edit Listing"),
        content: SingleChildScrollView(
          child: Container(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: "Title",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: "Price",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: "Phone",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: "Address",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final body = {
                'title': titleController.text.trim(),
                'content': contentController.text.trim(),
                'meta': {
                  '_price': priceController.text.trim(),
                  '_email': emailController.text.trim(),
                  '_phone': phoneController.text.trim(),
                  '_address': addressController.text.trim(),
                },
              };
              controller.updateListing(listing.id!, body);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFF2B342)),
            child: Text("Update", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    UnifiedListing listing,
    AdminListingsController controller,
    BuildContext context,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text("Delete Listing"),
        content: Text("Are you sure you want to delete '${listing.title}'?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              controller.deleteListing(listing.id!);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBulkDeleteDialog(
    AdminListingsController controller,
    BuildContext context,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text("Delete Listings"),
        content: Text(
          "Are you sure you want to delete ${controller.selectedListings.length} listing(s)?",
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              controller.deleteListings(List.from(controller.selectedListings));
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
