import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardManageController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable variables for dashboard stats
  var isLoading = true.obs;
  var totalListings = 0.obs;
  var totalUsers = 0.obs;
  var totalReports = 0.obs;
  var totalRanchServices = 0.obs;
  var totalBusinesses = 0.obs;
  var totalEvents = 0.obs;
  var totalItems = 0.obs;
  var totalAdmins = 0.obs;
  var totalSubscriptions = 0.obs;
  var totalNotifications = 0.obs;
  var totalChatRooms = 0.obs;
  var totalFavorites = 0.obs;

  // Chart data
  var monthlyUserData = <ChartData>[].obs;
  var monthlyListingData = <ChartData>[].obs;
  var listingDistribution = <PieChartData>[].obs;
  var reportsByCategory = <BarChartData>[].obs;
  var recentActivities = <ActivityData>[].obs;
  var topUsers = <UserStats>[].obs;
  var subscriptionStats = <SubscriptionStats>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
    // Set up real-time listeners
    setupRealtimeListeners();
  }

  void loadDashboardData() async {
    isLoading(true);
    try {
      await Future.wait([
        loadBasicStats(),
        loadChartData(),
        loadRecentActivities(),
        loadTopUsers(),
        loadSubscriptionStats(),
      ]);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load dashboard data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> loadBasicStats() async {
    try {
      // Get all counts in parallel for better performance
      final futures = [
        _firestore.collection('users').get(),
        _firestore.collection('items').get(),
        _firestore.collection('events').get(),
        _firestore.collection('businesses').get(),
        _firestore.collection('admins').get(),
        _firestore.collection('user_subscriptions').get(),
        _firestore.collection('notifications').get(),
        _firestore.collection('chatRooms').get(),
        _firestore.collection('favorites').get(),
        // Add reports when table is created
        // _firestore.collection('reports').get(),
      ];

      final results = await Future.wait(futures);

      totalUsers(results[0].docs.length);
      totalItems(results[1].docs.length);
      totalEvents(results[2].docs.length);
      totalBusinesses(results[3].docs.length);
      totalAdmins(results[4].docs.length);
      totalSubscriptions(results[5].docs.length);
      totalNotifications(results[6].docs.length);
      totalChatRooms(results[7].docs.length);
      totalFavorites(results[8].docs.length);

      // Calculate total listings
      totalListings(
        totalItems.value + totalEvents.value + totalBusinesses.value,
      );

      // Placeholder for reports - update when table is created
      totalReports(15); // Temporary static value

      // Ranch services from businesses (filter by category if needed)
      totalRanchServices(45); // Update based on your business logic
    } catch (e) {
      print('Error loading basic stats: $e');
    }
  }

  Future<void> loadChartData() async {
    try {
      await Future.wait([
        loadMonthlyData(),
        loadListingDistribution(),
        loadReportsByCategory(),
      ]);
    } catch (e) {
      print('Error loading chart data: $e');
    }
  }

  Future<void> loadMonthlyData() async {
    try {
      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);

      // Get users registered this year
      final usersQuery =
          await _firestore
              .collection('users')
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear),
              )
              .get();

      // Get listings created this year
      final itemsQuery =
          await _firestore
              .collection('items')
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear),
              )
              .get();

      final eventsQuery =
          await _firestore
              .collection('events')
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear),
              )
              .get();

      final businessesQuery =
          await _firestore
              .collection('businesses')
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear),
              )
              .get();

      // Process monthly user data
      Map<int, int> monthlyUsers = {};
      Map<int, int> monthlyListings = {};

      for (var doc in usersQuery.docs) {
        final data = doc.data();
        if (data['createdAt'] != null) {
          final createdAt = (data['createdAt'] as Timestamp).toDate();
          final month = createdAt.month;
          monthlyUsers[month] = (monthlyUsers[month] ?? 0) + 1;
        }
      }

      // Process monthly listing data
      final allListings = [
        ...itemsQuery.docs,
        ...eventsQuery.docs,
        ...businessesQuery.docs,
      ];
      for (var doc in allListings) {
        final data = doc.data();
        if (data['createdAt'] != null) {
          final createdAt = (data['createdAt'] as Timestamp).toDate();
          final month = createdAt.month;
          monthlyListings[month] = (monthlyListings[month] ?? 0) + 1;
        }
      }

      // Convert to chart data
      monthlyUserData.assignAll(
        List.generate(12, (index) {
          return ChartData(
            index.toDouble(),
            (monthlyUsers[index + 1] ?? 0).toDouble(),
          );
        }),
      );

      monthlyListingData.assignAll(
        List.generate(12, (index) {
          return ChartData(
            index.toDouble(),
            (monthlyListings[index + 1] ?? 0).toDouble(),
          );
        }),
      );
    } catch (e) {
      print('Error loading monthly data: $e');
    }
  }

  Future<void> loadListingDistribution() async {
    try {
      listingDistribution.assignAll([
        PieChartData('Items', totalItems.value.toDouble(), 0xff364C63),
        PieChartData('Business', totalBusinesses.value.toDouble(), 0xff0E8F07),
        PieChartData('Events', totalEvents.value.toDouble(), 0xFFF2B342),
      ]);
    } catch (e) {
      print('Error loading listing distribution: $e');
    }
  }

  Future<void> loadReportsByCategory() async {
    try {
      // This will be updated when reports table is created
      // For now, using mock data based on your existing design
      reportsByCategory.assignAll([
        BarChartData('Business', 40, 0xff0E8F07),
        BarChartData('Events', 65, 0xFFF2B342),
        BarChartData('Items', 85, 0xff364C63),
      ]);
    } catch (e) {
      print('Error loading reports by category: $e');
    }
  }

  Future<void> loadRecentActivities() async {
    try {
      final recentUsersQuery =
          await _firestore
              .collection('users')
              .orderBy('createdAt', descending: true)
              .limit(5)
              .get();

      final recentItemsQuery =
          await _firestore
              .collection('items')
              .orderBy('createdAt', descending: true)
              .limit(3)
              .get();

      List<ActivityData> activities = [];

      // Add user activities
      for (var doc in recentUsersQuery.docs) {
        final data = doc.data();
        // final createdAtStr = data['createdAt'].toString();
        // final createdAt = DateTime.parse(createdAtStr);

        activities.add(
          ActivityData(
            title: 'New user registered',
            subtitle: data['displayName'] ?? 'Unknown User',
            timestamp: null,
            type: ActivityType.user,
          ),
        );
      }

      // Add listing activities
      for (var doc in recentItemsQuery.docs) {
        final data = doc.data();
        // final createdAtStr = data['createdAt'].toString();
        // final createdAt = DateTime.parse(createdAtStr);

        activities.add(
          ActivityData(
            title: 'New item listed',
            subtitle: data['title'] ?? 'Unknown Item',
            timestamp: null,
            type: ActivityType.listing,
          ),
        );
      }

      // Sort by timestamp
      activities.sort((a, b) {
        if (a.timestamp == null && b.timestamp == null) return 0;
        if (a.timestamp == null) return 1;
        if (b.timestamp == null) return -1;
        return b.timestamp!.compareTo(a.timestamp!);
      });

      recentActivities.assignAll(activities.take(10).toList());
    } catch (e) {
      print('Error loading recent activities: $e');
    }
  }

  Future<void> loadTopUsers() async {
    try {
      // Get users with most listings
      final usersQuery = await _firestore.collection('users').get();
      List<UserStats> userStatsList = [];

      for (var userDoc in usersQuery.docs) {
        final userData = userDoc.data();
        final userId = userDoc.id;

        // Count user's listings
        final itemsCount =
            await _firestore
                .collection('items')
                .where('userId', isEqualTo: userId)
                .get();

        final eventsCount =
            await _firestore
                .collection('events')
                .where('userId', isEqualTo: userId)
                .get();

        final businessesCount =
            await _firestore
                .collection('businesses')
                .where('userId', isEqualTo: userId)
                .get();

        final totalListings =
            itemsCount.docs.length +
            eventsCount.docs.length +
            businessesCount.docs.length;

        if (totalListings > 0) {
          userStatsList.add(
            UserStats(
              id: userId,
              name: userData['displayName'] ?? 'Unknown User',
              email: userData['email'] ?? '',
              listingsCount: totalListings,
              avatar: userData['avatar'] ?? '',
            ),
          );
        }
      }

      // Sort by listings count and take top 10
      userStatsList.sort((a, b) => b.listingsCount.compareTo(a.listingsCount));
      topUsers.assignAll(userStatsList.take(10).toList());
    } catch (e) {
      print('Error loading top users: $e');
    }
  }

  Future<void> loadSubscriptionStats() async {
    try {
      final subscriptionsQuery =
          await _firestore.collection('user_subscriptions').get();

      Map<String, int> planCounts = {};
      int activeSubscriptions = 0;
      double totalRevenue = 0.0;

      for (var doc in subscriptionsQuery.docs) {
        final data = doc.data();
        final planType = data['planType'] ?? 'Unknown';
        planCounts[planType] = (planCounts[planType] ?? 0) + 1;

        // Check if subscription is active (you may need to adjust this logic)
        final endDate = data['endDate'] as Timestamp?;
        if (endDate != null && endDate.toDate().isAfter(DateTime.now())) {
          activeSubscriptions++;
          // Add revenue calculation if you have price data
          totalRevenue += data['amount']?.toDouble() ?? 0.0;
        }
      }

      List<SubscriptionStats> stats = [];
      planCounts.forEach((plan, count) {
        stats.add(
          SubscriptionStats(
            planName: plan,
            count: count,
            percentage: (count / subscriptionsQuery.docs.length * 100),
          ),
        );
      });

      subscriptionStats.assignAll(stats);
    } catch (e) {
      print('Error loading subscription stats: $e');
    }
  }

  void setupRealtimeListeners() {
    // Listen to users collection changes
    _firestore.collection('users').snapshots().listen((snapshot) {
      totalUsers(snapshot.docs.length);
    });

    // Listen to items collection changes
    _firestore.collection('items').snapshots().listen((snapshot) {
      totalItems(snapshot.docs.length);
      updateTotalListings();
    });

    // Listen to events collection changes
    _firestore.collection('events').snapshots().listen((snapshot) {
      totalEvents(snapshot.docs.length);
      updateTotalListings();
    });

    // Listen to businesses collection changes
    _firestore.collection('businesses').snapshots().listen((snapshot) {
      totalBusinesses(snapshot.docs.length);
      updateTotalListings();
    });

    // Add more listeners as needed
  }

  void updateTotalListings() {
    totalListings(totalItems.value + totalEvents.value + totalBusinesses.value);
    // Update listing distribution
    loadListingDistribution();
  }

  void refreshDashboard() {
    loadDashboardData();
  }

  // Utility methods for filtering data
  Future<List<Map<String, dynamic>>> getFilteredData(
    String collection,
    String field,
    dynamic value,
  ) async {
    final query =
        await _firestore
            .collection(collection)
            .where(field, isEqualTo: value)
            .get();
    return query.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> getDataByDateRange(
    String collection,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final query =
        await _firestore
            .collection(collection)
            .where(
              'createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where(
              'createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate),
            )
            .get();
    return query.docs.map((doc) => doc.data()).toList();
  }
}

// Data models for charts and analytics
class ChartData {
  final double x;
  final double y;

  ChartData(this.x, this.y);
}

class PieChartData {
  final String label;
  final double value;
  final int color;

  PieChartData(this.label, this.value, this.color);
}

class BarChartData {
  final String label;
  final double value;
  final int color;

  BarChartData(this.label, this.value, this.color);
}

class ActivityData {
  final String title;
  final String subtitle;
  final DateTime? timestamp;
  final ActivityType type;

  ActivityData({
    required this.title,
    required this.subtitle,
    this.timestamp,
    required this.type,
  });
}

enum ActivityType { user, listing, business, event, report, admin }

class UserStats {
  final String id;
  final String name;
  final String email;
  final int listingsCount;
  final String avatar;

  UserStats({
    required this.id,
    required this.name,
    required this.email,
    required this.listingsCount,
    required this.avatar,
  });
}

class SubscriptionStats {
  final String planName;
  final int count;
  final double percentage;

  SubscriptionStats({
    required this.planName,
    required this.count,
    required this.percentage,
  });
}
