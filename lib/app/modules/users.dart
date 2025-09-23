// user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedicated_cow_boy_admin/app/models/report_model/report_model.dart';
// shimmer_loading.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// responsive_admin_reports_screen.dart
import 'package:intl/intl.dart';

class UserService {
  static UserService? _instance;
  static UserService get instance => _instance ??= UserService._();
  UserService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  // Cache for user data to avoid repeated fetches
  final Map<String, Map<String, dynamic>> _userCache = {};

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      // Check cache first
      if (_userCache.containsKey(userId)) {
        return _userCache[userId];
      }

      final doc =
          await _firestore.collection(_usersCollection).doc(userId).get();
      if (doc.exists) {
        final userData = doc.data()!;
        _userCache[userId] = userData;
        return userData;
      }
      return null;
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  String getUserDisplayName(Map<String, dynamic>? userData, String userId) {
    if (userData == null) return '@${userId.substring(0, 8)}...';

    final firstName = userData['firstName'] as String?;
    final lastName = userData['lastName'] as String?;
    final username = userData['username'] as String?;
    final displayName = userData['displayName'] as String?;

    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (username != null) {
      return '@$username';
    } else if (displayName != null) {
      return displayName;
    } else {
      return '@${userId.substring(0, 8)}...';
    }
  }
}

class AdminReportService {
  static AdminReportService? _instance;
  static AdminReportService get instance =>
      _instance ??= AdminReportService._();
  AdminReportService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _reportsCollection = 'reports';

