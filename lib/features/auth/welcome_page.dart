import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/komi_app.dart';
import 'komi_brand.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _navigationTimer = Timer(const Duration(milliseconds: 2300), _goToApp);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _goToApp() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, animation, __) => const MainShell(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _goToApp,
          child: Center(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final logoWidth = (width * 0.74).clamp(220.0, 330.0);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.string(
                          _komiLogoLongSvg,
                          width: logoWidth,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Bienvenue sur Komi !',
                          style: TextStyle(
                            color: Color(0xFF202020),
                            fontSize: 21,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Votre assistant nutritionnel personnel',
                          style: TextStyle(
                            color: komiGreen.withOpacity(0.78),
                            fontSize: 11.5,
                            height: 1,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.15,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _komiLogoLongSvg = r'''
<svg width="782" height="366" viewBox="0 0 782 366" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M256.23 288.15H181.77L148.49 228.19L100.67 288.15H41V96.3201H106.29V200.66L184.83 96.3201H253.68L189.87 176.32L200.1 193.55C199.43 196.74 198.94 199.9 198.65 202.97C197.51 214.76 199.03 226.15 203.15 236.83C208.61 250.97 218.14 263.3 231.47 273.5C235.73 276.75 240.4 279.77 245.35 282.46C248.7 284.3 252.22 286 255.89 287.58L256.23 288.15Z" fill="#062F1A"/>
<path d="M364.14 90.0599C362.47 93.0899 360.29 95.3599 357.62 96.7899C354.36 98.5399 350.74 98.9599 346.84 98.0299C343.91 97.3299 340.78 95.8699 337.53 93.6699C334.46 91.5999 331.23 89.3099 327.9 86.8599C324.66 84.4899 321.04 82.1999 317.14 80.0799C313.31 77.9999 309.15 76.4099 304.77 75.3699C292.6 72.4699 282.86 74.5199 274.99 81.6199C267.38 88.4799 261.33 98.9399 256.97 112.73L287.19 119.93C288.85 116.89 291.05 114.63 293.71 113.2C295.84 112.05 298.11 111.48 300.54 111.48C301.82 111.48 303.14 111.64 304.48 111.96C307.38 112.65 310.5 114.06 313.77 116.16C316.85 118.14 320.11 120.4 323.47 122.87C326.71 125.26 330.34 127.6 334.26 129.81C338.04 131.95 342.18 133.56 346.56 134.62C358.73 137.51 368.52 135.48 376.47 128.38C384.14 121.54 390.16 111.08 394.38 97.2699L364.14 90.0599Z" fill="#062F1A"/>
<path d="M704.78 148.72C691.71 148.72 680.92 145.9 672.4 140.24V288.15H737.17V140.37C728.75 145.94 717.95 148.72 704.78 148.72ZM731.17 92.96C724.63 87.67 715.84 85.02 704.78 85.02C693.72 85.02 685.15 87.67 678.52 92.96C671.89 98.24 668.58 105.48 668.58 114.7C668.58 123.92 671.89 131.15 678.52 136.43C685.15 141.72 693.9 144.36 704.78 144.36C715.66 144.36 724.63 141.72 731.17 136.43C737.72 131.15 741 123.9 741 114.7C741 105.5 737.72 98.24 731.17 92.96Z" fill="#062F1A"/>
<path d="M667.56 205.28V288.15H602.78V214.49C602.78 206.31 600.78 200 596.79 195.56C592.8 191.13 587.05 188.91 579.58 188.91C574.3 188.91 569.76 190.06 565.93 192.36C562.11 194.67 559.22 197.99 557.27 202.34C555.31 206.69 554.33 211.93 554.33 218.06V288.15H489.56V214.49C489.56 206.31 487.56 200 483.57 195.56C479.57 191.13 473.83 188.91 466.35 188.91C461.08 188.91 456.53 190.06 452.71 192.36C448.89 194.67 445.99 197.99 444.04 202.34C442.09 206.69 441.11 211.93 441.11 218.06V288.15H376.33V277.9C378.32 276.1 380.22 274.17 381.97 272.17C390.11 262.9 395.8 251.57 398.9 238.51C400.47 231.87 401.26 225.35 401.26 219C401.26 209.87 399.64 201.07 396.4 192.69C392.22 181.86 385.6 172.02 376.73 163.47C374.39 161.19 371.86 158.98 369.19 156.89L366.14 141.09H430.91L435.34 168.35C435.34 168.35 435.34 168.33 435.36 168.32C441.92 157.67 449.86 149.69 459.21 144.41C468.56 139.13 478.59 136.48 489.31 136.48C503.08 136.48 514.8 139.34 524.49 145.04C534.18 150.76 541.58 158.77 546.68 169.09C546.89 169.51 547.09 169.92 547.28 170.35C547.67 169.66 548.06 168.99 548.47 168.32C554.92 157.67 562.83 149.69 572.19 144.41C581.53 139.13 591.56 136.48 602.27 136.48C616.04 136.48 627.82 139.34 637.59 145.04C647.37 150.76 654.81 158.77 659.91 169.09C665 179.41 667.56 191.47 667.56 205.28Z" fill="#062F1A"/>
<path d="M382.41 198.09C379.8 191.3 375.96 184.97 370.98 179.19C369.52 177.49 367.97 175.85 366.31 174.25C364.05 172.06 361.59 169.94 358.98 167.95C347.51 159.17 332.88 152.62 315.49 148.47C304.88 145.95 294.78 144.68 285.3 144.68C279.24 144.68 273.43 145.2 267.9 146.24C254.17 148.81 242.59 154.31 233.48 162.58C224.48 170.71 218.34 181.53 215.21 194.73C214.43 198 213.89 201.26 213.6 204.39C213.15 209.01 213.21 213.53 213.76 217.94C214.34 222.58 215.47 227.08 217.15 231.43C221.25 242.03 228.27 251.48 238.02 259.53C238.86 260.23 239.71 260.91 240.59 261.58C244.24 264.36 248.26 266.96 252.55 269.29C261.69 274.29 272.3 278.24 284.09 281.05C301.48 285.2 317.49 285.95 331.67 283.29C345.39 280.72 356.97 275.22 366.1 266.95C367.73 265.47 369.28 263.9 370.7 262.28C372.36 260.39 373.9 258.37 375.31 256.25C379.42 250.08 382.44 242.98 384.31 235.05C387.43 221.87 386.79 209.43 382.42 198.09H382.41ZM340.24 224.53C338.36 232.43 335.11 239.03 330.56 244.17C325.75 249.61 319.7 253.25 312.59 254.98C309.63 255.7 306.43 256.07 303.09 256.07C299.08 256.07 294.8 255.54 290.36 254.49C282.4 252.59 275.7 249.38 270.44 244.95C264.78 240.2 260.95 234.21 259.08 227.15C257.33 220.53 257.41 213.08 259.31 205C261.19 197.09 264.45 190.48 269 185.35C273.82 179.9 279.93 176.27 287.14 174.56C293.84 172.98 301.26 173.15 309.2 175.04C317.33 176.98 324.08 180.21 329.28 184.63C334.85 189.39 338.61 195.36 340.46 202.38C342.22 209.02 342.15 216.47 340.24 224.53Z" fill="#062F1A"/>
</svg>

''';
