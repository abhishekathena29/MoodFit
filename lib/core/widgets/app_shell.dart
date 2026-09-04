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
/// the floating bottom nav. Used two ways: as the single StatefulShellRoute
/// builder for every tab (Home, Log, Insights, Muse, Profile) — so no
/// individual screen constructs its own nav bar or repeats its title, and
/// each tab keeps its own state (scroll position, in-progress form) when
/// switched away from — and directly, via [AppShell.page], by the one
/// standalone, non-tab route (Rewards).
class AppShell extends StatelessWidget {
  final StatefulNavigationShell? navigationShell;
  final Widget? child;
  final String? currentPath;
  final String? title;
  final String? date;

  const AppShell({
    super.key,
    required StatefulNavigationShell this.navigationShell,
    this.title,
    this.date,
  }) : child = null,
       currentPath = null;

  const AppShell.page({
    super.key,
    required Widget this.child,
    required String this.currentPath,
    this.title,
    this.date,
  }) : navigationShell = null;

  static const _titles = {
    '/': 'MoodFit',
    '/log': 'Log',
    '/insights': 'Insights',
    '/muse': 'Muse',
    '/profile': 'Profile',
  };

  String get _activePath {
    final shell = navigationShell;
    return shell != null ? _kNavItems[shell.currentIndex].path : currentPath!;
  }

  void _onNavTap(BuildContext context, int index) {
    final shell = navigationShell;
    if (shell != null) {
      shell.goBranch(index, initialLocation: index == shell.currentIndex);
    } else if (_kNavItems[index].path != currentPath) {
      context.go(_kNavItems[index].path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserDataProvider>();
    final level = levelFromXp(store.xp);
    final today = DateFormat('EEEE, MMM d').format(DateTime.now());
    final activePath = _activePath;
    final resolvedTitle = title ?? _titles[activePath] ?? 'MoodFit';

    return Scaffold(
      backgroundColor: AppColors.background,
      // Scaffold.body hands out loose constraints, so without forcing it to
      // fill the screen the Stack (and the floating nav Positioned within
      // it) shrink-wraps to whichever branch's content is shortest — the
      // nav would then sit at a different height per tab instead of staying
      // pinned to the bottom of the screen.
      body: SizedBox.expand(
        child: Stack(
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
                                Text(
                                  (date ?? today).toUpperCase(),
                                  style: AppTheme.mono(),
                                ),
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
                              onTap: () => _onNavTap(context, 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.sageSoft,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: AppColors.sage.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      '🔥',
                                      style: TextStyle(fontSize: 14),
                                    ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.muted.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'LV ${level.level}',
                                  style: AppTheme.mono(fontSize: 10),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AnimatedHBar(
                                    percent: level.into.toDouble(),
                                    color: AppColors.sage,
                                    height: 6,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${store.xp} xp',
                                  style: AppTheme.mono(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    navigationShell ?? child!,
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: _BottomNav(
                currentPath: activePath,
                onTap: (index) => _onNavTap(context, index),
              ),
            ),
          ],
        ),
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
  _NavItem('/muse', 'Muse'),
  _NavItem('/insights', 'Insights'),
  _NavItem('/profile', 'Profile'),
];

class _BottomNav extends StatelessWidget {
  final String currentPath;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentPath, required this.onTap});

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
            children: List.generate(_kNavItems.length, (index) {
              final it = _kNavItems[index];
              final active = currentPath == it.path;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(index),
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
                              color: active
                                  ? AppColors.sage
                                  : AppColors.foreground,
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
            }),
          ),
        ),
      ),
    );
  }
}
