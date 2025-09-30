class UnifiedListing {
  final int? id;
  final String? title;
  final String? content;
  final String? slug;
  final String? status;
  final String? link;
  final int? author;
  final String? date;
  final String? modified;
  final List<int>? listingTypes; // atbdp_listing_types
  final List<int>? categories; // at_biz_dir-category
  final List<int>? locations; // at_biz_dir-location
  final List<int>? tags; // at_biz_dir-tags
  final String? email;
  final String? phone;
  final String? address;
  final String? manualLat;
  final String? manualLng;
  final String? lat;
  final String? lng;
  final String? price;
  final String? listingPricing;
  final Map<String, dynamic>? listingImg;
  final Map<String, dynamic>? meta;

  final String? listingPrvImg;
  final String? featured;
  final String? listingStatus;
  // New image fields
  final List<ListingImage>? images;
  final String? featuredImageUrl;

  UnifiedListing({
    this.id,
    this.title,
    this.content,
    this.slug,
    this.status,
    this.link,
    this.author,
    this.date,
    this.modified,
    this.listingTypes,
    this.categories,
    this.meta,
    this.locations,
    this.tags,
    this.email,
    this.phone,
    this.address,
    this.manualLat,
    this.manualLng,
    this.lat,
    this.lng,
    this.price,
    this.listingPricing,
    this.listingImg,
    this.listingPrvImg,
    this.featured,
    this.listingStatus,
    this.images,
    this.featuredImageUrl,
  });

  factory UnifiedListing.fromJson(Map<String, dynamic> json) {
    // Handle featured field type conversion
    String? featuredValue;
    if (json['_featured'] != null) {
      if (json['_featured'] is bool) {
        featuredValue = json['_featured'] ? '1' : '0';
      } else if (json['_featured'] is String) {
        featuredValue = json['_featured'];
      } else if (json['_featured'] is List) {
        featuredValue =
            json['_featured'].isNotEmpty
                ? json['_featured'][0].toString()
                : '0';
      }
    }

    // Handle listing status field type conversion
    String? listingStatusValue;
    if (json['_listing_status'] != null) {
      if (json['_listing_status'] is String) {
        listingStatusValue = json['_listing_status'];
      } else if (json['_listing_status'] is List) {
        listingStatusValue =
            json['_listing_status'].isNotEmpty
                ? json['_listing_status'][0].toString()
                : 'post_status';
      }
    } else {
      // Fallback to meta field
      final meta = json['meta'] as Map<String, dynamic>?;
      if (meta != null && meta['_listing_status'] != null) {
        if (meta['_listing_status'] is List &&
            meta['_listing_status'].isNotEmpty) {
          listingStatusValue = meta['_listing_status'][0].toString();
        }
      }
    }

    // Extract images from various sources
    List<ListingImage> extractedImages = [];
    String? featuredImage;

    // 1. Extract from image_urls
    final imageUrls = json['image_urls'] as Map<String, dynamic>?;
    if (imageUrls != null) {
      featuredImage =
          imageUrls['featured'] is String ? imageUrls['featured'] : null;
      if (featuredImage != null && featuredImage.isNotEmpty) {
        if (!extractedImages.any((img) => img.url == featuredImage)) {
          extractedImages.add(
            ListingImage(
              url: featuredImage,
              width: null,
              height: null,
              type: 'image/jpeg',
              source: 'featured',
              isFeatured: true,
            ),
          );
        }
      }

      // Handle gallery images
      if (imageUrls['gallery'] is List) {
        final gallery = imageUrls['gallery'] as List<dynamic>;
        for (final imageUrl in gallery) {
          if (imageUrl is String && imageUrl.isNotEmpty) {
            if (!extractedImages.any((img) => img.url == imageUrl)) {
              extractedImages.add(
                ListingImage(
                  url: imageUrl,
                  width: null,
                  height: null,
                  type: 'image/jpeg',
                  source: 'gallery',
                ),
              );
            }
          }
        }
      }
    }

    return UnifiedListing(
      id: json['id'],
      title: json['title']?['rendered'],
      content: json['content']?['rendered'],
      slug: json['slug'],
      status: json['status'],
      link: json['link'],
      author: json['author'],
      date: json['date'],
      modified: json['modified'],
      listingTypes: (json['atbdp_listing_types'] as List?)?.cast<int>(),
      categories: (json['at_biz_dir-category'] as List?)?.cast<int>(),
      locations: (json['at_biz_dir-location'] as List?)?.cast<int>(),
      tags: (json['at_biz_dir-tags'] as List?)?.cast<int>(),
      email: json['_email']?.toString(),
      phone: json['_phone']?.toString(),
      address: json['_address']?.toString(),
      manualLat: json['_manual_lat']?.toString(),
      manualLng: json['_manual_lng']?.toString(),
      lat: json['_lat']?.toString(),
      lng: json['_lng']?.toString(),
      meta: json['meta'] ?? {},
      price: json['_price']?.toString(),
      listingPricing: json['_atbd_listing_pricing']?.toString(),
      featured: featuredValue,
      listingStatus: listingStatusValue,
      listingPrvImg: json['_listing_prv_img']?.toString(),
      listingImg:
          json['_listing_img'] is Map
              ? Map<String, dynamic>.from(json['_listing_img'])
              : null,
      images: extractedImages.isEmpty ? null : extractedImages,
      featuredImageUrl: featuredImage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': {'rendered': title},
      'content': {'rendered': content},
      'slug': slug,
      'status': status,
      'link': link,
      'author': author,
      'date': date,
      'modified': modified,
      'atbdp_listing_types': listingTypes,
      'at_biz_dir-category': categories,
      'at_biz_dir-location': locations,
      'at_biz_dir-tags': tags,
      '_email': email,
      '_phone': phone,
      '_address': address,
      '_manual_lat': manualLat,
      '_manual_lng': manualLng,
      '_lat': lat,
      'meta': meta,
      '_lng': lng,
      '_price': price,
      '_atbd_listing_pricing': listingPricing,
      '_listing_img': listingImg,
      '_listing_prv_img': listingPrvImg,
      '_featured': featured,
      '_listing_status': listingStatus,
    };
  }

  // Helper methods to get type-specific information
  String get listingType {
    if (listingTypes == null || listingTypes!.isEmpty) return 'Unknown';
    // Based on the listing types from your data:
    // 130 = Business, 335 = Events, 131 = item
    switch (listingTypes!.first) {
      case 130:
        return 'Business';
      case 335:
        return 'Event';
      case 131:
        return 'Item';
      default:
        return 'Unknown';
    }
  }

  bool get isItem => listingTypes?.contains(131) ?? false;
  bool get isBusiness => listingTypes?.contains(130) ?? false;
  bool get isEvent => listingTypes?.contains(335) ?? false;

  double? get priceAsDouble {
    if (price == null || price!.isEmpty) return null;
    return double.tryParse(price!);
  }

  double? get latitude {
    if (lat != null && lat!.isNotEmpty) return double.tryParse(lat!);
    if (manualLat != null && manualLat!.isNotEmpty) {
      return double.tryParse(manualLat!);
    }
    return null;
  }

  double? get longitude {
    if (lng != null && lng!.isNotEmpty) return double.tryParse(lng!);
    if (manualLng != null && manualLng!.isNotEmpty) {
      return double.tryParse(manualLng!);
    }
    return null;
  }

  bool get isActive => status == 'publish';

  String get cleanContent {
    if (content == null) return '';
    // Remove HTML tags
    return content!.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  DateTime? get createdAt {
    if (date == null) return null;
    return DateTime.tryParse(date!);
  }

  DateTime? get updatedAt {
    if (modified == null) return null;
    return DateTime.tryParse(modified!);
  }

  // New image helper methods
  List<ListingImage> get allImages => images ?? [];

  List<ListingImage> get ogImages =>
      allImages.where((img) => img.source == 'og_image').toList();

  List<ListingImage> get galleryImages =>
      allImages.where((img) => img.source == 'listing_img').toList();

  ListingImage? get primaryFeaturedImage =>
      allImages.where((img) => img.isFeatured == true).firstOrNull ??
      allImages.where((img) => img.source == 'og_image').firstOrNull;

  String? get primaryImageUrl => featuredImageUrl ?? primaryFeaturedImage?.url;

  // Method to get image URLs (you'll need to implement URL construction for IDs)
  List<String> getImageUrls({String? baseUrl}) {
    List<String> urls = [];

    for (var image in allImages) {
      if (image.url != null) {
        urls.add(image.url!);
      } else if (image.id != null && baseUrl != null) {
        // Construct URL from ID - you'll need to adjust this based on your WordPress setup
        urls.add('$baseUrl/wp-content/uploads/media/${image.id}');
      }
    }

    return urls;
  }
}

// Supporting class for image data
class ListingImage {
  final int? id;
  final String? url;
  final int? width;
  final int? height;
  final String? type;
  final String source; // 'og_image', 'listing_img', 'featured_img'
  final int position;
  final bool isFeatured;

  ListingImage({
    this.id,
    this.url,
    this.width,
    this.height,
    this.type,
    required this.source,
    this.position = 0,
    this.isFeatured = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'width': width,
      'height': height,
      'type': type,
      'source': source,
      'position': position,
      'isFeatured': isFeatured,
    };
  }

  factory ListingImage.fromJson(Map<String, dynamic> json) {
    return ListingImage(
      id: json['id'],
      url: json['url'],
      width: json['width'],
      height: json['height'],
      type: json['type'],
      source: json['source'] ?? 'unknown',
      position: json['position'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
    );
  }
}

// Extension to help with null-aware operations
extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
