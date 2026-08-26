import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Horizontal progress fill — matches Tailwind's `transition-all duration-700`
/// used on every progress bar in the app (xp, mood %, streak-to-reward, etc).
class AnimatedHBar extends StatelessWidget {
  final double percent; // 0-100
  final Color color;
  final Color trackColor;
  final double height;

  const AnimatedHBar({
    super.key,
    required this.percent,
    required this.color,
    this.trackColor = AppColors.muted,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: height,
        color: trackColor,
        child: Align(
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (percent / 100).clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            builder: (context, value, child) => FractionallySizedBox(
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Vertical bar that grows from the bottom — matches the "Weekly Palette"
/// bars on the Home screen (`transition-all duration-500`, rounded top only).
class AnimatedVBar extends StatelessWidget {
  final double heightPercent; // 0-100
  final Color color;
  final double maxHeight;

  const AnimatedVBar({
    super.key,
    required this.heightPercent,
    required this.color,
    this.maxHeight = 128,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: (heightPercent / 100).clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          builder: (context, value, child) => Container(
            height: maxHeight * value,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ),
        ),
      ),
    );
  }
}
