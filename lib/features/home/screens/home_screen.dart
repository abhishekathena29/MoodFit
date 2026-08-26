import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/mood.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_bar.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/mood_chip.dart';
import '../../../core/widgets/pulsing_dot.dart';

/// Direct port of src/routes/index.tsx (the Home tab).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selected;

  void _pick(String moodKey) async {
    setState(() => selected = moodKey);
    final store = context.read<UserDataProvider>();
    final result = await store.addLog(moodKey, palette: 'sage');
    if (!mounted) return;
    ToastService.success(
      context,
      '+${result.xpGain} xp · ${result.streak} day streak${result.leveledUp ? ' · Level up!' : ''}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserDataProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeSlideIn(
            delay: const Duration(milliseconds: 100),
            child: _WeeklyPaletteCard(),
          ),
          const SizedBox(height: 32),
          FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('CAPTURE TODAY', style: AppTheme.mono()),
                ),
                const SizedBox(height: 16),
                _CaptureTodayCard(
                  selected: selected,
                  onPick: _pick,
                  streak: store.streak,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          FadeSlideIn(delay: const Duration(milliseconds: 300), child: const _RecallCard()),
          const SizedBox(height: 32),
          FadeSlideIn(delay: const Duration(milliseconds: 400), child: const _CheckingInCard()),
        ],
      ),
    );
  }
}

class _WeeklyPaletteCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('WEEKLY PALETTE', style: AppTheme.mono()),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.sageSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Soft Trend',
                  style: AppTheme.sans(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.sage),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 128,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedVBar(heightPercent: 80, color: AppColors.sage),
                const SizedBox(width: 6),
                AnimatedVBar(heightPercent: 40, color: AppColors.blueMist),
                const SizedBox(width: 6),
                AnimatedVBar(heightPercent: 65, color: AppColors.beige),
                const SizedBox(width: 6),
                AnimatedVBar(heightPercent: 95, color: AppColors.sage.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                AnimatedVBar(heightPercent: 30, color: AppColors.amberWarm.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                AnimatedVBar(heightPercent: 55, color: AppColors.sage.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                AnimatedVBar(heightPercent: 70, color: AppColors.blueMist.withValues(alpha: 0.5)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU']
                  .map((d) => Text(
                        d,
                        style: AppTheme.mono(fontSize: 9, color: AppColors.foreground.withValues(alpha: 0.4)),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
            child: RichText(
              text: TextSpan(
                style: AppTheme.sans(fontSize: 14, height: 1.6),
                children: [
                  TextSpan(text: 'Morning nudge: ', style: AppTheme.sans(fontSize: 14, fontWeight: FontWeight.w700)),
                  const TextSpan(
                    text: 'your palette is leaning cooler this week. Consider a warm layer today '
                        'to balance the morning fog.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureTodayCard extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onPick;
  final int streak;

  const _CaptureTodayCard({required this.selected, required this.onPick, required this.streak});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Image.asset(
                'assets/images/outfit-today.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How do you feel in this?',
                    style: AppTheme.mono(fontSize: 12, color: AppColors.foreground.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kMoods
                        .map((m) => MoodChip(
                              mood: m,
                              active: selected == m.key,
                              onTap: () => onPick(m.key),
                            ))
                        .toList(),
                  ),
                  if (selected != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Logged · streak $streak 🔥',
                      style: AppTheme.mono(fontSize: 10, color: AppColors.sage),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecallCard extends StatelessWidget {
  const _RecallCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.blueMist,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: AppColors.blueMist.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, 20)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/outfit-recall.jpg',
              width: 96,
              height: 96,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'From Oct 12',
                  style: AppTheme.mono(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 4),
                Text(
                  'You felt at your best in this combination.',
                  style: AppTheme.sans(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  'Want to try it again today?',
                  style: AppTheme.sans(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckingInCard extends StatelessWidget {
  const _CheckingInCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.amberWarm.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.amberWarm.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PulsingDot(color: AppColors.amberWarm),
              const SizedBox(width: 12),
              Text(
                'Checking in',
                style: AppTheme.sans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.amberDeep),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Your recent logs show a shift toward repeat heavy tones. It's okay to feel this way. "
            'Would you like to reach out or reflect?',
            style: AppTheme.sans(fontSize: 14, height: 1.6, color: AppColors.amberDeep.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}
