// admin_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedicated_cow_boy_admin/app/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AdminService extends GetxService {
  static AdminService get instance => Get.find();

  Future<AdminService> onInit() async {
    return this;
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create initial admin (run this once to setup your first admin)
  Future<void> createInitialAdmin({
    required String email,
    required String password,
    required String displayName,
    String department = 'IT',
  }) async {
    try {
      // Create Firebase Auth user
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user != null) {
        // Create admin document in Firestore
        final adminData = AdminModel(
          adminId: user.uid,
          email: email,
          displayName: displayName,
          role: 'super_admin',
          permissions: _getSuperAdminPermissions(),
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'system',
          department: department,
          twoFactorEnabled: false,
          sessionTimeout: 3600,
        );

        await _firestore
            .collection(FirestoreCollections.admins)
            .doc(user.uid)
            .set(adminData.toFirestore());

        print('Initial admin created successfully: $email');
      }
    } catch (e) {
      print('Error creating initial admin: $e');
      rethrow;
    }
  }

  // Get admin by ID
  Future<AdminModel?> getAdminById(String adminId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(FirestoreCollections.admins)
          .doc(adminId)
          .get();

      if (doc.exists) {
        return AdminModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting admin: $e');
      return null;
    }
  }

  // Get all active admins
  Future<List<AdminModel>> getAllActiveAdmins() async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(FirestoreCollections.admins)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AdminModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting active admins: $e');
      return [];
    }
  }

  // Update admin last login
  Future<void> updateLastLogin(String adminId) async {
    try {
      await _firestore
          .collection(FirestoreCollections.admins)
          .doc(adminId)
          .update({
            'lastLogin': FieldValue.serverTimestamp(),
            'loginCount': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error updating last login: $e');
    }
  }

  // Create admin log
  Future<void> createAdminLog({
    required String adminId,
    required String email,
    required String action,
    String? resourceType,
    String? resourceId,
    Map<String, dynamic> additionalDetails = const {},
    String severity = 'info',
  }) async {
    try {
      final logData = AdminLogModel(
        logId: '',
        adminId: adminId,
        email: email,
        action: action,
        resourceType: resourceType,
        resourceId: resourceId,
        details: {
          'userAgent': 'Web Admin Panel',
          'ipAddress': 'Unknown',
          'platform': 'web',
          'success': true,
          'errorCode': null,
          ...additionalDetails,
        },
        timestamp: DateTime.now(),
        severity: severity,
      );

      await _firestore
          .collection(FirestoreCollections.adminLogs)
          .add(logData.toFirestore());
    } catch (e) {
      print('Error creating admin log: $e');
    }
  }

  // Get admin logs with pagination
  Future<List<AdminLogModel>> getAdminLogs({
    String? adminId,
    int limit = 50,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection(FirestoreCollections.adminLogs)
          .orderBy('timestamp', descending: true);

      if (adminId != null) {
        query = query.where('adminId', isEqualTo: adminId);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final QuerySnapshot querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => AdminLogModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting admin logs: $e');
      return [];
    }
  }

  // Create admin session
  Future<void> createAdminSession(String adminId, String email) async {
    try {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 1)); // 1 hour session

      final sessionData = AdminSessionModel(
        sessionId: '',
        adminId: adminId,
        email: email,
        isActive: true,
        createdAt: now,
        lastActivity: now,
        expiresAt: expiresAt,
        deviceInfo: {
          'userAgent': 'Web Admin Panel',
          'ipAddress': 'Unknown',
          'platform': 'web',
          'browser': 'Chrome',
        },
      );

      await _firestore
          .collection(FirestoreCollections.adminSessions)
          .add(sessionData.toFirestore());
    } catch (e) {
      print('Error creating admin session: $e');
    }
  }

  // Deactivate admin sessions
  Future<void> deactivateAdminSessions(String adminId) async {
    try {
      final QuerySnapshot activeSessions = await _firestore
          .collection(FirestoreCollections.adminSessions)
          .where('adminId', isEqualTo: adminId)
          .where('isActive', isEqualTo: true)
          .get();

      final WriteBatch batch = _firestore.batch();

      for (final doc in activeSessions.docs) {
        batch.update(doc.reference, {
          'isActive': false,
          'lastActivity': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error deactivating admin sessions: $e');
    }
  }

  // Check admin permissions
  bool hasPermission(AdminModel admin, String resource, String action) {
    try {
      final permissions = admin.permissions[resource] as Map<String, dynamic>?;
      return permissions?[action] == true;
    } catch (e) {
      return false;
    }
  }

  // Create new admin (only super admins can do this)
  Future<bool> createNewAdmin({
    required String email,
    required String displayName,
    required String role,
    required String department,
    required String createdBy,
  }) async {
    try {
      // Generate a temporary password
      const String tempPassword = 'TempPass123!';

      // Create Firebase Auth user
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: tempPassword);

      final User? user = userCredential.user;
      if (user != null) {
        // Send password reset email immediately
        await _auth.sendPasswordResetEmail(email: email);

        // Create admin document
        final adminData = AdminModel(
          adminId: user.uid,
          email: email,
          displayName: displayName,
          role: role,
          permissions: _getPermissionsByRole(role),
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: createdBy,
          department: department,
          twoFactorEnabled: false,
          sessionTimeout: 3600,
        );

        await _firestore
            .collection(FirestoreCollections.admins)
            .doc(user.uid)
            .set(adminData.toFirestore());

        // Log the action
        await createAdminLog(
          adminId: createdBy,
          email: _auth.currentUser?.email ?? '',
          action: 'create_admin',
          resourceType: 'admin',
          resourceId: user.uid,
          additionalDetails: {'newAdminEmail': email, 'newAdminRole': role},
        );

        return true;
      }
      return false;
    } catch (e) {
      print('Error creating new admin: $e');
      return false;
    }
  }

  // Deactivate admin
  Future<bool> deactivateAdmin(String adminId, String deactivatedBy) async {
    try {
      await _firestore
          .collection(FirestoreCollections.admins)
          .doc(adminId)
          .update({
            'isActive': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Deactivate all sessions
      await deactivateAdminSessions(adminId);

      // Log the action
      await createAdminLog(
        adminId: deactivatedBy,
        email: _auth.currentUser?.email ?? '',
        action: 'deactivate_admin',
        resourceType: 'admin',
        resourceId: adminId,
      );

      return true;
    } catch (e) {
      print('Error deactivating admin: $e');
      return false;
    }
  }

  // Get permissions by role
  Map<String, dynamic> _getPermissionsByRole(String role) {
    switch (role) {
      case 'super_admin':
        return _getSuperAdminPermissions();
      case 'admin':
        return _getAdminPermissions();
      case 'moderator':
        return _getModeratorPermissions();
      default:
        return _getReadOnlyPermissions();
    }
  }

  // Super admin permissions (full access)
  Map<String, dynamic> _getSuperAdminPermissions() {
    return {
      'users': {'read': true, 'write': true, 'delete': true},
      'content': {'read': true, 'write': true, 'delete': true},
      'analytics': {'read': true, 'write': true, 'delete': false},
      'settings': {'read': true, 'write': true, 'delete': false},
      'admin_management': {'read': true, 'write': true, 'delete': true},
      'logs': {'read': true, 'write': false, 'delete': false},
    };
  }

  // Regular admin permissions
  Map<String, dynamic> _getAdminPermissions() {
    return {
      'users': {'read': true, 'write': true, 'delete': false},
      'content': {'read': true, 'write': true, 'delete': true},
      'analytics': {'read': true, 'write': false, 'delete': false},
      'settings': {'read': true, 'write': false, 'delete': false},
      'admin_management': {'read': true, 'write': false, 'delete': false},
      'logs': {'read': true, 'write': false, 'delete': false},
    };
  }

  // Moderator permissions
  Map<String, dynamic> _getModeratorPermissions() {
    return {
      'users': {'read': true, 'write': false, 'delete': false},
      'content': {'read': true, 'write': true, 'delete': false},
      'analytics': {'read': true, 'write': false, 'delete': false},
      'settings': {'read': false, 'write': false, 'delete': false},
      'admin_management': {'read': false, 'write': false, 'delete': false},
      'logs': {'read': false, 'write': false, 'delete': false},
    };
  }

  // Read-only permissions
  Map<String, dynamic> _getReadOnlyPermissions() {
    return {
      'users': {'read': true, 'write': false, 'delete': false},
      'content': {'read': true, 'write': false, 'delete': false},
      'analytics': {'read': true, 'write': false, 'delete': false},
      'settings': {'read': false, 'write': false, 'delete': false},
      'admin_management': {'read': false, 'write': false, 'delete': false},
      'logs': {'read': false, 'write': false, 'delete': false},
    };
  }

    // Get currently logged-in admin data
  Future<AdminModel?> getCurrentAdminData() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        print('No user is currently logged in');
        return null;
      }

      final DocumentSnapshot doc = await _firestore
          .collection(FirestoreCollections.admins)
          .doc(user.uid)
          .get();

      if (doc.exists) {
        return AdminModel.fromFirestore(doc);
      } else {
        print('No admin data found for UID: ${user.uid}');
        return null;
      }
    } catch (e) {
      print('Error getting current admin data: $e');
      return null;
    }
  }


  // Initialize default roles in Firestore (run once)
  Future<void> initializeDefaultRoles() async {
    try {
      final roles = [
        {
          'roleId': 'super_admin',
          'name': 'Super Administrator',
          'description': 'Full system access with all permissions',
          'permissions': _getSuperAdminPermissions(),
          'hierarchy': 1,
          'isActive': true,
        },
        {
          'roleId': 'admin',
          'name': 'Administrator',
          'description': 'Administrative access with most permissions',
          'permissions': _getAdminPermissions(),
          'hierarchy': 2,
          'isActive': true,
        },
        {
          'roleId': 'moderator',
          'name': 'Moderator',
          'description': 'Content moderation and user management',
          'permissions': _getModeratorPermissions(),
          'hierarchy': 3,
          'isActive': true,
        },
      ];

      final WriteBatch batch = _firestore.batch();

      for (final role in roles) {
        final docRef = _firestore
            .collection(FirestoreCollections.adminRoles)
            .doc(role['roleId'] as String);

        batch.set(docRef, {
          ...role,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print('Default roles initialized successfully');
    } catch (e) {
      print('Error initializing default roles: $e');
    }
  }
}
