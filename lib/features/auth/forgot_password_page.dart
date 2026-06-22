import 'package:flutter/material.dart';

import 'data/auth_api_client.dart';
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _apiClient = AuthApiClient();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || _emailController.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final result = await _apiClient.forgotPassword(
        _emailController.text.trim(),
      );
      if (!mounted) return;
      final debugLink = result.debugResetLink;
      final token = debugLink == null
          ? null
          : Uri.tryParse(debugLink)?.queryParameters['resetToken'];
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.mark_email_read_rounded),
          title: const Text('Demande prise en compte'),
          content: Text(result.detail),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted || token == null || token.isEmpty) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResetPasswordPage(token: token),
        ),
      );
    } on AuthApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublie')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 30),
          const Icon(Icons.email_outlined, size: 64),
          const SizedBox(height: 20),
          const Text(
            'Saisis ton adresse e-mail pour recevoir un lien de '
            'reinitialisation.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Adresse e-mail',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(_isSubmitting ? 'Envoi...' : 'Envoyer le lien'),
          ),
        ],
      ),
    );
  }
}
