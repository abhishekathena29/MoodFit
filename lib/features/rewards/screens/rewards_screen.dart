import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/reward.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_bar.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/fade_slide_in.dart';

/// Direct port of src/routes/rewards.tsx. Not linked from the bottom nav in
/// the web app either — it exists as a standalone route, reachable only by
/// direct navigation, and this mirrors that exactly.
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserDataProvider>();
    final level = levelFromXp(store.xp);
    final unlocked = kRewards.where((r) => store.streak >= r.at).toList();
    Reward? nextReward;
    for (final r in kRewards) {
      if (store.streak < r.at) {
        nextReward = r;
        break;
      }
    }
    final toNext = nextReward != null ? nextReward.at - store.streak : 0;

    return AppShell(
      currentPath: '/rewards',
      title: 'Rewards',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: FadeSlideIn(
          delay: const Duration(milliseconds: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Streak hero
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.sage, borderRadius: BorderRadius.circular(28)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CURRENT STREAK', style: AppTheme.mono(color: Colors.white.withValues(alpha: 0.7))),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          store.hydrated ? '${store.streak}' : '–',
                          style: AppTheme.sans(fontSize: 64, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1.5),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'day${store.streak == 1 ? '' : 's'} 🔥',
                            style: AppTheme.sans(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                          ),
                        ),
                      ],
                    ),
                    if (nextReward != null) ...[
                      const SizedBox(height: 12),
                      RichText(
                        text: TextSpan(
                          style: AppTheme.sans(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                          children: [
                            TextSpan(text: '$toNext day${toNext == 1 ? '' : 's'} until '),
                            TextSpan(
                              text: nextReward.name,
                              style: AppTheme.sans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            TextSpan(text: ' ${nextReward.emoji}'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // XP progress
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('LEVEL ${level.level}', style: AppTheme.mono()),
                        Text(
                          '${store.xp} xp',
                          style: AppTheme.mono(fontSize: 10, color: AppColors.foreground.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AnimatedHBar(percent: level.into.toDouble(), color: AppColors.sage),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${level.into} / 100',
                          style: AppTheme.mono(fontSize: 10, color: AppColors.foreground.withValues(alpha: 0.5)),
                        ),
                        Text(
                          'Lv ${level.level + 1} in ${100 - level.into} xp',
                          style: AppTheme.mono(fontSize: 10, color: AppColors.foreground.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Unlocked count
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.sageSoft.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('UNLOCKED', style: AppTheme.mono(color: AppColors.sage)),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              style: AppTheme.sans(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.sage, letterSpacing: -1),
                              children: [
                                TextSpan(text: '${unlocked.length}'),
                                TextSpan(
                                  text: '/${kRewards.length}',
                                  style: AppTheme.sans(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.sage.withValues(alpha: 0.6)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LOGS', style: AppTheme.mono()),
                          const SizedBox(height: 4),
                          Text(
                            '${store.logs.length}',
                            style: AppTheme.sans(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Rewards ladder
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
                    Text('ALL REWARDS', style: AppTheme.mono()),
                    const SizedBox(height: 16),
                    ...kRewards.map((r) {
                      final earned = store.streak >= r.at;
                      final progress = (store.streak / r.at * 100).clamp(0, 100).toDouble();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: earned ? AppColors.sageSoft.withValues(alpha: 0.6) : AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: earned ? Colors.white : AppColors.muted,
                                    shape: BoxShape.circle,
                                    border: earned
                                        ? Border.all(color: AppColors.sage.withValues(alpha: 0.3))
                                        : null,
                                  ),
                                  child: Opacity(
                                    opacity: earned ? 1 : 0.4,
                                    child: Text(r.emoji, style: const TextStyle(fontSize: 20)),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.name,
                                        style: AppTheme.sans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: earned ? AppColors.sage : AppColors.foreground,
                                        ),
                                      ),
                                      Text(
                                        r.desc,
                                        style: AppTheme.sans(fontSize: 11, color: AppColors.foreground.withValues(alpha: 0.6)),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  earned ? '✓' : '${r.at}d',
                                  style: AppTheme.mono(fontSize: 10, color: AppColors.foreground.withValues(alpha: 0.5)),
                                ),
                              ],
                            ),
                            if (!earned) ...[
                              const SizedBox(height: 12),
                              AnimatedHBar(percent: progress, color: AppColors.sage.withValues(alpha: 0.6), height: 4),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
