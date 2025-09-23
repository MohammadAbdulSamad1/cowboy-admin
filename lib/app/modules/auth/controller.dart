// auth_controller.dart - FIXED VERSION

import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observables
  final Rx<User?> firebaseUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxBool rememberPassword = false.obs;
  final RxString verificationId = ''.obs;
  final RxInt resendTimer = 0.obs;

  // Text controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  // Form keys
  final loginFormKey = GlobalKey<FormState>();
  final forgotPasswordFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
    // Remove the automatic navigation from here
    ever(firebaseUser, _handleAuthStateChange);
  }

  // Handle auth state changes without automatic navigation
  void _handleAuthStateChange(User? user) async {
    if (user != null) {
      bool isAdmin = await _checkAdminStatus(user);
      checkAuthAndNavigate(Get.context!);
      print('User auth state changed - isAdmin: $isAdmin');
    }
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  // Toggle remember password
  void toggleRememberPassword(bool? value) {
    rememberPassword.value = value ?? false;
  }

  // Admin login with enhanced security - FIXED VERSION
  Future<void> adminLogin(BuildContext context) async {
    if (!loginFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      // First, authenticate with Firebase
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      print('Login result: ${result.user}');

      if (result.user != null) {
        // Check if user is an admin
        final bool isAdmin = await _checkAdminStatus(result.user!);

        print('Is admin: $isAdmin');

        if (isAdmin) {
          // Log admin activity
          await _logAdminActivity(result.user!, 'login');

          // Show success snackbar
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login successful!'),
                backgroundColor: Color(0xFFF2B342),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          // Navigate to dashboard using GoRouter context
          if (context.mounted) {
            Get.offNamed('/dashboard/ProfileScreen');
          }
        } else {
          // Sign out non-admin users immediately
          await _auth.signOut();

          // Show error snackbar
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Access denied. Admin privileges required.'),
                backgroundColor:  Color(0xFFF2B342),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getAuthErrorMessage(e.code);

      // Show error using ScaffoldMessenger instead of Get.snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication Error: $errorMessage'),
            backgroundColor:  Color(0xFFF2B342),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor:  Color(0xFFF2B342),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Check if user has admin privileges
  Future<bool> _checkAdminStatus(User user) async {
    try {
      final QuerySnapshot adminQuery = await _firestore
          .collection('admins')
          .where('email', isEqualTo: user.email)
          .limit(1) // for efficiency
          .get();

      if (adminQuery.docs.isNotEmpty) {
        final data = adminQuery.docs.first.data() as Map<String, dynamic>;
        final bool isActive = data['isActive'] ?? false;
        final String role = data['role'] ?? '';

        return isActive && (role == 'super_admin' || role == 'admin');
      }

      return false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Log admin activities for security auditing
  Future<void> _logAdminActivity(User user, String action) async {
    try {
      await _firestore.collection('admin_logs').add({
        'adminId': user.uid,
        'email': user.email,
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
        'ipAddress': 'Unknown', // You can implement IP detection
        'userAgent': 'Web Admin Panel',
      });
    } catch (e) {
      print('Error logging admin activity: $e');
    }
  }

  // Send password reset email - FIXED VERSION
  Future<void> sendPasswordResetEmail(BuildContext context) async {
    if (!forgotPasswordFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      final String email = emailController.text.trim();

      // Check if email belongs to an admin
      final QuerySnapshot adminQuery = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .where('isActive', isEqualTo: true)
          .get();

      if (adminQuery.docs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No admin account found with this email'),
              backgroundColor:  Color(0xFFF2B342),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      await _auth.sendPasswordResetEmail(email: email);

      // Log password reset attempt
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _logAdminActivity(currentUser, 'password_reset_requested');
      }

      if (context.mounted) {
        Navigator.of(context).pop(); // Use Navigator instead of Get.back()
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent successfully'),
            backgroundColor:  Color(0xFFF2B342),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getAuthErrorMessage(e.code)),
            backgroundColor:  Color(0xFFF2B342),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Sign out admin - FIXED VERSION
  Future<void> signOut(BuildContext context) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await _logAdminActivity(user, 'logout');
      }

      await _auth.signOut();

      if (context.mounted) {
        Get.offNamed('/auth');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: ${e.toString()}'),
            backgroundColor:  Color(0xFFF2B342),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Get current admin data
  Future<Map<String, dynamic>?> getCurrentAdminData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final DocumentSnapshot adminDoc = await _firestore
            .collection('admins')
            .doc(user.uid)
            .get();

        if (adminDoc.exists) {
          return adminDoc.data() as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Error getting admin data: $e');
      return null;
    }
  }

  // Helper method to get user-friendly error messages
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No admin account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This admin account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'Authentication failed. Please try again';
    }
  }

  // Email validator
  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  // Password validator
  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Clear all form data
  void clearForm() {
    emailController.clear();
    passwordController.clear();
    phoneController.clear();
    otpController.clear();
    obscurePassword.value = true;
    rememberPassword.value = false;
  }

  // Method to check auth status and navigate - call this from your UI
  Future<void> checkAuthAndNavigate(BuildContext context) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      if (context.mounted) {
        Get.offNamed('/auth');
      }
    } else {
      bool isAdmin = await _checkAdminStatus(user);
      if (isAdmin && context.mounted) {
        Get.offNamed('/dashboard/ProfileScreen');
      } else if (context.mounted) {
        await _auth.signOut();
        Get.offNamed('/auth');
      }
    }
  }
}
