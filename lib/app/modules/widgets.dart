import 'package:dedicated_cow_boy_admin/app/models/model.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import 'package:get/get.dart';

// Global favorite state controller

class UnifiedDetailScreen extends StatefulWidget {
  final UnifiedListing listing;

  const UnifiedDetailScreen({super.key, required this.listing});

  @override
  _UnifiedDetailScreenState createState() => _UnifiedDetailScreenState();
}

class _UnifiedDetailScreenState extends State<UnifiedDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isPopular() {
    final postViews =
        int.tryParse(metaData['_atbdp_post_views_count']?.first ?? '0') ?? 0;
    final pageViews = int.tryParse(metaData['wl_pageviews']?.first ?? '0') ?? 0;
    final totalViews = postViews + pageViews;

    return postViews >= 8; // Threshold for popular items
  }

  // Dynamic meta data getter
  Map<String, dynamic> get metaData => widget.listing.meta ?? {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: RichText(
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: [
              // TextSpan(
              //   text: '${_getListingTypeCategory()}/',
              //   style: TextStyle(
              //     color: Colors.black,
              //     fontSize: 12,
              //     fontWeight: FontWeight.normal,
              //   ),
              // ),
              TextSpan(
                text: widget.listing.slug ?? '',
                style: TextStyle(
                  color: Color.fromARGB(255, 2, 2, 2),
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        actions: [SizedBox(width: 20)],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Media Gallery Section
            _buildEnhancedMediaGallery(),

            // Listing Info - Reorganized to match the image layout
            Padding(
              padding: EdgeInsets.only(left: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.listing.title ??
                        'Unnamed ${widget.listing.listingType}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'popins-bold',
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Popular tag (if applicable)
                  if (_isPopular())
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFFF2B342),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Color(0xFFF2B342)),
                      ),
                      child: Text(
                        'POPULAR',
                        style: TextStyle(
                          fontSize: 9,
                          fontFamily: 'popins-bold',
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  SizedBox(height: 16),

                  // Price
                  _buildPriceSection(),
                  SizedBox(height: 8),
                  Divider(thickness: 1, color: Colors.grey[300]),
                  // SizedBox(height: 8),

                  // Size/Dimensions (inline format like in image)
                  _buildSizeSection(),

                  // Location (inline format like in image)
                  _buildLocationInlineSection(),

                  // Shipping info (inline format like in image)
                  _buildShippingInfoInlineSection(),
                  SizedBox(height: 8),
                  Divider(thickness: 1, color: Colors.grey[300]),
                  SizedBox(height: 8),

                  // Description
                  if (widget.listing.cleanContent.isNotEmpty) ...[
                    Text(
                      widget.listing.cleanContent,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xff404040),
                        fontFamily: 'popins',
                      ),
                    ),
                    SizedBox(height: 32),
                  ],

                  // Email Section
                  _buildEmailSection(),
                  _buildphoneSection(),

                  // Payment Options Section
                  _buildPaymentOptionsSection(),
                  _buildPaypalSection(),

                  // Venmo account section
                  _buildVenmoSection(),
                  _buildCahAPpSection(),

                  // Preferred contact section
                  _buildPreferredContactSection(),
                  _buildotherPaymentSection(),
                  SizedBox(height: 32),

                  SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedMediaGallery() {
    final images = widget.listing?.images ?? [];

    if (images.isEmpty) {
      return Container(
        height: 300,
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
        ),
      );
    }

    return Container(
      height: 300,
      margin: EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          // Left side - Thumbnail list
          Container(
            width: 70,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: images.length > 4 ? 4 : images.length,
                    itemBuilder: (context, index) {
                      if (index == 3 && images.length > 4) {
                        return _buildMoreImagesThumbnail(images.length - 3);
                      }
                      return _buildThumbnail(
                        images[index].url.toString(),
                        index,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),

          // Right side - Main image display
          Expanded(
            child: Stack(
              children: [
                // Main image
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Get.to(
                        () => ImageViewer(
                          imageUrl: images[_currentImageIndex].url.toString(),
                        ),
                      );
                    },
                    child: CachedNetworkImage(
                      key: ValueKey(
                        '${widget.listing.id}_${images[_currentImageIndex].url}',
                      ),
                      imageUrl: images[_currentImageIndex].url.toString(),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,

                      placeholder:
                          (context, url) => Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.image_not_supported, size: 50),
                          ),
                      fadeInDuration: const Duration(milliseconds: 300),
                      fadeOutDuration: const Duration(milliseconds: 100),
                    ),
                  ),
                ),

                // Navigation buttons (only show when multiple images)
                if (images.length > 1) ...[
                  // Previous button
                  Positioned(
                    left: 6,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(0xff7f7f7f),
                          border: Border.all(color: Colors.black12),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 16,
                          ),
                          onPressed:
                              _currentImageIndex > 0
                                  ? () {
                                    setState(() {
                                      _currentImageIndex--;
                                    });
                                  }
                                  : null,
                        ),
                      ),
                    ),
                  ),

                  // Next button
                  Positioned(
                    right: 6,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(0xff7f7f7f),
                          border: Border.all(color: Colors.black12),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 16,
                          ),
                          onPressed:
                              _currentImageIndex < images.length - 1
                                  ? () {
                                    setState(() {
                                      _currentImageIndex++;
                                    });
                                  }
                                  : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(String imageUrl, int index) {
    final isSelected = _currentImageIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentImageIndex = index;
        });
      },
      child: Container(
        height: 60,
        margin: EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Color(0xFFF2B342) : Colors.transparent,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: CachedNetworkImage(
            key: ValueKey('thumb_${widget.listing.id}_$imageUrl'),
            imageUrl: imageUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low,

            placeholder:
                (context, url) => Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 1),
                    ),
                  ),
                ),
            errorWidget:
                (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.image_not_supported, size: 20),
                ),
            fadeInDuration: const Duration(milliseconds: 200),
            fadeOutDuration: const Duration(milliseconds: 100),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreImagesThumbnail(int moreCount) {
    return GestureDetector(
      onTap: () {
        _showAllImagesDialog();
      },
      child: Container(
        height: 60,
        margin: EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black.withOpacity(0.7),
        ),
        child: Center(
          child: Text(
            '+$moreCount\nmore',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _showAllImagesDialog() {
    final images = widget.listing?.images ?? [];

    Get.dialog(
      Dialog(
        backgroundColor: Colors.black,
        child: Container(
          height: Get.height * 0.8,
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Images (${images.length})',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),

              // Grid of all images
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Get.back();
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          key: ValueKey(
                            'grid_${widget.listing.id}_${images[index].url}',
                          ),
                          imageUrl: images[index].url.toString(),
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,

                          placeholder:
                              (context, url) => Container(
                                color: Colors.grey[800],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: Colors.grey[800],
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 30,
                                  color: Colors.white,
                                ),
                              ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceSection() {
    final price = _getPrice();
    if (price.isEmpty) return SizedBox.shrink();

    return Text(
      price,
      style: TextStyle(
        fontSize: 26,
        fontFamily: 'popins-bold',
        fontWeight: FontWeight.bold,
        color: Color(0xFFF2B342),
      ),
    );
  }

  // New inline sections to match the image format
  Widget _buildSizeSection() {
    final size = metaData['_custom-text-2']?.first ?? '';
    if (size.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Size / Dimensions : ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'popins',
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8), // spacing between heading and value
          Text(
            size,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Color(0xff404040),
              fontFamily: 'popins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInlineSection() {
    final address = _getAddress();
    if (address.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location/City & State : ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'popins',
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8), // spacing between heading and value
          Text(
            address,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Color(0xff404040),
              fontFamily: 'popins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingInfoInlineSection() {
    final shippingInfo = _getShippingInfo();
    if (shippingInfo.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shipping info / Pickup : ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'popins',
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8), // spacing between heading and value
          Text(
            shippingInfo,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Color(0xff404040),
              fontFamily: 'popins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSection() {
    final email = _getEmail();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email :',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'popins',
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8), // spacing between heading and value
        Text(
          email.isNotEmpty ? email : 'Contact through the app for more details',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Color(0xff404040),
            fontFamily: 'popins',
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOptionsSection() {
    final paymentOptions = _getPaymentOptions();
    if (paymentOptions.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Options :',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'popins',
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8), // spacing between heading and value
          Text(
            paymentOptions,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xff404040),
              fontFamily: 'popins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenmoSection() {
    final venmoAccount = _getVenmoAccount();
    if (venmoAccount.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Venmo account number :',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'popins',
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8), // spacing between heading and value
          Text(
            venmoAccount,
            style: TextStyle(
              color: Color(0xff404040),
              fontFamily: 'popins',
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCahAPpSection() {
    final venmoAccount = _getCashAppAccount();
    if (venmoAccount.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CashApp account number :',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'popins',
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8), // spacing between heading and value
          Text(
            venmoAccount,
            style: TextStyle(
              color: Color(0xff404040),
              fontFamily: 'popins',
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaypalSection() {
    final venmoAccount = _getPaypalAccount();
    if (venmoAccount.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paypal account number :',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'popins',
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8), // spacing between heading and value
          Text(
            venmoAccount,
            style: TextStyle(
              color: Color(0xff404040),
              fontFamily: 'popins',
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildotherPaymentSection() {
    final venmoAccount = _getOtherPaymentOptions();
    if (venmoAccount.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Other Payment Options :',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'popins',
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8), // spacing between heading and value
          Text(
            venmoAccount,
            style: TextStyle(
              color: Color(0xff404040),
              fontFamily: 'popins',
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildphoneSection() {
    final phone = _getOnlyPhone();
    if (phone.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phone number :',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'popins',
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8), // spacing between heading and value
          Text(
            phone,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xff404040),
              fontFamily: 'popins',
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferredContactSection() {
    final preferredContact = _getPreferredContact();
    if (preferredContact.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferred Method of Contact :',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'popins',
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8), // spacing between heading and value
          Text(
            preferredContact,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xff404040),
              fontFamily: 'popins',
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods remain the same
  String _getPrice() {
    final price = metaData['_price']?.first ?? widget.listing.price ?? '';
    return price.isNotEmpty ? '\$$price' : '';
  }

  String _getAddress() {
    return metaData['_address']?.first ?? widget.listing.address ?? '';
  }

  String _getEmail() {
    return metaData['_email']?.first ?? widget.listing.email ?? '';
  }

  String _getPhone() {
    return metaData['_phone']?.first ??
        metaData['_custom-text-3']?.first ??
        widget.listing.phone ??
        '';
  }

  String _getOnlyPhone() {
    return metaData['_phone']?.first ?? '';
  }

  String _getShippingInfo() {
    return metaData['_custom-text-3']?.first ?? '';
  }

  String _getPaymentOptions() {
    List<String> paymentOptions = [];
    if (metaData['_custom-checkbox-2'] != null) {
      String serialized = metaData['_custom-checkbox-2']?.first ?? '';

      // Regex to match strings inside quotes
      RegExp regex = RegExp(r'"([^"]*)"');
      Iterable<RegExpMatch> matches = regex.allMatches(serialized);

      List<String> names = matches.map((m) => m.group(1)!).toList();

      paymentOptions.addAll(names);
      return paymentOptions.join(', ');
    }
    String venmoField = metaData['_custom-textarea']?.first ?? '';

    if (venmoField.isNotEmpty) {
      paymentOptions.add('Venmo');
    }

    String cashAppField = metaData['_custom-text-7']?.first ?? '';
    if (cashAppField.isNotEmpty) {
      paymentOptions.add('CashApp');
    }

    String paypalField = metaData['_custom-text-6']?.first ?? '';
    if (paypalField.isNotEmpty) {
      paymentOptions.add('PayPal');
    }

    return paymentOptions.join(', ');
  }

  String _getVenmoAccount() {
    final venmoField = metaData['_custom-textarea']?.first ?? '';
    return venmoField;
  }

  String _getPaypalAccount() {
    final venmoField = metaData['_custom-text-6']?.first ?? '';
    return venmoField;
  }

  String _getCashAppAccount() {
    final cashAppField = metaData['_custom-text-7']?.first ?? '';
    return cashAppField;
  }

  String _getOtherPaymentOptions() {
    final otherPayments =
        metaData['_custom-text']?.first ??
        metaData['_other_payments']?.first ??
        metaData['_custom-other-payments']?.first ??
        '';
    return otherPayments;
  }

  String _getPreferredContact() {
    final contactData = metaData['_custom-checkbox-3']?.first ?? '';
    if (contactData.isNotEmpty) {
      List<String> methods = [];
      if (contactData.contains('Text')) methods.add('Text');
      if (contactData.contains('Call')) methods.add('Call');
      if (contactData.contains('Email')) methods.add('Email');
      return methods.join(', ');
    }
    return '';
  }

  String _getContactButtonText() {
    switch (widget.listing.listingType.toLowerCase()) {
      case 'item':
        return 'Inquire Now';
      case 'business':
        return 'Contact Business';
      case 'event':
        return 'Contact Organizer';
      default:
        return 'Contact';
    }
  }
}

// Updated ImageViewer (remains the same)
class ImageViewer extends StatelessWidget {
  final String imageUrl;

  const ImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: PhotoView(
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            imageProvider: NetworkImage(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
            heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
          ),
        ),
      ),
    );
  }
}
