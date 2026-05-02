import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

late StorageService storageService;
late NotificationService notificationService;
late ThemeProvider themeProvider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  storageService = StorageService();
  await storageService.init();
  notificationService = NotificationService();
  await notificationService.init();
  themeProvider = ThemeProvider();
  await themeProvider.init();
  runApp(const TeamFlowApp());
}

class TeamFlowApp extends StatelessWidget {
  const TeamFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, child) {
          return MaterialApp(
            title: 'TeamFlow',
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: theme.themeMode,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C4DFF),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C4DFF),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, child) {
        if (auth.isLoggedIn) {
          return const MainScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
