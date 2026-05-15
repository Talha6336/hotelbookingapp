import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

import 'presentation/login/login_screen.dart';
import 'presentation/signup/signup_screen.dart';
import 'presentation/customer/customer_dashboard_screen.dart';
import 'presentation/owner/owner_dashboard_screen.dart';
import 'presentation/splash/splash_screen.dart';

void main() async {
  // 1. Ensure Flutter bindings are initialized before calling native code
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase (Requires flutterfire configure)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // 3. Wrap the App with the ChangeNotifierProvider so the whole app can listen to theme changes
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const StayEaseApp(),
    ),
  );
}

class StayEaseApp extends StatelessWidget {
  const StayEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 4. Retrieve the themeProvider instance from the context
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'StayEase',
      debugShowCheckedModeBanner:
          false, // Removes the debug banner for a premium feel

      theme: AppTheme.lightTheme, // Applies our global typography and colors
      darkTheme: AppTheme.darkTheme,

      // 5. Connect the themeMode to the provider
      themeMode: themeProvider.themeMode,

      // Setup the routing engine
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),

        // Placeholder screens to prevent crash after splash routing
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/customer_nav': (context) => const CustomerDashboardScreen(),
        '/owner_nav': (context) => const OwnerDashboardScreen(),
      },
    );
  }
}
