import 'package:flutter/material.dart';

class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({
    super.key,
    required this.onGooglePressed,
    required this.onApplePressed,
  });

  final VoidCallback onGooglePressed;
  final VoidCallback onApplePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SocialAuthButton(
          leading: const GoogleMark(),
          label: 'Continuer avec Google',
          onPressed: onGooglePressed,
        ),
        const SizedBox(height: 10),
        SocialAuthButton(
          leading: const Icon(Icons.apple_rounded, size: 19),
          label: 'Continuer avec Apple',
          onPressed: onApplePressed,
        ),
      ],
    );
  }
}

class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    super.key,
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
      width: 230,
      height: 38,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF222222),
          side: const BorderSide(color: Color(0xFF8A8A8A), width: 1.25),
          padding: const EdgeInsets.symmetric(horizontal: 14),
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

class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 19,
      child: Text(
        'G',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          height: 1,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.2,
        ),
      ),
    );
  }
}
