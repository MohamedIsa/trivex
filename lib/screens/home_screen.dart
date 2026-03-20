import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/elo_history_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/elo_sparkline.dart';

/// Home screen — ELO display, sparkline & Play button (UI-001).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  // ── Entry animation controllers ───────────────────────────────────────────

  late final AnimationController _wordmarkCtrl;
  late final AnimationController _eloCtrl;
  late final AnimationController _buttonCtrl;

  // Wordmark — slide from left + fade.
  late final Animation<double> _wordmarkFade;
  late final Animation<Offset> _wordmarkSlide;

  // ELO group (number + label + sparkline) — slide from below + fade.
  late final Animation<double> _eloFade;
  late final Animation<Offset> _eloSlide;

  // Play button — slide from below + fade.
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();

    // Wordmark — 0 ms delay, 500 ms duration.
    _wordmarkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _wordmarkFade = CurvedAnimation(
      parent: _wordmarkCtrl,
      curve: Curves.easeOut,
    );
    _wordmarkSlide = Tween<Offset>(
      begin: const Offset(-0.15, 0),
      end: Offset.zero,
    ).animate(_wordmarkFade);

    // ELO group — 200 ms delay, 500 ms duration.
    _eloCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _eloFade = CurvedAnimation(
      parent: _eloCtrl,
      curve: Curves.easeOut,
    );
    _eloSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(_eloFade);

    // Play button — 600 ms delay, 500 ms duration.
    _buttonCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _buttonFade = CurvedAnimation(
      parent: _buttonCtrl,
      curve: Curves.easeOut,
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(_buttonFade);

    // Fire staggered.
    _wordmarkCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _eloCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _buttonCtrl.forward();
    });
  }

  @override
  void dispose() {
    _wordmarkCtrl.dispose();
    _eloCtrl.dispose();
    _buttonCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(eloHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: historyAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.teal),
          ),
          error: (_, __) => const Center(
            child: CircularProgressIndicator(color: AppColors.teal),
          ),
          data: (history) => _buildContent(
            history.isEmpty ? 1000 : history.last.rating,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(int rating) {

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Wordmark ──────────────────────────────────────────────────
          FadeTransition(
            opacity: _wordmarkFade,
            child: SlideTransition(
              position: _wordmarkSlide,
              child: RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Triv',
                      style: TextStyle(
                        color: AppColors.foreground,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: 'ex',
                      style: TextStyle(
                        color: AppColors.teal,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // ── ELO group ─────────────────────────────────────────────────
          FadeTransition(
            opacity: _eloFade,
            child: SlideTransition(
              position: _eloSlide,
              child: Column(
                children: [
                  // ELO number
                  Center(
                    child: Text(
                      '$rating',
                      style: const TextStyle(
                        color: AppColors.foreground,
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // "Your Rating" label
                  const Center(
                    child: Text(
                      'Your Rating',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sparkline
                  const SizedBox(
                    height: 96,
                    width: double.infinity,
                    child: EloSparkline(),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // ── Play button ───────────────────────────────────────────────
          FadeTransition(
            opacity: _buttonFade,
            child: SlideTransition(
              position: _buttonSlide,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/topic'),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Play',
                    style: TextStyle(
                      color: AppColors.foreground,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
