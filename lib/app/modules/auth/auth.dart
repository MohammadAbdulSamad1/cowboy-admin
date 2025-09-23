// auth_screen.dart
import 'package:dedicated_cow_boy_admin/app/modules/auth/sign_in_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SignInController signInController = Get.put(SignInController());
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;
          final isTablet =
              constraints.maxWidth >= 768 && constraints.maxWidth < 1200;

          if (isMobile) {
            return _MobileLayout(controller: signInController);
          } else {
            return Row(
              children: [
                // Left side - Gradient background with branding
                Expanded(
                  flex: isTablet ? 1 : 1,
                  child: _BrandingSide(isMobile: false),
                ),
                // Right side - Sign in form
                Expanded(
                  flex: isTablet ? 1 : 1,
                  child: _SignInForm(
                    controller: signInController,
                    isMobile: false,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final SignInController controller;

  const _MobileLayout({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: Column(
          children: [
            // Top branding section for mobile
            Container(
              height: MediaQuery.of(context).size.height * 0.35,
              child: _BrandingSide(isMobile: true),
            ),
            // Sign in form
            Container(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height * 0.65,
              ),
              child: _SignInForm(controller: controller, isMobile: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandingSide extends StatelessWidget {
  final bool isMobile;

  const _BrandingSide({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF364C63), Color(0xFF6E9AC9)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 24 : 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo and title
            Row(
              mainAxisAlignment:
                  isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Image.asset('assets/images/web_logo.png', height: 100),
              ],
            ),
            // Welcome text
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Hey There!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 18 : 24,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      color: const Color(0xFFF2B342),
                      fontSize: isMobile ? 32 : 48,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Secure Admin Access Portal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 16 : 24,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInForm extends StatelessWidget {
  final SignInController controller;
  final bool isMobile;

  const _SignInForm({required this.controller, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F8F8),
      padding: EdgeInsets.all(isMobile ? 24 : 60),
      child: Form(
        key: controller.formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                'ADMIN SIGN IN',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Authorized Personnel Only',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: isMobile ? 32 : 40),

            // Email field
            _buildEmailField(),
            const SizedBox(height: 24),

            // Password field
            _buildPasswordField(),
            const SizedBox(height: 16),

            // Remember password and forgot password
            _buildOptionsRow(context),
            const SizedBox(height: 32),

            // Sign in button
            _buildSignInButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin Email Address',
          style: TextStyle(
            fontSize: isMobile ? 13 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade700),
            color: Colors.white,
          ),
          child: TextFormField(
            controller: controller.emailController.value,
            validator: controller.validateEmail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'admin@company.com',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: isMobile ? 13 : 14,
              ),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: Colors.grey.shade400,
                size: isMobile ? 18 : 20,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 16,
                vertical: isMobile ? 14 : 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: TextStyle(
            fontSize: isMobile ? 13 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade700),
            color: Colors.white,
          ),
          child: Obx(
            () => TextFormField(
              controller: controller.passwordController.value,
              validator: controller.validatePassword,
              obscureText: !controller.showPassword.value,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: '••••••••',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: isMobile ? 16 : 18,
                  letterSpacing: 2,
                ),
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: Colors.grey.shade400,
                  size: isMobile ? 18 : 20,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 14 : 16,
                  vertical: isMobile ? 14 : 16,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.showPassword.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey.shade400,
                    size: isMobile ? 18 : 20,
                  ),
                  onPressed: controller.togglePasswordVisibility,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsRow(BuildContext context) {
    if (isMobile) {
      // Stack vertically on mobile for better usability
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Obx(
                () => Checkbox(
                  value: controller.rememberMe.value,
                  onChanged: controller.toggleRememberMe,
                  activeColor: const Color(0xFFF2B342),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              Text(
                'Remember me',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => controller.showForgotPasswordDialog(),
              child: Text(
                'Forgot password?',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Keep side by side on desktop
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Obx(
                () => Checkbox(
                  value: controller.rememberMe.value,
                  onChanged: controller.toggleRememberMe,
                  activeColor: const Color(0xFFF2B342),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              Text(
                'Remember me',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
          TextButton(
            onPressed: () => controller.showForgotPasswordDialog(),
            child: Text(
              'Forgot password?',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildSignInButton(BuildContext context) {
    return Obx(
      () => SizedBox(
        height: isMobile ? 48 : 50,
        child: ElevatedButton(
          onPressed:
              controller.isLoading.value
                  ? null
                  : () {
                    controller.signInWithEmailAndPassword();
                  },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF2B342),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 0,
          ),
          child:
              controller.isLoading.value
                  ? SizedBox(
                    height: isMobile ? 18 : 20,
                    width: isMobile ? 18 : 20,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Text(
                    'SIGN IN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
        ),
      ),
    );
  }
}
