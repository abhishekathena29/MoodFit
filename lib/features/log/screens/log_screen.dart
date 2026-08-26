import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/log_entry.dart';
import '../../../core/models/mood.dart';
import '../../../core/models/style.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/mood_chip.dart';
import '../../../core/widgets/primary_button.dart';

/// Direct port of src/routes/log.tsx, extended with style and aesthetic
/// steps so Insights can correlate more than just palette and mood.
class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

const _kPalettes = [
  (key: 'sage', label: 'Sage'),
  (key: 'blue-mist', label: 'Mist'),
  (key: 'beige', label: 'Beige'),
  (key: 'amber-warm', label: 'Amber'),
];

class _LogScreenState extends State<LogScreen> {
  String? mood;
  String palette = 'sage';
  String? style;
  String? aesthetic;
  final _noteController = TextEditingController();
  bool saved = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (mood == null) return;
    final store = context.read<UserDataProvider>();
    final result = await store.addLog(
      mood!,
      palette: palette,
      note: _noteController.text,
      style: style,
      aesthetic: aesthetic,
    );
    if (!mounted) return;
    ToastService.success(
      context,
      '+${result.xpGain} xp · ${result.streak} day streak${result.leveledUp ? ' · Level up!' : ''}',
    );
    setState(() => saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserDataProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FadeSlideIn(
        delay: const Duration(milliseconds: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepCard(
              step: 'Step 1',
              title: "Add today's outfit",
              child: _PhotoUploadBox(),
            ),
            const SizedBox(height: 16),
            _StepCard(
              step: 'Step 2',
              title: 'Dominant palette',
              child: _PaletteGrid(
                selected: palette,
                onSelect: (p) => setState(() => palette = p),
              ),
            ),
            const SizedBox(height: 16),
            _StepCard(
              step: 'Step 3',
              title: 'Style',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kStyles
                    .map((s) => _TagChip(
                          label: s.label,
                          active: style == s.key,
                          onTap: () => setState(() => style = style == s.key ? null : s.key),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            _StepCard(
              step: 'Step 4',
              title: 'Aesthetic',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kAesthetics
                    .map((a) => _TagChip(
                          label: a.label,
                          active: aesthetic == a.key,
                          onTap: () => setState(() => aesthetic = aesthetic == a.key ? null : a.key),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            _StepCard(
              step: 'Step 5',
              title: 'Mood in this fit',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kMoods
                        .map((m) => MoodChip(
                              mood: m,
                              active: mood == m.key,
                              onTap: () => setState(() => mood = m.key),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  _NoteField(controller: _noteController),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: saved ? 'Logged ✓' : 'Save log',
              onTap: mood == null ? null : _save,
            ),
            const SizedBox(height: 24),
            _RecentLogsCard(logs: store.logs),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TagChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.sageSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? AppColors.sage : Colors.black.withValues(alpha: 0.05)),
        ),
        child: Text(
          label,
          style: AppTheme.sans(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? AppColors.sage : AppColors.foreground,
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final Widget child;

  const _StepCard({required this.step, required this.title, required this.child});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(step.toUpperCase(), style: AppTheme.mono()),
          const SizedBox(height: 4),
          Text(title, style: AppTheme.sans(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PhotoUploadBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Matches the web version: a decorative, non-functional upload target.
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.15),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppColors.sageSoft, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Text('📷', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 8),
              Text('Take or upload a photo', style: AppTheme.sans(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                'Stored on device. Never shared.',
                style: AppTheme.sans(fontSize: 11, color: AppColors.foreground.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaletteGrid extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _PaletteGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _kPalettes.map((p) {
        final active = selected == p.key;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(p.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: active ? AppColors.muted : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: active ? Border.all(color: AppColors.sage, width: 2) : null,
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.paletteToColor(p.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(p.label, style: AppTheme.sans(fontSize: 10, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NoteField extends StatelessWidget {
  final TextEditingController controller;

  const _NoteField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        controller: controller,
        maxLines: 2,
        style: AppTheme.sans(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'A word or two (optional)',
          hintStyle: AppTheme.sans(fontSize: 14, color: AppColors.foreground.withValues(alpha: 0.35)),
          border: InputBorder.none,
          isCollapsed: true,
        ),
      ),
    );
  }
}

class _RecentLogsCard extends StatelessWidget {
  final List<LogEntry> logs;

  const _RecentLogsCard({required this.logs});

  @override
  Widget build(BuildContext context) {
    final shown = logs.take(6).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RECENT LOGS', style: AppTheme.mono()),
              Text(
                '${logs.length} entries',
                style: AppTheme.mono(fontSize: 10, color: AppColors.foreground.withValues(alpha: 0.4)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...shown.map((l) {
            final m = moodByKey(l.mood);
            final s = styleByKey(l.style);
            final a = aestheticByKey(l.aesthetic);
            final tags = [s?.label, a?.label].whereType<String>().join(' · ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.paletteToColor(l.palette),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m?.label ?? l.mood, style: AppTheme.sans(fontSize: 14, fontWeight: FontWeight.w500)),
                        Text(
                          tags.isEmpty ? l.date : '${l.date} · $tags',
                          style: AppTheme.mono(fontSize: 10, color: AppColors.foreground.withValues(alpha: 0.5)),
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
    );
  }
}
