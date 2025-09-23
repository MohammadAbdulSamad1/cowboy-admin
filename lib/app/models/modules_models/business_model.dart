import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessListing {
  final String? id; // Firebase document ID
  final String? businessName;
  final String? description;
  final List<String>? businessCategory;
  final String? subcategory;
  final String? address;
  final String? locationCityState;
  final double? latitude;
  final double? longitude;
  final String? paymentStatus; // New field: payment status
  final String? websiteOnlineStore;
  final List<String>? photoUrls;
  final List<String>? videoUrls;
  final List<String>? attachmentUrls;
  final String? email;
  final String? phoneText;
  final String? phoneCall;
  final String? facebookInstagramLink;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? userId; // Reference to user who created the listing
  final bool? isActive;
  final bool? isVerified;
    final bool isBanned;
  final bool isRejected;
  final String? rejectionReason;

  const BusinessListing({
    this.id,
    this.businessName,
    this.description,
    this.businessCategory,
    this.subcategory,
    this.paymentStatus, // New field
    this.address,
    this.locationCityState,
    this.latitude,
    this.longitude,
    this.websiteOnlineStore,
    this.photoUrls,
    this.videoUrls,
    this.attachmentUrls,
    this.email,
    this.phoneText,
    this.phoneCall,
    this.facebookInstagramLink,
    this.createdAt,
    this.updatedAt,
    this.userId,
    this.isActive,
    this.isVerified,
        this.isBanned = false,
    this.isRejected = false,
    this.rejectionReason,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'businessName': businessName,
      'description': description,
      'businessCategory': businessCategory,
      'subcategory': subcategory,
      'address': address,
      'locationCityState': locationCityState,
      'latitude': latitude,
      'paymentStatus': paymentStatus,
      'longitude': longitude,
      'websiteOnlineStore': websiteOnlineStore,
      'photoUrls': photoUrls,
      'videoUrls': videoUrls,
      'attachmentUrls': attachmentUrls,
      'email': email,
      'phoneText': phoneText,
      'phoneCall': phoneCall,
      'facebookInstagramLink': facebookInstagramLink,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'userId': userId,
      'isActive': isActive ?? true,
      'isVerified': isVerified ?? false,
    };
  }

  // Create from Firebase document
  factory BusinessListing.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return BusinessListing(
      id: documentId,
      businessName: data['businessName'] as String?,
      description: data['description'] as String?,
      businessCategory:
          data['businessCategory'] != null
              ? List<String>.from(data['businessCategory'])
              : null,
      subcategory: data['subcategory'] as String?,
      address: data['address'] as String?,
      locationCityState: data['locationCityState'] as String?,
      latitude: data['latitude']?.toDouble(),
      paymentStatus: data['paymentStatus'] ?? 'pending',
      longitude: data['longitude']?.toDouble(),
      websiteOnlineStore: data['websiteOnlineStore'] as String?,
      photoUrls:
          data['photoUrls'] != null
              ? List<String>.from(data['photoUrls'])
              : null,
      videoUrls:
          data['videoUrls'] != null
              ? List<String>.from(data['videoUrls'])
              : null,
      attachmentUrls:
          data['attachmentUrls'] != null
              ? List<String>.from(data['attachmentUrls'])
              : null,
      email: data['email'] as String?,
      phoneText: data['phoneText'] as String?,
      phoneCall: data['phoneCall'] as String?,
      facebookInstagramLink: data['facebookInstagramLink'] as String?,
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
      updatedAt:
          data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : null,
      userId: data['userId'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      isVerified: data['isVerified'] as bool? ?? false,
    );
  }

  // Copy with method for updates
  BusinessListing copyWith({
    String? id,
    String? businessName,
    String? description,
    List<String>? businessCategory,
    String? subcategory,
    String? address,
    String? locationCityState,
    double? latitude,
    double? longitude,
    String? websiteOnlineStore,
    List<String>? photoUrls,
    List<String>? videoUrls,
    String? paymentStatus,
    List<String>? attachmentUrls,
    String? email,
    String? phoneText,
    String? phoneCall,
    String? facebookInstagramLink,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    bool? isActive,
    bool? isVerified,
  }) {
    return BusinessListing(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      description: description ?? this.description,
      businessCategory: businessCategory ?? this.businessCategory,
      subcategory: subcategory ?? this.subcategory,
      address: address ?? this.address,
      locationCityState: locationCityState ?? this.locationCityState,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      websiteOnlineStore: websiteOnlineStore ?? this.websiteOnlineStore,
      photoUrls: photoUrls ?? this.photoUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      email: email ?? this.email,
      phoneText: phoneText ?? this.phoneText,
      phoneCall: phoneCall ?? this.phoneCall,
      facebookInstagramLink:
          facebookInstagramLink ?? this.facebookInstagramLink,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  // Validation method
  bool get isValid {
    return businessName != null &&
        businessName!.isNotEmpty &&
        businessCategory != null &&
        businessCategory!.isNotEmpty;
  }

  // Get primary contact method
  String? get primaryContact {
    if (email != null && email!.isNotEmpty) return email;
    if (phoneCall != null && phoneCall!.isNotEmpty) return phoneCall;
    if (phoneText != null && phoneText!.isNotEmpty) return phoneText;
    return null;
  }

  @override
  String toString() {
    return 'BusinessListing(id: $id, businessName: $businessName, category: $businessCategory)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusinessListing && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Import statement needed for Timestamp
// import 'package:cloud_firestore/cloud_firestore.dart';