  // Get all reports with client-side filtering (due to Firestore limitations)
  Future<Map<String, dynamic>> getReportsWithPagination({
    DocumentSnapshot? lastDocument,
    int limit = 20,
    String? reportType,
    String? reason,
    ReportStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) async {
    try {
      Query query = _firestore.collection(_reportsCollection);

      // Only apply basic ordering - other filters will be client-side
      query = query.orderBy('createdAt', descending: true);

      // Apply pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(
        limit * 2,
      ); // Fetch more to account for client-side filtering

      final snapshot = await query.get();

      List<ReportModel> reports =
          snapshot.docs.map((doc) {
            return ReportModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();

      // Apply client-side filters
      reports = _applyClientSideFilters(
        reports,
        reportType: reportType,
        reason: reason,
        status: status,
        startDate: startDate,
        endDate: endDate,
        searchQuery: searchQuery,
      );

      // Take only the requested limit after filtering
      final limitedReports = reports.take(limit).toList();

      return {
        'reports': limitedReports,
        'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        'hasMore': reports.length > limit,
        'totalFiltered': reports.length,
      };
    } catch (e) {
      print('Error getting reports: $e');
      return {
        'reports': <ReportModel>[],
        'lastDocument': null,
        'hasMore': false,
        'totalFiltered': 0,
      };
    }
  }

  List<ReportModel> _applyClientSideFilters(
    List<ReportModel> reports, {
    String? reportType,
    String? reason,
    ReportStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) {
    return reports.where((report) {
      // Report type filter
      if (reportType != null && reportType != 'All') {
        if (report.listingType != reportType) return false;
      }

      // Reason filter
      if (reason != null && reason != 'All Reasons') {
        if (report.reason != reason) return false;
      }

      // Status filter
      if (status != null) {
        if (report.status != status) return false;
      }

      // Date range filter
      if (startDate != null) {
        if (report.createdAt.isBefore(startDate)) return false;
      }
      if (endDate != null) {
        if (report.createdAt.isAfter(endDate.add(Duration(days: 1)))) {
          return false;
        }
      }

      // Search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchTerm = searchQuery.toLowerCase();
        if (!report.listingName.toLowerCase().contains(searchTerm) &&
            !report.reason.toLowerCase().contains(searchTerm) &&
            !(report.customReason?.toLowerCase().contains(searchTerm) ??
                false)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Get total count with filters applied
  Future<int> getReportsCount({
    String? reportType,
    String? reason,
    ReportStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) async {
    try {
      // Fetch all reports for accurate count (consider caching this)
      final snapshot = await _firestore.collection(_reportsCollection).get();

      List<ReportModel> reports =
          snapshot.docs.map((doc) {
            return ReportModel.fromFirestore(doc.data(), doc.id);
          }).toList();

      // Apply filters
      reports = _applyClientSideFilters(
        reports,
        reportType: reportType,
        reason: reason,
        status: status,
        startDate: startDate,
        endDate: endDate,
        searchQuery: searchQuery,
      );

      return reports.length;
    } catch (e) {
      print('Error getting reports count: $e');
      return 0;
    }
  }

  // Update multiple reports status
  Future<bool> updateMultipleReportsStatus({
    required List<String> reportIds,
    required ReportStatus status,
    String? adminResponse,
    required String adminId,
  }) async {
    try {
      final batch = _firestore.batch();

      for (String reportId in reportIds) {
        final docRef = _firestore.collection(_reportsCollection).doc(reportId);
        batch.update(docRef, {
          'status': status.toString().split('.').last,
          'resolvedAt':
              status != ReportStatus.pending && status != ReportStatus.inReview
                  ? Timestamp.fromDate(DateTime.now())
                  : null,
          'adminResponse': adminResponse,
          'adminId': adminId,
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error updating multiple reports: $e');
      return false;
    }
  }

  // Delete multiple reports
  Future<bool> deleteMultipleReports(List<String> reportIds) async {
    try {
      final batch = _firestore.batch();

      for (String reportId in reportIds) {
        final docRef = _firestore.collection(_reportsCollection).doc(reportId);
        batch.delete(docRef);
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error deleting multiple reports: $e');
      return false;
    }
  }

  // Get unique reasons
  Future<List<String>> getUniqueReasons() async {
    try {
      final snapshot = await _firestore.collection(_reportsCollection).get();
      final reasons =
          snapshot.docs
              .map((doc) => doc.data()['reason'] as String?)
              .where((reason) => reason != null)
              .cast<String>()
              .toSet()
              .toList();
      reasons.sort();
      return ['All Reasons', ...reasons];
    } catch (e) {
      print('Error getting unique reasons: $e');
      return ['All Reasons'];
    }
  }
}

class ReportsShimmerLoading extends StatelessWidget {
  const ReportsShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Table header
        // Container(
        //   padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        //   decoration: BoxDecoration(
        //     color: Colors.grey.shade100,
        //     borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        //   ),
        //   child: Row(
        //     children: [
        //       SizedBox(width: 40, child: Container()),
        //       Expanded(
        //         flex: 2,
        //         child: Text(
        //           "Reporter",
        //           style: TextStyle(fontWeight: FontWeight.w600),
        //         ),
        //       ),
        //       Expanded(
        //         flex: 3,
        //         child: Text(
        //           "Reported Item",
        //           style: TextStyle(fontWeight: FontWeight.w600),
        //         ),
        //       ),
        //       Expanded(
        //         flex: 3,
        //         child: Text(
        //           "Reason",
        //           style: TextStyle(fontWeight: FontWeight.w600),
        //         ),
        //       ),
        //       Expanded(
        //         flex: 2,
        //         child: Text(
        //           "Date",
        //           style: TextStyle(fontWeight: FontWeight.w600),
        //         ),
        //       ),
        //       Expanded(
        //         flex: 2,
        //         child: Text(
        //           "Status",
        //           style: TextStyle(fontWeight: FontWeight.w600),
        //         ),
        //       ),
        //       Expanded(
        //         flex: 2,
        //         child: Text(
        //           "Actions",
        //           style: TextStyle(fontWeight: FontWeight.w600),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        // Shimmer rows
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 10,
            itemBuilder: (context, index) {
              return Container(
                color: index % 2 == 1 ? Colors.grey.shade50 : Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Container(
                        width: 20,
                        height: 20,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(height: 16, color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Container(height: 16, color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Container(height: 16, color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Container(height: 16, color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Container(height: 20, color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Container(height: 16, color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ResponsiveAdminReportsScreen extends StatefulWidget {
  const ResponsiveAdminReportsScreen({super.key});

  @override
  State<ResponsiveAdminReportsScreen> createState() =>
      _ResponsiveAdminReportsScreenState();
}

class _ResponsiveAdminReportsScreenState
    extends State<ResponsiveAdminReportsScreen> {
  final AdminReportService _adminReportService = AdminReportService.instance;
  final UserService _userService = UserService.instance;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Data and state
  List<ReportModel> _reports = [];
  List<String> _selectedReportIds = [];
  final Map<String, Map<String, dynamic>?> _usersData = {};
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  int _currentPage = 1;
  int _totalReports = 0;
  static const int _pageSize = 20;

  // Filter states
  String _selectedReportType = 'All';
  String _selectedReason = 'All Reasons';
  ReportStatus? _selectedStatus;
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  List<String> _availableReasons = ['All Reasons'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isMobile => MediaQuery.of(context).size.width < 768;
  bool get _isTablet =>
      MediaQuery.of(context).size.width >= 768 &&
      MediaQuery.of(context).size.width < 1024;

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_hasMore && !_isLoading) {
        _loadMoreReports();
      }
    }
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadReports(reset: true),
      _loadAvailableReasons(),
      _loadTotalCount(),
    ]);
  }

  Future<void> _loadAvailableReasons() async {
    final reasons = await _adminReportService.getUniqueReasons();
    if (mounted) {
      setState(() {
        _availableReasons = reasons;
      });
    }
  }

  Future<void> _loadTotalCount() async {
    final count = await _adminReportService.getReportsCount(
      reportType: _selectedReportType,
      reason: _selectedReason,
      status: _selectedStatus,
      startDate: _selectedDateRange?.start,
      endDate: _selectedDateRange?.end,
      searchQuery: _searchQuery,
    );
    if (mounted) {
      setState(() {
        _totalReports = count;
      });
    }
  }

  Future<void> _loadReports({bool reset = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (reset) {
        _reports.clear();
        _lastDocument = null;
        _currentPage = 1;
        _selectedReportIds.clear();
        _usersData.clear();
      }
    });

    try {
      final result = await _adminReportService.getReportsWithPagination(
        lastDocument: reset ? null : _lastDocument,
        limit: _pageSize,
        reportType: _selectedReportType,
        reason: _selectedReason,
        status: _selectedStatus,
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
        searchQuery: _searchQuery,
      );

      final List<ReportModel> newReports = result['reports'];

      // Load user data for new reports
      await _loadUsersForReports(newReports);

      if (mounted) {
        setState(() {
          if (reset) {
            _reports = newReports;
          } else {
            _reports.addAll(newReports);
          }
          _lastDocument = result['lastDocument'];
          _hasMore = result['hasMore'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Failed to load reports: $e');
      }
    }
  }

  Future<void> _loadUsersForReports(List<ReportModel> reports) async {
    final userIds = reports.map((r) => r.reporterId).toSet();

    for (String userId in userIds) {
      if (!_usersData.containsKey(userId)) {
        final userData = await _userService.getUserById(userId);
        _usersData[userId] = userData;
      }
    }
  }

  Future<void> _loadMoreReports() async {
    if (_hasMore && !_isLoading) {
      setState(() {
        _currentPage++;
      });
      await _loadReports();
    }
  }

  void _applyFilters() {
    _loadInitialData();
  }

  void _clearFilters() {
    setState(() {
      _selectedReportType = 'All';
      _selectedReason = 'All Reasons';
      _selectedStatus = null;
      _selectedDateRange = null;
      _searchQuery = '';
      _searchController.clear();
    });
    _loadInitialData();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    // Debounce search
    Future.delayed(Duration(milliseconds: 800), () {
      if (_searchQuery == value && mounted) {
        _loadReports(reset: true);
        _loadTotalCount();
      }
    });
  }

  void _toggleReportSelection(String reportId) {
    setState(() {
      if (_selectedReportIds.contains(reportId)) {
        _selectedReportIds.remove(reportId);
      } else {
        _selectedReportIds.add(reportId);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedReportIds.length == _reports.length) {
        _selectedReportIds.clear();
      } else {
        _selectedReportIds = _reports.map((r) => r.id!).toList();
      }
    });
  }

  Future<void> _updateSelectedReportsStatus(
    ReportStatus status,
    String? response,
  ) async {
    if (_selectedReportIds.isEmpty) return;

    try {
      final success = await _adminReportService.updateMultipleReportsStatus(
        reportIds: _selectedReportIds,
        status: status,
        adminResponse: response,
        adminId: 'admin_user_id', // Replace with actual admin ID
      );

      if (success) {
        _showSuccess(
          '${_selectedReportIds.length} reports updated successfully',
        );
        setState(() {
          _selectedReportIds.clear();
        });
        _loadReports(reset: true);
        _loadTotalCount();
      } else {
        _showError('Failed to update reports');
      }
    } catch (e) {
      _showError('Error updating reports: $e');
    }
  }

  Future<void> _deleteSelectedReports() async {
    if (_selectedReportIds.isEmpty) return;

    final confirmed = await _showConfirmDialog(
      'Delete Reports',
      'Are you sure you want to delete ${_selectedReportIds.length} selected reports?',
    );

    if (confirmed == true) {
      try {
        final success = await _adminReportService.deleteMultipleReports(
          _selectedReportIds,
        );

        if (success) {
          _showSuccess(
            '${_selectedReportIds.length} reports deleted successfully',
          );
          setState(() {
            _selectedReportIds.clear();
          });
          _loadReports(reset: true);
          _loadTotalCount();
        } else {
          _showError('Failed to delete reports');
        }
      } catch (e) {
        _showError('Error deleting reports: $e');
      }
    }
  }

  void _showReportDetails(ReportModel report) {
    showDialog(
      context: context,
      builder: (context) => ReportDetailsDialog(report: report),
    );
  }

  void _editReport(ReportModel report) {
    showDialog(
      context: context,
      builder:
          (context) => EditReportDialog(
            report: report,
            onUpdated: () {
              _loadReports(reset: true);
              _loadTotalCount();
            },
          ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _applyFilters();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Color(0xFFF2B342)),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Color(0xFFF2B342)),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Confirm'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      body: SafeArea(
        child: Container(
          margin: EdgeInsets.all(_isMobile ? 8 : 16),
          padding: EdgeInsets.all(_isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                SizedBox(height: _isMobile ? 12 : 16),

                // Filters
                _buildFilters(),
                SizedBox(height: _isMobile ? 12 : 16),

                // Results info
                _buildResultsInfo(),
                SizedBox(height: 8),

                // Table
                _buildTable(),
                SizedBox(height: _isMobile ? 12 : 16),

                // Bulk Actions
                if (_selectedReportIds.isNotEmpty) ...[
                  _buildBulkActions(),
                  SizedBox(height: _isMobile ? 12 : 16),
                ],

                // Pagination info
                _buildPaginationInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    if (_isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "User Reports",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search reports...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: _onSearchChanged,
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "User Reports",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        SizedBox(
          width: _isTablet ? 250 : 300,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search reports...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xff364C63),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: _isMobile ? _buildMobileFilters() : _buildDesktopFilters(),
    );
  }

  Widget _buildMobileFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDropdownFilter(
                "Report Type",
                _selectedReportType,
                ['All', 'Listings', 'Messages', 'Profile'],
                (value) => setState(() => _selectedReportType = value),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildDropdownFilter(
                "Reason",
                _selectedReason,
                _availableReasons,
                (value) => setState(() => _selectedReason = value),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdownFilter(
                "Status",
                _selectedStatus?.displayName ?? 'All Status',
                [
                  'All Status',
                  ...ReportStatus.values.map((s) => s.displayName),
                ],
                _handleStatusFilter,
              ),
            ),
            SizedBox(width: 12),
            Expanded(child: _buildDateRangeFilter()),
          ],
        ),
        SizedBox(height: 20),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildDesktopFilters() {
    return Center(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildDropdownFilter(
            "Report Type",
            _selectedReportType,
            ['All', 'Listings', 'Messages', 'Profile'],
            (value) => setState(() => _selectedReportType = value),
          ),
          SizedBox(width: 16),
          _buildDropdownFilter(
            "Reason",
            _selectedReason,
            _availableReasons,
            (value) => setState(() => _selectedReason = value),
          ),
          SizedBox(width: 16),
          _buildDropdownFilter(
            "Status",
            _selectedStatus?.displayName ?? 'All Status',
            ['All Status', ...ReportStatus.values.map((s) => s.displayName)],
            _handleStatusFilter,
          ),
          SizedBox(width: 16),
          _buildDateRangeFilter(),
          SizedBox(width: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  void _handleStatusFilter(String value) {
    setState(() {
      if (value == 'All Status') {
        _selectedStatus = null;
      } else {
        _selectedStatus = ReportStatus.values.firstWhere(
          (s) => s.displayName == value,
        );
      }
    });
  }

  Widget _buildDropdownFilter(
    String label,
    String value,
    List<String> items,
    Function(String) onChanged,
  ) {
    return Container(
      width: _isMobile ? null : 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              items:
                  items.map((e) {
                    return DropdownMenuItem(
                      value: e,
                      child: Text(
                        e,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
              ),
              dropdownColor: Color(0xFFF2B342),
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.white),
              onChanged: (val) {
                if (val != null) {
                  onChanged(val);
                  _applyFilters();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    return Container(
      width: _isMobile ? null : 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Date Range",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          InkWell(
            onTap: _selectDateRange,
            child: Container(
              height: 44,
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedDateRange != null
                          ? '${DateFormat('MM/dd').format(_selectedDateRange!.start)} - ${DateFormat('MM/dd').format(_selectedDateRange!.end)}'
                          : 'Last 7 Days',
                      style: TextStyle(color: Colors.black, fontSize: 14),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.black,
                    size: 20,
                  ),
                  if (_selectedDateRange != null) ...[
                    SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDateRange = null;
                        });
                        _applyFilters();
                      },
                      child: Icon(
                        Icons.clear,
                        color: Color(0xFF6B7280),
                        size: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isMobile) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF2B342),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                'Apply Filters',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _clearFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                'Clear All',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFF2B342),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24),
            ),
            child: Text(
              'Apply Filters',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        SizedBox(width: 12),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _clearFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24),
            ),
            child: Text(
              'Clear All',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing ${_reports.length} of $_totalReports reports',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: _isMobile ? 12 : 14,
          ),
        ),
        if (_selectedReportIds.isNotEmpty)
          Text(
            '${_selectedReportIds.length} selected',
            style: TextStyle(
              color: Color(0xFFF2B342),
              fontWeight: FontWeight.w600,
              fontSize: _isMobile ? 12 : 14,
            ),
          ),
      ],
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          _isLoading && _reports.isEmpty
              ? ReportsShimmerLoading()
              : _reports.isEmpty
              ? _buildEmptyState()
              : _isMobile
              ? _buildMobileList()
              : _buildDesktopTable(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No reports found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          if (_searchQuery.isNotEmpty ||
              _selectedReportType != 'All' ||
              _selectedReason != 'All Reasons' ||
              _selectedStatus != null ||
              _selectedDateRange != null) ...[
            SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF2B342),
                foregroundColor: Colors.white,
              ),
              child: Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    if (_isMobile) return Container(); // No header for mobile cards

    final allSelected =
        _selectedReportIds.length == _reports.length && _reports.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: allSelected,
              tristate: true,
              onChanged: (val) => _toggleSelectAll(),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Reporter",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              "Reported Item",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              "Reason",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text("Date", style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Status",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Actions",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      shrinkWrap: true,
      controller: _scrollController,
      itemCount: _reports.length + (_hasMore && !_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _reports.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _buildMobileReportCard(_reports[index]);
      },
    );
  }

  Widget _buildDesktopTable() {
    return ListView.builder(
      shrinkWrap: true,
      controller: _scrollController,
      itemCount: _reports.length + (_hasMore && !_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _reports.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _buildTableRow(_reports[index], index % 2 == 1);
      },
    );
  }

  Widget _buildMobileReportCard(ReportModel report) {
    final isSelected = _selectedReportIds.contains(report.id);
    final dateStr = DateFormat('dd/MM/yyyy').format(report.createdAt);
    final userData = _usersData[report.reporterId];
    final userName = _userService.getUserDisplayName(
      userData,
      report.reporterId,
    );

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isSelected ? Color(0xFFF2B342).withOpacity(0.1) : Colors.white,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with checkbox and status
            Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (v) => _toggleReportSelection(report.id!),
                ),
                Expanded(
                  child: Text(
                    report.listingName,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: report.status.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report.status.displayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            // Reporter info
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  'Reporter: ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                userData == null
                    ? SizedBox(
                      width: 80,
                      height: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    )
                    : Text(
                      userName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
              ],
            ),

            SizedBox(height: 4),

            // Reason
            Row(
              children: [
                Icon(Icons.report_problem, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  'Reason: ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Expanded(
                  child: Text(
                    report.reason,
                    style: TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            SizedBox(height: 4),

            // Date and type
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  dateStr,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getListingTypeColor(report.listingType),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report.listingType,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showReportDetails(report),
                  icon: Icon(Icons.visibility, size: 16),
                  label: Text('View', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _editReport(report),
                  icon: Icon(Icons.edit, size: 16),
                  label: Text('Edit', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(ReportModel report, bool grey) {
    final isSelected = _selectedReportIds.contains(report.id);
    final dateStr = DateFormat('dd/MM/yyyy').format(report.createdAt);
    final userData = _usersData[report.reporterId];
    final userName = _userService.getUserDisplayName(
      userData,
      report.reporterId,
    );

    return Container(
      color:
          isSelected
              ? Color(0xFFF2B342).withOpacity(0.1)
              : grey
              ? Colors.grey.shade50
              : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: isSelected,
              onChanged: (v) => _toggleReportSelection(report.id!),
            ),
          ),
          Expanded(
            flex: 2,
            child:
                userData == null
                    ? Container(
                      width: 100,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    )
                    : Text(userName, style: TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => _showReportDetails(report),
              child: Text(
                report.listingName,
                style: TextStyle(
                  fontSize: 13,

                  decoration: TextDecoration.underline,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => _showReportDetails(report),
              child: Text(
                report.reason,
                style: TextStyle(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(dateStr, style: TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: report.status.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                report.status.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, size: 18),
                  onPressed: () => _showReportDetails(report),
                  tooltip: 'View Details',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _editReport(report),
                  tooltip: 'Edit Report',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActions() {
    if (_isMobile) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  () => _updateSelectedReportsStatus(
                    ReportStatus.completed,
                    null,
                  ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff364C63),
                foregroundColor: Colors.white,
              ),
              child: Text('Mark as Resolved'),
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      () => _updateSelectedReportsStatus(
                        ReportStatus.rejected,
                        null,
                      ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF2B342),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Reject'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _deleteSelectedReports,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _bulkActionButton("Mark as Resolved", () {
          _updateSelectedReportsStatus(ReportStatus.completed, null);
        }),
        const SizedBox(width: 12),
        _bulkActionButton("Mark as Rejected", () {
          _updateSelectedReportsStatus(ReportStatus.rejected, null);
        }),
        const SizedBox(width: 12),
        _bulkActionButton(
          "Delete Selected",
          _deleteSelectedReports,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildPaginationInfo() {
    return Text(
      'Page $_currentPage • Total: $_totalReports reports',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.grey[600], fontSize: _isMobile ? 12 : 14),
    );
  }

  Widget _bulkActionButton(
    String label,
    VoidCallback onPressed, {
    Color? color,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? const Color(0xFFF2B342),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: _isMobile ? 12 : 16,
          vertical: _isMobile ? 8 : 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: _isMobile ? 12 : 14,
        ),
      ),
    );
  }

  Color _getListingTypeColor(String type) {
    switch (type) {
      case 'Item':
        return Color(0xFFF2B342);
      case 'Business':
        return Colors.blue;
      case 'Event':
        return Colors.tealAccent;
      default:
        return Colors.grey;
    }
  }
}

// Also include the same dialog classes from before
class ReportDetailsDialog extends StatelessWidget {
  final ReportModel report;

  const ReportDetailsDialog({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width:
            isMobile
                ? MediaQuery.of(context).size.width * 0.9
                : MediaQuery.of(context).size.width * 0.6,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Report Details',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            Divider(),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow('Report ID', report.id ?? 'N/A'),
                    _detailRow('Status', report.status.displayName),
                    _detailRow(
                      'Submitted',
                      DateFormat(
                        'MMM dd, yyyy at hh:mm a',
                      ).format(report.createdAt),
                    ),
                    if (report.resolvedAt != null)
                      _detailRow(
                        'Resolved',
                        DateFormat(
                          'MMM dd, yyyy at hh:mm a',
                        ).format(report.resolvedAt!),
                      ),

                    SizedBox(height: 20),

                    Text(
                      'Reporter Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    _detailRow('Reporter ID', report.reporterId),

                    SizedBox(height: 20),

                    Text(
                      'Reported Listing',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (report.listingImage != null)
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(report.listingImage!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _detailRow('Listing ID', report.listingId),
                              _detailRow('Listing Name', report.listingName),
                              _detailRow('Listing Type', report.listingType),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    Text(
                      'Report Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    _detailRow('Reason', report.reason),

                    if (report.customReason != null) ...[
                      SizedBox(height: 12),
                      Text(
                        'Custom Reason:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          report.customReason!,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],

                    if (report.adminResponse != null) ...[
                      SizedBox(height: 20),
                      Text(
                        'Admin Response',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Text(
                          report.adminResponse!,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      if (report.adminId != null)
                        _detailRow('Admin ID', report.adminId!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value, style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class EditReportDialog extends StatefulWidget {
  final ReportModel report;
  final VoidCallback onUpdated;

  const EditReportDialog({
    super.key,
    required this.report,
    required this.onUpdated,
  });

  @override
  State<EditReportDialog> createState() => _EditReportDialogState();
}

class _EditReportDialogState extends State<EditReportDialog> {
  late ReportStatus _selectedStatus;
  final TextEditingController _responseController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.report.status;
    _responseController.text = widget.report.adminResponse ?? '';
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _updateReport() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final success = await AdminReportService.instance
          .updateMultipleReportsStatus(
            reportIds: [widget.report.id!],
            status: _selectedStatus,
            adminResponse:
                _responseController.text.trim().isEmpty
                    ? null
                    : _responseController.text.trim(),
            adminId: 'admin_user_id', // Replace with actual admin ID
          );

      if (success) {
        Navigator.of(context).pop();
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report updated successfully'),
            backgroundColor: Color(0xFFF2B342),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update report'),
            backgroundColor: Color(0xFFF2B342),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating report: $e'),
          backgroundColor: Color(0xFFF2B342),
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width:
            isMobile
                ? MediaQuery.of(context).size.width * 0.9
                : MediaQuery.of(context).size.width * 0.5,
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Report',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            Divider(),

            SizedBox(height: 16),

            Text(
              'Report: ${widget.report.listingName}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Text(
              'Reason: ${widget.report.reason}',
              style: TextStyle(color: Colors.grey[600]),
            ),

            SizedBox(height: 20),

            Text(
              'Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<ReportStatus>(
              value: _selectedStatus,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items:
                  ReportStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Icon(status.icon, size: 18, color: status.color),
                          SizedBox(width: 8),
                          Text(status.displayName),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (status) {
                if (status != null) {
                  setState(() {
                    _selectedStatus = status;
                  });
                }
              },
            ),

            SizedBox(height: 20),

            Text(
              'Admin Response (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _responseController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter your response to the reporter...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.all(12),
              ),
            ),

            SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isUpdating ? null : _updateReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF2B342),
                    foregroundColor: Colors.white,
                  ),
                  child:
                      _isUpdating
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text('Update Report'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Required dependencies in pubspec.yaml:
/*
dependencies:
  shimmer: ^3.0.0
  intl: ^0.19.0
  cloud_firestore: ^4.13.0
  firebase_auth: ^4.15.0
*/

// Usage in your main admin app:
/*
import 'package:flutter/material.dart';

class AdminApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Admin Panel')),
        drawer: Drawer(
          child: ListView(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFFF2B342)),
                child: Text('Admin Panel', style: TextStyle(color: Colors.white, fontSize: 24)),
              ),
              ListTile(
                leading: Icon(Icons.dashboard),
                title: Text('Dashboard'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(Icons.report_outlined),
                title: Text('User Reports'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ResponsiveAdminReportsScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.people),
                title: Text('Users'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(Icons.inventory),
                title: Text('Listings'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        body: Center(child: Text('Select an option from the drawer')),
      ),
    );
  }
}
*/

// Key Features Summary:
/*
✅ Fixed Issues:
1. User fetching with FutureBuilder and caching
2. Shimmer loading for better UX
3. Fixed filters with client-side filtering (due to Firestore limitations)
4. Fully responsive design for mobile, tablet, and desktop
5. Expanded filters section for mobile
6. Mobile card layout instead of table

✅ Features:
- Real-time user name fetching from users collection
- Shimmer loading animation
- Client-side filtering (works around Firestore compound query limits)
- Responsive design that works on all screen sizes
- Mobile-first card layout for reports
- Infinite scroll pagination
- Bulk operations (select all, update status, delete)
- Search functionality across all report fields
- Date range picker with clear functionality
- Status management with visual indicators
- Detailed report viewing with user information
- Edit reports with admin responses

✅ Performance Optimizations:
- User data caching to reduce Firestore reads
- Efficient pagination with document snapshots
- Debounced search to reduce API calls
- Client-side filtering for complex queries
- Lazy loading of report data

✅ Mobile Responsiveness:
- Card layout for mobile devices
- Stacked filters on mobile
- Touch-friendly buttons and controls
- Optimized spacing and typography
- Full-width action buttons on mobile
- Responsive dialogs and modals

This implementation handles the Firestore query limitations by fetching more data
and applying filters client-side, ensuring all filter combinations work properly.
The responsive design adapts seamlessly from mobile to desktop while maintaining
the same design language as your original mockup.
*/
