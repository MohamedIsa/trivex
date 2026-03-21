import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;

import '../constants/animation_constants.dart';
import '../constants/layout_constants.dart';
import '../models/game_config.dart';
import '../providers/game_state_notifier.dart';
import '../services/question_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Loading screen — pulsing wordmark, question fetch, error retry (UI-003).
class LoadingScreen extends HookConsumerWidget {
  const LoadingScreen({super.key, this.gameConfig});

  /// Game configuration passed via [GoRouter] typed extras.
  final GameConfig? gameConfig;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── Animation ───────────────────────────────────────────────────────────

    final pulseCtrl = useAnimationController(duration: kWordmarkPulse);
    final pulseOpacity = useMemoized(
      () => Tween<double>(begin: 1.0, end: 0.6).animate(
        CurvedAnimation(parent: pulseCtrl, curve: kPulseCurve),
      ),
      [pulseCtrl],
    );
    final pulseScale = useMemoized(
      () => Tween<double>(begin: 1.0, end: 0.98).animate(
        CurvedAnimation(parent: pulseCtrl, curve: kPulseCurve),
      ),
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
        final questions = await QuestionService(
          client: client,
        ).fetchQuestions(config);

        if (cancelled.value || !context.mounted) return;

        // Initialise game state before navigating.
        ref
            .read(gameStateProvider.notifier)
            .initGame(
              questions,
              topic: config.topic,
              difficulty: config.difficulty,
            );

        if (!context.mounted) return;
        context.pushReplacement('/game');
      } catch (e) {
        if (cancelled.value || !context.mounted) return;
        pulseCtrl.stop();
        fetching.value = false;
        error.value = e.toString();
      }
    }

    void cancel() {
      cancelled.value = true;
      context.pop();
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) cancel();
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
      GestureDetector(
        onTap: onCancel,
        child: const SizedBox(
          height: 48,
          child: Center(
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.muted, fontSize: 16),
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
      GestureDetector(
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
      const SizedBox(height: 16),

      // Cancel.
      GestureDetector(
        onTap: onCancel,
        child: const SizedBox(
          height: 48,
          child: Center(
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.muted, fontSize: 16),
            ),
          ),
        ),
      ),
    ],
  );
}
