import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? userName;
  final String? firstName;
  final String? lastName;
  final String? photoURL;
  final String? avatar;
  final String? phone;
  final String? website;
  final String? address;
  final String? about;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final DateTime updatedAt;
  final String deviceId;
  final String? fcmToken;
  final String? deviceType;
  final DateTime? lastSeen;
  final bool? isOnline;

  // Business Information
  final String? businessName;
  final String? businessLink;
  final String? businessAddress;
  final String? professionalStatus;
  final String? industry;

  // Social Profiles
  final String? facebookUrl;
  final String? twitterUrl;
  final String? linkedinUrl;
  final String? youtubeUrl;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.userName,
    this.firstName,
    this.lastName,
    this.photoURL,
    this.avatar,
    this.phone,
    this.website,
    this.address,
    this.about,
    required this.emailVerified,
    required this.createdAt,
    this.lastLoginAt,
    required this.updatedAt,
    required this.deviceId,
    this.fcmToken,
    this.deviceType,
    this.lastSeen,
    this.isOnline,
    this.businessName,
    this.businessLink,
    this.businessAddress,
    this.professionalStatus,
    this.industry,
    this.facebookUrl,
    this.twitterUrl,
    this.linkedinUrl,
    this.youtubeUrl,
  });

  factory UserModel.fromFirebaseUser(User firebaseUser) {
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email!,
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
      emailVerified: firebaseUser.emailVerified,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      lastLoginAt: firebaseUser.metadata.lastSignInTime,
      updatedAt: DateTime.now(),
      deviceId: '',
      fcmToken: '',
      deviceType: '',
      // lastSeen: DateTime.now(),
      isOnline: false,
      avatar: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'userName': userName,
      'firstName': firstName,
      'lastName': lastName,
      'photoURL': photoURL,
      'avatar': avatar,
      'phone': phone,
      'website': website,
      'address': address,
      'about': about,
      'emailVerified': emailVerified,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deviceId': deviceId,
      'fcmToken': fcmToken,
      'deviceType': deviceType,
      'lastSeen': lastSeen?.toIso8601String(),
      'isOnline': isOnline,
      'businessName': businessName,
      'businessLink': businessLink,
      'businessAddress': businessAddress,
      'professionalStatus': professionalStatus,
      'industry': industry,
      'facebookUrl': facebookUrl,
      'twitterUrl': twitterUrl,
      'linkedinUrl': linkedinUrl,
      'youtubeUrl': youtubeUrl,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      userName: json['userName'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      photoURL: json['photoURL'],
      avatar: json['avatar'],
      phone: json['phone'],
      website: json['website'],
      address: json['address'],
      about: json['about'],
      emailVerified: json['emailVerified'] ?? false,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      lastLoginAt: _parseDateTime(json['lastLoginAt']),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
      deviceId: json['deviceId'] ?? '',
      fcmToken: json['fcmToken'],
      deviceType: json['deviceType'],
      // lastSeen: _parseDateTime(json['lastSeen']),
      isOnline: json['isOnline'] ?? false,
      businessName: json['businessName'],
      businessLink: json['businessLink'],
      businessAddress: json['businessAddress'],
      professionalStatus: json['professionalStatus'],
      industry: json['industry'],
      facebookUrl: json['facebookUrl'],
      twitterUrl: json['twitterUrl'],
      linkedinUrl: json['linkedinUrl'],
      youtubeUrl: json['youtubeUrl'],
    );
  }

  // Helper method to handle both Timestamp and String date parsing
  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;

    if (dateValue is Timestamp) {
      return dateValue.toDate();
    } else if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? userName,
    String? firstName,
    String? lastName,
    String? photoURL,
    String? avatar,
    String? phone,
    String? website,
    String? address,
    String? about,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? updatedAt,
    String? deviceId,
    String? fcmToken,
    String? deviceType,
    DateTime? lastSeen,
    bool? isOnline,
    String? businessName,
    String? businessLink,
    String? businessAddress,
    String? professionalStatus,
    String? industry,
    String? facebookUrl,
    String? twitterUrl,
    String? linkedinUrl,
    String? youtubeUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      userName: userName ?? this.userName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      photoURL: photoURL ?? this.photoURL,
      avatar: avatar ?? this.avatar,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      address: address ?? this.address,
      about: about ?? this.about,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      fcmToken: fcmToken ?? this.fcmToken,
      deviceType: deviceType ?? this.deviceType,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      businessName: businessName ?? this.businessName,
      businessLink: businessLink ?? this.businessLink,
      businessAddress: businessAddress ?? this.businessAddress,
      professionalStatus: professionalStatus ?? this.professionalStatus,
      industry: industry ?? this.industry,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      twitterUrl: twitterUrl ?? this.twitterUrl,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
    );
  }

  String get fullName {
    if (firstName?.isNotEmpty == true && lastName?.isNotEmpty == true) {
      return '$firstName $lastName';
    } else if (firstName?.isNotEmpty == true) {
      return firstName!;
    } else if (lastName?.isNotEmpty == true) {
      return lastName!;
    } else if (displayName?.isNotEmpty == true) {
      return displayName!;
    }
    return email.split('@').first;
  }

  String get profileImageUrl {
    return avatar?.isNotEmpty == true ? avatar! : (photoURL ?? '');
  }

  String get initials {
    if ((firstName?.isNotEmpty ?? false) && (lastName?.isNotEmpty ?? false)) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    } else if (displayName?.isNotEmpty ?? false) {
      final parts = displayName!.trim().split(
        RegExp(r'\s+'),
      ); // split by spaces safely
      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        return parts[0][0].toUpperCase();
      }
    }
    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    print(email);
    return "?"; // fallback to avoid RangeError
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
