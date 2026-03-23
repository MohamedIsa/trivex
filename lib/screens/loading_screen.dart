import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;

import '../constants/animation_constants.dart';
import '../constants/layout_constants.dart';
import '../core/app_error.dart';
import '../core/result.dart';
import '../models/game_config.dart';
import '../providers/game_state_notifier.dart';
import '../repositories/question_cache_repository.dart';
import '../services/question_service.dart';
import '../state/game_phase.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Loading screen — pulsing wordmark, question fetch, error retry .
class LoadingScreen extends HookConsumerWidget {
  const LoadingScreen({super.key, this.gameConfig});

  /// Game configuration passed via [GoRouter] typed extras.
  final GameConfig? gameConfig;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── Animation ───────────────────────────────────────────────────────────

    final pulseCtrl = useAnimationController(duration: kWordmarkPulse);
    final pulseOpacity = useMemoized(
      () => Tween<double>(
        begin: 1.0,
        end: 0.6,
      ).animate(CurvedAnimation(parent: pulseCtrl, curve: kPulseCurve)),
      [pulseCtrl],
    );
    final pulseScale = useMemoized(
      () => Tween<double>(
        begin: 1.0,
        end: 0.98,
      ).animate(CurvedAnimation(parent: pulseCtrl, curve: kPulseCurve)),
      [pulseCtrl],
    );

    // Start pulse loop on mount.
    useEffect(() {
      pulseCtrl.repeat(reverse: true);
      return null;
    }, const []);

    // ── HTTP client (closed on unmount) ─────────────────────────────────────

    final client = useMemoized(http.Client.new);
    useEffect(() => client.close, const []);

    // ── Mutable state ───────────────────────────────────────────────────────

    final fetching = useState(false);
    final cancelled = useRef(false);
    final error = useState<String?>(null);
    final entryOpacity = useState(0.0);

    // ── Fetch logic ─────────────────────────────────────────────────────────

    Future<void> fetchQuestions() async {
      if (fetching.value) return;
      fetching.value = true;
      error.value = null;

      final config = gameConfig;
      if (config == null) {
        fetching.value = false;
        error.value = 'Missing game configuration.';
        return;
      }

      try {
        // Predict the language client-side using the same Arabic Unicode
        // regex the worker uses, so the cache key matches the one
        // result_screen.dart saves under after the game.
        final detectedLanguage =
            RegExp(r'[\u0600-\u06FF]').hasMatch(config.topic) ? 'ar' : 'en';

        final cacheRepo = ref.read(questionCacheRepositoryProvider);
        final cacheKey = QuestionCacheRepository.cacheKey(
          topic: config.topic,
          difficulty: config.difficulty,
          language: detectedLanguage,
        );
        final seenQuestions = cacheRepo.getSeenQuestions(cacheKey);

        final result = await QuestionService(
          client: client,
        ).fetchQuestions(config, excludeQuestions: seenQuestions);

        if (cancelled.value || !context.mounted) return;

        switch (result) {
          case Ok(value: final fetchResult):
            // Initialise game state before navigating.
            ref
                .read(gameStateNotifierProvider.notifier)
                .initGame(
                  fetchResult.questions,
                  topic: config.topic,
                  difficulty: config.difficulty,
                  language: fetchResult.language,
                );

            if (!context.mounted) return;
            context.pushReplacement('/game');
          case Err(error: final appError):
            if (cancelled.value || !context.mounted) return;
            pulseCtrl.stop();
            fetching.value = false;
            error.value = switch (appError) {
              TimeoutError() => 'Request timed out. Please try again.',
              NetworkError(:final message) => message,
              ParseError(:final message) => message,
              UnknownError(:final message) => message,
            };
        }
      } catch (e) {
        if (cancelled.value || !context.mounted) return;
        pulseCtrl.stop();
        fetching.value = false;
        error.value = e.toString();
      }
    }

    void cancel() {
      cancelled.value = true;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }

    // ── Entry fade + deferred fetch ─────────────────────────────────────────

    useEffect(() {
      Future.microtask(() {
        if (context.mounted) entryOpacity.value = 1;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) fetchQuestions();
      });
      return null;
    }, const []);

    // ── Build ───────────────────────────────────────────────────────────────

    final gamePhase = ref.watch(gameStateNotifierProvider);
    final isGameActive =
        gamePhase is PlayingPhase || gamePhase is RevealingPhase;

    return PopScope(
      canPop: !isGameActive,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          cancelled.value = true;
          return;
        }
        if (!isGameActive) cancel();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: AnimatedOpacity(
          opacity: entryOpacity.value,
          duration: kRevealSlide,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: error.value != null
                  ? _buildError(
                      error: error.value!,
                      onRetry: () {
                        cancelled.value = false;
                        pulseCtrl.repeat(reverse: true);
                        fetchQuestions();
                      },
                      onCancel: cancel,
                    )
                  : _buildLoading(
                      pulseCtrl: pulseCtrl,
                      pulseOpacity: pulseOpacity,
                      pulseScale: pulseScale,
                      onCancel: cancel,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Build helpers (top-level, stateless) ────────────────────────────────────

Widget _buildLoading({
  required AnimationController pulseCtrl,
  required Animation<double> pulseOpacity,
  required Animation<double> pulseScale,
  required VoidCallback onCancel,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Pulsing wordmark.
      AnimatedBuilder(
        animation: pulseCtrl,
        builder: (_, child) {
          return Opacity(
            opacity: pulseOpacity.value,
            child: Transform.scale(scale: pulseScale.value, child: child),
          );
        },
        child: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Triv',
                style: TextStyle(
                  color: AppColors.foreground,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: 'ex',
                style: TextStyle(
                  color: AppColors.teal,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),

      // Subtitle.
      const Text(
        'Generating questions…',
        style: TextStyle(color: AppColors.foreground, fontSize: 18),
      ),
      const SizedBox(height: 48),

      // Cancel.
      Semantics(
        label: 'Cancel loading',
        button: true,
        child: GestureDetector(
          onTap: onCancel,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: const Center(
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.muted, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _buildError({
  required String error,
  required VoidCallback onRetry,
  required VoidCallback onCancel,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Wordmark (static).
      RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'Triv',
              style: TextStyle(
                color: AppColors.foreground,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: 'ex',
              style: TextStyle(
                color: AppColors.teal,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),

      // Error message.
      Text(
        error,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.red, fontSize: 16),
      ),
      const SizedBox(height: 32),

      // Try Again.
      Semantics(
        label: 'Try Again',
        button: true,
        child: GestureDetector(
          onTap: onRetry,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(kButtonRadius),
              boxShadow: [AppShadows.primaryGlow],
            ),
            alignment: Alignment.center,
            child: const Text(
              'Try Again',
              style: TextStyle(
                color: AppColors.foreground,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Cancel.
      Semantics(
        label: 'Cancel',
        button: true,
        child: GestureDetector(
          onTap: onCancel,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: const Center(
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.muted, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
