import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/komi_app.dart';
import 'auth_choice_page.dart';
import 'data/auth_session_store.dart';
import 'komi_brand.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  final _sessionStore = const AuthSessionStore();
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _scale = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    _navigationTimer = Timer(
      const Duration(milliseconds: 1400),
      _resolveInitialRoute,
    );
  }

  Future<void> _resolveInitialRoute() async {
    final hasValidSession = await _sessionStore.hasValidSession();
    if (!mounted) return;

    final target = hasValidSession ? const MainShell() : const AuthChoicePage();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, animation, __) => target,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: komiLogoHeroTag,
                    child: KomiLogo(size: komiHeroLogoSize),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Chargement',
                    style: TextStyle(
                      color: komiGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.4,
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
