import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/log_entry.dart';

class AddLogResult {
  final int xpGain;
  final int streak;
  final bool leveledUp;

  const AddLogResult({required this.xpGain, required this.streak, required this.leveledUp});
}

final DateFormat _ymd = DateFormat('yyyy-MM-dd');

String _todayKey() => _ymd.format(DateTime.now());

/// Firestore-backed replacement for the old local-only store — same shape
/// (onboarding status, name, streak, xp, logs) but reads/writes
/// `users/{uid}` + `users/{uid}/logs` under the signed-in Firebase user
/// instead of SharedPreferences. Shared across Home, Log, Insights, Profile
/// and Onboarding, which is why it lives in core/ rather than one feature.
class UserDataProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _logsSub;

  String? _uid;
  bool hydrated = false;
  bool consent = false;
  String name = '';
  int streak = 0;
  String? lastLogDate;
  int xp = 0;
  List<LogEntry> logs = [];

  UserDataProvider({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance {
    _authSub = _auth.authStateChanges().listen(_onAuthChanged);
    _onAuthChanged(_auth.currentUser);
  }

  DocumentReference<Map<String, dynamic>> get _profileRef => _db.collection('users').doc(_uid);
  CollectionReference<Map<String, dynamic>> get _logsRef => _profileRef.collection('logs');

  void _onAuthChanged(User? user) {
    _profileSub?.cancel();
    _logsSub?.cancel();
    _uid = user?.uid;

    if (_uid == null) {
      hydrated = true;
      consent = false;
      name = '';
      streak = 0;
      xp = 0;
      lastLogDate = null;
      logs = [];
      notifyListeners();
      return;
    }

    hydrated = false;
    notifyListeners();

    _profileSub = _profileRef.snapshots().listen((snap) {
      final data = snap.data();
      consent = data?['consent'] as bool? ?? false;
      name = data?['name'] as String? ?? '';
      streak = data?['streak'] as int? ?? 0;
      xp = data?['xp'] as int? ?? 0;
      lastLogDate = data?['lastLogDate'] as String?;
      hydrated = true;
      notifyListeners();
    });

    _logsSub = _logsRef.orderBy('date', descending: true).limit(60).snapshots().listen((snap) {
      logs = snap.docs.map((d) => LogEntry.fromJson({...d.data(), 'id': d.id})).toList();
      notifyListeners();
    });
  }

  /// Mirrors `update()` in the original store — used by onboarding to save
  /// the user's name once they're through the welcome step.
  Future<void> completeOnboarding({required String name}) async {
    if (_uid == null) return;
    this.name = name.trim().isEmpty ? 'Friend' : name.trim();
    consent = true;
    await _profileRef.set({
      'name': this.name,
      'consent': true,
      'streak': streak,
      'xp': xp,
      'lastLogDate': lastLogDate,
      'email': _auth.currentUser?.email,
    }, SetOptions(merge: true));
    notifyListeners();
  }

  Future<AddLogResult> addLog(
    String mood, {
    String palette = 'sage',
    String? note,
    String? style,
    String? aesthetic,
  }) async {
    if (_uid == null) {
      return const AddLogResult(xpGain: 0, streak: 0, leveledUp: false);
    }
    final today = _todayKey();
    final already = logs.any((l) => l.date == today);

    int newStreak = streak;
    int xpGain = 15;
    if (!already) {
      final yesterday = _ymd.format(DateTime.now().subtract(const Duration(days: 1)));
      newStreak = (lastLogDate == yesterday || lastLogDate == today) ? streak + 1 : 1;
      xpGain = 25;
    }
    final oldXp = xp;
    final newXp = oldXp + xpGain;

    final entry = LogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: today,
      mood: mood,
      palette: palette,
      note: (note == null || note.isEmpty) ? null : note,
      style: style,
      aesthetic: aesthetic,
    );

    final payload = entry.toJson()..remove('id');
    await _logsRef.doc(entry.id).set(payload);
    await _profileRef.set({
      'streak': newStreak,
      'xp': newXp,
      'lastLogDate': today,
    }, SetOptions(merge: true));

    // Optimistic local update — the snapshot listener above will reconcile
    // with the server copy moments later.
    streak = newStreak;
    xp = newXp;
    lastLogDate = today;
    logs = [entry, ...logs.where((l) => l.id != entry.id)];
    notifyListeners();

    return AddLogResult(xpGain: xpGain, streak: newStreak, leveledUp: (oldXp ~/ 100) != (newXp ~/ 100));
  }

  /// Mirrors the "Reset all data" action on Profile — clears stats and every
  /// log, but leaves the Firebase Auth account itself intact.
  Future<void> reset() async {
    if (_uid == null) return;
    final batch = _db.batch();
    final existing = await _logsRef.get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    batch.set(_profileRef, {
      'consent': false,
      'streak': 0,
      'xp': 0,
      'lastLogDate': null,
    }, SetOptions(merge: true));
    await batch.commit();

    consent = false;
    streak = 0;
    xp = 0;
    lastLogDate = null;
    logs = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    _logsSub?.cancel();
    super.dispose();
  }
}
