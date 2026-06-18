import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_session_provider.dart';
import 'data/auth_api_client.dart';
import 'data/auth_session_store.dart';
import 'komi_brand.dart';
import 'login_page.dart';
import 'social_auth_buttons.dart';
import 'welcome_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiClient = AuthApiClient();
  final _sessionStore = const AuthSessionStore();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final fullName = [
      _firstNameController.text.trim(),
      _lastNameController.text.trim(),
    ].where((part) => part.isNotEmpty).join(' ');

    setState(() => _isSubmitting = true);
    try {
      final session = await _apiClient.register(
        name: fullName,
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await _sessionStore.save(session);

      if (!mounted) return;
      await context.read<UserSessionProvider>().setUser(session.user);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const WelcomePage()),
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
          'Inscription avec $provider bientot disponible.',
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
                        const _SignUpHeader(),
                        SizedBox(height: height * 0.105),
                        Center(
                          child: Column(
                            children: [
                              const KomiLogo(size: 70),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: formWidth,
                                child: Column(
                                  children: [
                                    _SignUpTextField(
                                      controller: _firstNameController,
                                      hintText: 'Prenom',
                                      textInputAction: TextInputAction.next,
                                    ),
                                    const SizedBox(height: 10),
                                    _SignUpTextField(
                                      controller: _lastNameController,
                                      hintText: 'Nom',
                                      textInputAction: TextInputAction.next,
                                    ),
                                    const SizedBox(height: 10),
                                    _SignUpTextField(
                                      controller: _emailController,
                                      hintText: 'Adresse mail',
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                    ),
                                    const SizedBox(height: 10),
                                    _SignUpTextField(
                                      controller: _passwordController,
                                      hintText: 'Mot de passe',
                                      obscureText: true,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _submit(),
                                    ),
                                    const SizedBox(height: 12),
                                    _SignUpMainButton(
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
                      child: _LoginFooter(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const LoginPage(),
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

class _SignUpHeader extends StatelessWidget {
  const _SignUpHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Creer un compte',
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
          'Pour commencer a utiliser l\'application,\nveuillez creer un compte',
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

class _SignUpTextField extends StatefulWidget {
  const _SignUpTextField({
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
  State<_SignUpTextField> createState() => _SignUpTextFieldState();
}

class _SignUpTextFieldState extends State<_SignUpTextField> {
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

class _SignUpMainButton extends StatelessWidget {
  const _SignUpMainButton({required this.onPressed, required this.isLoading});

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
            : const Text('S\'inscrire'),
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

class _LoginFooter extends StatelessWidget {
  const _LoginFooter({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Flexible(
          child: Text(
            'Vous avez deja un compte ?',
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
          child: const Text('Se connecter'),
        ),
      ],
    );
  }
}
