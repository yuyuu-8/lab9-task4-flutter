import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController(text: 'user@example.com');
  final _password = TextEditingController();
  String? _errorKey;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _login() {
    final error = ref.read(authProvider.notifier).login(_email.text, _password.text);
    setState(() => _errorKey = error);
    // При успехе (_errorKey == null) GoRouter сам перенаправит на главный экран.
  }

  String? _errorText(AppLocalizations l) {
    switch (_errorKey) {
      case 'invalidEmail':
        return l.invalidEmail;
      case 'shortPassword':
        return l.shortPassword;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.loginTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: l.email),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  onSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText: l.password,
                    errorText: _errorText(l),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: _login, child: Text(l.loginButton)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
