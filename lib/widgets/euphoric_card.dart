import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class EuphoricCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final List<BoxShadow>? boxShadow;
  final double? elevation;

  const EuphoricCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 14,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.boxShadow,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.card.withOpacity(0.95),
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor != null 
            ? Border.all(color: borderColor!, width: borderWidth ?? 1)
            : null,
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class EuphoricCardWithBorder extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color borderColor;
  final double borderWidth;
  final Color? backgroundColor;

  const EuphoricCardWithBorder({
    super.key,
    required this.child,
    required this.borderColor,
    this.padding,
    this.borderRadius = 20,
    this.borderWidth = 2,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return EuphoricCard(
      padding: padding,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor ?? const Color(0xFFF8F9FB),
      borderColor: borderColor,
      borderWidth: borderWidth,
      boxShadow: [
        BoxShadow(
          color: AppColors.cardShadow,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      child: child,
    );
  }
} 