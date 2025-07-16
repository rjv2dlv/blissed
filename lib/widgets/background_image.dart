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
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(opacity),
            colorBlendMode: blendMode,
            cacheWidth: MediaQuery.of(context).size.width.toInt(),
          ),
        ),
        child,
      ],
    );
  }
} 