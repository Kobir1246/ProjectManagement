import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final theme = context.watch<ThemeProvider>();
    final user = auth.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'User',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 32),
          _buildMenuItem(
            context,
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () {},
          ),
          _buildDarkModeItem(context, theme),
          _buildMenuItem(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {},
          ),
          _buildMenuItem(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {},
          ),
          _buildMenuItem(
            context,
            icon: Icons.logout,
            title: 'Logout',
            color: Colors.red,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<AuthService>().signOut();
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDarkModeItem(BuildContext context, ThemeProvider theme) {
    final isDark = theme.themeMode == ThemeMode.dark || 
                  (theme.themeMode == ThemeMode.system && 
                   WidgetsBinding.instance.platformDispatcher.platformBrightness == 
                   Brightness.dark);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            color: const Color(0xFF7C4DFF),
          ),
        ),
        title: const Text(
          'Dark Mode',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: Switch(
          value: isDark,
          onChanged: (_) => theme.toggleTheme(),
          activeTrackColor: const Color(0xFF7C4DFF),
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return Colors.grey;
          }),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? const Color(0xFF7C4DFF)).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color ?? const Color(0xFF7C4DFF)),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w500, color: color),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }
}
