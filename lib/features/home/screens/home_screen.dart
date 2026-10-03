import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/log_entry.dart';
import '../../../core/models/mood.dart';
import '../../../core/models/palette.dart';
import '../../../core/models/style.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../core/services/ai_context.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_bar.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/mood_chip.dart';
import '../../../core/widgets/palette_swatch.dart';
import '../../../core/widgets/pulsing_dot.dart';
import '../../../core/widgets/research_hint.dart';

/// The Home tab — weekly palette, today's AI nudge, quick mood capture, a
/// recalled best outfit and a gentle check-in, all computed from the
/// user's Firestore logs.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selected;
  bool _nudgeRequested = false;

  /// Generates today's nudge with Groq once per day (cached on the user
  /// doc). If the AI is unavailable nothing is saved, so the card shows
  /// the local fallback and tomorrow tries again.
  Future<void> _ensureNudge(UserDataProvider store) async {
    if (_nudgeRequested || !store.hydrated || store.hasNudgeForToday) return;
    _nudgeRequested = true;
    final text = await AiService.instance.chat([
      AiMessage(
        'system',
        'You write the short "morning nudge" on the MoodFit home screen. Using the research and this '
            "user's recent logs and taste, write ONE or TWO sentences (max 40 words) that notice a pattern in "
            'their recent palettes/moods and suggest one concrete color or aesthetic idea for today. Warm, '
            'gentle, plain text, no greeting, no quotes, never diagnose.\n\n'
            '${AiContext.research()}\n${AiContext.user(store)}',
      ),
      const AiMessage('user', "Write today's nudge."),
    ], maxTokens: 120);
    if (text != null && mounted) await store.saveNudge(text);
  }

  void _pick(String moodKey) async {
    setState(() => selected = moodKey);
    final store = context.read<UserDataProvider>();
    final result = await store.addLog(moodKey);
    if (!mounted) return;
    ToastService.success(
      context,
      '+${result.xpGain} xp · ${result.streak} day streak${result.leveledUp ? ' · Level up!' : ''}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserDataProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureNudge(store));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeSlideIn(
            delay: const Duration(milliseconds: 100),
            child: _WeeklyPaletteCard(logs: store.logs, nudge: store.hasNudgeForToday ? store.nudgeText : null),
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
                  selected: selected ?? _todayMood(store.logs),
                  onPick: _pick,
                  streak: store.streak,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (_bestPastLog(store.logs) case final recall?) ...[
            FadeSlideIn(delay: const Duration(milliseconds: 300), child: _RecallCard(log: recall)),
            const SizedBox(height: 32),
          ],
          if (_recentHeavyCount(store.logs) >= 3)
            FadeSlideIn(
              delay: const Duration(milliseconds: 400),
              child: _CheckingInCard(heavyCount: _recentHeavyCount(store.logs)),
            ),
        ],
      ),
    );
  }
}

final DateFormat _ymd = DateFormat('yyyy-MM-dd');

/// The happiest earlier log that has a palette — what "You felt at your
/// best in this" recalls.
LogEntry? _bestPastLog(List<LogEntry> logs) {
  final today = _ymd.format(DateTime.now());
  LogEntry? best;
  var bestEnergy = 0;
  for (final l in logs) {
    final m = moodByKey(l.mood);
    if (l.date == today || l.palette == null || m == null || m.heavy) continue;
    if (m.energy > bestEnergy) {
      best = l;
      bestEnergy = m.energy;
    }
  }
  return best;
}

String? _todayMood(List<LogEntry> logs) {
  final today = _ymd.format(DateTime.now());
  for (final l in logs) {
    if (l.date == today) return l.mood;
  }
  return null;
}

/// Heavier moods among the last 7 logs — drives the gentle check-in.
int _recentHeavyCount(List<LogEntry> logs) =>
    logs.take(7).where((l) => moodByKey(l.mood)?.heavy ?? false).length;

class _WeeklyPaletteCard extends StatelessWidget {
  final List<LogEntry> logs;
  final String? nudge;

  const _WeeklyPaletteCard({required this.logs, this.nudge});

  /// Local fallback when there's no AI nudge for today.
  String _fallbackNudge(PaletteDef? top) {
    if (top == null) return "log today's outfit to start seeing which colors line up with your moods.";
    final calming = const ['muted', 'neutral', 'cool'].contains(top.key);
    return 'your palette is leaning ${top.label.toLowerCase()} this week — often linked with feeling '
        '${top.feelings.take(2).join(' and ')}. '
        '${calming ? 'A warm layer today could add a little energy.' : 'A calm neutral piece could balance things out.'}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final byDay = <String, LogEntry>{};
    for (final l in logs) {
      byDay.putIfAbsent(l.date, () => l); // logs are newest-first
    }
    final week = days.map((d) => byDay[_ymd.format(d)]).toList();

    final counts = <String, int>{};
    for (final l in week.whereType<LogEntry>()) {
      if (l.palette != null) counts[l.palette!] = (counts[l.palette!] ?? 0) + 1;
    }
    final topPalette = counts.isEmpty
        ? null
        : paletteByKey(counts.keys.reduce((a, b) => counts[a]! >= counts[b]! ? a : b));

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
                  topPalette == null ? 'No palette yet' : '${topPalette.label}-leaning',
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
                for (var i = 0; i < 7; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  AnimatedVBar(
                    heightPercent: week[i] == null ? 6 : (moodByKey(week[i]!.mood)?.energy ?? 50).toDouble(),
                    color: week[i] == null
                        ? AppColors.muted
                        : (paletteByKey(week[i]!.palette)?.swatch.first ?? AppColors.sage.withValues(alpha: 0.5)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days
                  .map((d) => Text(
                        DateFormat('E').format(d).substring(0, 2).toUpperCase(),
                        style: AppTheme.mono(fontSize: 9, color: AppColors.foreground.withValues(alpha: 0.4)),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bar height = how upbeat the mood was · color = palette worn',
            textAlign: TextAlign.center,
            style: AppTheme.sans(fontSize: 10, color: AppColors.foreground.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
            child: RichText(
              text: TextSpan(
                style: AppTheme.sans(fontSize: 14, height: 1.6),
                children: [
                  TextSpan(text: 'Morning nudge: ', style: AppTheme.sans(fontSize: 14, fontWeight: FontWeight.w700)),
                  TextSpan(text: nudge ?? _fallbackNudge(topPalette)),
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
                    if (moodByKey(selected!) case final mood?) ...[
                      const SizedBox(height: 12),
                      ResearchHint.forMood(mood),
                    ],
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
  final LogEntry log;

  const _RecallCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final mood = moodByKey(log.mood);
    final palette = paletteByKey(log.palette);
    final aesthetic = aestheticByKey(log.aesthetic);
    final date = DateTime.tryParse(log.date);
    final combo = [
      if (palette != null) '${palette.label.toLowerCase()} colors',
      if (aesthetic != null) aesthetic.label,
    ].join(' + ');
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
            child: PaletteSwatch(palette: log.palette, size: 96, radius: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'From ${date == null ? log.date : DateFormat('MMM d').format(date)}',
                  style: AppTheme.mono(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 4),
                Text(
                  'You felt ${mood?.label.toLowerCase() ?? 'great'} in $combo.',
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
  final int heavyCount;

  const _CheckingInCard({required this.heavyCount});

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
            '$heavyCount of your last 7 logs were heavier moods. It\'s okay to feel this way. '
            'Would you like to talk it through with Muse, or check the Support section on your Profile?',
            style: AppTheme.sans(fontSize: 14, height: 1.6, color: AppColors.amberDeep.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}
