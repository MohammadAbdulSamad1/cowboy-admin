import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Import your UserModel here
// import 'path/to/your/user_model.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen>
    with TickerProviderStateMixin {
  // Color Theme
  static const Color primaryColor = Color(0xFF364C63);
  static const Color secondaryColor = Color(0xFFF2B342);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFF8F9FA);
  static const Color textPrimaryColor = Colors.black87;
  static const Color textSecondaryColor = Colors.black54;

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        elevation: 0,

        title: const Text(
          'Subscription Management',
          style: TextStyle(
            fontFamily: 'popins',
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Container(
            color: backgroundColor,
            child: Column(children: [_buildSearchBar(), _buildTabBar()]),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubscriptionPlansTab(),
          _buildActiveUsersTab(),
          _buildExpiredUsersTab(),
          _buildTopUsersTab(),
        ],
      ),
      floatingActionButton:
          _tabController.index == 0
              ? FloatingActionButton.extended(
                onPressed: () => _showAddSubscriptionDialog(context),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add Plan',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: secondaryColor,
              )
              : null,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search subscriptions or users...',
          hintStyle: TextStyle(color: textSecondaryColor),
          prefixIcon: Icon(Icons.search, color: textSecondaryColor),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: Icon(Icons.clear, color: textSecondaryColor),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                  : null,
          filled: true,
          fillColor: surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: primaryColor,
      unselectedLabelColor: textSecondaryColor,
      indicatorColor: secondaryColor,
      indicatorWeight: 3,
      tabs: const [
        Tab(icon: Icon(Icons.subscriptions), text: 'Plans'),
        Tab(icon: Icon(Icons.people), text: 'Active Users'),
        Tab(icon: Icon(Icons.people_outline), text: 'Expired Users'),
        Tab(icon: Icon(Icons.star), text: 'Top Users'),
      ],
    );
  }

  Widget _buildSubscriptionPlansTab() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('subscription_plans')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No subscription plans found');
        }

        var plans = snapshot.data!.docs;
        if (_searchQuery.isNotEmpty) {
          plans =
              plans.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                return data['name']?.toString().toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false;
              }).toList();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // Fixed responsive layout logic
            int crossAxisCount = 1;
            double childAspectRatio = 1.2;

            if (constraints.maxWidth > 1200) {
              crossAxisCount = 3;
            } else if (constraints.maxWidth > 800) {
              crossAxisCount = 2;
            } else {
              crossAxisCount = 1;
              childAspectRatio = 0.8; // Better ratio for mobile
            }

            return _buildPlansGrid(plans, crossAxisCount, childAspectRatio);
          },
        );
      },
    );
  }

  Widget _buildPlansGrid(
    List<QueryDocumentSnapshot> plans,
    int crossAxisCount,
    double childAspectRatio,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: plans.length,
        itemBuilder:
            (context, index) => _buildSubscriptionPlanCard(plans[index]),
      ),
    );
  }

  Widget _buildSubscriptionPlanCard(QueryDocumentSnapshot plan) {
    var data = plan.data() as Map<String, dynamic>? ?? {};
    bool isPopular = data['isPopular'] ?? false;

    return Card(
      elevation: isPopular ? 8 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient:
              isPopular
                  ? LinearGradient(
                    colors: [primaryColor.withOpacity(0.8), primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : null,
          color: isPopular ? null : backgroundColor,
          border: isPopular ? null : Border.all(color: Colors.grey[200]!),
        ),
        child: Stack(
          children: [
            if (isPopular)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: secondaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name']?.toString() ?? 'Unknown Plan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isPopular ? Colors.white : textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['description']?.toString() ?? 'No description',
                    style: TextStyle(
                      color: isPopular ? Colors.white70 : textSecondaryColor,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        '\$${data['price']?.toString() ?? '0'}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isPopular ? Colors.white : textPrimaryColor,
                        ),
                      ),
                      Text(
                        '/${data['type']?.toString() ?? 'month'}',
                        style: TextStyle(
                          color:
                              isPopular ? Colors.white70 : textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (data['features'] != null && data['features'] is List)
                    ...((data['features'] as List)
                        .take(3)
                        .map(
                          (feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color:
                                      isPopular ? Colors.white : secondaryColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    feature?.toString() ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          isPopular
                                              ? Colors.white
                                              : textPrimaryColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              () => _showEditSubscriptionDialog(context, plan),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isPopular ? backgroundColor : secondaryColor,
                            foregroundColor:
                                isPopular ? primaryColor : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _deleteSubscriptionPlan(plan.id),
                        icon: Icon(
                          Icons.delete,
                          color: isPopular ? Colors.white : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('user_subscriptions')
              .where('status', isEqualTo: 'active')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No active subscriptions found');
        }

        return _buildUsersTable(snapshot.data!.docs, isActive: true);
      },
    );
  }

  Widget _buildExpiredUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('user_subscriptions')
              .where('status', whereIn: ['expired', 'cancelled'])
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No expired subscriptions found');
        }

        return _buildUsersTable(snapshot.data!.docs, isActive: false);
      },
    );
  }

  Widget _buildTopUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('user_subscriptions')
              .where('status', isEqualTo: 'active')
              .limit(50)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No top users found');
        }

        return _buildTopUsersGrid(snapshot.data!.docs);
      },
    );
  }

  // User information widget that fetches from users collection
  Widget _buildUserInfo(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return Text(
            userId.length > 12 ? '${userId.substring(0, 12)}...' : userId,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: textSecondaryColor,
            ),
          );
        }

        var userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};

        // Create UserModel from the data
        String displayName =
            userData['displayName'] ??
            userData['firstName'] ??
            userData['email']?.toString().split('@').first ??
            'Unknown User';
        String email = userData['email'] ?? '';

        return GestureDetector(
          onTap: () => _showUserDetails(userData, userId),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
              if (email.isNotEmpty)
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textSecondaryColor,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsersTable(
    List<QueryDocumentSnapshot> subscriptions, {
    required bool isActive,
  }) {
    var filteredSubscriptions = subscriptions;
    if (_searchQuery.isNotEmpty) {
      filteredSubscriptions =
          subscriptions.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return data['userId']?.toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false;
          }).toList();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return _buildDesktopTable(filteredSubscriptions, isActive);
        } else {
          return _buildMobileUsersList(filteredSubscriptions, isActive);
        }
      },
    );
  }

  Widget _buildDesktopTable(
    List<QueryDocumentSnapshot> subscriptions,
    bool isActive,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: DataTable(
          headingRowColor: MaterialStateColor.resolveWith(
            (states) => surfaceColor,
          ),
          columns: const [
            DataColumn(
              label: Text(
                'User',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Plan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Purchase Date',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Price',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Actions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ],
          rows:
              subscriptions.map((subscription) {
                var data = subscription.data() as Map<String, dynamic>? ?? {};
                return DataRow(
                  cells: [
                    DataCell(_buildUserInfo(data['userId']?.toString() ?? '')),
                    DataCell(
                      FutureBuilder<DocumentSnapshot>(
                        future:
                            FirebaseFirestore.instance
                                .collection('subscription_plans')
                                .doc(data['plan']?['id'])
                                .get(),
                        builder: (context, planSnapshot) {
                          if (planSnapshot.hasData &&
                              planSnapshot.data!.exists) {
                            var planData =
                                planSnapshot.data!.data()
                                    as Map<String, dynamic>? ??
                                {};
                            return Text(
                              planData['name']?.toString() ?? 'Unknown Plan',
                              style: const TextStyle(color: textPrimaryColor),
                            );
                          }
                          return const Text(
                            'Loading...',
                            style: TextStyle(color: textSecondaryColor),
                          );
                        },
                      ),
                    ),
                    DataCell(
                      Text(
                        data['purchaseDate'] != null
                            ? DateFormat('MMM dd, yyyy').format(
                              (data['purchaseDate'] as Timestamp).toDate(),
                            )
                            : 'Unknown',
                        style: const TextStyle(color: textPrimaryColor),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive ? Color(0xff364C63) : Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (data['status']?.toString() ?? 'unknown')
                              .toUpperCase(),
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.red[700],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '\$${data['plan']?['price']?.toString() ?? '0'}',
                        style: const TextStyle(color: textPrimaryColor),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.visibility,
                              size: 18,
                              color: primaryColor,
                            ),
                            onPressed:
                                () =>
                                    _showUserSubscriptionDetails(subscription),
                          ),
                          if (isActive)
                            IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                size: 18,
                                color: Colors.red,
                              ),
                              onPressed:
                                  () => _cancelSubscription(subscription.id),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileUsersList(
    List<QueryDocumentSnapshot> subscriptions,
    bool isActive,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: subscriptions.length,
      itemBuilder: (context, index) {
        var subscription = subscriptions[index];
        var data = subscription.data() as Map<String, dynamic>? ?? {};

        return Card(
          color: backgroundColor,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: isActive ? Color(0xff364C63) : Colors.red[100],
              child: Icon(
                isActive ? Icons.check : Icons.close,
                color: isActive ? Color(0xff364C63) : Colors.red[700],
              ),
            ),
            title: _buildUserInfo(data['userId']?.toString() ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Price: \$${data['plan']?['price']?.toString() ?? '0'}',
                  style: const TextStyle(color: textPrimaryColor),
                ),
                if (data['purchaseDate'] != null)
                  Text(
                    'Purchase: ${DateFormat('MMM dd, yyyy').format((data['purchaseDate'] as Timestamp).toDate())}',
                    style: const TextStyle(color: textSecondaryColor),
                  ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: ListTile(
                        leading: Icon(Icons.visibility, color: primaryColor),
                        title: Text('View Details'),
                      ),
                    ),
                    if (isActive)
                      const PopupMenuItem(
                        value: 'cancel',
                        child: ListTile(
                          leading: Icon(Icons.cancel, color: Colors.red),
                          title: Text('Cancel'),
                        ),
                      ),
                  ],
              onSelected: (value) {
                if (value == 'view') {
                  _showUserSubscriptionDetails(subscription);
                } else if (value == 'cancel') {
                  _cancelSubscription(subscription.id);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopUsersGrid(List<QueryDocumentSnapshot> topUsers) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            MediaQuery.of(context).size.width > 1200
                ? 4
                : MediaQuery.of(context).size.width > 800
                ? 3
                : MediaQuery.of(context).size.width > 600
                ? 2
                : 1,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: topUsers.length,
      itemBuilder: (context, index) {
        var user = topUsers[index];
        var data = user.data() as Map<String, dynamic>? ?? {};

        return Card(
          elevation: 4,
          color: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.1),
                  secondaryColor.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: secondaryColor,
                      child: Text(
                        '#${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.star, color: secondaryColor),
                  ],
                ),
                const SizedBox(height: 12),
                _buildUserInfo(data['userId']?.toString() ?? ''),
                const Spacer(),
                Text(
                  'Since: ${data['purchaseDate'] != null ? DateFormat('MMM yyyy').format((data['purchaseDate'] as Timestamp).toDate()) : 'Unknown'}',
                  style: const TextStyle(
                    color: textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Value: \$${data['plan']?['price']?.toString() ?? '0'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: textSecondaryColor),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              color: textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Show full user details dialog
  void _showUserDetails(Map<String, dynamic> userData, String userId) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: primaryColor,
                        child: Text(
                          _getInitials(userData),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getDisplayName(userData),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            Text(
                              userData['email']?.toString() ?? '',
                              style: const TextStyle(color: textSecondaryColor),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'User Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildUserDetailRow('User ID', userId),
                  if (userData['firstName'] != null)
                    _buildUserDetailRow(
                      'First Name',
                      userData['firstName'].toString(),
                    ),
                  if (userData['lastName'] != null)
                    _buildUserDetailRow(
                      'Last Name',
                      userData['lastName'].toString(),
                    ),
                  if (userData['phone'] != null)
                    _buildUserDetailRow('Phone', userData['phone'].toString()),
                  if (userData['address'] != null)
                    _buildUserDetailRow(
                      'Address',
                      userData['address'].toString(),
                    ),
                  if (userData['createdAt'] != null)
                    _buildUserDetailRow(
                      'Member Since',
                      DateFormat('MMM dd, yyyy').format(
                        userData['createdAt'] is Timestamp
                            ? (userData['createdAt'] as Timestamp).toDate()
                            : DateTime.parse(userData['createdAt'].toString()),
                      ),
                    ),
                  if (userData['businessName'] != null)
                    _buildUserDetailRow(
                      'Business',
                      userData['businessName'].toString(),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildUserDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: textPrimaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: textSecondaryColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayName(Map<String, dynamic> userData) {
    if (userData['firstName'] != null && userData['lastName'] != null) {
      return '${userData['firstName']} ${userData['lastName']}';
    } else if (userData['displayName'] != null) {
      return userData['displayName'].toString();
    } else if (userData['firstName'] != null) {
      return userData['firstName'].toString();
    } else if (userData['email'] != null) {
      return userData['email'].toString().split('@').first;
    }
    return 'Unknown User';
  }

  String _getInitials(Map<String, dynamic> userData) {
    if (userData['firstName'] != null && userData['lastName'] != null) {
      return '${userData['firstName'].toString()[0]}${userData['lastName'].toString()[0]}'
          .toUpperCase();
    } else if (userData['displayName'] != null) {
      final parts = userData['displayName'].toString().trim().split(
        RegExp(r'\s+'),
      );
      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        return parts[0][0].toUpperCase();
      }
    }
    if (userData['email'] != null && userData['email'].toString().isNotEmpty) {
      return userData['email'].toString()[0].toUpperCase();
    }
    return '?';
  }

  void _showAddSubscriptionDialog(BuildContext context) {
    _showSubscriptionDialog(context, null);
  }

  void _showEditSubscriptionDialog(
    BuildContext context,
    QueryDocumentSnapshot plan,
  ) {
    _showSubscriptionDialog(context, plan);
  }

  void _showSubscriptionDialog(
    BuildContext context,
    QueryDocumentSnapshot? existingPlan,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final durationController = TextEditingController();
    String selectedType = 'monthly';
    bool isPopular = false;
    List<String> features = [];
    final featureController = TextEditingController();

    if (existingPlan != null) {
      var data = existingPlan.data() as Map<String, dynamic>? ?? {};
      nameController.text = data['name']?.toString() ?? '';
      descriptionController.text = data['description']?.toString() ?? '';
      priceController.text = (data['price']?.toString() ?? '0');
      durationController.text = (data['duration']?.toString() ?? '1');
      selectedType = data['type']?.toString() ?? 'monthly';
      isPopular = data['isPopular'] ?? false;
      features = List<String>.from(data['features'] ?? []);
    }

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  backgroundColor: backgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    existingPlan == null
                        ? 'Add Subscription Plan'
                        : 'Edit Subscription Plan',
                    style: const TextStyle(color: primaryColor),
                  ),
                  content: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Plan Name',
                                labelStyle: TextStyle(color: primaryColor),
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: secondaryColor),
                                ),
                              ),
                              validator:
                                  (value) =>
                                      value?.isEmpty ?? true
                                          ? 'Required'
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                labelStyle: TextStyle(color: primaryColor),
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: secondaryColor),
                                ),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: priceController,
                                    decoration: const InputDecoration(
                                      labelText: 'Price',
                                      labelStyle: TextStyle(
                                        color: primaryColor,
                                      ),
                                      border: OutlineInputBorder(),
                                      prefixText: '\$ ',

                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: secondaryColor,
                                        ),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator:
                                        (value) =>
                                            value?.isEmpty ?? true
                                                ? 'Required'
                                                : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: selectedType,
                                    decoration: const InputDecoration(
                                      labelText: 'Type',
                                      labelStyle: TextStyle(
                                        color: primaryColor,
                                      ),
                                      border: OutlineInputBorder(),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: secondaryColor,
                                        ),
                                      ),
                                    ),
                                    items:
                                        ['daily', 'monthly', 'yearly'].map((
                                          String value,
                                        ) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value.capitalize()),
                                          );
                                        }).toList(),
                                    onChanged:
                                        (value) => setState(
                                          () => selectedType = value!,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: durationController,
                              decoration: const InputDecoration(
                                labelText: 'Duration',
                                labelStyle: TextStyle(color: primaryColor),
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: secondaryColor),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            CheckboxListTile(
                              title: const Text('Popular Plan'),
                              value: isPopular,
                              activeColor: secondaryColor,
                              onChanged:
                                  (value) => setState(() => isPopular = value!),
                            ),
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Features:',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...features.map(
                                  (feature) => ListTile(
                                    title: Text(feature),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => setState(
                                            () => features.remove(feature),
                                          ),
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: featureController,
                                        decoration: const InputDecoration(
                                          labelText: 'Add Feature',
                                          labelStyle: TextStyle(
                                            color: primaryColor,
                                          ),
                                          border: OutlineInputBorder(),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: secondaryColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add,
                                        color: secondaryColor,
                                      ),
                                      onPressed: () {
                                        if (featureController.text.isNotEmpty) {
                                          setState(() {
                                            features.add(
                                              featureController.text,
                                            );
                                            featureController.clear();
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: textSecondaryColor),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          var planData = {
                            'name': nameController.text,
                            'description': descriptionController.text,
                            'price': double.tryParse(priceController.text) ?? 0,
                            'duration':
                                int.tryParse(
                                  durationController.text.isEmpty
                                      ? '1'
                                      : durationController.text,
                                ) ??
                                1,
                            'type': selectedType,
                            'isPopular': isPopular,
                            'features': features,
                            'updatedAt': FieldValue.serverTimestamp(),
                          };

                          try {
                            if (existingPlan == null) {
                              planData['id'] =
                                  selectedType == 'daily'
                                      ? 'daily_plan'
                                      : selectedType == 'monthly'
                                      ? 'monthly_plan'
                                      : 'yearly_plan';
                              await FirebaseFirestore.instance
                                  .collection('subscription_plans')
                                  .add(planData);
                            } else {
                              await FirebaseFirestore.instance
                                  .collection('subscription_plans')
                                  .doc(existingPlan.id)
                                  .update(planData);
                            }
                            Navigator.of(context).pop();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor:  Color(0xFFF2B342)
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(existingPlan == null ? 'Add' : 'Update'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _deleteSubscriptionPlan(String planId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: backgroundColor,
            title: const Text(
              'Delete Subscription Plan',
              style: TextStyle(color: primaryColor),
            ),
            content: const Text(
              'Are you sure you want to delete this subscription plan?',
              style: TextStyle(color: textPrimaryColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: textSecondaryColor),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('subscription_plans')
                        .doc(planId)
                        .delete();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Subscription plan deleted successfully'),
                        backgroundColor:  Color(0xFFF2B342)
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting plan: $e'),
                        backgroundColor:  Color(0xFFF2B342)
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFF2B342)),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _cancelSubscription(String subscriptionId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: backgroundColor,
            title: const Text(
              'Cancel Subscription',
              style: TextStyle(color: primaryColor),
            ),
            content: const Text(
              'Are you sure you want to cancel this user\'s subscription?',
              style: TextStyle(color: textPrimaryColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: textSecondaryColor),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('user_subscriptions')
                        .doc(subscriptionId)
                        .update({
                          'status': 'cancelled',
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Subscription cancelled successfully'),
                        backgroundColor:  Color(0xFFF2B342)
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error cancelling subscription: $e'),
                        backgroundColor: Color(0xFFF2B342)
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor:  Color(0xFFF2B342)),
                child: const Text(
                  'Cancel Subscription',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _showUserSubscriptionDetails(QueryDocumentSnapshot subscription) {
    var data = subscription.data() as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Subscription Details',
              style: TextStyle(color: primaryColor),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'User ID:',
                    data['userId']?.toString() ?? 'Unknown',
                  ),
                  _buildDetailRow(
                    'Transaction ID:',
                    data['transactionId']?.toString() ?? 'Unknown',
                  ),
                  _buildDetailRow(
                    'Status:',
                    data['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                  ),
                  _buildDetailRow(
                    'Purchase Method:',
                    data['purchase_method']?.toString() ?? 'Unknown',
                  ),
                  if (data['purchaseDate'] != null)
                    _buildDetailRow(
                      'Purchase Date:',
                      DateFormat(
                        'MMM dd, yyyy HH:mm',
                      ).format((data['purchaseDate'] as Timestamp).toDate()),
                    ),
                  if (data['updatedAt'] != null)
                    _buildDetailRow(
                      'Updated At:',
                      DateFormat(
                        'MMM dd, yyyy HH:mm',
                      ).format((data['updatedAt'] as Timestamp).toDate()),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Plan Details:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (data['plan'] != null) ...[
                    _buildDetailRow(
                      'Plan Name:',
                      data['plan']['name']?.toString() ?? 'Unknown',
                    ),
                    _buildDetailRow(
                      'Plan Type:',
                      data['plan']['type']?.toString() ?? 'Unknown',
                    ),
                    _buildDetailRow(
                      'Plan Duration:',
                      '${data['plan']['duration']?.toString() ?? '0'}',
                    ),
                    _buildDetailRow(
                      'Plan Price:',
                      '\$${data['plan']['price']?.toString() ?? '0'}',
                    ),
                    if (data['plan']['description'] != null)
                      _buildDetailRow(
                        'Description:',
                        data['plan']['description'].toString(),
                      ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(color: textSecondaryColor),
                ),
              ),
              if (data['status'] == 'active')
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _cancelSubscription(subscription.id);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text(
                    'Cancel Subscription',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: textPrimaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
