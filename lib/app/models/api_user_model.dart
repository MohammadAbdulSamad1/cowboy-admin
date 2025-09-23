// app/models/user_model.dart
class ApiUserModel {
  final String id;
  final String username;
  final String name;
  final String firstName;
  final String lastName;
  final String email;
  final String url;
  final String description;
  final String link;
  final String locale;
  final String nickname;
  final String slug;
  final List<String> roles;
  final DateTime registeredDate;
  final Map<String, dynamic> capabilities;
  final Map<String, dynamic> extraCapabilities;
  final Map<String, String> avatarUrls;
  final Map<String, dynamic>? meta;
  final List<dynamic> acf;
  final bool isSuperAdmin;
  final List<int>? favouriteListings;

  ApiUserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.url,
    required this.description,
    required this.link,
    required this.locale,
    required this.nickname,
    required this.slug,
    required this.roles,
    required this.registeredDate,
    required this.capabilities,
    required this.extraCapabilities,
    required this.avatarUrls,
    this.meta,
    required this.acf,
    required this.isSuperAdmin,
    this.favouriteListings,
  });

  factory ApiUserModel.fromJson(Map<String, dynamic> json) {
    // Extract meta data properly
    Map<String, dynamic>? metaData;
    if (json['meta'] != null) {
      metaData = <String, dynamic>{};
      final rawMeta = json['meta'] as Map<String, dynamic>;
      
      // Convert meta arrays to their first values (WordPress stores meta as arrays)
      rawMeta.forEach((key, value) {
        if (value is List && value.isNotEmpty) {
          metaData![key] = value.first;
        } else {
          metaData![key] = value;
        }
      });
    }

    // Extract favourites if present
    List<int>? parsedFavourites;
    if (metaData != null && metaData.containsKey('atbdp_favourites')) {
      final favData = metaData['atbdp_favourites'];
      if (favData != null && favData.toString().isNotEmpty) {
        parsedFavourites = _parseFavourites(favData.toString());
      }
    }

    return ApiUserModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      url: json['url'] ?? '',
      description: json['description'] ?? '',
      link: json['link'] ?? '',
      locale: json['locale'] ?? 'en_US',
      nickname: json['nickname'] ?? '',
      slug: json['slug'] ?? '',
      roles: List<String>.from(json['roles'] ?? []),
      registeredDate: DateTime.tryParse(json['registered_date'] ?? '') ?? DateTime.now(),
      capabilities: Map<String, dynamic>.from(json['capabilities'] ?? {}),
      extraCapabilities: Map<String, dynamic>.from(json['extra_capabilities'] ?? {}),
      avatarUrls: Map<String, String>.from(json['avatar_urls'] ?? {}),
      meta: metaData,
      acf: List<dynamic>.from(json['acf'] ?? []),
      isSuperAdmin: json['is_super_admin'] ?? false,
      favouriteListings: parsedFavourites,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'url': url,
      'description': description,
      'link': link,
      'locale': locale,
      'nickname': nickname,
      'slug': slug,
      'roles': roles,
      'registered_date': registeredDate.toIso8601String(),
      'capabilities': capabilities,
      'extra_capabilities': extraCapabilities,
      'avatar_urls': avatarUrls,
      'meta': meta,
      'acf': acf,
      'is_super_admin': isSuperAdmin,
    };
  }

  // Helper method to parse PHP serialized favourites
  static List<int> _parseFavourites(String serializedData) {
    try {
      // Parse PHP serialized array: "a:2:{i:0;i:17538;i:1;i:17151;}"
      final regex = RegExp(r'i:\d+;i:(\d+);');
      final matches = regex.allMatches(serializedData);
      
      return matches
          .map((match) => int.tryParse(match.group(1) ?? '') ?? 0)
          .where((id) => id > 0)
          .toList();
    } catch (e) {
      print('Error parsing favourites: $e');
      return [];
    }
  }

  // Helper method to serialize favourites to PHP format
   String serializeFavourites(List<int> favourites) {
    if (favourites.isEmpty) return '';
    
    final length = favourites.length;
    final buffer = StringBuffer();
    buffer.write('a:$length:{');
    
    for (int i = 0; i < favourites.length; i++) {
      buffer.write('i:$i;i:${favourites[i]};');
    }
    
    buffer.write('}');
    return buffer.toString();
  }

  // Getter for display name
  String get displayName => name.isNotEmpty ? name : username;
  
  // Getter for photo URL
  String get photoURL => avatarUrls['96'] ?? avatarUrls['48'] ?? avatarUrls['24'] ?? '';
  
  // Check if user has active subscription
  bool get isActiveSubscription {
    if (meta == null) return false;
    
    // Check for Stripe customer key (indicates paid subscription)
    final stripeCustomerKey = meta!['_stripe_customer_key'];
    if (stripeCustomerKey != null && stripeCustomerKey.toString().isNotEmpty) {
      return true;
    }
    
    // Additional check: if user has subscriber role and stripe key
    final hasSubscriberRole = roles.contains('subscriber');
    
    return hasSubscriberRole && stripeCustomerKey != null;
  }
  
  // Get subscription tier/plan
  String get subscriptionPlan {
    if (!isActiveSubscription) return 'free';
    
    if (meta == null) return 'free';
    
    // Check for plan information in meta
    final planToActive = meta!['_plan_to_active'];
    if (planToActive != null) {
      // You can map plan IDs to plan names here
      switch (planToActive.toString()) {
        case '349':
          return 'premium'; // Based on the admin user data
        case '14753':
          return 'standard'; // Based on other subscriber users
        default:
          return 'subscriber';
      }
    }
    
    return 'subscriber';
  }
  
  // Get Stripe customer ID
  String? get stripeCustomerId {
    return meta?['_stripe_customer_key']?.toString();
  }
  
  // Check if user is verified
  bool get isEmailVerified {
    if (meta == null) return true; // Default to true if no meta
    
    final unverified = meta!['directorist_user_email_unverified'];
    return unverified == null || unverified != '1';
  }
  
  // Get user capabilities as a list
  List<String> get userCapabilities {
    final caps = <String>[];
    capabilities.forEach((key, value) {
      if (value == true || value == 1) {
        caps.add(key);
      }
    });
    return caps;
  }
  
  // Check if user has specific capability
  bool hasCapability(String capability) {
    return capabilities[capability] == true || capabilities[capability] == 1;
  }

  // Get favourite listing IDs
  List<int> get favouriteListingIds => favouriteListings ?? [];

  // Check if listing is in favourites
  bool isListingFavourite(int listingId) {
    return favouriteListingIds.contains(listingId);
  }

  // Add listing to favourites
  ApiUserModel addToFavourites(int listingId) {
    final currentFavs = List<int>.from(favouriteListingIds);
    
    if (!currentFavs.contains(listingId)) {
      currentFavs.add(listingId);
    }
    
    // Update meta with serialized format
    final updatedMeta = Map<String, dynamic>.from(meta ?? {});
    updatedMeta['atbdp_favourites'] = serializeFavourites(currentFavs);
    
    return copyWith(
      favouriteListings: currentFavs,
      meta: updatedMeta,
    );
  }

  // Remove listing from favourites
  ApiUserModel removeFromFavourites(int listingId) {
    final currentFavs = List<int>.from(favouriteListingIds);
    currentFavs.remove(listingId);
    
    // Update meta with serialized format
    final updatedMeta = Map<String, dynamic>.from(meta ?? {});
    if (currentFavs.isEmpty) {
      updatedMeta['atbdp_favourites'] = '';
    } else {
      updatedMeta['atbdp_favourites'] = serializeFavourites(currentFavs);
    }
    
    return copyWith(
      favouriteListings: currentFavs,
      meta: updatedMeta,
    );
  }

  // Toggle favourite status
  ApiUserModel toggleFavourite(int listingId) {
    if (isListingFavourite(listingId)) {
      return removeFromFavourites(listingId);
    } else {
      return addToFavourites(listingId);
    }
  }

  // Get total favourites count
  int get favouritesCount => favouriteListingIds.length;
  
  ApiUserModel copyWith({
    String? id,
    String? username,
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? url,
    String? description,
    String? link,
    String? locale,
    String? nickname,
    String? slug,
    List<String>? roles,
    DateTime? registeredDate,
    Map<String, dynamic>? capabilities,
    Map<String, dynamic>? extraCapabilities,
    Map<String, String>? avatarUrls,
    Map<String, dynamic>? meta,
    List<dynamic>? acf,
    bool? isSuperAdmin,
    List<int>? favouriteListings,
  }) {
    return ApiUserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      url: url ?? this.url,
      description: description ?? this.description,
      link: link ?? this.link,
      locale: locale ?? this.locale,
      nickname: nickname ?? this.nickname,
      slug: slug ?? this.slug,
      roles: roles ?? this.roles,
      registeredDate: registeredDate ?? this.registeredDate,
      capabilities: capabilities ?? this.capabilities,
      extraCapabilities: extraCapabilities ?? this.extraCapabilities,
      avatarUrls: avatarUrls ?? this.avatarUrls,
      meta: meta ?? this.meta,
      acf: acf ?? this.acf,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      favouriteListings: favouriteListings ?? this.favouriteListings,
    );
  }

  @override
  String toString() {
    return 'ApiUserModel(id: $id, username: $username, name: $name, isActiveSubscription: $isActiveSubscription, subscriptionPlan: $subscriptionPlan, favouritesCount: $favouritesCount)';
  }
}