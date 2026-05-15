import 'package:flutter/material.dart';
import '/core/theme/app_theme.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final bool useSafeArea;
  final EdgeInsetsGeometry padding;

  const AppBackground({
    super.key,
    required this.child,
    this.useSafeArea = false,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final content = Padding(
      padding: padding,
      child: useSafeArea ? SafeArea(child: child) : child,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        gradient: isDark
            ? AppColors.darkBackgroundGradient
            : AppColors.lightBackgroundGradient,
      ),
      child: SizedBox.expand(child: content),
    );
  }
}
