import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/providers/user_data_provider.dart';
import '../../../core/services/ai_context.dart';
import '../../../core/services/ai_service.dart';
import 'muse_reply.dart';

class MuseMessage {
  final String id;
  final String text;
  final bool isUser;

  const MuseMessage({required this.id, required this.text, required this.isUser});
}

/// Muse chat state. Messages persist to `users/{uid}/muse_messages`, and
/// replies come from Groq (via [AiService]) grounded in the outfit-mood
/// research and the user's own profile + logs — falling back to the local
/// [MuseReply] rules when the AI is unavailable.
class MuseProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  String? _uid;

  List<MuseMessage> messages = [];
  bool typing = false;

  static const _persona = '''
You are Muse, the in-app stylist for MoodFit — an app where people log their outfits and moods to notice how what they wear shapes how they feel.

How to respond:
- Fashion is always the door in: answer outfit, color, palette and aesthetic questions directly and specifically, using the research and this user's own logs and taste below.
- When their logs show a pattern (e.g. a palette that lines up with good days), mention it — but call it a pattern, never a rule.
- Every few turns, or when they sound low, gently check in on how they're actually feeling. Never lead with mental health and never diagnose.
- If they mention self-harm or being in danger, respond with care and encourage them to contact local emergency services or a crisis line right away, and point them to the Support section on their Profile tab.
- Keep replies warm, short (under 120 words), plain text, no markdown headings. Use their first name occasionally.''';

  MuseProvider({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance {
    _authSub = _auth.authStateChanges().listen(_onAuthChanged);
    _onAuthChanged(_auth.currentUser);
  }

  CollectionReference<Map<String, dynamic>> get _ref =>
      _db.collection('users').doc(_uid).collection('muse_messages');

  void _onAuthChanged(User? user) {
    if (user?.uid == _uid && _sub != null) return;
    _sub?.cancel();
    _sub = null;
    _uid = user?.uid;
    messages = [];
    typing = false;
    notifyListeners();
    if (_uid == null) return;

    // Ordered by a client timestamp: serverTimestamp is null on pending
    // writes, which would make a just-sent message jump around.
    _sub = _ref.orderBy('clientTime', descending: true).limit(100).snapshots().listen((snap) {
      messages = snap.docs.reversed
          .map((d) => MuseMessage(
                id: d.id,
                text: d.data()['text'] as String? ?? '',
                isUser: d.data()['role'] == 'user',
              ))
          .toList();
      notifyListeners();
    });
  }

  Future<void> _write(String text, {required String role, String? source}) {
    return _ref.add({
      'text': text,
      'role': role,
      'source': ?source,
      'clientTime': DateTime.now().millisecondsSinceEpoch,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> send(String text, UserDataProvider store) async {
    final clean = text.trim();
    if (clean.isEmpty || _uid == null || typing) return;

    typing = true;
    notifyListeners();
    await _write(clean, role: 'user');

    final history = messages.length > 12 ? messages.sublist(messages.length - 12) : messages;
    final ai = await AiService.instance.chat([
      AiMessage('system', '$_persona\n\n${AiContext.research()}\n${AiContext.user(store)}'),
      ...history.map((m) => AiMessage(m.isUser ? 'user' : 'assistant', m.text)),
      // The snapshot may not include the just-written message yet.
      if (history.isEmpty || history.last.text != clean || !history.last.isUser) AiMessage('user', clean),
    ]);

    final userTurns = messages.where((m) => m.isUser).length;
    final reply = ai ?? MuseReply.reply(clean, turnCount: userTurns);
    await _write(reply, role: 'assistant', source: ai == null ? 'local' : 'groq');

    typing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}
