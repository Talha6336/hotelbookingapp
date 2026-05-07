import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hotelbookingapp/presentation/login/login_screen.dart';
import 'presentation/signup/signup_screen.dart';
import 'firebase_options.dart';

// Assuming you structured the folders as suggested:
import 'core/theme/app_theme.dart';
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

  // 3. Run the App
  runApp(const StayEaseApp());
}

class StayEaseApp extends StatelessWidget {
  const StayEaseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StayEase',
      debugShowCheckedModeBanner:
          false, // Removes the debug banner for a premium feel
      theme: AppTheme.lightTheme, // Applies our global typography and colors
      // Setup the routing engine
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),

        // Placeholder screens to prevent crash after splash routing
        // We will replace these with actual screens later
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/customer_nav': (context) => const Scaffold(
          body: Center(child: Text('Customer Navigation Screen (To Be Built)')),
        ),
        '/owner_nav': (context) => const Scaffold(
          body: Center(child: Text('Owner Navigation Screen (To Be Built)')),
        ),
      },
    );
  }
}
