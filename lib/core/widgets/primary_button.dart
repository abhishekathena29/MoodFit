import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The bold, full-width uppercase button used throughout onboarding and
/// the Log screen's "Save log" action (`rounded-2xl bg-foreground ...`).
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const PrimaryButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: disabled ? 0.3 : 1,
      child: Material(
        color: AppColors.foreground,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                label.toUpperCase(),
                style: AppTheme.sans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.background,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
