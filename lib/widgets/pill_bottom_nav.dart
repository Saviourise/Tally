import 'package:flutter/material.dart';

import '../theme/tally_colors.dart';

class NavItem {
  final IconData icon;
  final String label;
  const NavItem(this.icon, this.label);
}

class PillBottomNav extends StatelessWidget {
  const PillBottomNav({
    super.key,
    required this.items,
    required this.current,
    required this.onTap,
    required this.onCenterTap,
    this.centerIcon = Icons.play_arrow_rounded,
  });

  final List<NavItem> items; // 4 items, center slot is the FAB
  final int current;
  final ValueChanged<int> onTap;
  final VoidCallback onCenterTap;
  final IconData centerIcon;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = Theme.of(context).colorScheme.onSurface;
    final inactive = ink.withValues(alpha: 0.45);

    // Glass fill, faked with a top-to-bottom sheen gradient instead of a live
    // BackdropFilter blur. A real-time blur samples whatever is painted behind
    // it, so during a page cross-fade it re-rendered the outgoing page as a
    // blurred grid flash. A gradient reads as frosted glass, costs nothing, and
    // never samples the backdrop — so screen transitions stay clean. Light mode:
    // a near-opaque white pill brighter than the warm cream bg. Dark mode: a
    // lifted warm surface noticeably lighter than the near-black bg.
    final glassGradient = dark
        ? [
            const Color(0xFF463729).withValues(alpha: 0.94),
            const Color(0xFF362A1F).withValues(alpha: 0.88),
          ]
        : [
            Colors.white.withValues(alpha: 0.96),
            Colors.white.withValues(alpha: 0.82),
          ];
    final borderColor = dark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.9);

    // Neumorphic dual shadows: a light highlight toward the top-left light
    // source and a matching dark shadow to the bottom-right. Keeping them
    // symmetric (equal, opposite offsets) and soft is what sells the "extruded
    // from the surface" neumorphic look.
    final highlight = dark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 1.0);
    final shadow = dark
        ? Colors.black.withValues(alpha: 0.70)
        : TallyColors.ink.withValues(alpha: 0.28);

    const radius = 36.0;

    Widget tab(int i) {
      final item = items[i];
      final active = current == i;
      return Expanded(
        child: InkResponse(
          onTap: () => onTap(i),
          radius: 28,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Icon(
                item.icon,
                key: ValueKey('${item.label}-$active'),
                color: active ? TallyColors.honey : inactive,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: glassGradient,
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              // Dark shadow, bottom-right.
              BoxShadow(
                color: shadow,
                offset: const Offset(9, 9),
                blurRadius: 22,
              ),
              // Light highlight, top-left (mirrors the dark one).
              BoxShadow(
                color: highlight,
                offset: const Offset(-9, -9),
                blurRadius: 22,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Material(
              color: Colors.transparent,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  tab(0),
                  tab(1),
                  // center FAB
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: onCenterTap,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: TallyColors.honey,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: TallyColors.honey.withValues(alpha: 0.5),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(centerIcon,
                            color: TallyColors.ink, size: 26),
                      ),
                    ),
                  ),
                  tab(2),
                  tab(3),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
