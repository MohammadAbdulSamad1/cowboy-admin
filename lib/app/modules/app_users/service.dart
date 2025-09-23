import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedicated_cow_boy_admin/app/models/app_user-model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _usersCollection = 'users';

  // Get paginated users with filters
  static Future<QuerySnapshot> getPaginatedUsers({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    String? searchQuery,
    String? userType,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    Query query = _firestore
        .collection(_usersCollection)
        .orderBy('createdAt', descending: true);

    // Apply filters
    if (userType != null && userType != 'All users') {
      query = query.where('professionalStatus', isEqualTo: userType);
    }

    if (status != null && status != 'All status') {
      bool isOnline = status == 'Active';
      query = query.where('isOnline', isEqualTo: isOnline);
    }

    if (fromDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: fromDate);
    }

    if (toDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: toDate);
    }

    // Apply pagination
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(limit);

    return await query.get();
  }

  // Search users by name, email, or phone
  static Future<List<UserModel>> searchUsers(String searchQuery) async {
    final querySnapshot = await _firestore
        .collection(_usersCollection)
        .get();

    final users = querySnapshot.docs
        .map((doc) => UserModel.fromJson({
              ...doc.data(),
              'uid': doc.id,
            }))
        .toList();

    // Filter locally for complex search
    return users.where((user) {
      final query = searchQuery.toLowerCase();
      return user.fullName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          (user.phone?.toLowerCase().contains(query) ?? false) ||
          (user.userName?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  // Get user by ID
  static Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson({
          ...doc.data()!,
          'uid': doc.id,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  // Create new user
  static Future<String> createUser(Map<String, dynamic> userData) async {
    try {
      // Check if email already exists
      final existingUsers = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: userData['email'])
          .get();

      if (existingUsers.docs.isNotEmpty) {
        throw Exception('User with this email already exists');
      }

      // Add timestamps
      userData['createdAt'] = FieldValue.serverTimestamp();
      userData['updatedAt'] = FieldValue.serverTimestamp();
      userData['emailVerified'] = false;
      userData['deviceId'] = '';

      final docRef = await _firestore.collection(_usersCollection).add(userData);
      return docRef.id;
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  // Update user
  static Future<void> updateUser(String uid, Map<String, dynamic> userData) async {
    try {
      userData['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(_usersCollection).doc(uid).update(userData);
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  // Delete user
  static Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).delete();
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  // Bulk update users
  static Future<void> bulkUpdateUsers(List<String> userIds, Map<String, dynamic> updateData) async {
    try {
      final batch = _firestore.batch();
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      for (final uid in userIds) {
        final docRef = _firestore.collection(_usersCollection).doc(uid);
        batch.update(docRef, updateData);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error bulk updating users: $e');
    }
  }

  // Bulk delete users
  static Future<void> bulkDeleteUsers(List<String> userIds) async {
    try {
      final batch = _firestore.batch();

      for (final uid in userIds) {
        final docRef = _firestore.collection(_usersCollection).doc(uid);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error bulk deleting users: $e');
    }
  }

  // Get user statistics
  static Future<Map<String, int>> getUserStatistics() async {
    try {
      final snapshot = await _firestore.collection(_usersCollection).get();
      final users = snapshot.docs.map((doc) => UserModel.fromJson({
        ...doc.data(),
        'uid': doc.id,
      })).toList();

      int totalUsers = users.length;
      int activeUsers = users.where((user) => user.isOnline == true).length;
      int sellers = users.where((user) => user.professionalStatus == 'Seller').length;
      int buyers = users.where((user) => user.professionalStatus == 'Buyer').length;
      int verifiedUsers = users.where((user) => user.emailVerified).length;

      return {
        'total': totalUsers,
        'active': activeUsers,
        'sellers': sellers,
        'buyers': buyers,
        'verified': verifiedUsers,
      };
    } catch (e) {
      throw Exception('Error getting user statistics: $e');
    }
  }

  // Export users to CSV format
  static Future<String> exportUsersToCSV() async {
    try {
      final snapshot = await _firestore.collection(_usersCollection).get();
      final users = snapshot.docs.map((doc) => UserModel.fromJson({
        ...doc.data(),
        'uid': doc.id,
      })).toList();

      final csvHeaders = [
        'UID', 'Email', 'First Name', 'Last Name', 'Phone', 'User Type',
        'Status', 'Created At', 'Last Login', 'Email Verified', 'Business Name'
      ];

      final csvRows = users.map((user) => [
        user.uid,
        user.email,
        user.firstName ?? '',
        user.lastName ?? '',
        user.phone ?? '',
        user.professionalStatus ?? 'Buyer',
        user.isOnline == true ? 'Active' : 'Inactive',
        user.createdAt.toIso8601String(),
        user.lastLoginAt?.toIso8601String() ?? '',
        user.emailVerified.toString(),
        user.businessName ?? '',
      ]);

      final csvContent = [csvHeaders, ...csvRows]
          .map((row) => row.map((cell) => '"$cell"').join(','))
          .join('\n');

      return csvContent;
    } catch (e) {
      throw Exception('Error exporting users: $e');
    }
  }

  // Real-time users stream
  static Stream<QuerySnapshot> getUsersStream({
    int limit = 50,
    String? orderBy = 'createdAt',
    bool descending = true,
  }) {
    return _firestore
        .collection(_usersCollection)
        .orderBy(orderBy!, descending: descending)
        .limit(limit)
        .snapshots();
  }

  // Update user online status
  static Future<void> updateUserOnlineStatus(String uid, bool isOnline) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating online status: $e');
    }
  }

  // Get users by date range
  static Future<List<UserModel>> getUsersByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromJson({
                ...doc.data(),
                'uid': doc.id,
              }))
          .toList();
    } catch (e) {
      throw Exception('Error getting users by date range: $e');
    }
  }

  // Validate user data
  static Map<String, String> validateUserData(Map<String, dynamic> userData) {
    final errors = <String, String>{};

    if (userData['firstName']?.toString().trim().isEmpty ?? true) {
      errors['firstName'] = 'First name is required';
    }

    if (userData['lastName']?.toString().trim().isEmpty ?? true) {
      errors['lastName'] = 'Last name is required';
    }

    final email = userData['email']?.toString().trim() ?? '';
    if (email.isEmpty) {
      errors['email'] = 'Email is required';
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      errors['email'] = 'Invalid email format';
    }

    final phone = userData['phone']?.toString().trim() ?? '';
    if (phone.isNotEmpty && !RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(phone)) {
      errors['phone'] = 'Invalid phone number format';
    }

    final website = userData['website']?.toString().trim() ?? '';
    if (website.isNotEmpty && !RegExp(r'^https?://').hasMatch(website)) {
      errors['website'] = 'Website must start with http:// or https://';
    }

    return errors;
  }
}