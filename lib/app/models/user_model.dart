// firestore_collections.dart
// This file defines the Firestore collections structure for the admin system

/*
FIRESTORE COLLECTIONS STRUCTURE:

1. ADMINS COLLECTION (/admins/{adminId})
{
  "adminId": "firebase_user_uid",
  "email": "admin@company.com",
  "displayName": "John Doe",
  "role": "super_admin", // "super_admin", "admin", "moderator"
  "permissions": {
    "users": {
      "read": true,
      "write": true,
      "delete": true
    },
    "content": {
      "read": true,
      "write": true,
      "delete": false
    },
    "analytics": {
      "read": true,
      "write": false,
      "delete": false
    }
  },
  "isActive": true,
  "createdAt": "2025-01-20T10:30:00Z",
  "updatedAt": "2025-01-20T10:30:00Z",
  "createdBy": "creator_admin_uid",
  "lastLogin": "2025-01-20T15:45:00Z",
  "loginCount": 150,
  "profilePicture": "https://...",
  "department": "IT",
  "phoneNumber": "+1234567890",
  "twoFactorEnabled": false,
  "sessionTimeout": 3600 // seconds
}

2. ADMIN_LOGS COLLECTION (/admin_logs/{logId})
{
  "logId": "auto_generated_id",
  "adminId": "firebase_user_uid",
  "email": "admin@company.com",
  "action": "login", // "login", "logout", "create_user", "delete_content", etc.
  "resourceType": "user", // "user", "content", "settings", etc.
  "resourceId": "affected_resource_id",
  "details": {
    "userAgent": "Mozilla/5.0...",
    "ipAddress": "192.168.1.1",
    "platform": "web",
    "success": true,
    "errorCode": null,
    "additionalData": {}
  },
  "timestamp": "2025-01-20T15:45:00Z",
  "severity": "info" // "info", "warning", "error", "critical"
}

3. ADMIN_SESSIONS COLLECTION (/admin_sessions/{sessionId})
{
  "sessionId": "auto_generated_id",
  "adminId": "firebase_user_uid",
  "email": "admin@company.com",
  "isActive": true,
  "createdAt": "2025-01-20T15:45:00Z",
  "lastActivity": "2025-01-20T16:30:00Z",
  "expiresAt": "2025-01-20T19:45:00Z",
  "deviceInfo": {
    "userAgent": "Mozilla/5.0...",
    "ipAddress": "192.168.1.1",
    "platform": "web",
    "browser": "Chrome"
  }
}

4. ADMIN_ROLES COLLECTION (/admin_roles/{roleId})
{
  "roleId": "super_admin",
  "name": "Super Administrator",
  "description": "Full system access with all permissions",
  "permissions": {
    "users": ["read", "write", "delete"],
    "content": ["read", "write", "delete"],
    "analytics": ["read", "write"],
    "settings": ["read", "write"],
    "admin_management": ["read", "write", "delete"],
    "logs": ["read"]
  },
  "hierarchy": 1, // Lower number = higher authority
  "isActive": true,
  "createdAt": "2025-01-20T10:00:00Z",
  "updatedAt": "2025-01-20T10:00:00Z"
}

5. SYSTEM_SETTINGS COLLECTION (/system_settings/{settingId})
{
  "settingId": "security_settings",
  "category": "security",
  "settings": {
    "maxLoginAttempts": 5,
    "lockoutDuration": 1800, // seconds
    "sessionTimeout": 3600, // seconds
    "requireTwoFactor": false,
    "passwordPolicy": {
      "minLength": 8,
      "requireUppercase": true,
      "requireLowercase": true,
      "requireNumbers": true,
      "requireSpecialChars": true
    }
  },
  "updatedBy": "admin_uid",
  "updatedAt": "2025-01-20T12:00:00Z"
}
*/

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreCollections {
  static const String admins = 'admins';
  static const String adminLogs = 'admin_logs';
  static const String adminSessions = 'admin_sessions';
  static const String adminRoles = 'admin_roles';
  static const String systemSettings = 'system_settings';
}

class AdminModel {
  final String adminId;
  final String email;
  final String displayName;
  final String role;
  final Map<String, dynamic> permissions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final DateTime? lastLogin;
  final int loginCount;
  final String? profilePicture;
  final String? department;
  final String? phoneNumber;
  final bool twoFactorEnabled;
  final int sessionTimeout;

  AdminModel({
    required this.adminId,
    required this.email,
    required this.displayName,
    required this.role,
    required this.permissions,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.lastLogin,
    this.loginCount = 0,
    this.profilePicture,
    this.department,
    this.phoneNumber,
    this.twoFactorEnabled = false,
    this.sessionTimeout = 3600,
  });

