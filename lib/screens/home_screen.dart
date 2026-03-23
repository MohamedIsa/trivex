import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../constants/animation_constants.dart';
import '../constants/layout_constants.dart';
import '../providers/elo_history_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../widgets/elo_sparkline.dart';

/// Home screen — ELO display, sparkline & Play button .
class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── Entry animation controllers ─────────────────────────────────────────

    // Wordmark — 0 ms delay, 500 ms duration.
    final wordmarkCtrl = useAnimationController(duration: kEntryDuration);
    final wordmarkFade = useMemoized(
      () => CurvedAnimation(parent: wordmarkCtrl, curve: kEntryCurve),
      [wordmarkCtrl],
    );
    final wordmarkSlide = useMemoized(
      () => Tween<Offset>(
        begin: const Offset(-0.15, 0),
        end: Offset.zero,
      ).animate(wordmarkFade),
      [wordmarkFade],
    );

    // ELO group — 200 ms delay, 500 ms duration.
    final eloCtrl = useAnimationController(duration: kEntryDuration);
    final eloFade = useMemoized(
      () => CurvedAnimation(parent: eloCtrl, curve: kEntryCurve),
      [eloCtrl],
    );
    final eloSlide = useMemoized(
      () => Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(eloFade),
      [eloFade],
    );

    // Play button — 600 ms delay, 500 ms duration.
    final buttonCtrl = useAnimationController(duration: kEntryDuration);
    final buttonFade = useMemoized(
      () => CurvedAnimation(parent: buttonCtrl, curve: kEntryCurve),
      [buttonCtrl],
    );
    final buttonSlide = useMemoized(
      () => Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(buttonFade),
      [buttonFade],
    );

    // Fire staggered entry animations on first build.
    useEffect(() {
      wordmarkCtrl.forward();
      Future.delayed(kEntryStagger * 2, () {
        if (context.mounted) eloCtrl.forward();
      });
      Future.delayed(kEntryStagger * 6, () {
        if (context.mounted) buttonCtrl.forward();
      });
      return null;
    }, const []);

    // ── Build ───────────────────────────────────────────────────────────────

    final historyAsync = ref.watch(eloHistoryProvider);

    final themeMode = ref.watch(themeModeNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            historyAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.teal),
              ),
              error: (_, _) => const Center(
                child: CircularProgressIndicator(color: AppColors.teal),
              ),
              data: (history) => _buildContent(
                context,
                rating: history.isEmpty ? 1000 : history.last.rating,
                wordmarkFade: wordmarkFade,
                wordmarkSlide: wordmarkSlide,
                eloFade: eloFade,
                eloSlide: eloSlide,
                buttonFade: buttonFade,
                buttonSlide: buttonSlide,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _ThemeToggle(mode: themeMode, ref: ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.mode, required this.ref});

  final ThemeMode mode;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final icon = switch (mode) {
      ThemeMode.system => Icons.brightness_auto,
      ThemeMode.light => Icons.light_mode,
      ThemeMode.dark => Icons.dark_mode,
    };
    final tooltip = switch (mode) {
      ThemeMode.system => 'Theme: System',
      ThemeMode.light => 'Theme: Light',
      ThemeMode.dark => 'Theme: Dark',
    };

    return Semantics(
      label: tooltip,
      button: true,
      child: IconButton(
        icon: Icon(icon, color: AppColors.muted),
        tooltip: tooltip,
        onPressed: () {
          ref.read(themeModeNotifierProvider.notifier).cycle();
        },
      ),
    );
  }
}

Widget _buildContent(
  BuildContext context, {
  required int rating,
  required Animation<double> wordmarkFade,
  required Animation<Offset> wordmarkSlide,
  required Animation<double> eloFade,
  required Animation<Offset> eloSlide,
  required Animation<double> buttonFade,
  required Animation<Offset> buttonSlide,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: kScreenPaddingH,
      vertical: kScreenPaddingH,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Wordmark ──────────────────────────────────────────────────
        FadeTransition(
          opacity: wordmarkFade,
          child: SlideTransition(
            position: wordmarkSlide,
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
          opacity: eloFade,
          child: SlideTransition(
            position: eloSlide,
            child: Column(
              children: [
                // ELO number
                Semantics(
                  label: 'Your rating: $rating',
                  child: Center(
                    child: Text(
                      '$rating',
                      style: const TextStyle(
                        color: AppColors.foreground,
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // "Your Rating" label
                const ExcludeSemantics(
                  child: Center(
                    child: Text(
                      'Your Rating',
                      style: TextStyle(color: AppColors.muted, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Sparkline
                Semantics(
                  label: 'ELO history chart',
                  child: const SizedBox(
                    height: 96,
                    width: double.infinity,
                    child: RepaintBoundary(child: EloSparkline()),
                  ),
                ),
              ],
            ),
          ),
        ),

        const Spacer(),

        // ── Play button ───────────────────────────────────────────────
        FadeTransition(
          opacity: buttonFade,
          child: SlideTransition(
            position: buttonSlide,
            child: GestureDetector(
              onTap: () => context.push('/topic'),
              child: Semantics(
                label: 'Play',
                button: true,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: kMinTapTarget),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(kButtonRadius),
                    boxShadow: [AppShadows.primaryGlow],
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
        ),
      ],
    ),
  );
}
