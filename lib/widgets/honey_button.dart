import 'package:flutter/material.dart';

import '../theme/tally_colors.dart';
import '../theme/tally_typography.dart';

class HoneyButton extends StatelessWidget {
  const HoneyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = false,
    this.height = 56,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: onPressed == null
          ? TallyColors.honey.withValues(alpha: 0.4)
          : TallyColors.honey,
      borderRadius: BorderRadius.circular(height / 2),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(height / 2),
        splashColor: TallyColors.honeyDeep.withValues(alpha: 0.25),
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: compact ? 18 : 26),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: TallyType.title(Colors.white, size: compact ? 14 : 16),
              ),
            ],
          ),
        ),
      ),
    );
    return expanded
        ? SizedBox(width: double.infinity, height: height, child: button)
        : button;
  }
}

class GlassPillButton extends StatelessWidget {
  const GlassPillButton({super.key, required this.label, this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark
          ? TallyColors.glassFill(true)
          : Colors.white.withValues(alpha: 0.7),
      shape: StadiumBorder(side: BorderSide(color: TallyColors.glassBorder(dark))),
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: cs.onSurface),
                const SizedBox(width: 8),
              ],
              Text(label, style: TallyType.label(cs.onSurface, size: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
