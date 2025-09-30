// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dedicated_cow_boy_admin/app/modules/cv.dart';
import 'package:dedicated_cow_boy_admin/app/profile/controllers/profile_controller.dart';

import 'package:flutter/material.dart';

import 'package:get/get.dart';

class UserProfileEditScreen extends StatefulWidget {
  const UserProfileEditScreen({super.key});

  @override
  _UserProfileEditScreenState createState() => _UserProfileEditScreenState();
}

class _UserProfileEditScreenState extends State<UserProfileEditScreen> {
  static const double _collapsedAppBarHeight = 60.0;
  static const double _expandedAppBarHeight = 280.0;

  // Get the ProfileController instance
  final ProfileController controller = Get.put(ProfileController());

  @override
  void initState() {
    super.initState();
    // Controllers are already populated from the ProfileController
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildProfileForm()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: _expandedAppBarHeight,
      collapsedHeight: _collapsedAppBarHeight,
      pinned: true,
      backgroundColor: const Color(0xff364C63),
      leading: GestureDetector(
        onTap: () => Get.back(),
        child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
      ),
      title: const Text(
        'Edit Profile',
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Background image
            Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xff364C63),
              child: Image.asset(
                'assets/images/5001147_19742 1.png',
                fit: BoxFit.cover,
              ),
            ),
            // Dark overlay
            Container(
              height: double.infinity,
              width: double.infinity,
              decoration: const BoxDecoration(color: Colors.black45),
            ),
            // Profile content
            _buildProfileHeader(),
          ],
        ),
        collapseMode: CollapseMode.parallax,
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40), // Account for app bar
          Obx(
            () => GestureDetector(
              onTap: controller.changeProfilePicture,
              child: Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child:
                          controller.isUploadingImage.value
                              ? Container(
                                color: Colors.white,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFF2B342),
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                              : controller.currentUser.value?.profile_image !=
                                  null
                              ? CachedNetworkImage(
                                imageUrl:
                                    controller
                                        .currentUser
                                        .value
                                        ?.profile_image ??
                                    '',
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      color: Colors.white,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFFF2B342),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) =>
                                        _buildAvatarFallback(),
                              )
                              : _buildAvatarFallback(),
                    ),
                  ),
                  // Camera icon overlay
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2B342),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => Text(
              controller.currentUser.value?.displayName ?? 'User Name',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Obx(
            () => Text(
              controller.userEmail.value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                shadows: const [
                  Shadow(
                    color: Colors.black45,
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          // Add subscription badge if user has active subscription
          Obx(() {
            if (controller.isActiveSubscription.value) {
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2B342),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  controller.subscriptionPlan.value.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: const Color(0xFFF2B342).withOpacity(0.2),
      child: Center(
        child: Obx(
          () => Text(
            _getInitials(controller.currentUser.value?.displayName ?? 'U'),
            style: const TextStyle(
              color: Color(0xFFF2B342),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final words = name.trim().split(' ');
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  Widget _buildProfileForm() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Information Section
          _buildSectionTitle('Personal Information'),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Display Name',
            controller: controller.displayNameController,
            hintText: 'Enter your display name',
          ),
          _buildFormField(
            label: 'Username',
            controller: controller.userNameController,
            hintText: 'Enter your username',
          ),
          _buildFormField(
            label: 'First Name',
            controller: controller.firstNameController,
            hintText: 'Enter your first name',
          ),
          _buildFormField(
            label: 'Last Name',
            controller: controller.lastNameController,
            hintText: 'Enter your last name',
          ),
          _buildFormField(
            label: 'Email',
            controller: controller.emailController,
            hintText: 'user@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
          _buildFormField(
            label: 'Website',
            controller: controller.websiteController,
            hintText: 'https://yourwebsite.com',
            keyboardType: TextInputType.url,
          ),
          _buildFormField(
            label: 'About Author',
            controller: controller.descriptionController,
            hintText: 'Tell us about yourself',
            maxLines: 4,
          ),

          // Social Media Section
          const SizedBox(height: 32),
          _buildSectionTitle('Social Profiles'),
          const SizedBox(height: 24),

          _buildSocialField(
            label: 'Facebook',
            controller: controller.facebookController,
            icon: Icons.facebook,
            color: const Color(0xFF1877F2),
          ),

          _buildSocialField(
            label: 'Twitter',
            controller: controller.instagramController,
            customIcon: _buildTwitterIcon(),
            color: const Color(0xFF000000),
          ),

          _buildSocialField(
            label: 'LinkedIn',
            controller: controller.linkedinController,
            icon: Icons.business_center,
            color: const Color(0xFF0A66C2),
          ),

          _buildSocialField(
            label: 'Youtube',
            controller: controller.youtubeController,
            icon: Icons.play_circle_filled,
            color: const Color(0xFFFF0000),
          ),

          // Account Information
          const SizedBox(height: 32),
          _buildSectionTitle('Account Information'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => _buildInfoRow(
                    'Account Type:',
                    controller.subscriptionPlan.value.toUpperCase(),
                  ),
                ),
                Obx(
                  () => _buildInfoRow(
                    'User Roles:',
                    controller.currentUser.value?.roles.join(', ') ?? 'N/A',
                  ),
                ),
                Obx(
                  () => _buildInfoRow(
                    'Member Since:',
                    _formatDate(controller.currentUser.value?.registeredDate),
                  ),
                ),
                Obx(
                  () => _buildInfoRow(
                    'Favourites:',
                    '${controller.favouriteListingIds.length} listings',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF333333),
        letterSpacing: 0.1,
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color(0xFF999999),
                fontSize: 14,
              ),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF5A7A95),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    Widget? customIcon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Platform label with icon
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child:
                    customIcon ??
                    Icon(icon, color: const Color(0xFF666666), size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Input field with underline style
          TextFormField(
            controller: controller,
            style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
            decoration: InputDecoration(
              hintText: 'Enter your ${label.toLowerCase()} url',
              hintStyle: const TextStyle(
                color: Color(0xFF6B859D),
                fontSize: 14,
              ),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: color, width: 2),
              ),
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Leave it empty to hide',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildTwitterIcon() {
    return Container(
      width: 20,
      height: 20,
      child: CustomPaint(painter: TwitterXPainter()),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: Obx(
        () => CustomElevatedButton(
          text: 'Save Changes',
          backgroundColor: const Color(0xFF42576C),
          textColor: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          borderRadius: 6,
          isLoading: controller.isSaving.value,
          onTap: controller.saveProfileChanges,
        ),
      ),
    );
  }
}

// Custom painter for Twitter X icon
class TwitterXPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF000000)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

    // Draw the X shape
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.8),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.2, size.height * 0.8),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
