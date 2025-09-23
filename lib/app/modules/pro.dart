import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isUpdatingProfile = false.obs;
  final RxBool isUpdatingPassword = false.obs;

  // Form controllers
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final userNameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();

  // Password controllers
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Password visibility
  final RxBool obscureOldPassword = true.obs;
  final RxBool obscureNewPassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;

  // User data
  final Rx<Map<String, dynamic>> adminData = Rx<Map<String, dynamic>>({});
  final RxString profileImageUrl = ''.obs;
  final RxString userInitials = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAdminData();
  }

  // Load admin data from Firestore
  Future<void> loadAdminData() async {
    try {
      isLoading.value = true;
      final User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        // Get admin data from Firestore
        final DocumentSnapshot adminDoc =
            await _firestore.collection('admins').doc(currentUser.uid).get();

        if (adminDoc.exists) {
          final data = adminDoc.data() as Map<String, dynamic>;
          adminData.value = data;

          // Populate form controllers
          firstNameController.text = data['firstName'] ?? '';
          lastNameController.text = data['lastName'] ?? '';
          userNameController.text = data['userName'] ?? '';
          mobileController.text = data['phone'] ?? '';
          emailController.text = data['email'] ?? currentUser.email ?? '';

          // Set profile image and initials
          profileImageUrl.value = data['photoURL'] ?? data['avatar'] ?? '';
          _updateUserInitials();
        } else {
          // Create admin document if it doesn't exist
          await _createAdminDocument(currentUser);
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load profile data: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Create admin document if it doesn't exist
  Future<void> _createAdminDocument(User user) async {
    try {
      final adminData = {
        'uid': user.uid,
        'email': user.email,
        'firstName': '',
        'lastName': '',
        'userName': '',
        'phone': '',
        'photoURL': user.photoURL ?? '',
        'avatar': '',
        'role': 'admin',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('admins').doc(user.uid).set(adminData);

      // Reload data
      await loadAdminData();
    } catch (e) {
      print('Error creating admin document: $e');
    }
  }

  // Update user initials
  void _updateUserInitials() {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      userInitials.value = '${firstName[0]}${lastName[0]}'.toUpperCase();
    } else if (firstName.isNotEmpty) {
      userInitials.value = firstName[0].toUpperCase();
    } else if (lastName.isNotEmpty) {
      userInitials.value = lastName[0].toUpperCase();
    } else {
      final email = emailController.text.trim();
      if (email.isNotEmpty) {
        userInitials.value = email[0].toUpperCase();
      } else {
        userInitials.value = 'A';
      }
    }
  }

  // Update profile
  Future<void> updateProfile() async {
    try {
      isUpdatingProfile.value = true;
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        Get.snackbar(
          'Error',
          'No user found',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFFF2B342),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      // Validate required fields
      if (firstNameController.text.trim().isEmpty) {
        Get.snackbar(
          'Error',
          'First name is required',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFFF2B342),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      if (emailController.text.trim().isEmpty) {
        Get.snackbar(
          'Error',
          'Email is required',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFFF2B342),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      // Update user initials
      _updateUserInitials();

      // Prepare update data
      final updateData = {
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'userName': userNameController.text.trim(),
        'phone': mobileController.text.trim(),
        'email': emailController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update Firestore document
      await _firestore
          .collection('admins')
          .doc(currentUser.uid)
          .update(updateData);

      // Update local data
      adminData.value = {...adminData.value, ...updateData};

      Get.snackbar(
        'Success',
        'Profile updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      String errorMessage = 'Failed to update profile';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'requires-recent-login':
            errorMessage = 'Please re-authenticate to update email';
            break;
          case 'email-already-in-use':
            errorMessage = 'Email is already in use by another account';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address';
            break;
        }
      }

      Get.snackbar(
        'Error',
        '$errorMessage: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isUpdatingProfile.value = false;
    }
  }

  // Update password
  Future<void> updatePassword() async {
    try {
      isUpdatingPassword.value = true;
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        Get.snackbar(
          'Error',
          'No user found',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFFF2B342),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      // Validate inputs
      if (oldPasswordController.text.isEmpty ||
          newPasswordController.text.isEmpty ||
          confirmPasswordController.text.isEmpty) {
        Get.snackbar(
          'Error',
          'All password fields are required',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFFF2B342),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      if (newPasswordController.text != confirmPasswordController.text) {
        Get.snackbar(
          'Error',
          'New passwords do not match',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFFF2B342),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      if (newPasswordController.text.length < 6) {
        Get.snackbar(
          'Error',
          'Password must be at least 6 characters long',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFFF2B342),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      // Re-authenticate user with old password
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: oldPasswordController.text,
      );

      await currentUser.reauthenticateWithCredential(credential);

      // Update password
      await currentUser.updatePassword(newPasswordController.text);

      // Log password change activity
      await _firestore.collection('admin_logs').add({
        'adminId': currentUser.uid,
        'email': currentUser.email,
        'action': 'password_changed',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clear password fields
      oldPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      Get.snackbar(
        'Success',
        'Password updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      String errorMessage = 'Failed to update password';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            errorMessage = 'Current password is incorrect';
            break;
          case 'weak-password':
            errorMessage = 'New password is too weak';
            break;
          case 'requires-recent-login':
            errorMessage = 'Please re-login and try again';
            break;
        }
      }

      Get.snackbar(
        'Error',
        '$errorMessage: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isUpdatingPassword.value = false;
    }
  }

  // Get full name
  String get fullName {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    }
    return 'Admin User';
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    userNameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}

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
      child: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: Color(0xFFF2B342)),
          );
        }

        return _currentView == 'profile'
            ? _buildProfileView()
            : _currentView == 'edit'
            ? _buildEditView()
            : _buildPasswordView();
      }),
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
                  child: Obx(
                    () => CircleAvatar(
                      radius: 47,
                      backgroundColor: Color(0xFF6C757D),
                      backgroundImage:
                          controller.profileImageUrl.value.isNotEmpty
                              ? NetworkImage(controller.profileImageUrl.value)
                              : null,
                      child:
                          controller.profileImageUrl.value.isEmpty
                              ? Text(
                                controller.userInitials.value,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                              : null,
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  controller.fullName,
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFF495057),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 5),
                Text(
                  controller.emailController.text,
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputField('First Name *', controller.firstNameController),
          SizedBox(height: 16),
          _buildInputField('Last Name', controller.lastNameController),
          SizedBox(height: 16),
          _buildInputField('User Name', controller.userNameController),
          SizedBox(height: 16),
          _buildInputField(
            'Mobile Number',
            controller.mobileController,
            placeholder: 'Enter Mobile Number',
          ),
          SizedBox(height: 16),
          _buildInputField('Email *', controller.emailController),
          SizedBox(height: 24),
          Obx(
            () => _buildButton(
              controller.isUpdatingProfile.value ? 'Updating...' : 'Update',
              Color(0xFFF2B342),
              Colors.white,
              controller.isUpdatingProfile.value
                  ? null
                  : () async {
                    await controller.updateProfile();
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
