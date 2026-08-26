import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

/// Email/password sign-in backed by Firebase Auth ([AuthProvider]). A
/// successful sign-up still lands on Onboarding — the Firestore profile
/// (name, consent) doesn't exist yet, so the router sends new accounts
/// there automatically.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool signUp = true;
  bool _submitting = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (!email.contains('@') || email.length < 5) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });

    final auth = context.read<AuthProvider>();
    final ok = signUp
        ? await auth.signUp(email: email, password: password)
        : await auth.signIn(email: email, password: password);

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = ok ? null : auth.errorMessage;
    });
    if (ok) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: FadeSlideIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(signUp ? 'CREATE ACCOUNT' : 'SIGN IN', style: AppTheme.mono()),
                const SizedBox(height: 4),
                Text(
                  signUp ? 'Start your MoodFit journal' : 'Welcome back',
                  style: AppTheme.sans(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8),
                ),
                const SizedBox(height: 32),
                Text('EMAIL', style: AppTheme.mono()),
                const SizedBox(height: 8),
                _AuthField(controller: _emailController, hint: 'you@example.com', keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 20),
                Text('PASSWORD', style: AppTheme.mono()),
                const SizedBox(height: 8),
                _AuthField(controller: _passwordController, hint: '••••••••', obscure: true),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: AppTheme.sans(fontSize: 12, color: AppColors.amberDeep),
                  ),
                ],
                const SizedBox(height: 32),
                PrimaryButton(
                  label: _submitting ? 'Please wait…' : (signUp ? 'Create account' : 'Sign in'),
                  onTap: _submitting ? null : _submit,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      signUp = !signUp;
                      _error = null;
                    }),
                    child: Text(
                      signUp ? 'Already have an account? Sign in' : "New here? Create an account",
                      style: AppTheme.sans(fontSize: 12, color: AppColors.foreground.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;

  const _AuthField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: AppTheme.sans(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTheme.sans(fontSize: 14, color: AppColors.foreground.withValues(alpha: 0.35)),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
