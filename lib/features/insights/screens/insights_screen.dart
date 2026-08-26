import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/mood.dart';
import '../../../core/models/style.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_bar.dart';
import '../../../core/widgets/fade_slide_in.dart';

class _PaletteMoodStat {
  final String mood;
  final bool positive;
  final double pct;
  const _PaletteMoodStat({required this.mood, required this.positive, required this.pct});
}

/// Direct port of src/routes/insights.tsx, with the palette→mood card now
/// computed from real logs (style, aesthetic and color-mood correlation)
/// instead of hardcoded demo numbers.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  static const _kPalettes = ['sage', 'blue-mist', 'beige', 'amber-warm'];

  /// For each palette, the mood it most often shows up with in real logs —
  /// this is the "color-mood correlation" the log's palette+mood pair feeds.
  Map<String, _PaletteMoodStat> _correlations(List logs) {
    final result = <String, _PaletteMoodStat>{};
    for (final palette in _kPalettes) {
      final withPalette = logs.where((l) => l.palette == palette).toList();
      if (withPalette.isEmpty) continue;
      final moodCounts = <String, int>{};
      for (final l in withPalette) {
        moodCounts[l.mood] = (moodCounts[l.mood] ?? 0) + 1;
      }
      final topMood = moodCounts.keys.reduce((a, b) => moodCounts[a]! >= moodCounts[b]! ? a : b);
      final pct = moodCounts[topMood]! / withPalette.length * 100;
      final def = moodByKey(topMood);
      result[palette] = _PaletteMoodStat(mood: def?.label ?? topMood, positive: !(def?.warm ?? false), pct: pct);
    }
    return result;
  }

  /// Most-logged style / aesthetic tag, when present.
  StyleDef? _topTag(List logs, String field) {
    final counts = <String, int>{};
    for (final l in logs) {
      final key = field == 'style' ? l.style : l.aesthetic;
      if (key == null) continue;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final topKey = counts.keys.reduce((a, b) => counts[a]! >= counts[b]! ? a : b);
    return field == 'style' ? styleByKey(topKey) : aestheticByKey(topKey);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserDataProvider>();

    final counts = <String, int>{};
    for (final l in store.logs) {
      counts[l.mood] = (counts[l.mood] ?? 0) + 1;
    }
    final total = store.logs.isEmpty ? 1 : store.logs.length;
    final sorted = counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    final paletteMood = _correlations(store.logs);
    final topStyle = _topTag(store.logs, 'style');
    final topAesthetic = _topTag(store.logs, 'aesthetic');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FadeSlideIn(
        delay: const Duration(milliseconds: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MOOD DISTRIBUTION', style: AppTheme.mono()),
                  const SizedBox(height: 24),
                  if (sorted.isEmpty)
                    Text(
                      'Log a few outfits to see patterns.',
                      style: AppTheme.sans(fontSize: 14, color: AppColors.foreground.withValues(alpha: 0.5)),
                    )
                  else
                    ...sorted.map((k) {
                      final m = moodByKey(k)!;
                      final pct = (counts[k]! / total * 100).round();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(m.label, style: AppTheme.sans(fontSize: 12, fontWeight: FontWeight.w500)),
                                Text(
                                  '$pct%',
                                  style: AppTheme.mono(fontSize: 11, color: AppColors.foreground.withValues(alpha: 0.5)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            AnimatedHBar(
                              percent: pct.toDouble(),
                              color: m.warm ? AppColors.amberWarm : AppColors.sage,
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PALETTE → MOOD', style: AppTheme.mono()),
                  const SizedBox(height: 4),
                  Text(
                    'What colors correlate with your best days.',
                    style: AppTheme.sans(fontSize: 11, color: AppColors.foreground.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 20),
                  if (paletteMood.isEmpty)
                    Text(
                      'Log a few outfits to see color-mood correlations.',
                      style: AppTheme.sans(fontSize: 14, color: AppColors.foreground.withValues(alpha: 0.5)),
                    )
                  else
                    ...paletteMood.entries.map((e) {
                      final v = e.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.paletteToColor(e.key),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: AppTheme.sans(fontSize: 13, fontWeight: FontWeight.w500),
                                      children: [
                                        TextSpan(text: 'Feels ${v.mood.toLowerCase()} '),
                                        TextSpan(
                                          text: '${v.pct.round()}% of the time',
                                          style: AppTheme.mono(fontSize: 10, color: AppColors.foreground.withValues(alpha: 0.4)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  AnimatedHBar(
                                    percent: v.pct,
                                    color: v.positive ? AppColors.sage : AppColors.amberWarm,
                                    height: 6,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (topStyle != null || topAesthetic != null) ...[
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('STYLE & AESTHETIC', style: AppTheme.mono()),
                    const SizedBox(height: 4),
                    Text(
                      'Your most-logged look.',
                      style: AppTheme.sans(fontSize: 11, color: AppColors.foreground.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (topStyle != null)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(16)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('STYLE', style: AppTheme.mono(fontSize: 9)),
                                  const SizedBox(height: 4),
                                  Text(topStyle.label, style: AppTheme.sans(fontSize: 15, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        if (topStyle != null && topAesthetic != null) const SizedBox(width: 12),
                        if (topAesthetic != null)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration:
                                  BoxDecoration(color: AppColors.sageSoft.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(16)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('AESTHETIC', style: AppTheme.mono(fontSize: 9, color: AppColors.sage)),
                                  const SizedBox(height: 4),
                                  Text(topAesthetic.label,
                                      style: AppTheme.sans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.sage)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.sage, borderRadius: BorderRadius.circular(28)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI PATTERN',
                      style: AppTheme.mono(color: Colors.white.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sage tones align with your most focused days.',
                      style: AppTheme.sans(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Based on ${store.logs.length} logs across the last '
                      '${store.logs.length < 30 ? store.logs.length : 30} days.',
                      style: AppTheme.sans(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.amberWarm.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.amberWarm.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GENTLE OBSERVATION', style: AppTheme.mono(color: AppColors.amberDeep.withValues(alpha: 0.7))),
                    const SizedBox(height: 8),
                    Text(
                      "Heavy tones tend to cluster on Sundays. That's just data — not a diagnosis.",
                      style: AppTheme.sans(fontSize: 14, height: 1.6, color: AppColors.amberDeep.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }
}
