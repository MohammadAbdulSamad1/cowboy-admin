import 'package:dedicated_cow_boy_admin/app/modules/dashboard_manage/controllers/dashboard_manage_controller.dart'
    hide PieChartData, BarChartData;
import 'package:dedicated_cow_boy_admin/app/modules/pro.dart';
import 'package:dedicated_cow_boy_admin/app/modules/useraccounts.dart';
import 'package:dedicated_cow_boy_admin/app/new/auth_service.dart';
import 'package:dedicated_cow_boy_admin/main.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';

class DashboardManageView extends StatelessWidget {
  final DashboardManageController controller = Get.put(
    DashboardManageController(),
  );

  DashboardManageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            child: Column(
              children: [
                _buildHeader(context, constraints.maxWidth),
                _buildDashboardTitle(constraints.maxWidth),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildStatsCards(context),
                        _buildMainChartsSection(constraints.maxWidth),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isMobile(double width) => width < 600;

  Widget _buildHeader(BuildContext context, double screenWidth) {
    return const ProfileTopBar();
  }

  Widget _buildDashboardTitle(double screenWidth) {
    return SizedBox.shrink(); // Remove extra title
  }

  Widget _buildStatsCards(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.all(screenWidth < 600 ? 16 : 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount;
          double childAspectRatio;

          if (screenWidth < 600) {
            // Phones
            crossAxisCount = 2;
            childAspectRatio = 1.1;
          } else if (screenWidth < 900) {
            // Small tablets
            crossAxisCount = 2;
            childAspectRatio = 1.3;
          } else if (screenWidth < 1100) {
            // Large tablets / small laptops
            crossAxisCount = 3;
            childAspectRatio = 1;
          } else if (screenWidth < 1300) {
            // Large tablets / small laptops
            crossAxisCount = 3;
            childAspectRatio = 1.4;
          } else if (screenWidth < 1500) {
            // Large tablets / small laptops
            crossAxisCount = 3;
            childAspectRatio = 1.3;
          } else {
            // Desktops
            crossAxisCount = 4;
            childAspectRatio = 1.5;
          }

          return Obx(() {
            final stats = [
              {
                'title': 'Total Listings',
                'value': controller.totalListings.value,
                'icon': Icons.check_circle,
                'color': const Color(0xFFD3D3D3),
              },
              {
                'title': 'Registered Users',
                'value': controller.totalUsers.value,
                'icon': Icons.group,
                'color': const Color(0xFFD3D3D3),
              },
              {
                'title': 'Reported Listings',
                'value': controller.reportedListings.value,
                'icon': Icons.error_outline,
                'color': const Color(0xFFF2B342).withOpacity(0.57),
              },
              {
                'title': 'Ranch Services Posted',
                'value': controller.ranchServicesPosted.value,
                'icon': Icons.headset,
                'color': const Color(0xFFD3D3D3),
              },
            ];

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                final stat = stats[index];
                return _buildStatsCard(
                  stat['title'] as String,
                  '${stat['value']}',
                  stat['icon'] as IconData,
                  stat['color'] as Color,
                  screenWidth < 600, // pass true only for phones
                );
              },
            );
          });
        },
      ),
    );
  }

  Widget _buildMainChartsSection(double screenWidth) {
    final isMobile = _isMobile(screenWidth);
    final padding = isMobile ? 16.0 : 24.0;

    return Padding(
      padding: EdgeInsets.all(padding),
      child:
          isMobile
              ? Column(
                children: [
                  _buildLineChartCard(),
                  const SizedBox(height: 16),
                  _buildPieChartCard(),
                  const SizedBox(height: 16),
                  _buildBarChartCard(),
                ],
              )
              : Row(
                children: [
                  Expanded(flex: 2, child: _buildLineChartCard()),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildPieChartCard(),
                        const SizedBox(height: 16),
                        _buildBarChartCard(),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildLineChartCard() {
    return Container(
      height: 480,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Users & Listings over time',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(child: Obx(() => _buildDynamicLineChart())),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Users', Color(0xFFF2B342)),
              const SizedBox(width: 24),
              _buildLegendItem('Listings', Color(0xFF364C63)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Listing Distribution',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: Obx(() => _buildDynamicPieChart())),
        ],
      ),
    );
  }

  Widget _buildBarChartCard() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reports by category',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: Obx(() => _buildDynamicBarChart())),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    String title,
    String value,
    IconData icon,
    Color bgColor,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 16 : 20,
        horizontal: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Big Number
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 22 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),

          // Icon inside white circle
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black87, size: isMobile ? 16 : 20),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicLineChart() {
    if (controller.monthlyUserData.isEmpty &&
        controller.monthlyListingData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const months = [
                  'JAN',
                  'FEB',
                  'MAR',
                  'APR',
                  'MAY',
                  'JUN',
                  'JUL',
                  'AUG',
                  'SEP',
                  'OCT',
                  'NOV',
                  'DEC',
                ];
                if (value.toInt() >= 0 && value.toInt() < months.length) {
                  return Text(
                    months[value.toInt()],
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 11,
        minY: 0,
        maxY: _getMaxYValue(),
        lineBarsData: [
          LineChartBarData(
            spots:
                controller.monthlyUserData
                    .map((data) => FlSpot(data.x, data.y))
                    .toList(),
            isCurved: true,
            color: Color(0xFFF2B342),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
          ),
          LineChartBarData(
            spots:
                controller.monthlyListingData
                    .map((data) => FlSpot(data.x, data.y))
                    .toList(),
            isCurved: true,
            color: Color(0xFF364C63),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  double _getMaxYValue() {
    double maxUsers =
        controller.monthlyUserData.isNotEmpty
            ? controller.monthlyUserData
                .map((e) => e.y)
                .reduce((a, b) => a > b ? a : b)
            : 0;
    double maxListings =
        controller.monthlyListingData.isNotEmpty
            ? controller.monthlyListingData
                .map((e) => e.y)
                .reduce((a, b) => a > b ? a : b)
            : 0;
    return (maxUsers > maxListings ? maxUsers : maxListings) + 20;
  }

  Widget _buildDynamicPieChart() {
    if (controller.listingDistribution.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalValue = controller.listingDistribution
        .map((e) => e.value)
        .reduce((a, b) => a + b);

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections:
                  controller.listingDistribution.map((data) {
                    final percentage =
                        totalValue > 0 ? (data.value / totalValue * 100) : 0;
                    return PieChartSectionData(
                      color: Color(data.color),
                      value: data.value,
                      title: '${percentage.toInt()}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              controller.listingDistribution
                  .map(
                    (data) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildLegendItem(data.label, Color(data.color)),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildDynamicBarChart() {
    if (controller.reportsByCategory.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final maxValue = controller.reportsByCategory
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue + 20,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < controller.reportsByCategory.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      controller.reportsByCategory[index].label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups:
            controller.reportsByCategory.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: data.value,
                    color: Color(data.color),
                    width: 32,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
