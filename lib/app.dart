import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/home/root_shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'theme/tally_theme.dart';

class TallyApp extends ConsumerWidget {
  const TallyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp(
      title: 'Tally',
      debugShowCheckedModeBanner: false,
      theme: TallyTheme.light(),
      darkTheme: TallyTheme.dark(),
      themeMode: settings.themeMode,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const _LoadingScreen(),
      error: (e, _) => _ErrorScreen(message: e.toString()),
      data: (user) {
        if (user == null) return const SignInScreen();
        return const _OnboardingGate();
      },
    );
  }
}

class _OnboardingGate extends ConsumerWidget {
  const _OnboardingGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsStreamProvider);
    return s.when(
      loading: () => const _LoadingScreen(),
      error: (e, _) => _ErrorScreen(message: e.toString()),
      data: (settings) =>
          settings.onboarded ? const RootShell() : const OnboardingScreen(),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Something went wrong:\n$message',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
