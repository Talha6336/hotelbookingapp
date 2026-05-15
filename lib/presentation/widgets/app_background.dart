import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import '/core/theme/app_theme.dart';

class AppBackground extends StatefulWidget {
  final Widget child;

  const AppBackground({
    super.key,
    required this.child,
  });

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatingController;

  @override
  void initState() {
    super.initState();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Same dashboard gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.darkGradient,
          ),
        ),

        // Same floating blurred circles
        AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return Stack(
              children: [
                _buildFloatingCircle(
                  size: 260,
                  top: -80 +
                      (math.sin(_floatingController.value * math.pi) * 30),
                  left: -90,
                  color: AppColors.primary.withValues(alpha: 0.35),
                ),
                _buildFloatingCircle(
                  size: 320,
                  bottom: -120 +
                      (math.cos(_floatingController.value * math.pi) * 45),
                  right: -80,
                  color: AppColors.secondary.withValues(alpha: 0.25),
                ),
              ],
            );
          },
        ),

        widget.child,
      ],
    );
  }

  Widget _buildFloatingCircle({
    required double size,
    double? top,
    double? bottom,
    double? left,
    double? right,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}