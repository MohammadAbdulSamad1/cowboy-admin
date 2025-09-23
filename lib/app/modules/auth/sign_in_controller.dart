import 'package:dedicated_cow_boy_admin/app/models/api_user_model.dart';
import 'package:dedicated_cow_boy_admin/app/modules/cv.dart';
import 'package:dedicated_cow_boy_admin/app/new/auth_service.dart';
import 'package:dedicated_cow_boy_admin/app/utils/exceptions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInController extends GetxController {
  // Form controllers
  final emailController = TextEditingController().obs;
  final passwordController = TextEditingController().obs;
  final forgotPasswordEmailController = TextEditingController();

  // Form key for validation
  final formKey = GlobalKey<FormState>();

  // Observable states
  final showPassword = false.obs;
  final rememberMe = false.obs;
  final isLoading = false.obs;
  final isForgotPasswordLoading = false.obs;

  // Services
  late final AuthService _authService;

  @override
  void onInit() {
    super.onInit();
    _authService = Get.find<AuthService>();
    _initializeService();
    _loadRememberMeState();
  }

  @override
  void onClose() {
    emailController.value.dispose();
    passwordController.value.dispose();
    forgotPasswordEmailController.dispose();
    super.onClose();
  }

  // Initialize auth service
  Future<void> _initializeService() async {
    try {
      await _authService.initialize();
    } catch (e) {
      debugPrint('Error initializing auth service: $e');
    }
  }

  // Load remember me state from SharedPreferences
  Future<void> _loadRememberMeState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      rememberMe.value = prefs.getBool('remember_me') ?? false;

      if (rememberMe.value) {
        final savedEmail = prefs.getString('saved_email');
        if (savedEmail != null) {
          emailController.value.text = savedEmail;
        }
      }
    } catch (e) {
      debugPrint('Error loading remember me state: $e');
    }
  }

  // Save remember me state to SharedPreferences
  Future<void> _saveRememberMeState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', rememberMe.value);

      if (rememberMe.value) {
        await prefs.setString('saved_email', emailController.value.text.trim());
      } else {
        await prefs.remove('saved_email');
      }
    } catch (e) {
      debugPrint('Error saving remember me state: $e');
    }
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    showPassword.value = !showPassword.value;
  }

  // Toggle remember me checkbox
  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? false;
  }

  // Validate form inputs
  String? validateEmail(String? email) {
    return AuthValidator.validateUsernameOrEmail(email, true);
  }

  String? validatePassword(String? password) {
    return AuthValidator.validatePassword(password);
  }

  // Sign in with email and password
  Future<void> signInWithEmailAndPassword() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      isLoading.value = true;

      final email = emailController.value.text.trim();
      final password = passwordController.value.text;

      // Sign in using auth service
      final ApiUserModel user = await _authService.signIn(
        email: email,
        password: password,
      );

      // Print user information for debugging
      print('=== USER LOGIN DEBUG INFO ===');
      print('User ID: ${user.id}');
      print('User Name: ${user.name}');
      print('User Email: ${user.email}');
      print('User Roles: ${user.roles}');
      print('Is Super Admin: ${user.isSuperAdmin}');
      print('User Capabilities: ${user.capabilities}');
      print('=============================');

      // Check if user is super admin
      if (!user.isSuperAdmin) {
        // Sign out the user if they don't have admin privileges
        await _authService.signOut();

        // Show access denied message
        Get.snackbar(
          'Access Denied',
          'Only super administrators are allowed to access this panel.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.block, color: Colors.white),
        );
        return;
      }

      // Save remember me state
      await _saveRememberMeState();

      // Mark onboarding as seen
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_seen', true);

      // Show success message
      Get.snackbar(
        'Success',
        'Welcome back, ${user.name}!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      // Navigate to main app
      Get.offNamed('/dashboard');
    } on AuthException catch (e) {
      _handleAuthException(e);
    } catch (e) {
      _handleGenericError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // Show forgot password dialog
  void showForgotPasswordDialog() {
    // Pre-fill with current email if available
    if (emailController.value.text.trim().isNotEmpty) {
      forgotPasswordEmailController.text = emailController.value.text.trim();
    }

    Get.dialog(
      Material(
        color: Colors.transparent,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with close button
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 20,
                      left: 24,
                      right: 16,
                    ),
                    child: Row(
                      children: [
                        // Lock icon
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title
                        const Expanded(
                          child: Text(
                            'Forget Password',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        // Close button
                        GestureDetector(
                          onTap: () {
                            forgotPasswordEmailController.clear();
                            Get.back();
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8A317),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        // Description text
                        const Text(
                          'Please enter your email to recover your password.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Email label
                        const Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Input field
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: forgotPasswordEmailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter your email',
                              hintStyle: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade400,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8F8F8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE8A317),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: validateEmail,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Send button
                        Obx(
                          () => SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: CustomElevatedButton(
                              borderRadius: 25,
                              text: 'Send',
                              backgroundColor: Colors.yellow,
                              isLoading: isForgotPasswordLoading.value,
                              onTap:
                                  isForgotPasswordLoading.value
                                      ? null
                                      : sendPasswordResetEmail,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail() async {
    final email = forgotPasswordEmailController.text.trim();

    // Validate email
    final emailError = validateEmail(email);
    if (emailError != null) {
      Get.snackbar(
        'Invalid Email',
        emailError,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.error, color: Colors.white),
      );
      return;
    }

    try {
      isForgotPasswordLoading.value = true;

      await _authService.sendPasswordResetEmail(email);

      // Close dialog
      Get.back();

      // Clear controller
      forgotPasswordEmailController.clear();

      // Show success message
      Get.snackbar(
        'Email Sent',
        'Password reset link has been sent to $email. Please check your inbox.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.mark_email_read, color: Colors.white),
      );
    } on AuthException catch (e) {
      _handleAuthException(e);
    } catch (e) {
      _handleGenericError(e);
    } finally {
      isForgotPasswordLoading.value = false;
    }
  }

  // Handle authentication exceptions
  void _handleAuthException(AuthException e) {
    String message = e.message;

    // Customize messages based on error codes
    switch (e.code) {
      case 'invalid-credentials':
        message = 'Invalid email or password. Please try again.';
        break;
      case 'user-not-found':
        message = 'No account found with this email address.';
        break;
      case 'network-error':
        message = 'Network error. Please check your internet connection.';
        break;
      case 'invalid-email':
        message = 'Please enter a valid email address.';
        break;
      case 'too-many-requests':
        message = 'Too many requests. Please try again later.';
        break;
      case 'server-error':
        message = 'Server error. Please try again later.';
        break;
      default:
        message = e.message;
    }

    Get.snackbar(
      'Sign In Failed',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  // Handle generic errors
  void _handleGenericError(dynamic error) {
    debugPrint('Sign in error: $error');

    Get.snackbar(
      'Error',
      'An unexpected error occurred. Please try again.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  // Clear all form data
  void clearForm() {
    emailController.value.clear();
    passwordController.value.clear();
    showPassword.value = false;
    rememberMe.value = false;
  }
}
