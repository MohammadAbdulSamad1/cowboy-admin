import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CustomElevatedButton extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final String? imageAsset;
  final bool isLoading;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? imageSize;
  final double? spacing;
  final double? borderRadius;
  final double? loadingSize;

  const CustomElevatedButton({
    Key? key,
    required this.text,
    required this.backgroundColor,
    this.onTap,
    this.imageAsset,
    this.isLoading = false,
    this.textColor = Colors.white,
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.bold,
    this.imageSize = 24.0,
    this.spacing = 8.0,
    this.borderRadius = 50.0, // Rounded pill shape
    this.loadingSize = 20.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56, // You can adjust this to match the image height
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius!),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 16,
              offset: Offset(0, 6),
              spreadRadius: 1,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            elevation: 0, // shadow handled by BoxDecoration
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius!),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 10.0,
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: loadingSize,
                  height: loadingSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      textColor ?? Colors.white,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (imageAsset != null) ...[
                      Image.asset(
                        imageAsset!,
                        width: imageSize,
                        height: imageSize,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(width: spacing),
                    ],
                    Text(
                      text,
                      style: TextStyle(
                        color: textColor,
                        fontSize: fontSize,
                        fontWeight: fontWeight,
                        fontFamily: 'popins-bold',
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// Usage Example:
class ButtonExampleScreen extends StatelessWidget {
  const ButtonExampleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Button Examples')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Example 1: Button with image
            SizedBox(
              width: double.infinity,
              height: 60,
              child: CustomElevatedButton(
                text: 'LOGIN',
                backgroundColor: const Color(0xFF4A5D7A),
                imageAsset:
                    'assets/images/login_icon.png', // Your image asset path
                onTap: () {
                  print('Login button tapped');
                },
              ),
            ),

            const SizedBox(height: 16),

            // Example 2: Button without image
            SizedBox(
              width: double.infinity,
              height: 50,
              child: CustomElevatedButton(
                text: 'SIGN UP',
                backgroundColor: Color(0xFFF2B342),
                onTap: () {
                  print('Sign up button tapped');
                },
              ),
            ),

            const SizedBox(height: 16),

            // Example 3: Custom styled button
            SizedBox(
              width: double.infinity,
              height: 70,
              child: CustomElevatedButton(
                text: 'Get Started',
                backgroundColor: Color(0xFFF2B342),
                imageAsset:
                    'assets/images/arrow_icon.png', // Your image asset path
                textColor: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                imageSize: 28,
                spacing: 12,
                borderRadius: 12,
                onTap: () {
                  print('Get Started button tapped');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
