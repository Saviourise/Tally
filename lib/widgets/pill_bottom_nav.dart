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
    final bg = dark ? TallyColors.cream : TallyColors.ink;
    final fg = dark ? TallyColors.ink : TallyColors.cream;
    final inactive = fg.withValues(alpha: 0.5);

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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: Material(
            color: bg,
            child: SizedBox(
              height: 68,
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
                        child: Icon(centerIcon, color: TallyColors.ink, size: 26),
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
