import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class BackgroundImage extends StatelessWidget {
  final Widget child;
  final String imagePath;
  final double opacity;
  final BlendMode blendMode;

  const BackgroundImage({
    super.key,
    required this.child,
    this.imagePath = 'assets/wa_background.jpeg',
    this.opacity = 0.08,
    this.blendMode = BlendMode.darken,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF000000),
            Color(0xFF1a1a1a),
            Color(0xFF2d2d2d),
          ],
        ),
      ),
      child: child,
    );
  }
} 