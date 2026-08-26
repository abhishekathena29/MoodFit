import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Thin, reactive wrapper around [FirebaseAuth] — the only place in the app
/// that talks to the Firebase Auth SDK directly. Everything else (router,
/// screens) reads [user]/[authed] and calls [signUp]/[signIn]/[signOut].
class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth;

  User? _user;
  bool _ready = false;
  String? errorMessage;

  AuthProvider({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance {
    _user = _auth.currentUser;
    _auth.authStateChanges().listen((u) {
      _user = u;
      _ready = true;
      notifyListeners();
    });
  }

  /// True once the very first auth state has been delivered — the router
  /// waits on this before it makes any redirect decision, so a returning
  /// user is never bounced to /welcome while Firebase is still resolving.
  bool get ready => _ready;

  User? get user => _user;
  bool get authed => _user != null;
  String? get uid => _user?.uid;
  String get email => _user?.email ?? '';

  Future<bool> signUp({required String email, required String password}) => _run(() async {
        final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        _user = cred.user;
      });

  Future<bool> signIn({required String email, required String password}) => _run(() async {
        final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
        _user = cred.user;
      });

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    errorMessage = null;
    try {
      await action();
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _friendlyMessage(e);
      notifyListeners();
      return false;
    }
  }

  String _friendlyMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address doesn\'t look right.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email — try signing in.';
      case 'weak-password':
        return 'Choose a password with at least 6 characters.';
      case 'network-request-failed':
        return 'No connection — check your network and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
