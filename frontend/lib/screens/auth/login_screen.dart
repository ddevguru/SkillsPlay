import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/clay/clay_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authStateProvider.notifier).login(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = 'Invalid email or password');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClayBox(
                      color: SkillPlayTheme.primary.withValues(alpha: 0.12),
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [SkillPlayTheme.primary, SkillPlayTheme.accent]),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Icon(Icons.sports_esports, size: 40, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text('SkillPlay', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                          Text('Learn. Play. Level Up.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: SkillPlayTheme.clayTextMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ClayBox(
                      inset: true,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordCtrl,
                            decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                            obscureText: true,
                            validator: (v) => v != null && v.length >= 8 ? null : 'Min 8 characters',
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B))),
                          ],
                          const SizedBox(height: 24),
                          ClayButton(label: 'Sign In', icon: Icons.login, loading: _loading, onPressed: _loading ? null : _login),
                          const SizedBox(height: 12),
                          TextButton(onPressed: () => context.go('/signup'), child: const Text('Create an account')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Demo: demo@skillplay.dev / Demo1234!', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SkillPlayTheme.clayTextMuted), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
