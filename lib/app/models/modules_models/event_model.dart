import 'package:cloud_firestore/cloud_firestore.dart';

class EventListing {
  final String? id; // Firebase document ID
  final String? eventName;
  final String? description;
  final List<String>? eventCategory;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? eventWebsiteRegistrationLink;
  final String? facebookEventSocialLink;
  final List<String>? photoUrls;
  final List<String>? videoUrls;
  final List<String>? attachmentUrls;
  final String? paymentStatus; // New field: payment status
  final String? email;
  final String? phoneText;
  final String? phoneCall;
  final String? facebook;
  final DateTime? eventStartDate;
  final DateTime? eventEndDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? userId; // Reference to user who created the listing
  final bool? isActive;
  final bool? isFeatured;
    final bool isBanned;
  final bool isRejected;
  final String? rejectionReason;

  const EventListing({
    this.id,
    this.eventName,
    this.description,
    this.eventCategory,
    this.address,
    this.latitude,
    this.longitude,
    this.paymentStatus, // New field
    this.eventWebsiteRegistrationLink,
    this.facebookEventSocialLink,
    this.photoUrls,
    this.videoUrls,
    this.attachmentUrls,
    this.email,
    this.phoneText,
    this.phoneCall,
    this.facebook,
    this.eventStartDate,
    this.eventEndDate,
    this.createdAt,
    this.updatedAt,
    this.userId,
    this.isActive,
    this.isFeatured,
        this.isBanned = false,
    this.isRejected = false,
    this.rejectionReason,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'eventName': eventName,
      'description': description,
      'eventCategory': eventCategory,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'eventWebsiteRegistrationLink': eventWebsiteRegistrationLink,
      'facebookEventSocialLink': facebookEventSocialLink,
      'photoUrls': photoUrls,
      'videoUrls': videoUrls,
      'attachmentUrls': attachmentUrls,
      'paymentStatus': paymentStatus,
      'email': email,
      'phoneText': phoneText,
      'phoneCall': phoneCall,
      'facebook': facebook,
      'eventStartDate': eventStartDate,
      'eventEndDate': eventEndDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'userId': userId,
      'isActive': isActive ?? true,
      'isFeatured': isFeatured ?? false,
    };
  }

  // Create from Firebase document
  factory EventListing.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return EventListing(
      id: documentId,
      eventName: data['eventName'] as String?,
      description: data['description'] as String?,
      eventCategory:
          data['eventCategory'] != null
              ? List<String>.from(data['eventCategory'])
              : null,
      address: data['address'] as String?,
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      paymentStatus: data['paymentStatus'] ?? 'pending',
      eventWebsiteRegistrationLink:
          data['eventWebsiteRegistrationLink'] as String?,
      facebookEventSocialLink: data['facebookEventSocialLink'] as String?,
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
      facebook: data['facebook'] as String?,
      eventStartDate:
          data['eventStartDate'] != null
              ? (data['eventStartDate'] as Timestamp).toDate()
              : null,
      eventEndDate:
          data['eventEndDate'] != null
              ? (data['eventEndDate'] as Timestamp).toDate()
              : null,
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
      isFeatured: data['isFeatured'] as bool? ?? false,
    );
  }

  // Copy with method for updates
  EventListing copyWith({
    String? id,
    String? eventName,
    String? description,
    List<String>? eventCategory,
    String? address,
    double? latitude,
    double? longitude,
    String? eventWebsiteRegistrationLink,
    String? facebookEventSocialLink,
    List<String>? photoUrls,
    List<String>? videoUrls,
    List<String>? attachmentUrls,
    String? email,
    String? phoneText,
    String? phoneCall,
    String? facebook,
    DateTime? eventStartDate,
    DateTime? eventEndDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    bool? isActive,
    String? paymentStatus,
    bool? isFeatured,
  }) {
    return EventListing(
      id: id ?? this.id,
      eventName: eventName ?? this.eventName,
      description: description ?? this.description,
      eventCategory: eventCategory ?? this.eventCategory,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      eventWebsiteRegistrationLink:
          eventWebsiteRegistrationLink ?? this.eventWebsiteRegistrationLink,
      facebookEventSocialLink:
          facebookEventSocialLink ?? this.facebookEventSocialLink,
      photoUrls: photoUrls ?? this.photoUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      email: email ?? this.email,
      phoneText: phoneText ?? this.phoneText,
      phoneCall: phoneCall ?? this.phoneCall,
      facebook: facebook ?? this.facebook,
      eventStartDate: eventStartDate ?? this.eventStartDate,
      eventEndDate: eventEndDate ?? this.eventEndDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  // Validation method
  bool get isValid {
    return eventName != null &&
        eventName!.isNotEmpty &&
        eventCategory != null &&
        eventCategory!.isNotEmpty &&
        eventStartDate != null;
  }

  // Check if event is upcoming
  bool get isUpcoming {
    if (eventStartDate == null) return false;
    return eventStartDate!.isAfter(DateTime.now());
  }

  // Check if event is currently happening
  bool get isHappening {
    if (eventStartDate == null) return false;
    final now = DateTime.now();
    if (eventEndDate != null) {
      return now.isAfter(eventStartDate!) && now.isBefore(eventEndDate!);
    }
    // If no end date, assume it's a single day event
    return now.day == eventStartDate!.day &&
        now.month == eventStartDate!.month &&
        now.year == eventStartDate!.year;
  }

  // Check if event has ended
  bool get hasEnded {
    if (eventEndDate != null) {
      return DateTime.now().isAfter(eventEndDate!);
    }
    if (eventStartDate != null) {
      // If no end date, assume event ended the same day after start date
      final endOfStartDate = DateTime(
        eventStartDate!.year,
        eventStartDate!.month,
        eventStartDate!.day,
        23,
        59,
        59,
      );
      return DateTime.now().isAfter(endOfStartDate);
    }
    return false;
  }

  // Get event duration in days
  int get durationInDays {
    if (eventStartDate == null) return 0;
    if (eventEndDate == null) return 1; // Single day event
    return eventEndDate!.difference(eventStartDate!).inDays + 1;
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
    return 'EventListing(id: $id, eventName: $eventName, category: $eventCategory, startDate: $eventStartDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventListing && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Import statement needed for Timestamp
// import 'package:cloud_firestore/cloud_firestore.dart';
