import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/providers/user_data_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/muse/providers/muse_provider.dart';
import 'firebase_options.dart';

/// MoodFit — wardrobe intelligence for well-being.
///
/// Flutter port of the TanStack Start web app in src/routes/*.tsx, extended
/// with Firebase Auth + Firestore, a Muse chat tab and richer per-log
/// detail. Code is organized feature-first: each feature under lib/features
/// owns its screens (and providers, where it talks to a backend), while
/// lib/core holds what's shared across all of them (theme, models, widgets,
/// router, and the Firestore-backed UserDataProvider).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MoodFitApp());
}

class MoodFitApp extends StatelessWidget {
  const MoodFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserDataProvider()),
        ChangeNotifierProvider(create: (_) => MuseProvider()),
      ],
      child: Builder(
        builder: (context) {
          final auth = context.watch<AuthProvider>();
          final data = context.watch<UserDataProvider>();
          return MaterialApp.router(
            title: 'MoodFit',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.theme,
            routerConfig: buildRouter(auth, data),
          );
        },
      ),
    );
  }
}
