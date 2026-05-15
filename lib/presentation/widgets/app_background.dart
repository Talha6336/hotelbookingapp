import 'package:flutter/material.dart';
import '/core/theme/app_theme.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
   
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppColors.darkGradient,
      ),
      child: SizedBox.expand(
        child: child,
      ),
    );
  }
}