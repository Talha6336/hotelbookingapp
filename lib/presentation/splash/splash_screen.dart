import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/app_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Changed to SingleTicker since we removed the looping background animation
  late AnimationController _entryController;

  // Entry Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _textOpacity;
  late Animation<double> _loadingOpacity;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateAfterSplash();
  }

  void _setupAnimations() {
    // Controller for the 3-second staggered entry
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Staggered Animations using Intervals
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.3, 0.7, curve: Curves.easeOutQuart),
          ),
        );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeIn),
      ),
    );

    _loadingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
      ),
    );

    _entryController.forward();
  }

  Future<void> _navigateAfterSplash() async {
    // Enforce minimum 3-second splash duration for the premium feel
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        // Navigate to Login
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        // Fetch role from Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final role = doc.data()?['role'] ?? 'customer';

        if (!mounted) return;

        if (role == 'owner') {
          Navigator.of(context).pushReplacementNamed('/owner_nav');
        } else {
          Navigator.of(context).pushReplacementNamed('/customer_nav');
        }
      }
    } catch (e) {
      // Fallback navigation on error
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        useSafeArea: true,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // App Logo with Scale, Fade, and Glow
              FadeTransition(
                opacity: _logoOpacity,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.adaptiveSurface(context),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.adaptiveBorder(context),
                        width: 1.5,
                      ),
                    ),
                    // Luxury Building/Pin Icon
                    child: const Icon(
                      Icons.domain,
                      size: 72,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // App Name & Subtitle with Slide and Fade
              FadeTransition(
                opacity: _textOpacity,
                child: SlideTransition(
                  position: _textSlide,
                  child: Column(
                    children: [
                      Text(
                        "StayEase",
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: AppColors.adaptiveTextPrimary(context),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Book Luxury Hotels Easily",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: AppColors.adaptiveTextSecondary(context),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Loading Section
              FadeTransition(
                opacity: _loadingOpacity,
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Finding the best stays for you...",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.adaptiveTextSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
