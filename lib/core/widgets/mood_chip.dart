import 'package:flutter/material.dart';

import '../models/mood.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The pill-shaped mood selector used on Home ("How do you feel in this?")
/// and Log ("Mood in this fit"). Same states in both places: default,
/// amber "gentle care" tint for heavier moods, and active/selected (sage).
class MoodChip extends StatelessWidget {
  final MoodDef mood;
  final bool active;
  final VoidCallback onTap;

  const MoodChip({super.key, required this.mood, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color background;
    Color? borderColor;
    Color textColor = AppColors.foreground;

    if (active) {
      background = AppColors.sageSoft;
      borderColor = AppColors.sage;
      textColor = AppColors.sage;
    } else if (mood.heavy) {
      background = AppColors.amberWarm.withValues(alpha: 0.1);
    } else {
      background = Colors.transparent;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: borderColor ?? Colors.black.withValues(alpha: 0.05),
            width: active ? 1 : 1,
          ),
        ),
        child: Text(
          '${mood.emoji}  ${mood.label}',
          style: AppTheme.sans(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
