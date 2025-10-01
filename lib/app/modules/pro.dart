import 'package:dedicated_cow_boy_admin/app/modules/useraccounts.dart';
import 'package:dedicated_cow_boy_admin/app/profile/controllers/profile_controller.dart';
import 'package:dedicated_cow_boy_admin/app/profile/views/edit.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileDialog extends StatefulWidget {
  @override
  _ProfileDialogState createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  String _currentView = 'profile'; // 'profile', 'edit', 'password'
  final ProfileController controller = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 0,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ProfileTopBar(),
            SizedBox(height: 30),
            _buildHeader(),
            Flexible(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1)),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentView != 'profile')
            IconButton(
              onPressed: () => setState(() => _currentView = 'profile'),
              icon: Icon(Icons.arrow_back, color: Color(0xFF2D3748), size: 24),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            )
          else
            Text(
              _currentView == 'profile'
                  ? 'My Profile'
                  : _currentView == 'edit'
                  ? 'My Profile'
                  : 'Change Password',
              style: TextStyle(
                fontSize: 20,
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: EdgeInsets.all(24),
      child:
          _currentView == 'profile'
              ? _buildProfileView()
              : _currentView == 'edit'
              ? _buildEditView()
              : _buildPasswordView(),
    );
  }

  Widget _buildProfileView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Column(
              children: [
                // Profile Image
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: CircleAvatar(
                    radius: 73,
                    backgroundColor: Color(0xFFE0E0E0),
                    backgroundImage:
                        controller.currentUser.value?.profile_image != null &&
                                controller
                                    .currentUser
                                    .value!
                                    .profile_image!
                                    .isNotEmpty
                            ? NetworkImage(
                              controller.currentUser.value!.profile_image!,
                            )
                            : null,
                    child:
                        controller.currentUser.value?.profile_image == null ||
                                controller
                                    .currentUser
                                    .value!
                                    .profile_image!
                                    .isEmpty
                            ? Icon(Icons.person, size: 45, color: Colors.white)
                            : null,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  controller.currentUser.value?.displayName ??
                      'Admin Dedicated Cowboy',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF2D3748),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6),
                Text(
                  controller.currentUser.value?.email ??
                      'admin@dedicatedcowboy.com',
                  style: TextStyle(fontSize: 14, color: Color(0xFF718096)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          // Edit Profile Button
          _buildMenuItem(
            icon: Icons.edit_outlined,
            title: 'Edit Profile',
            onTap: () => setState(() => _currentView = 'edit'),
          ),
          SizedBox(height: 16),
          // Password Button
          _buildMenuItem(
            icon: Icons.lock_outline,
            title: 'Password',
            onTap: () => setState(() => _currentView = 'password'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFF2D3748),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Icon(Icons.chevron_right, color: Color(0xFF718096), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEditView() {
    return UserProfileEditScreen();
  }

  Widget _buildPasswordView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => _buildPasswordField(
              'Old Password',
              controller.oldPasswordController,
              controller.obscureOldPassword.value,
              () =>
                  controller.obscureOldPassword.value =
                      !controller.obscureOldPassword.value,
            ),
          ),
          SizedBox(height: 20),
          Obx(
            () => _buildPasswordField(
              'New Password',
              controller.newPasswordController,
              controller.obscureNewPassword.value,
              () =>
                  controller.obscureNewPassword.value =
                      !controller.obscureNewPassword.value,
            ),
          ),
          SizedBox(height: 20),
          Obx(
            () => _buildPasswordField(
              'Confirm Password',
              controller.confirmPasswordController,
              controller.obscureConfirmPassword.value,
              () =>
                  controller.obscureConfirmPassword.value =
                      !controller.obscureConfirmPassword.value,
            ),
          ),
          SizedBox(height: 32),
          Obx(
            () => _buildButton(
              controller.isUpdatingPassword.value ? 'Submitting...' : 'Submit',
              Color(0xFFFDB022),
              Colors.white,
              controller.isUpdatingPassword.value
                  ? null
                  : () async {
                    await controller.updatePassword();
                    setState(() => _currentView = 'profile');
                  },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    String? placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFFE2E8F0), width: 1),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(fontSize: 14, color: Color(0xFF2D3748)),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool obscure,
    VoidCallback toggleObscure,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFFE2E8F0), width: 1),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: TextStyle(fontSize: 14, color: Color(0xFF2D3748)),
            decoration: InputDecoration(
              hintText: '••••••••••',
              hintStyle: TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: GestureDetector(
                onTap: toggleObscure,
                child: Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Color(0xFF718096),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(
    String text,
    Color backgroundColor,
    Color textColor,
    VoidCallback? onPressed, {
    bool hasBorder = false,
  }) {
    return Container(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side:
                hasBorder
                    ? BorderSide(color: Color(0xFFE2E8F0), width: 1)
                    : BorderSide.none,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// How to use this dialog:
void showProfileDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => ProfileDialog(),
    barrierDismissible: true,
  );
}
