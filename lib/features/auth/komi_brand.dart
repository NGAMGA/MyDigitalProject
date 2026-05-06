import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const komiGreen = Color(0xFF062F1A);
const komiLime = Color(0xFFDDF577);
const komiLogoPath = 'assets/images/komi-logo-dark.svg';
const komiBowlPath = 'assets/images/komi-bowl.png';
const komiHeroLogoSize = 132.0;
const komiLogoHeroTag = 'komi-logo-hero';

class KomiLogo extends StatelessWidget {
  const KomiLogo({super.key, this.size = 140});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      komiLogoPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
