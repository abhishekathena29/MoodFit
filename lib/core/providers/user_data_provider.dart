import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/fashion_profile.dart';
import '../models/log_entry.dart';

class AddLogResult {
  final int xpGain;
  final int streak;
  final bool leveledUp;

  const AddLogResult({required this.xpGain, required this.streak, required this.leveledUp});
}

final DateFormat _ymd = DateFormat('yyyy-MM-dd');

String _todayKey() => _ymd.format(DateTime.now());

/// Firestore-backed user state — profile (name, email, fashion profile,
/// onboarding status, streak, xp, daily AI nudge) on `users/{uid}` and
/// outfit logs on `users/{uid}/logs`, all under the signed-in Firebase
/// user. Shared across Home, Log, Insights, Profile
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
  String email = '';
  DateTime? createdAt;
  FashionProfile fashionProfile = const FashionProfile();

  /// Today's AI-written Home nudge, cached so it's generated once per day.
  String? nudgeDate;
  String? nudgeText;
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
      email = '';
      createdAt = null;
      fashionProfile = const FashionProfile();
      nudgeDate = null;
      nudgeText = null;
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
      name = data?['name'] as String? ?? _auth.currentUser?.displayName ?? '';
      email = data?['email'] as String? ?? _auth.currentUser?.email ?? '';
      createdAt = (data?['createdAt'] as Timestamp?)?.toDate() ?? _auth.currentUser?.metadata.creationTime;
      fashionProfile = FashionProfile.fromJson(data?['fashionProfile'] as Map<String, dynamic>?);
      final nudge = data?['nudge'] as Map<String, dynamic>?;
      nudgeDate = nudge?['date'] as String?;
      nudgeText = nudge?['text'] as String?;
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

  /// Called right after sign-up, before onboarding — creates the profile
  /// doc with the name typed on the sign-up form. Uses the Auth user
  /// directly since this can run before [_onAuthChanged] has fired.
  Future<void> createProfile({required String name}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final clean = name.trim();
    await user.updateDisplayName(clean);
    await _db.collection('users').doc(user.uid).set({
      'name': clean,
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
      'consent': false,
      'streak': 0,
      'xp': 0,
      'lastLogDate': null,
    }, SetOptions(merge: true));
  }

  /// Saves the onboarding answers and lets the user into the app.
  Future<void> completeOnboarding({required String name, required FashionProfile profile}) async {
    if (_uid == null) return;
    this.name = name.trim().isEmpty ? 'Friend' : name.trim();
    fashionProfile = profile;
    consent = true;
    await _profileRef.set({
      'name': this.name,
      'consent': true,
      'fashionProfile': profile.toJson(),
      'email': _auth.currentUser?.email,
      'onboardedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    notifyListeners();
  }

  Future<void> updateName(String value) async {
    if (_uid == null || value.trim().isEmpty) return;
    name = value.trim();
    notifyListeners();
    await _auth.currentUser?.updateDisplayName(name);
    await _profileRef.set({'name': name}, SetOptions(merge: true));
  }

  Future<void> updateFashionProfile(FashionProfile profile) async {
    if (_uid == null) return;
    fashionProfile = profile;
    notifyListeners();
    await _profileRef.set({'fashionProfile': profile.toJson()}, SetOptions(merge: true));
  }

  Future<void> saveNudge(String text) async {
    if (_uid == null) return;
    nudgeDate = _todayKey();
    nudgeText = text;
    notifyListeners();
    await _profileRef.set({
      'nudge': {'date': nudgeDate, 'text': text},
    }, SetOptions(merge: true));
  }

  bool get hasNudgeForToday => nudgeDate == _todayKey() && (nudgeText?.isNotEmpty ?? false);

  Future<AddLogResult> addLog(
    String mood, {
    String? palette,
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
    final chat = await _profileRef.collection('muse_messages').get();
    for (final doc in chat.docs) {
      batch.delete(doc.reference);
    }
    batch.set(_profileRef, {
      'consent': false,
      'streak': 0,
      'xp': 0,
      'lastLogDate': null,
      'nudge': FieldValue.delete(),
    }, SetOptions(merge: true));
    await batch.commit();

    consent = false;
    streak = 0;
    xp = 0;
    lastLogDate = null;
    nudgeDate = null;
    nudgeText = null;
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
