import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/pill_bottom_nav.dart';
import '../analytics/analytics_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import '../timer/timer_screen.dart';
import 'home_screen.dart';

class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  int _index = 0;
  bool _timerOpen = false;

  static const _items = [
    NavItem(Icons.home_rounded, 'Home'),
    NavItem(Icons.history_rounded, 'History'),
    NavItem(Icons.insights_rounded, 'Analytics'),
    NavItem(Icons.settings_rounded, 'Settings'),
  ];

  Widget _page() {
    switch (_index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const HistoryScreen();
      case 2:
        return const AnalyticsScreen();
      case 3:
        return const SettingsScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(_index),
            child: _timerOpen ? const TimerScreen() : _page(),
          ),
        ),
      ),
      bottomNavigationBar: PillBottomNav(
        items: _items,
        current: _timerOpen ? -1 : _index,
        onTap: (i) => setState(() {
          _timerOpen = false;
          _index = i;
        }),
        onCenterTap: () => setState(() => _timerOpen = !_timerOpen),
        centerIcon: _timerOpen ? Icons.close_rounded : Icons.play_arrow_rounded,
      ),
    );
  }
}
