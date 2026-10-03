import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/fashion_profile.dart';
import '../../../core/models/palette.dart';
import '../../../core/models/style.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/palette_swatch.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/research_hint.dart';

/// Fashion-sense quiz shown once after sign-up: name, style + aesthetics,
/// colors, how getting dressed feels + goals, then ready. Answers are saved
/// as the user's [FashionProfile] and ground the AI layer. With [editing],
/// the same steps are reused from Profile and the ready step is skipped.
class OnboardingScreen extends StatefulWidget {
  final bool editing;

  const OnboardingScreen({super.key, this.editing = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;
  bool _saving = false;

  final _nameController = TextEditingController();
  late FashionProfile _profile;

  int get _stepCount => widget.editing ? 4 : 5;

  @override
  void initState() {
    super.initState();
    final store = context.read<UserDataProvider>();
    _nameController.text = store.name;
    _profile = store.fashionProfile;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Right after sign-up the profile doc (with the name typed on the
    // sign-up form) can land a moment after this screen opens.
    final name = context.watch<UserDataProvider>().name;
    if (_nameController.text.isEmpty && name.isNotEmpty) _nameController.text = name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<String> _toggle(List<String> list, String key) =>
      list.contains(key) ? (List.of(list)..remove(key)) : [...list, key];

  void _back() => setState(() => step = (step - 1).clamp(0, _stepCount - 1));

  Future<void> _next() async {
    if (step < _stepCount - 1) {
      setState(() => step++);
      return;
    }
    setState(() => _saving = true);
    final store = context.read<UserDataProvider>();
    if (widget.editing) {
      await store.updateName(_nameController.text);
      await store.updateFashionProfile(_profile);
      if (!mounted) return;
      ToastService.success(context, 'Style profile saved');
      context.pop();
    } else {
      await store.completeOnboarding(name: _nameController.text, profile: _profile);
      if (mounted) context.go('/');
    }
  }

  String get _buttonLabel {
    if (_saving) return 'Saving…';
    if (step < _stepCount - 1) return 'Continue';
    return widget.editing ? 'Save changes' : 'Enter MoodFit';
  }

  bool get _canContinue => !_saving && (step != 0 || _nameController.text.trim().isNotEmpty);

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
                children: [
                  if (step > 0 || widget.editing)
                    GestureDetector(
                      onTap: step > 0 ? _back : () => context.pop(),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.foreground),
                      ),
                    ),
                  ...List.generate(_stepCount, (i) {
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i == _stepCount - 1 ? 0 : 6),
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= step ? AppColors.sage : AppColors.muted,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: FadeSlideIn(key: ValueKey(step), child: _buildStep()),
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _nameController,
                builder: (context, _, _) => PrimaryButton(
                  label: _buttonLabel,
                  onTap: _canContinue ? _next : null,
                ),
              ),
              if (step > 0 && step < 4) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Pick as many as you like — or skip.',
                    style: AppTheme.sans(fontSize: 11, color: AppColors.foreground.withValues(alpha: 0.45)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (step) {
      case 0:
        return _StepBody(
          eyebrow: widget.editing ? 'YOUR PROFILE' : 'WELCOME TO MOODFIT',
          title: 'WHAT YOU WEAR SHAPES HOW YOU FEEL.',
          subtitle: 'A few quick questions about your style help Muse and your insights speak to you — '
              'not just anyone.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WHAT SHOULD WE CALL YOU?', style: AppTheme.mono()),
              const SizedBox(height: 8),
              _TextField(controller: _nameController, hint: 'e.g. Alex'),
            ],
          ),
        );
      case 1:
        return _StepBody(
          eyebrow: 'YOUR STYLE',
          title: 'How do you usually dress?',
          subtitle: 'Choose the styles and aesthetics that feel most like you.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('STYLE', style: AppTheme.mono()),
              const SizedBox(height: 12),
              _ChipWrap(
                children: kStyles
                    .map((s) => _Choice(
                          label: s.label,
                          active: _profile.styles.contains(s.key),
                          onTap: () => setState(
                              () => _profile = _profile.copyWith(styles: _toggle(_profile.styles, s.key))),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              Text('AESTHETIC', style: AppTheme.mono()),
              const SizedBox(height: 12),
              _ChipWrap(
                children: kAesthetics
                    .map((a) => _Choice(
                          label: a.label,
                          active: _profile.aesthetics.contains(a.key),
                          onTap: () => setState(() =>
                              _profile = _profile.copyWith(aesthetics: _toggle(_profile.aesthetics, a.key))),
                        ))
                    .toList(),
              ),
            ],
          ),
        );
      case 2:
        return _StepBody(
          eyebrow: 'YOUR COLORS',
          title: 'Which colors do you reach for?',
          subtitle: 'The color families that show up most in your wardrobe.',
          child: Column(
            children: kPalettes.map((p) {
              final active = _profile.palettes.contains(p.key);
              return GestureDetector(
                onTap: () =>
                    setState(() => _profile = _profile.copyWith(palettes: _toggle(_profile.palettes, p.key))),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: active ? AppColors.sageSoft : AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: active ? AppColors.sage : Colors.black.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      PaletteSwatch(palette: p.key, size: 36, radius: 12),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.label, style: AppTheme.sans(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text(
                              p.description,
                              style: AppTheme.sans(fontSize: 11, color: AppColors.foreground.withValues(alpha: 0.55)),
                            ),
                          ],
                        ),
                      ),
                      if (active) Icon(Icons.check_rounded, size: 18, color: AppColors.sage),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      case 3:
        return _StepBody(
          eyebrow: 'WHY MOODFIT',
          title: 'Getting dressed usually feels…',
          subtitle: 'No right answer — this just helps Muse know how to show up for you.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ChipWrap(
                children: kDressingFeelings
                    .map((o) => _Choice(
                          label: '${o.emoji}  ${o.label}',
                          active: _profile.dressingFeeling == o.key,
                          onTap: () => setState(() => _profile = FashionProfile(
                                styles: _profile.styles,
                                aesthetics: _profile.aesthetics,
                                palettes: _profile.palettes,
                                goals: _profile.goals,
                                dressingFeeling: _profile.dressingFeeling == o.key ? null : o.key,
                              )),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              Text('WHAT DO YOU WANT FROM MOODFIT?', style: AppTheme.mono()),
              const SizedBox(height: 12),
              _ChipWrap(
                children: kGoals
                    .map((o) => _Choice(
                          label: '${o.emoji}  ${o.label}',
                          active: _profile.goals.contains(o.key),
                          onTap: () =>
                              setState(() => _profile = _profile.copyWith(goals: _toggle(_profile.goals, o.key))),
                        ))
                    .toList(),
              ),
            ],
          ),
        );
      default:
        return _ReadyStep(name: _nameController.text.trim(), profile: _profile);
    }
  }
}

class _StepBody extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;

  const _StepBody({required this.eyebrow, required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: AppTheme.mono()),
        const SizedBox(height: 4),
        Text(
          title,
          style: AppTheme.sans(fontSize: 26, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.8),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: AppTheme.sans(fontSize: 14, height: 1.6, color: AppColors.foreground.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 28),
        child,
      ],
    );
  }
}

class _ReadyStep extends StatelessWidget {
  final String name;
  final FashionProfile profile;

  const _ReadyStep({required this.name, required this.profile});

  @override
  Widget build(BuildContext context) {
    final aesthetic = profile.aesthetics.map(aestheticByKey).whereType<StyleDef>().where((a) => a.feelings.isNotEmpty);
    final palette = profile.palettes.map(paletteByKey).whereType<PaletteDef>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
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
          'Log one outfit today to plant your first seed. Over time you\'ll see which colors and looks '
          'line up with your best days.',
          textAlign: TextAlign.center,
          style: AppTheme.sans(fontSize: 14, height: 1.6, color: AppColors.foreground.withValues(alpha: 0.7)),
        ),
        if (palette.isNotEmpty) ...[
          const SizedBox(height: 24),
          ResearchHint(
            title: '${palette.first.label} colors often feel',
            body: '${feelingsSentence(palette.first.feelings)}.',
          ),
        ],
        if (aesthetic.isNotEmpty) ...[
          const SizedBox(height: 8),
          ResearchHint(
            title: '${aesthetic.first.label} often feels',
            body: '${feelingsSentence(aesthetic.first.feelings)}.',
          ),
        ],
        const SizedBox(height: 16),
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
      ],
    );
  }
}

class _ChipWrap extends StatelessWidget {
  final List<Widget> children;

  const _ChipWrap({required this.children});

  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: children);
}

class _Choice extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Choice({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.sageSoft : AppColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? AppColors.sage : Colors.black.withValues(alpha: 0.08)),
        ),
        child: Text(
          label,
          style: AppTheme.sans(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? AppColors.sage : AppColors.foreground,
          ),
        ),
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
        textCapitalization: TextCapitalization.words,
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
