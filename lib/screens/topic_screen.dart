import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '../constants/animation_constants.dart';
import '../constants/game_constants.dart';
import '../constants/layout_constants.dart';
import '../models/game_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Topic selection + difficulty picker (UI-002).
class TopicScreen extends HookWidget {
  const TopicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topicCtrl = useTextEditingController();
    final difficulty = useState('medium');
    final questionCount = useState(kDefaultQuestionCount);

    // ── Entry animation ─────────────────────────────────────────────────────

    final entryCtrl = useAnimationController(duration: kTopicEntryDuration);
    final entryFade = useMemoized(
      () => CurvedAnimation(parent: entryCtrl, curve: kEntryCurve),
      [entryCtrl],
    );
    final entrySlide = useMemoized(
      () => Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(entryFade),
      [entryFade],
    );

    useEffect(() {
      entryCtrl.forward();
      return null;
    }, const []);

    // Rebuild when text changes (drives _canStart).
    useListenable(topicCtrl);

    // ── Helpers ─────────────────────────────────────────────────────────────

    bool canStart() => topicCtrl.text.trim().isNotEmpty;

    void start() {
      if (!canStart()) return;
      context.push(
        '/loading',
        extra: GameConfig(
          topic: topicCtrl.text.trim(),
          difficulty: difficulty.value,
          count: questionCount.value,
        ),
      );
    }

    // ── Build ───────────────────────────────────────────────────────────────

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: entryFade,
          child: SlideTransition(
            position: entrySlide,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kScreenPaddingH,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Back arrow ────────────────────────────────────────
                  SizedBox(
                    width: kMinTapTarget,
                    height: kMinTapTarget,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.foreground,
                      ),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Heading ───────────────────────────────────────────
                  const Text(
                    'Your Round',
                    style: TextStyle(
                      color: AppColors.foreground,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Topic TextField ───────────────────────────────────
                  TextField(
                    controller: topicCtrl,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => start(),
                    style: const TextStyle(
                      color: AppColors.foreground,
                      fontSize: 16,
                    ),
                    cursorColor: AppColors.primary,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      hintText: 'e.g. The Roman Empire',
                      hintStyle: TextStyle(color: AppColors.mutedHalf),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kButtonRadius),
                        borderSide: BorderSide(color: AppColors.mutedSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kButtonRadius),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Difficulty pills ──────────────────────────────────
                  Row(
                    children: [
                      _DifficultyPill(
                        label: 'Easy',
                        selected: difficulty.value == 'easy',
                        onTap: () => difficulty.value = 'easy',
                      ),
                      const SizedBox(width: 12),
                      _DifficultyPill(
                        label: 'Medium',
                        selected: difficulty.value == 'medium',
                        onTap: () => difficulty.value = 'medium',
                      ),
                      const SizedBox(width: 12),
                      _DifficultyPill(
                        label: 'Hard',
                        selected: difficulty.value == 'hard',
                        onTap: () => difficulty.value = 'hard',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Question count pills ────────────────────────────────
                  Row(
                    children: [
                      for (int i = 0;
                          i < kQuestionCountOptions.length;
                          i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        _DifficultyPill(
                          label: '${kQuestionCountOptions[i]}',
                          selected: questionCount.value ==
                              kQuestionCountOptions[i],
                          onTap: () => questionCount.value =
                              kQuestionCountOptions[i],
                        ),
                      ],
                    ],
                  ),

                  const Spacer(),

                  // ── Start button ──────────────────────────────────────
                  _StartButton(enabled: canStart(), onTap: start),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Private sub-widgets
// ═══════════════════════════════════════════════════════════════════════════════

// ── Difficulty pill ─────────────────────────────────────────────────────────

class _DifficultyPill extends StatelessWidget {
  const _DifficultyPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: kButtonTransition,
          constraints: const BoxConstraints(minHeight: kMinTapTarget),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(kChipRadius),
            border: selected ? null : Border.all(color: AppColors.mutedSubtle),
            boxShadow: selected ? [AppShadows.primaryGlowSmall] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.foreground : AppColors.muted,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Start button ────────────────────────────────────────────────────────────

class _StartButton extends StatelessWidget {
  const _StartButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: kButtonTransition,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(kButtonRadius),
          boxShadow: enabled ? [AppShadows.primaryGlow] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          'Start',
          style: TextStyle(
            color: enabled ? AppColors.foreground : AppColors.mutedSubtle,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
