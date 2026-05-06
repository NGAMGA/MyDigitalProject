import 'package:flutter/material.dart';

import 'komi_brand.dart';
import 'login_page.dart';
import 'welcome_page.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                                    const _SignUpTextField(
                                      hintText: 'Prenom',
                                      textInputAction: TextInputAction.next,
                                    ),
                                    const SizedBox(height: 10),
                                    const _SignUpTextField(
                                      hintText: 'Nom',
                                      textInputAction: TextInputAction.next,
                                    ),
                                    const SizedBox(height: 10),
                                    const _SignUpTextField(
                                      hintText: 'Adresse mail',
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                    ),
                                    const SizedBox(height: 10),
                                    _SignUpTextField(
                                      hintText: 'Mot de passe',
                                      obscureText: true,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _goToWelcome(context),
                                    ),
                                    const SizedBox(height: 12),
                                    _SignUpMainButton(
                                      onPressed: () => _goToWelcome(context),
                                    ),
                                    const SizedBox(height: 18),
                                    const _OrDivider(),
                                    const SizedBox(height: 16),
                                    _SocialButton(
                                      leading: const Icon(
                                        Icons.apple_rounded,
                                        size: 18,
                                      ),
                                      label: 'Continuer avec apple',
                                      onPressed: () {},
                                    ),
                                    const SizedBox(height: 10),
                                    _SocialButton(
                                      leading: const _GoogleLetter(),
                                      label: 'Continuer avec google',
                                      onPressed: () {},
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
                  child: _LoginFooter(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                          builder: (_) => const LoginPage()),
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

  static void _goToWelcome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const WelcomePage()),
      (_) => false,
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
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

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
  const _SignUpMainButton({required this.onPressed});

  final VoidCallback onPressed;

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
        onPressed: onPressed,
        child: const Text('S\'inscrire'),
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

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.leading,
    required this.label,
    required this.onPressed,
  });

  final Widget leading;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      height: 36,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF222222),
          side: const BorderSide(color: Color(0xFF8A8A8A), width: 1.25),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          shape: const StadiumBorder(),
        ),
        onPressed: onPressed,
        icon: leading,
        label: Text(label),
      ),
    );
  }
}

class _GoogleLetter extends StatelessWidget {
  const _GoogleLetter();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      child: Text(
        'G',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.black,
          fontSize: 17,
          height: 1,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.2,
        ),
      ),
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
