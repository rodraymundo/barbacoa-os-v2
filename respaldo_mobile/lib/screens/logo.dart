import 'package:flutter/material.dart';

import '../main.dart';

/// Muestra assets/logo.png si existe (declaralo en pubspec.yaml); si no, un icono.
class Logo extends StatelessWidget {
  final double size;
  const Logo({super.key, this.size = 110});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
        BoxShadow(color: Color(0x22000000), blurRadius: 14),
      ]),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/logo.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(Icons.outdoor_grill, size: size * 0.55, color: vino),
      ),
    );
  }
}
