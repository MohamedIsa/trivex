import 'package:flutter/material.dart';

import '../models/game_config.dart';
import '../theme/app_colors.dart';

/// Topic selection + difficulty picker (UI-002).
class TopicScreen extends StatefulWidget {
  const TopicScreen({super.key});

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen>
    with SingleTickerProviderStateMixin {
  final _topicCtrl = TextEditingController();
  String _difficulty = 'medium';

  // ── Entry animation ───────────────────────────────────────────────────────

  late final AnimationController _entryCtrl;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_entryFade);
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get _canStart => _topicCtrl.text.trim().isNotEmpty;

  void _start() {
    if (!_canStart) return;
    Navigator.pushNamed(
      context,
      '/loading',
      arguments: GameConfig(
        topic: _topicCtrl.text.trim(),
        difficulty: _difficulty,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _entryFade,
          child: SlideTransition(
            position: _entrySlide,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Back arrow ────────────────────────────────────────
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.foreground,
                      ),
                      onPressed: () => Navigator.pop(context),
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
                    controller: _topicCtrl,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => _start(),
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      color: AppColors.foreground,
                      fontSize: 16,
                    ),
                    cursorColor: AppColors.primary,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      hintText: 'e.g. The Roman Empire',
                      hintStyle: TextStyle(
                        color: AppColors.muted.withValues(alpha: 0.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.muted.withValues(alpha: 0.4),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
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
                        selected: _difficulty == 'easy',
                        onTap: () => setState(() => _difficulty = 'easy'),
                      ),
                      const SizedBox(width: 12),
                      _DifficultyPill(
                        label: 'Medium',
                        selected: _difficulty == 'medium',
                        onTap: () => setState(() => _difficulty = 'medium'),
                      ),
                      const SizedBox(width: 12),
                      _DifficultyPill(
                        label: 'Hard',
                        selected: _difficulty == 'hard',
                        onTap: () => setState(() => _difficulty = 'hard'),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // ── Start button ──────────────────────────────────────
                  _StartButton(
                    enabled: _canStart,
                    onTap: _start,
                  ),

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
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: selected
                ? null
                : Border.all(
                    color: AppColors.muted.withValues(alpha: 0.4),
                  ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                    ),
                  ]
                : null,
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
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 24,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          'Start',
          style: TextStyle(
            color: enabled
                ? AppColors.foreground
                : AppColors.muted.withValues(alpha: 0.4),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
