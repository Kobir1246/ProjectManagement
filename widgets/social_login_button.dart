import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final String text;
  final String iconPath;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.text,
    required this.iconPath,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    iconPath,
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(width: 24, height: 24);
                    },
                  ),
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
