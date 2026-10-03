import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/fashion_profile.dart';
import '../../../core/models/log_entry.dart';
import '../../../core/models/mood.dart';
import '../../../core/models/palette.dart';
import '../../../core/models/reward.dart';
import '../../../core/models/style.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_bar.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/palette_swatch.dart';
import '../../../core/widgets/pulsing_dot.dart';
import '../../auth/providers/auth_provider.dart';

/// Profile tab — everything the old Care screen had (streak, rewards,
/// support, reset-data) plus a profile detail header and sign-out. Reads
/// [UserDataProvider] (Firestore profile/logs) and [AuthProvider] (the
/// Firebase Auth session itself) side by side.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _reset(BuildContext context) async {
    await context.read<UserDataProvider>().reset();
    if (context.mounted) ToastService.success(context, 'All data cleared');
  }

  Future<void> _editName(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Your name', style: AppTheme.sans(fontSize: 17, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: AppTheme.sans(fontSize: 14),
          decoration: const InputDecoration(hintText: 'e.g. Alex'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.trim().isEmpty || !context.mounted) return;
    await context.read<UserDataProvider>().updateName(result);
    if (context.mounted) ToastService.success(context, 'Name updated');
  }

  /// Most frequent non-null value of [pick] across [logs].
  String? _mostCommon(List<LogEntry> logs, String? Function(LogEntry) pick) {
    final counts = <String, int>{};
    for (final l in logs) {
      final k = pick(l);
      if (k != null) counts[k] = (counts[k] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    return counts.keys.reduce((a, b) => counts[a]! >= counts[b]! ? a : b);
  }

  Future<void> _signOut(BuildContext context) async {
    await context.read<AuthProvider>().signOut();
    if (context.mounted) context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserDataProvider>();
    final auth = context.watch<AuthProvider>();
    final level = levelFromXp(store.xp);
    final initial = store.name.isNotEmpty ? store.name[0].toUpperCase() : '?';
    final topMood = moodByKey(_mostCommon(store.logs, (l) => l.mood) ?? '');
    final topPalette = paletteByKey(_mostCommon(store.logs, (l) => l.palette));
    final email = store.email.isNotEmpty ? store.email : auth.email;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FadeSlideIn(
        delay: const Duration(milliseconds: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile detail
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.sageSoft, shape: BoxShape.circle),
                    child: Text(
                      initial,
                      style: AppTheme.sans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.sage),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name.isNotEmpty ? store.name : 'Friend',
                          style: AppTheme.sans(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: AppTheme.sans(fontSize: 12, color: AppColors.foreground.withValues(alpha: 0.55)),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          'LEVEL ${level.level} · ${store.xp} XP'
                          '${store.createdAt != null ? ' · SINCE ${DateFormat('MMM yyyy').format(store.createdAt!).toUpperCase()}' : ''}',
                          style: AppTheme.mono(fontSize: 10, color: AppColors.sage),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _editName(context, store.name),
                    icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.foreground.withValues(alpha: 0.5)),
                    tooltip: 'Edit name',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats from real logs
            Row(
              children: [
                Expanded(child: _StatTile(label: 'LOGS', value: '${store.logs.length}')),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'TOP MOOD',
                    value: topMood == null ? '—' : topMood.emoji,
                    caption: topMood?.label,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'GO-TO COLORS',
                    value: topPalette == null ? '—' : null,
                    swatch: topPalette?.key,
                    caption: topPalette?.label,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _StyleProfileCard(profile: store.fashionProfile),
            const SizedBox(height: 16),

            // Streak hero
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.sage, borderRadius: BorderRadius.circular(28)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STREAK', style: AppTheme.mono(color: Colors.white.withValues(alpha: 0.7))),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${store.streak}',
                        style: AppTheme.sans(fontSize: 56, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1.5),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'day${store.streak == 1 ? '' : 's'} 🔥',
                          style: AppTheme.sans(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('LEVEL ${level.level}', style: AppTheme.mono(color: Colors.white.withValues(alpha: 0.8))),
                      Text('${store.xp} xp', style: AppTheme.mono(color: Colors.white.withValues(alpha: 0.8))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedHBar(
                    percent: level.into.toDouble(),
                    color: Colors.white,
                    trackColor: Colors.white.withValues(alpha: 0.25),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Rewards
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REWARDS', style: AppTheme.mono()),
                  const SizedBox(height: 16),
                  ...kRewards.map((r) => _RewardRow(reward: r, earned: store.streak >= r.at)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Support
            Container(
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
                      PulsingDot(color: AppColors.amberWarm, size: 8),
                      const SizedBox(width: 12),
                      Text(
                        'Support',
                        style: AppTheme.sans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.amberDeep),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You can always reach someone. No streak, no data — just people.',
                    style: AppTheme.sans(fontSize: 14, height: 1.6, color: AppColors.amberDeep.withValues(alpha: 0.85)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _WarnButton(label: 'Journal')),
                      const SizedBox(width: 12),
                      Expanded(child: _WarnButton(label: 'Resources')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Privacy
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOUR DATA', style: AppTheme.mono()),
                  const SizedBox(height: 8),
                  Text(
                    '${store.logs.length} logs and your Muse chat are saved privately to your account. '
                    'Delete everything, anytime.',
                    style: AppTheme.sans(fontSize: 12, color: AppColors.foreground.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _reset(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'RESET ALL DATA',
                        style: AppTheme.sans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.foreground.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sign out
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _signOut(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.amberDeep.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'SIGN OUT',
                  style: AppTheme.sans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.amberDeep),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  final Reward reward;
  final bool earned;

  const _RewardRow({required this.reward, required this.earned});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: earned ? AppColors.sageSoft.withValues(alpha: 0.6) : AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: earned ? Colors.white : AppColors.muted,
              shape: BoxShape.circle,
              border: earned ? Border.all(color: AppColors.sage.withValues(alpha: 0.3)) : null,
            ),
            child: Opacity(
              opacity: earned ? 1 : 0.4,
              child: Text(reward.emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  style: AppTheme.sans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: earned ? AppColors.sage : AppColors.foreground,
                  ),
                ),
                Text(
                  reward.desc,
                  style: AppTheme.sans(fontSize: 11, color: AppColors.foreground.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          Text(
            earned ? '✓' : '${reward.at}d',
            style: AppTheme.mono(fontSize: 10, color: AppColors.foreground.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

class _WarnButton extends StatelessWidget {
  final String label;

  const _WarnButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: AppTheme.sans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.amberDeep),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String? value;
  final String? swatch;
  final String? caption;

  const _StatTile({required this.label, this.value, this.swatch, this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: AppTheme.mono(fontSize: 9))),
          const Spacer(),
          if (swatch != null)
            PaletteSwatch(palette: swatch, size: 28, radius: 8)
          else
            Text(value ?? '—', style: AppTheme.sans(fontSize: 24, fontWeight: FontWeight.w800)),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.sans(fontSize: 11, color: AppColors.foreground.withValues(alpha: 0.6)),
            ),
          ],
        ],
      ),
    );
  }
}

/// The onboarding quiz answers, with an entry point to edit them.
class _StyleProfileCard extends StatelessWidget {
  final FashionProfile profile;

  const _StyleProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final tags = [
      ...profile.styles.map((k) => styleByKey(k)?.label),
      ...profile.aesthetics.map((k) => aestheticByKey(k)?.label),
    ].whereType<String>().toList();
    final palettes = profile.palettes.map(paletteByKey).whereType<PaletteDef>().toList();
    final feeling = optionByKey(kDressingFeelings, profile.dressingFeeling);
    final goals = profile.goals.map((k) => optionByKey(kGoals, k)).whereType<OptionDef>().toList();

    return Container(
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
              Text('STYLE PROFILE', style: AppTheme.mono()),
              GestureDetector(
                onTap: () => context.push('/style-profile'),
                child: Text(
                  profile.isEmpty ? 'Take quiz →' : 'Edit',
                  style: AppTheme.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.sage),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (profile.isEmpty)
            Text(
              'Tell Muse about your style so suggestions fit you.',
              style: AppTheme.sans(fontSize: 13, color: AppColors.foreground.withValues(alpha: 0.6)),
            ),
          if (tags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.sageSoft, borderRadius: BorderRadius.circular(999)),
                        child: Text(t, style: AppTheme.sans(fontSize: 11, color: AppColors.sage, fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
            ),
          if (palettes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: palettes
                  .map((p) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PaletteSwatch(palette: p.key, size: 18, radius: 9),
                          const SizedBox(width: 6),
                          Text(p.label, style: AppTheme.sans(fontSize: 12)),
                        ],
                      ))
                  .toList(),
            ),
          ],
          if (feeling != null || goals.isNotEmpty) ...[
            const SizedBox(height: 12),
            if (feeling != null)
              Text(
                'Getting dressed: ${feeling.label.toLowerCase()}',
                style: AppTheme.sans(fontSize: 12, color: AppColors.foreground.withValues(alpha: 0.7)),
              ),
            ...goals.map((g) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${g.emoji}  ${g.label}',
                    style: AppTheme.sans(fontSize: 12, color: AppColors.foreground.withValues(alpha: 0.7)),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
