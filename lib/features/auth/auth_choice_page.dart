import 'package:flutter/material.dart';

import 'komi_brand.dart';
import 'login_page.dart';
import 'signup_page.dart';

class AuthChoicePage extends StatefulWidget {
  const AuthChoicePage({super.key});

  @override
  State<AuthChoicePage> createState() => _AuthChoicePageState();
}

class _AuthChoicePageState extends State<AuthChoicePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _buttonsFade;
  late final Animation<Offset> _buttonsSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..forward();
    _buttonsFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.52, 1, curve: Curves.easeOut),
    );
    _buttonsSlide = Tween<Offset>(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.52, 1, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final bowlSize = (width * 0.292).clamp(78.0, 108.0);
            final buttonWidth = (width * 0.44).clamp(150.0, 176.0);
            final buttonBottom = (height * 0.08).clamp(42.0, 62.0);
            final visualHeight = height.clamp(width * 1.72, width * 2.12);
            final verticalInset = (height - visualHeight) / 2;
            final logoCenterY = verticalInset + visualHeight * 0.39;
            final orbitRadiusY = (width * 0.52).clamp(168.0, 218.0);
            final upperSideY = logoCenterY - orbitRadiusY * 0.43;
            final lowerSideY = logoCenterY + orbitRadiusY * 0.55;
            final bottomY = logoCenterY + orbitRadiusY * 0.95;
            double topFromCenter(double centerY) => centerY - bowlSize / 2;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: topFromCenter(logoCenterY - orbitRadiusY),
                  left: (width - bowlSize) / 2,
                  child: _AnimatedBowlImage(
                    controller: _controller,
                    delay: 0,
                    beginOffset: const Offset(0, -0.44),
                    size: bowlSize,
                    angle: -0.14,
                  ),
                ),
                Positioned(
                  top: topFromCenter(upperSideY),
                  left: -bowlSize * 0.44,
                  child: _AnimatedBowlImage(
                    controller: _controller,
                    delay: 0.08,
                    beginOffset: const Offset(-0.55, -0.12),
                    size: bowlSize,
                    angle: -0.30,
                  ),
                ),
                Positioned(
                  top: topFromCenter(upperSideY),
                  right: -bowlSize * 0.40,
                  child: _AnimatedBowlImage(
                    controller: _controller,
                    delay: 0.12,
                    beginOffset: const Offset(0.55, -0.12),
                    size: bowlSize,
                    angle: 0.26,
                  ),
                ),
                Positioned(
                  top: topFromCenter(lowerSideY),
                  left: -bowlSize * 0.36,
                  child: _AnimatedBowlImage(
                    controller: _controller,
                    delay: 0.18,
                    beginOffset: const Offset(-0.55, 0.08),
                    size: bowlSize,
                    angle: 0.22,
                  ),
                ),
                Positioned(
                  top: topFromCenter(lowerSideY),
                  right: -bowlSize * 0.34,
                  child: _AnimatedBowlImage(
                    controller: _controller,
                    delay: 0.22,
                    beginOffset: const Offset(0.55, 0.08),
                    size: bowlSize,
                    angle: -0.18,
                  ),
                ),
                Positioned(
                  top: topFromCenter(bottomY),
                  left: (width - bowlSize) / 2,
                  child: _AnimatedBowlImage(
                    controller: _controller,
                    delay: 0.28,
                    beginOffset: const Offset(0, 0.42),
                    size: bowlSize,
                    angle: 0.16,
                  ),
                ),
                Center(
                  child: Transform.translate(
                    offset: Offset(0, logoCenterY - height / 2),
                    child: const Hero(
                      tag: komiLogoHeroTag,
                      child: KomiLogo(size: komiHeroLogoSize),
                    ),
                  ),
                ),
                Positioned(
                  left: (width - buttonWidth) / 2,
                  bottom: buttonBottom,
                  width: buttonWidth,
                  child: FadeTransition(
                    opacity: _buttonsFade,
                    child: SlideTransition(
                      position: _buttonsSlide,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PillButton(
                            label: 'Connexion',
                            filled: true,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const LoginPage(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _PillButton(
                            label: 'Creer un compte',
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const SignUpPage(),
                              ),
                            ),
                          ),
                        ],
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

class _AnimatedBowlImage extends StatelessWidget {
  const _AnimatedBowlImage({
    required this.controller,
    required this.delay,
    required this.beginOffset,
    required this.size,
    required this.angle,
  });

  final AnimationController controller;
  final double delay;
  final Offset beginOffset;
  final double size;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(delay, (delay + 0.58).clamp(0, 1),
          curve: Curves.easeOutBack),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: beginOffset, end: Offset.zero)
            .animate(animation),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.86, end: 1).animate(animation),
          child: _BowlImage(size: size, angle: angle),
        ),
      ),
    );
  }
}

class _BowlImage extends StatelessWidget {
  const _BowlImage({required this.size, required this.angle});

  final double size;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.asset(
          komiBowlPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 30,
      child: filled
          ? FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: komiLime,
                foregroundColor: komiGreen,
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                shape: const StadiumBorder(),
              ),
              onPressed: onPressed,
              child: Text(label),
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: komiGreen,
                side: const BorderSide(color: Color(0xFF6E6E6E), width: 1.1),
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                shape: const StadiumBorder(),
              ),
              onPressed: onPressed,
              child: Text(label),
            ),
    );
  }
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AuthFormBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(height: 34),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 34,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                    color: komiGreen,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: komiGreen.withValues(alpha: 0.68),
                  ),
                ),
                const SizedBox(height: 30),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthFormBackground extends StatelessWidget {
  const _AuthFormBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF4F9E9)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -70,
            top: 70,
            child: _SoftCircle(color: komiLime, size: 180),
          ),
          const Positioned(
            left: -85,
            bottom: 120,
            child: _SoftCircle(color: Color(0xFFBBD8AF), size: 210),
          ),
          child,
        ],
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.24),
        shape: BoxShape.circle,
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
  });

  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.88),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: komiGreen,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
