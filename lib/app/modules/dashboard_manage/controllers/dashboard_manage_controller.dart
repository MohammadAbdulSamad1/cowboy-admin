import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DashboardManageController extends GetxController {
  final String baseUrl = 'https://dedicatedcowboy.com/wp-json/wp/v2';

  // Observable variables for dashboard stats (only from image)
  var isLoading = true.obs;
  var totalListings = 0.obs;
  var totalUsers = 0.obs;
  var reportedListings = 0.obs;
  var ranchServicesPosted = 0.obs;

  // Chart data (only from image)
  var monthlyUserData = <ChartData>[].obs;
  var monthlyListingData = <ChartData>[].obs;
  var listingDistribution = <PieChartData>[].obs;
  var reportsByCategory = <BarChartData>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  void loadDashboardData() async {
    isLoading(true);
    try {
      await loadStatisticsFromAPI();
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

  Future<void> loadStatisticsFromAPI() async {
    try {
      const username = "18XLegend";
      const appPassword = "O9px KmDk isTg PgaW wysH FqL6";
      final basicAuth =
          'Basic ${base64Encode(utf8.encode('$username:$appPassword'))}';
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard_statistics'),
        headers: {'Authorization': basicAuth, 'Accept': 'application/json'},
      );


      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Update summary stats
        totalListings(data['summary']['total_listings'] ?? 0);
        totalUsers(data['summary']['registered_users'] ?? 0);
        reportedListings(data['summary']['reported_listings'] ?? 15);
        ranchServicesPosted(data['summary']['ranch_services_posted'] ?? 45);

        // Update monthly chart data
        List<ChartData> userChartData = [];
        List<ChartData> listingChartData = [];

        for (var item in data['monthly_data']['users']) {
          userChartData.add(
            ChartData(item['month'].toDouble(), item['count'].toDouble()),
          );
        }

        for (var item in data['monthly_data']['listings']) {
          listingChartData.add(
            ChartData(item['month'].toDouble(), item['count'].toDouble()),
          );
        }

        monthlyUserData.assignAll(userChartData);
        monthlyListingData.assignAll(listingChartData);

        // Update listing distribution (pie chart)
        final distribution = data['listing_distribution'];
        listingDistribution.assignAll([
          PieChartData(
            'Items',
            distribution['items'].toDouble(),
            0xff364C63, // Dark blue
          ),
          PieChartData(
            'Business',
            distribution['business'].toDouble(),
            0xff0E8F07, // Green
          ),
          PieChartData(
            'Events',
            distribution['events'].toDouble(),
            0xFFF2B342, // Orange/Yellow
          ),
        ]);

        // Update reports by category (bar chart)
        final reports = data['reports_by_category'];
        reportsByCategory.assignAll([
          BarChartData(
            'Business',
            reports['business'].toDouble(),
            0xff0E8F07, // Green
          ),
          BarChartData(
            'Events',
            reports['events'].toDouble(),
            0xFFF2B342, // Orange/Yellow
          ),
          BarChartData(
            'Items',
            reports['items'].toDouble(),
            0xff364C63, // Dark blue
          ),
        ]);
      } else {
        throw Exception('Failed to load statistics: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading statistics: $e');
      rethrow;
    }
  }

  void refreshDashboard() {
    loadDashboardData();
  }
}

// Data models for charts
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
