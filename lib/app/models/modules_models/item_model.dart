import 'package:cloud_firestore/cloud_firestore.dart';

class ItemListing {
  final String? id; // Firebase document ID
  final String? itemName;
  final String? description;
  final List<String>? category;
  final String? location;
  final String? cityState;
  final double? latitude;
  final double? longitude;
  final String? linkWebsite;
  final List<String>? photoUrls;
  final List<String>? videoUrls;
  final List<String>? attachmentUrls;
  final String? sizeDimensions;
  final String? condition;
  final String? brand;
  final double? price;
  final String? shippingInfo;
  final String? phoneNumber;
  final String? email;
  final String? preferredContactMethod; // 'text', 'messenger', 'email'
  final List<String>? paymentMethod; // 'paypal', 'venmo', 'cash', 'credit_card'
  final String? otherPaymentOptions;
  final String? paypalAccount; // New field
  final String? cashappAccount; // New field
  final String? venmoAccount; // New field
  final String? facebookPage; // New field
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? userId; // Reference to user who created the listing
  final String? paymentStatus; // New field: payment status
  final bool? isActive;
  final bool isBanned;
  final bool isRejected;
  final String? rejectionReason;

  const ItemListing({
    this.id,
    this.itemName,
    this.description,
    this.category,
    this.location,
    this.cityState,
    this.latitude,
    this.longitude,
    this.linkWebsite,
    this.photoUrls,
    this.videoUrls,
    this.attachmentUrls,
    this.sizeDimensions,
    this.condition,
    this.brand,
    this.price,
    this.shippingInfo,
    this.email,
    this.preferredContactMethod,
    this.paymentMethod,
    this.otherPaymentOptions,
    this.paymentStatus, // New field
    this.paypalAccount, // New field
    this.cashappAccount, // New field
    this.venmoAccount, // New field
    this.createdAt,
    this.updatedAt,
    this.facebookPage,
    this.userId,
    this.isActive,
    this.isBanned = false,
    this.isRejected = false,
    this.rejectionReason,
    this.phoneNumber,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'itemName': itemName,
      'description': description,
      'category': category,
      'location': location,
      'cityState': cityState,
      'latitude': latitude,
      'longitude': longitude,
      'linkWebsite': linkWebsite,
      'photoUrls': photoUrls,
      'videoUrls': videoUrls,
      'attachmentUrls': attachmentUrls,
      'sizeDimensions': sizeDimensions,
      'condition': condition,
      'brand': brand,
      'price': price,
      'shippingInfo': shippingInfo,
      'email': email,
      'preferredContactMethod': preferredContactMethod,
      'paymentMethod': paymentMethod,
      'otherPaymentOptions': otherPaymentOptions,
      'paypalAccount': paypalAccount, // New field
      'cashappAccount': cashappAccount, // New field
      'venmoAccount': venmoAccount, // New field
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'paymentStatus': paymentStatus,
      'userId': userId,
      'isActive': isActive ?? true,
      'facebookPage': facebookPage,
      'phonenumber': phoneNumber,
    };
  }

  // Create from Firebase document
  factory ItemListing.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return ItemListing(
      id: documentId,
      itemName: data['itemName'] as String?,
      description: data['description'] as String?,
      category: data['category'] != null
          ? List<String>.from(data['category'])
          : null,
      location: data['location'] as String?,
      cityState: data['cityState'] as String?,
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      paymentStatus: data['paymentStatus'] ?? 'pending',
      linkWebsite: data['linkWebsite'] as String?,
      photoUrls: data['photoUrls'] != null
          ? List<String>.from(data['photoUrls'])
          : null,
      videoUrls: data['videoUrls'] != null
          ? List<String>.from(data['videoUrls'])
          : null,
      attachmentUrls: data['attachmentUrls'] != null
          ? List<String>.from(data['attachmentUrls'])
          : null,
      sizeDimensions: data['sizeDimensions'] as String?,
      condition: data['condition'] as String?,
      brand: data['brand'] as String?,
      price: data['price']?.toDouble(),
      shippingInfo: data['shippingInfo'] as String?,
      email: data['email'] as String?,
      preferredContactMethod: data['preferredContactMethod'] as String?,
      paymentMethod: data['paymentMethod'] != null
          ? data['paymentMethod'] is String
                ? [data['paymentMethod']]
                : List<String>.from(data['paymentMethod'])
          : null,
      otherPaymentOptions: data['otherPaymentOptions'] as String?,
      paypalAccount: data['paypalAccount'] as String?, // New field
      cashappAccount: data['cashappAccount'] as String?, // New field
      venmoAccount: data['venmoAccount'] as String?, // New field
      facebookPage: data['facebookPage'] as String?,
      phoneNumber: data['phonenumber'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      userId: data['userId'] as String?,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  // Copy with method for updates
  ItemListing copyWith({
    String? id,
    String? itemName,
    String? description,
    List<String>? category,
    String? location,
    String? cityState,
    double? latitude,
    double? longitude,
    String? linkWebsite,
    List<String>? photoUrls,
    List<String>? videoUrls,
    List<String>? attachmentUrls,
    String? sizeDimensions,
    String? condition,
    String? brand,
    double? price,
    String? facebookPage,
    String? shippingInfo,
    String? email,
    String? preferredContactMethod,
    List<String>? paymentMethod,
    String? otherPaymentOptions,
    String? paypalAccount, // New field
    String? cashappAccount, // New field
    String? venmoAccount, // New field
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    bool? isActive,
    String? phoneNumber,
    String? paymentStatus,
  }) {
    return ItemListing(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      cityState: cityState ?? this.cityState,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      facebookPage: facebookPage ?? this.facebookPage,
      linkWebsite: linkWebsite ?? this.linkWebsite,
      photoUrls: photoUrls ?? this.photoUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      sizeDimensions: sizeDimensions ?? this.sizeDimensions,
      condition: condition ?? this.condition,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      shippingInfo: shippingInfo ?? this.shippingInfo,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      preferredContactMethod:
          preferredContactMethod ?? this.preferredContactMethod,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      otherPaymentOptions: otherPaymentOptions ?? this.otherPaymentOptions,
      paypalAccount: paypalAccount ?? this.paypalAccount, // New field
      cashappAccount: cashappAccount ?? this.cashappAccount, // New field
      venmoAccount: venmoAccount ?? this.venmoAccount, // New field
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      isActive: isActive ?? this.isActive,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  @override
  String toString() {
    return 'ItemListing(id: $id, itemName: $itemName, category: $category, price: $price)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemListing && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
