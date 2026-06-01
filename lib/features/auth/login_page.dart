import 'package:flutter/material.dart';

import '../../app/komi_app.dart';
import 'data/auth_api_client.dart';
import 'data/auth_session_store.dart';
import 'komi_brand.dart';
import 'signup_page.dart';
import 'social_auth_buttons.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiClient = AuthApiClient();
  final _sessionStore = const AuthSessionStore();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final session = await _apiClient.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await _sessionStore.save(session);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
        (_) => false,
      );
    } on AuthApiException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _handleSocialAuth(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Connexion avec $provider bientot disponible.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final horizontalPadding = (width * 0.055).clamp(18.0, 26.0);
            final availableWidth = width - horizontalPadding * 2;
            final formWidth = availableWidth > 360 ? 360.0 : availableWidth;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 28,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: height - 56),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 34),
                        const _LoginHeader(),
                        SizedBox(height: height * 0.105),
                        Center(
                          child: Column(
                            children: [
                              const KomiLogo(size: 70),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: formWidth,
                                child: Column(
                                  children: [
                                    _LoginTextField(
                                      controller: _emailController,
                                      hintText: 'Adresse mail',
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                    ),
                                    const SizedBox(height: 10),
                                    _LoginTextField(
                                      controller: _passwordController,
                                      hintText: 'Mot de passe',
                                      obscureText: true,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _submit(),
                                    ),
                                    const SizedBox(height: 12),
                                    _LoginMainButton(
                                      isLoading: _isSubmitting,
                                      onPressed: _submit,
                                    ),
                                    const SizedBox(height: 18),
                                    const _OrDivider(),
                                    const SizedBox(height: 16),
                                    SocialAuthButtons(
                                      onGooglePressed: () =>
                                          _handleSocialAuth('Google'),
                                      onApplePressed: () =>
                                          _handleSocialAuth('Apple'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  bottom: 18,
                  child: IgnorePointer(
                    ignoring: isKeyboardOpen,
                    child: AnimatedOpacity(
                      opacity: isKeyboardOpen ? 0 : 1,
                      duration: const Duration(milliseconds: 140),
                      child: _CreateAccountFooter(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const SignUpPage(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Se connecter',
          style: TextStyle(
            color: Color(0xFF202020),
            fontSize: 21,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Si vous avez deja un compte, veuillez\nsimplement vous connecter',
          style: TextStyle(
            color: Color(0xFF313131),
            fontSize: 10.5,
            height: 1.12,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _LoginTextField extends StatefulWidget {
  const _LoginTextField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_LoginTextField> createState() => _LoginTextFieldState();
}

class _LoginTextFieldState extends State<_LoginTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.normal,
        ),
        decoration: InputDecoration(
          hintText: _focusNode.hasFocus ? null : widget.hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF565656),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.normal,
          ),
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF6C6C6C), width: 1.4),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: komiGreen, width: 1.6),
          ),
        ),
      ),
    );
  }
}

class _LoginMainButton extends StatelessWidget {
  const _LoginMainButton({required this.onPressed, required this.isLoading});

  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 36,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: komiGreen,
          foregroundColor: komiLime,
          padding: EdgeInsets.zero,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          shape: const StadiumBorder(),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Connexion'),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFB7B7B7), thickness: 1.2)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ou',
            style: TextStyle(
              color: Color(0xFF4A4A4A),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFB7B7B7), thickness: 1.2)),
      ],
    );
  }
}

class _CreateAccountFooter extends StatelessWidget {
  const _CreateAccountFooter({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Flexible(
          child: Text(
            'Vous n\'avez pas encore de compte ?',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFF303030),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF86C742),
            padding: const EdgeInsets.only(left: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle:
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
          onPressed: onPressed,
          child: const Text('Creer un compte'),
        ),
      ],
    );
  }
}
