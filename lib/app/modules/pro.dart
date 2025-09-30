import 'package:dedicated_cow_boy_admin/app/profile/controllers/profile_controller.dart';
import 'package:dedicated_cow_boy_admin/app/profile/views/edit.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileDialog extends StatefulWidget {
  @override
  _ProfileDialogState createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  String _currentView = 'profile'; // 'profile', 'edit', 'password'
  final ProfileController controller = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 0,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_buildHeader(), Flexible(child: _buildContent())],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1)),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentView != 'profile')
            IconButton(
              onPressed: () => setState(() => _currentView = 'profile'),
              icon: Icon(Icons.arrow_back, color: Color(0xFF495057)),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            )
          else
            SizedBox(width: 24),

          Text(
            _currentView == 'profile'
                ? 'My Profile'
                : _currentView == 'edit'
                ? 'Edit Profile'
                : 'Change Password',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF495057),
              fontWeight: FontWeight.w600,
            ),
          ),

          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: Color(0xFF495057)),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: EdgeInsets.all(20),
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
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xFFE9ECEF),
              borderRadius: BorderRadius.circular(15),
            ),
            padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 47,
                    backgroundColor: Color(0xFF6C757D),
                    backgroundImage: NetworkImage(
                      controller.currentUser.value?.photoURL ?? '',
                    ),
                    child: null,
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  controller.currentUser.value?.displayName ?? '',
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFF495057),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 5),
                Text(
                  controller.currentUser.value?.email ?? '',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6C757D)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          _buildMenuItem(
            icon: Icons.edit_outlined,
            title: 'Edit Profile',
            onTap: () => setState(() => _currentView = 'edit'),
          ),
          SizedBox(height: 15),
          _buildMenuItem(
            icon: Icons.lock_outline,
            title: 'Change Password',
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color(0xFFE9ECEF),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Color(0xFF495057),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF495057),
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Icon(Icons.chevron_right, color: Color(0xFF6C757D), size: 20),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(
            () => _buildPasswordField(
              'Current Password *',
              controller.oldPasswordController,
              controller.obscureOldPassword.value,
              () =>
                  controller.obscureOldPassword.value =
                      !controller.obscureOldPassword.value,
            ),
          ),
          SizedBox(height: 16),
          Obx(
            () => _buildPasswordField(
              'New Password *',
              controller.newPasswordController,
              controller.obscureNewPassword.value,
              () =>
                  controller.obscureNewPassword.value =
                      !controller.obscureNewPassword.value,
            ),
          ),
          SizedBox(height: 16),
          Obx(
            () => _buildPasswordField(
              'Confirm New Password *',
              controller.confirmPasswordController,
              controller.obscureConfirmPassword.value,
              () =>
                  controller.obscureConfirmPassword.value =
                      !controller.obscureConfirmPassword.value,
            ),
          ),
          SizedBox(height: 24),
          Obx(
            () => _buildButton(
              controller.isUpdatingPassword.value
                  ? 'Updating...'
                  : 'Update Password',
              Color(0xFFF2B342),
              Colors.white,
              controller.isUpdatingPassword.value
                  ? null
                  : () async {
                    await controller.updatePassword();
                    setState(() => _currentView = 'profile');
                  },
            ),
          ),
          SizedBox(height: 12),
          _buildButton(
            'Cancel',
            Colors.white,
            Color(0xff364C63),
            () => setState(() => _currentView = 'profile'),
            hasBorder: true,
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
            color: Color(0xFF495057),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFFE0E0E0)),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(fontSize: 14, color: Color(0xFF495057)),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(color: Color(0xFF6C757D), fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
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
            color: Color(0xFF495057),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFFE0E0E0)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: TextStyle(fontSize: 14, color: Color(0xFF495057)),
            decoration: InputDecoration(
              hintText: '••••••••••',
              hintStyle: TextStyle(color: Color(0xFF6C757D), fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
              suffixIcon: GestureDetector(
                onTap: toggleObscure,
                child: Container(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: Color(0xFF6C757D),
                    size: 18,
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
      height: 45,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side:
                hasBorder
                    ? BorderSide(color: Color(0xFFE0E0E0))
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
