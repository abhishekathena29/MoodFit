import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/reward.dart';
import '../providers/user_data_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'animated_bar.dart';
import 'fade_slide_in.dart';

/// Shared app chrome: header (date/title + streak chip), xp bar, content and
/// the floating bottom nav. Used two ways: as the single ShellRoute builder
/// for every tab (Home, Log, Insights, Muse, Profile) — so no individual
/// screen constructs its own nav bar or repeats its title — and directly by
/// the one standalone, non-tab route (Rewards).
class AppShell extends StatelessWidget {
  final Widget child;
  final String currentPath;
  final String? title;
  final String? date;

  const AppShell({
    super.key,
    required this.child,
    required this.currentPath,
    this.title,
    this.date,
  });

  static const _titles = {
    '/': 'MoodFit',
    '/log': 'Log',
    '/insights': 'Insights',
    '/muse': 'Muse',
    '/profile': 'Profile',
  };

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserDataProvider>();
    final level = levelFromXp(store.xp);
    final today = DateFormat('EEEE, MMM d').format(DateTime.now());
    final resolvedTitle = title ?? _titles[currentPath] ?? 'MoodFit';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeSlideIn(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text((date ?? today).toUpperCase(), style: AppTheme.mono()),
                              const SizedBox(height: 4),
                              Text(
                                resolvedTitle.toUpperCase(),
                                style: AppTheme.sans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => context.go('/profile'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.sageSoft,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppColors.sage.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🔥', style: TextStyle(fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Text(
                                    store.hydrated ? '${store.streak}' : '–',
                                    style: AppTheme.mono(
                                      color: AppColors.sage,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (store.hydrated)
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 50),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.muted.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              Text('LV ${level.level}', style: AppTheme.mono(fontSize: 10)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AnimatedHBar(
                                  percent: level.into.toDouble(),
                                  color: AppColors.sage,
                                  height: 6,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('${store.xp} xp', style: AppTheme.mono(fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  child,
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: _BottomNav(currentPath: currentPath),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String path;
  final String label;
  const _NavItem(this.path, this.label);
}

const _kNavItems = [
  _NavItem('/', 'Home'),
  _NavItem('/log', 'Log'),
  _NavItem('/insights', 'Insights'),
  _NavItem('/muse', 'Muse'),
  _NavItem('/profile', 'Profile'),
];

class _BottomNav extends StatelessWidget {
  final String currentPath;

  const _BottomNav({required this.currentPath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: _kNavItems.map((it) {
              final active = currentPath == it.path;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (!active) context.go(it.path);
                  },
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: active ? 1 : 0.4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active ? AppColors.sage : AppColors.foreground,
                            ),
                          ),
                          Text(
                            it.label.toUpperCase(),
                            style: AppTheme.sans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
