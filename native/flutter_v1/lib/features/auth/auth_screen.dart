import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';

enum _AuthMode { signIn, signUp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({required this.backend, super.key});

  final FameverseBackend backend;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();

  _AuthMode _mode = _AuthMode.signIn;
  bool _busy = false;
  String _message = '';

  bool get _signUp => _mode == _AuthMode.signUp;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _setMode(_AuthMode mode) {
    if (_busy || _mode == mode) return;
    setState(() {
      _mode = mode;
      _message = '';
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _message = 'Email and password are required.');
      return;
    }
    if (password.length < 6) {
      setState(() => _message = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      if (_signUp) {
        final result = await widget.backend.signUp(
          email: email,
          password: password,
          displayName: _displayNameController.text,
        );
        if (!mounted) return;
        if (!result.signedIn) {
          setState(() {
            _mode = _AuthMode.signIn;
            _message = result.message.isEmpty
                ? 'Account created. Sign in to continue.'
                : result.message;
          });
        }
      } else {
        await widget.backend.signIn(email: email, password: password);
        if (!mounted) return;
        if (widget.backend.currentIdentity == null) {
          setState(() {
            _message =
                'Sign in did not start a session. Check your email and password and try again.';
          });
        }
      }
    } catch (error) {
      if (!mounted) return;
      final friendly = _friendlyError(error);
      final alreadyRegistered = friendly.toLowerCase().contains(
        'already registered',
      );
      setState(() {
        if (_signUp && alreadyRegistered) {
          _mode = _AuthMode.signIn;
          _message = 'That email already has a Fameverse account. Sign in instead.';
        } else {
          _message = friendly;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyError(Object error) {
    final raw = error.toString().replaceFirst('AuthException(message: ', '');
    return raw.length > 180 ? 'Could not complete sign in.' : raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text(
                        'FAMEVERSE',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF21162E),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'NATIVE BETA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Container(
                    key: const Key('auth-mode-switch'),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF17121E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF33253F)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ModeButton(
                            keyValue: const Key('auth-mode-sign-in'),
                            label: 'Sign in',
                            selected: !_signUp,
                            onPressed: _busy
                                ? null
                                : () => _setMode(_AuthMode.signIn),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _ModeButton(
                            keyValue: const Key('auth-mode-sign-up'),
                            label: 'Create account',
                            selected: _signUp,
                            onPressed: _busy
                                ? null
                                : () => _setMode(_AuthMode.signUp),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 34),
                  Text(
                    'ACCOUNT',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _signUp ? 'Create your Fameverse account' : 'Welcome back',
                    key: Key(_signUp ? 'auth-sign-up-title' : 'auth-sign-in-title'),
                    style: const TextStyle(
                      fontSize: 34,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _signUp
                        ? 'Create a new Fameverse account.'
                        : 'Use your existing Fameverse email and password.',
                    style: const TextStyle(
                      color: Color(0xFFBEB5C8),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 34),
                  if (_signUp) ...[
                    _Field(
                      keyValue: const Key('auth-display-name'),
                      label: 'Display name',
                      hint: 'Your name',
                      controller: _displayNameController,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _Field(
                    keyValue: const Key('auth-email'),
                    label: 'Email',
                    hint: 'you@example.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  _Field(
                    keyValue: const Key('auth-password'),
                    label: 'Password',
                    hint: '6+ characters',
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_message.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      _message,
                      key: const Key('auth-message'),
                      style: const TextStyle(
                        color: Color(0xFFE9D7FF),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  FilledButton(
                    key: const Key('auth-primary'),
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_signUp ? 'Create account' : 'Sign in'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    key: const Key('auth-secondary'),
                    onPressed: _busy
                        ? null
                        : () => _setMode(
                            _signUp ? _AuthMode.signIn : _AuthMode.signUp,
                          ),
                    child: Text(
                      _signUp
                          ? 'Already have an account? Sign in'
                          : 'New to Fameverse? Create account',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.keyValue,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final Key keyValue;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: keyValue,
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        foregroundColor: selected ? Colors.white : const Color(0xFFBEB5C8),
        backgroundColor: selected ? const Color(0xFF5F2DA8) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.keyValue,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final Key keyValue;
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFFD6CFDE),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: keyValue,
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          autocorrect: !obscureText,
          enableSuggestions: !obscureText,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFF17121E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
