import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/user_data_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/primary_button.dart';

/// Personalization wizard shown once, after sign-in: welcome + name, then
/// ready. Runs after auth, so there's no separate consent or trusted-contact
/// step here anymore — just enough to get a first name before entering the app.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _stepCount = 2;
  int step = 0;

  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _next() => setState(() => step = (step + 1).clamp(0, _stepCount - 1));

  Future<void> _finish() async {
    final store = context.read<UserDataProvider>();
    await store.completeOnboarding(name: _nameController.text);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: List.generate(_stepCount, (i) {
                  final on = i <= step;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i == _stepCount - 1 ? 0 : 6),
                      height: 4,
                      decoration: BoxDecoration(
                        color: on ? AppColors.sage : AppColors.muted,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              Expanded(child: _buildStep(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (step) {
      case 0:
        return _WelcomeStep(
          key: const ValueKey('step0'),
          controller: _nameController,
          onContinue: _next,
        );
      default:
        return _ReadyStep(
          key: const ValueKey('step1'),
          name: _nameController.text.trim(),
          onEnter: _finish,
        );
    }
  }
}

class _WelcomeStep extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onContinue;

  const _WelcomeStep({super.key, required this.controller, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MOODFIT', style: AppTheme.mono()),
          const SizedBox(height: 4),
          Text(
            'WHAT YOU WEAR SHAPES HOW YOU FEEL.'.toUpperCase(),
            style: AppTheme.sans(fontSize: 30, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -1),
          ),
          const SizedBox(height: 24),
          Text(
            'MoodFit is a calm, private space to notice patterns between your outfits and your '
            'moods — so tiny daily choices can support your well-being.',
            style: AppTheme.sans(fontSize: 14, height: 1.6, color: AppColors.foreground.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 32),
          Text('YOUR FIRST NAME', style: AppTheme.mono()),
          const SizedBox(height: 8),
          _TextField(controller: controller, hint: 'e.g. Alex'),
          const Spacer(),
          const SizedBox(height: 32),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => PrimaryButton(
              label: 'Continue',
              onTap: value.text.trim().isEmpty ? null : onContinue,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyStep extends StatelessWidget {
  final String name;
  final VoidCallback onEnter;

  const _ReadyStep({super.key, required this.name, required this.onEnter});

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: AppColors.sageSoft, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Text('🌱', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "YOU'RE SET${name.isNotEmpty ? ', ${name.toUpperCase()}' : ''}.",
            textAlign: TextAlign.center,
            style: AppTheme.sans(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Log one outfit today to plant your first seed. Streaks unlock small rewards along the '
            'way.',
            textAlign: TextAlign.center,
            style: AppTheme.sans(fontSize: 14, height: 1.6, color: AppColors.foreground.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.sageSoft.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FIRST REWARD', style: AppTheme.mono(color: AppColors.sage)),
                const SizedBox(height: 4),
                Text('🌱 First Bloom — 3 day streak', style: AppTheme.sans(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(height: 32),
          PrimaryButton(label: 'Enter MoodFit', onTap: onEnter),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _TextField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        style: AppTheme.sans(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTheme.sans(fontSize: 14, color: AppColors.foreground.withValues(alpha: 0.35)),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
