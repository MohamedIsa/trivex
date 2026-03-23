import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../constants/layout_constants.dart';
import '../models/achievement.dart';
import '../repositories/achievement_repository.dart';
import '../theme/app_colors.dart';

/// Achievements screen — lists all 8 achievements with locked/unlocked state.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(achievementRepositoryProvider);
    final unlocked = repo.getUnlocked();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AppBar(onBack: () => context.pop()),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: kScreenPaddingH,
                  vertical: 8,
                ),
                itemCount: kAchievements.length,
                itemBuilder: (_, index) => _AchievementTile(
                  achievement: kAchievements[index],
                  unlockDate: repo.getUnlockDate(kAchievements[index].id),
                  isUnlocked: unlocked.contains(kAchievements[index].id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sub-widgets (private)
// ═══════════════════════════════════════════════════════════════════════════════

class _AppBar extends StatelessWidget {
  const _AppBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kScreenPaddingH,
        vertical: 16,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: const Icon(Icons.arrow_back, color: AppColors.foreground),
          ),
          const SizedBox(width: 12),
          const Text(
            'Achievements',
            style: TextStyle(
              color: AppColors.foreground,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    required this.unlockDate,
    required this.isUnlocked,
  });

  final Achievement achievement;
  final DateTime? unlockDate;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(kCardPadding),
        decoration: BoxDecoration(
          color: isUnlocked ? AppColors.card : AppColors.cardDimmed,
          borderRadius: BorderRadius.circular(kCardRadius),
          border: Border.all(
            color: isUnlocked ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            _EmojiCircle(
              emoji: achievement.emoji,
              isUnlocked: isUnlocked,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _TileContent(
                achievement: achievement,
                unlockDate: unlockDate,
                isUnlocked: isUnlocked,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiCircle extends StatelessWidget {
  const _EmojiCircle({required this.emoji, required this.isUnlocked});

  final String emoji;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kMinTapTarget,
      height: kMinTapTarget,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUnlocked
            ? AppColors.primary.withValues(alpha: 0.2)
            : AppColors.mutedFaint,
      ),
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: TextStyle(
          fontSize: 22,
          color: isUnlocked ? null : AppColors.muted,
        ),
      ),
    );
  }
}

class _TileContent extends StatelessWidget {
  const _TileContent({
    required this.achievement,
    required this.unlockDate,
    required this.isUnlocked,
  });

  final Achievement achievement;
  final DateTime? unlockDate;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          achievement.name,
          style: TextStyle(
            color: isUnlocked ? AppColors.foreground : AppColors.muted,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isUnlocked && unlockDate != null
              ? 'Unlocked ${_formatDate(unlockDate!)}'
              : achievement.hint,
          style: TextStyle(
            color: isUnlocked ? AppColors.teal : AppColors.mutedHalf,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