  factory AdminModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminModel(
      adminId: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: data['role'] ?? '',
      permissions: data['permissions'] ?? {},
      isActive: data['isActive'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      lastLogin: data['lastLogin'] != null 
          ? (data['lastLogin'] as Timestamp).toDate() 
          : null,
      loginCount: data['loginCount'] ?? 0,
      profilePicture: data['profilePicture'],
      department: data['department'],
      phoneNumber: data['phoneNumber'],
      twoFactorEnabled: data['twoFactorEnabled'] ?? false,
      sessionTimeout: data['sessionTimeout'] ?? 3600,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'permissions': permissions,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'loginCount': loginCount,
      'profilePicture': profilePicture,
      'department': department,
      'phoneNumber': phoneNumber,
      'twoFactorEnabled': twoFactorEnabled,
      'sessionTimeout': sessionTimeout,
    };
  }
}

class AdminLogModel {
  final String logId;
  final String adminId;
  final String email;
  final String action;
  final String? resourceType;
  final String? resourceId;
  final Map<String, dynamic> details;
  final DateTime timestamp;
  final String severity;

  AdminLogModel({
    required this.logId,
    required this.adminId,
    required this.email,
    required this.action,
    this.resourceType,
    this.resourceId,
    required this.details,
    required this.timestamp,
    this.severity = 'info',
  });

  factory AdminLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminLogModel(
      logId: doc.id,
      adminId: data['adminId'] ?? '',
      email: data['email'] ?? '',
      action: data['action'] ?? '',
      resourceType: data['resourceType'],
      resourceId: data['resourceId'],
      details: data['details'] ?? {},
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      severity: data['severity'] ?? 'info',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'adminId': adminId,
      'email': email,
      'action': action,
      'resourceType': resourceType,
      'resourceId': resourceId,
      'details': details,
      'timestamp': Timestamp.fromDate(timestamp),
      'severity': severity,
    };
  }
}

class AdminSessionModel {
  final String sessionId;
  final String adminId;
  final String email;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastActivity;
  final DateTime expiresAt;
  final Map<String, dynamic> deviceInfo;

  AdminSessionModel({
    required this.sessionId,
    required this.adminId,
    required this.email,
    required this.isActive,
    required this.createdAt,
    required this.lastActivity,
    required this.expiresAt,
    required this.deviceInfo,
  });

  factory AdminSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminSessionModel(
      sessionId: doc.id,
      adminId: data['adminId'] ?? '',
      email: data['email'] ?? '',
      isActive: data['isActive'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActivity: (data['lastActivity'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      deviceInfo: data['deviceInfo'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'adminId': adminId,
      'email': email,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActivity': Timestamp.fromDate(lastActivity),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'deviceInfo': deviceInfo,
    };
  }
}

// Firestore Security Rules for Admin Collections
/*
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Admin collection - only accessible by authenticated admins
    match /admins/{adminId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == adminId 
        && isActiveAdmin(request.auth.uid);
      
      allow read: if request.auth != null 
        && isActiveAdmin(request.auth.uid)
        && hasPermission(request.auth.uid, 'admin_management', 'read');
      
      allow write: if request.auth != null 
        && isActiveAdmin(request.auth.uid)
        && hasPermission(request.auth.uid, 'admin_management', 'write');
    }
    
    // Admin logs - read only for admins with log permissions
    match /admin_logs/{logId} {
      allow read: if request.auth != null 
        && isActiveAdmin(request.auth.uid)
        && hasPermission(request.auth.uid, 'logs', 'read');
      
      allow create: if request.auth != null 
        && isActiveAdmin(request.auth.uid);
    }
    
    // Admin sessions - only accessible by session owner
    match /admin_sessions/{sessionId} {
      allow read, write: if request.auth != null 
        && resource.data.adminId == request.auth.uid
        && isActiveAdmin(request.auth.uid);
    }
    
    // Admin roles - read only for admins
    match /admin_roles/{roleId} {
      allow read: if request.auth != null 
        && isActiveAdmin(request.auth.uid);
      
      allow write: if request.auth != null 
        && isActiveAdmin(request.auth.uid)
        && hasPermission(request.auth.uid, 'admin_management', 'write');
    }
    
    // System settings - super admin only
    match /system_settings/{settingId} {
      allow read: if request.auth != null 
        && isActiveAdmin(request.auth.uid)
        && hasPermission(request.auth.uid, 'settings', 'read');
      
      allow write: if request.auth != null 
        && isActiveAdmin(request.auth.uid)
        && hasPermission(request.auth.uid, 'settings', 'write');
    }
    
    // Helper functions
    function isActiveAdmin(uid) {
      return exists(/databases/$(database)/documents/admins/$(uid)) 
        && get(/databases/$(database)/documents/admins/$(uid)).data.isActive == true;
    }
    
    function hasPermission(uid, resource, action) {
      let adminDoc = get(/databases/$(database)/documents/admins/$(uid));
      return adminDoc.data.permissions[resource][action] == true;
    }
    
    function isSuperAdmin(uid) {
      let adminDoc = get(/databases/$(database)/documents/admins/$(uid));
      return adminDoc.data.role == 'super_admin';
    }
  }
}
*/