import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.avatarDataUrl,
    required this.radius,
    this.initial,
    this.backgroundColor = const Color(0xFF202020),
  });

  final String avatarDataUrl;
  final double radius;
  final String? initial;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeAvatar();
    if (bytes != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFEFEFEF),
        backgroundImage: MemoryImage(bytes),
      );
    }

    final fallbackInitial = initial?.trim();
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: fallbackInitial != null && fallbackInitial.isNotEmpty
          ? Text(
              fallbackInitial.characters.first.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: radius,
                fontWeight: FontWeight.w800,
              ),
            )
          : Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: radius * 1.1,
            ),
    );
  }

  Uint8List? _decodeAvatar() {
    const marker = 'base64,';
    final markerIndex = avatarDataUrl.indexOf(marker);
    final raw = markerIndex >= 0
        ? avatarDataUrl.substring(markerIndex + marker.length)
        : avatarDataUrl;
    if (raw.trim().isEmpty) return null;

    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }
}
