import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/primary_button.dart';

/// The very first screen a new install sees — brand intro, before any
/// account exists. "Get Started" leads into /auth; onboarding (fashion
/// quiz) only happens after that, once someone is signed in.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: FadeSlideIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(color: AppColors.sageSoft, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const Text('🌿', style: TextStyle(fontSize: 40)),
                  ),
                ),
                const SizedBox(height: 32),
                Text('MOODFIT', style: AppTheme.mono(), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'WHAT YOU WEAR\nSHAPES HOW YOU FEEL.',
                  textAlign: TextAlign.center,
                  style: AppTheme.sans(fontSize: 30, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -1),
                ),
                const SizedBox(height: 20),
                Text(
                  'A calm, private space to notice patterns between your outfits, your style and '
                  'your well-being.',
                  textAlign: TextAlign.center,
                  style: AppTheme.sans(fontSize: 14, height: 1.6, color: AppColors.foreground.withValues(alpha: 0.7)),
                ),
                const Spacer(),
                PrimaryButton(label: 'Get Started', onTap: () => context.go('/auth')),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Your logs are private to your account.',
                    style: AppTheme.sans(fontSize: 11, color: AppColors.foreground.withValues(alpha: 0.4)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
