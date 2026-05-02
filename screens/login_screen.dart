import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/team_flow_logo.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const TeamFlowLogo(size: 120),
              const SizedBox(height: 32),
              Text(
                'TeamFlow',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your team projects with ease',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              _buildLoginButtons(context),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Text(
                  'By continuing, you agree to our Terms of Service',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButtons(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, child) {
        return Column(
          children: [
            _LoginButton(
              text: 'Continue with Google',
              icon: Icons.g_mobiledata,
              backgroundColor: Colors.white,
              textColor: Colors.black87,
              isLoading: auth.isLoading,
              onPressed: () => auth.signInWithGoogle(),
            ),
            const SizedBox(height: 12),
            _LoginButton(
              text: 'Continue with Facebook',
              icon: Icons.facebook,
              backgroundColor: const Color(0xFF1877F2),
              textColor: Colors.white,
              isLoading: auth.isLoading,
              onPressed: () => auth.signInWithFacebook(),
            ),
            const SizedBox(height: 12),
            _LoginButton(
              text: 'Continue with X',
              icon: Icons.alternate_email,
              backgroundColor: Colors.black,
              textColor: Colors.white,
              isLoading: auth.isLoading,
              onPressed: () => auth.signInWithTwitter(),
            ),
          ],
        );
      },
    );
  }
}

class _LoginButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;
  final bool isLoading;

  const _LoginButton({
    required this.text,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
    required this.isLoading,
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
            side: backgroundColor == Colors.white
                ? BorderSide(color: Colors.grey.shade300)
                : BorderSide.none,
          ),
          elevation: backgroundColor == Colors.white ? 1 : 0,
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
                  Icon(icon, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
