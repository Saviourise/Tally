import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/tally_colors.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.radius = 28,
    this.padding = const EdgeInsets.all(20),
    this.blur = 24,
    this.height,
    this.width,
    this.onTap,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final double blur;
  final double? height;
  final double? width;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = color ?? TallyColors.glassFill(dark);
    final border = borderColor ?? TallyColors.glassBorder(dark);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Material(
          color: fill,
          child: InkWell(
            onTap: onTap,
            splashColor: TallyColors.honey.withValues(alpha: 0.12),
            highlightColor: Colors.transparent,
            child: Container(
              height: height,
              width: width,
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: border, width: 1),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
