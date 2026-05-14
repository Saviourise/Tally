import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../theme/tally_colors.dart';
import '../../theme/tally_typography.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/honey_button.dart';
import '../../widgets/tally_logo.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _busy = false;
  String? _error;

  static const _genericError =
      "Couldn't sign you in. Check your connection and try again.";

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepoProvider).signInWithGoogle();
    } catch (e, st) {
      debugPrint('[Tally] sign-in failed: $e\n$st');
      if (mounted) setState(() => _error = _genericError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = Theme.of(context).colorScheme.onSurface;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final size = MediaQuery.of(context).size;
    // Headline text color: dark ink on light mode (readable over the warm
    // amber image), cream on dark mode (readable over the darkened image).
    final headlineColor = dark ? TallyColors.cream : TallyColors.ink;

    return Scaffold(
      body: Stack(
        children: [
          // Hero image fills top ~58% of the screen
          Positioned.fill(
            child: Column(
              children: [
                SizedBox(
                  height: size.height * 0.62,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/signin_warm.jpg',
                        fit: BoxFit.cover,
                      ),
                      // Bottom-to-transparent gradient so headline + scaffold blend
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.55, 1.0],
                            colors: [
                              Colors.transparent,
                              scaffoldBg.withValues(alpha: 0.0),
                              scaffoldBg,
                            ],
                          ),
                        ),
                      ),
                      // Subtle top vignette for legibility behind the wordmark
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.black.withValues(alpha: dark ? 0.35 : 0.18),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
          // Soft dot grain across the whole screen for editorial texture
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DotsPainter(color: ink.withValues(alpha: 0.05)),
              ),
            ),
          ),
          // Foreground content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Wordmark stays light (over the image top) regardless of theme
                  TallyLogo(
                    size: 44,
                    color: dark ? TallyColors.cream : Colors.white,
                  ),
                  const Spacer(),
                  // Headline near the image-to-scaffold fade — color tracks theme
                  // so it stays readable on either the warm image or cream/dark bg.
                  Padding(
                    padding: EdgeInsets.only(bottom: size.height * 0.20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Worked\ntoday?',
                          style: TallyType.headline(headlineColor, size: 56)
                              .copyWith(height: 0.95),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Your tiny ledger for the hours\nyou put in — and what they\'re worth.',
                          style: TallyType.body(
                            headlineColor.withValues(alpha: 0.8),
                            size: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Glass sign-in card
                  GlassCard(
                    radius: 28,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: TallyColors.honey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'GET STARTED',
                              style: TallyType.label(
                                ink.withValues(alpha: 0.6),
                                size: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        HoneyButton(
                          label: _busy ? 'Signing in…' : 'Continue with Google',
                          icon: Icons.account_circle_rounded,
                          expanded: true,
                          onPressed: _busy ? null : _signIn,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          _ErrorBanner(message: _error!, ink: ink),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'By continuing you agree to keep your hours honest.',
                      style: TallyType.label(
                        ink.withValues(alpha: 0.45),
                        size: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.ink});
  final String message;
  final Color ink;

  static const _red = Color(0xFFB04A2F);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _red.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: _red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TallyType.body(_red, size: 13)
                  .copyWith(height: 1.35, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    const step = 20.0;
    for (var y = 0.0; y < size.height; y += step) {
      for (var x = 0.0; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 0.6, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter old) => old.color != color;
}
