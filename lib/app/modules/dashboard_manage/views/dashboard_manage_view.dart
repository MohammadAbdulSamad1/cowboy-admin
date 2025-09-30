import 'package:dedicated_cow_boy_admin/app/modules/dashboard_manage/controllers/dashboard_manage_controller.dart'
    hide PieChartData, BarChartData;
import 'package:dedicated_cow_boy_admin/app/modules/pro.dart';
import 'package:dedicated_cow_boy_admin/app/new/auth_service.dart';
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
                        _buildStatsCards(constraints.maxWidth),
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

  double _getResponsivePadding(double width) {
    if (width < 600) return 8;
    if (width < 1200) return 16;
    return 24;
  }

  bool _isMobile(double width) => width < 600;
  bool _isTablet(double width) => width >= 600 && width < 1200;
  bool _isDesktop(double width) => width >= 1200;

  Widget _buildHeader(BuildContext context, double screenWidth) {
    final isMobile = _isMobile(screenWidth);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Dashboard',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'profile') {
                Get.dialog(
                  Material(
                    type: MaterialType.transparency,
                    color: Colors.transparent,
                    child: Center(
                      child: SizedBox(
                        width: 800,
                        height: 1500,
                        child: ProfileDialog(),
                      ),
                    ),
                  ),
                );
              } else if (value == 'logout') {
                final authService = Get.find<AuthService>();
                await authService.signOut();
                Get.offAllNamed('/auth');
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            offset: const Offset(0, 50),
            elevation: 8,
            color: Color(0xFFF2B342),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'My Profile',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text('Logout', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFFF2B342),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'My Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTitle(double screenWidth) {
    return SizedBox.shrink(); // Remove extra title
  }

  Widget _buildStatsCards(double screenWidth) {
    final isMobile = _isMobile(screenWidth);
    final isTablet = _isTablet(screenWidth);

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount;
          double childAspectRatio;

          if (isMobile) {
            crossAxisCount = 2;
            childAspectRatio = 1.1;
          } else if (isTablet) {
            crossAxisCount = 2;
            childAspectRatio = 1.5;
          } else {
            crossAxisCount = 4;
            childAspectRatio = 1.8;
          }

          return Obx(() {
            final stats = [
              {
                'title': 'Total Listings',
                'value': controller.totalListings.value,
                'icon': Icons.check_circle,
                'color': const Color(0xFFD3D3D3), // Light gray
              },
              {
                'title': 'Registered Users',
                'value': controller.totalUsers.value,
                'icon': Icons.group,
                'color': const Color(0xFFD3D3D3), // Light gray
              },
              {
                'title': 'Reported Listings',
                'value': controller.reportedListings.value,
                'icon': Icons.remove_red_eye,
                'color': const Color(0xFFF2B342), // Orange/Yellow
              },
              {
                'title': 'Ranch Services\nPosted',
                'value': controller.ranchServicesPosted.value,
                'icon': Icons.headset,
                'color': const Color(0xFFD3D3D3), // Light gray
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
                  isMobile,
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
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.black54,
                  size: isMobile ? 16 : 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
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
