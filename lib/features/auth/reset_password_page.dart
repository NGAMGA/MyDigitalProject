import 'package:flutter/material.dart';

import 'data/auth_api_client.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({
    super.key,
    required this.token,
  });

  final String token;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _apiClient = AuthApiClient();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_passwordController.text != _confirmationController.text) {
      _showMessage('Les mots de passe ne correspondent pas.');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await _apiClient.resetPassword(
        token: widget.token,
        password: _passwordController.text,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon:
              const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D52)),
          title: const Text('Mot de passe modifie'),
          content: const Text('Tu peux maintenant te connecter.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Continuer'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } on AuthApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau mot de passe')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.lock_reset_rounded, size: 64),
          const SizedBox(height: 20),
          const Text(
            'Choisis un mot de passe contenant une majuscule, une minuscule, '
            'un chiffre et un caractere special.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nouveau mot de passe',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirmationController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirmer le mot de passe',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(
              _isSubmitting ? 'Modification...' : 'Modifier le mot de passe',
            ),
          ),
        ],
      ),
    );
  }
}
