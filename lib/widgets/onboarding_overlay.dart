import 'package:flutter/material.dart';

import '../constants/layout_constants.dart';

/// Number of onboarding steps.
const int kOnboardingStepCount = 3;

/// Size of each progress dot.
const double kDotSize = 10.0;

/// Spacing between progress dots.
const double kDotSpacing = 8.0;

/// Data for a single onboarding step.
class _StepData {
  const _StepData({
    required this.emoji,
    required this.title,
    required this.body,
  });

  final String emoji;
  final String title;
  final String body;
}

const _steps = [
  _StepData(
    emoji: '📚',
    title: 'Pick a Topic',
    body: 'Choose a category, pick a difficulty level, '
        'and the AI generates unique questions just for you.',
  ),
  _StepData(
    emoji: '🤖',
    title: 'Beat the Bot',
    body: 'Answer within the time limit before the bot does. '
        'Higher difficulty makes the bot faster and smarter.',
  ),
  _StepData(
    emoji: '📈',
    title: 'Your ELO Rating',
    body: 'Your rating goes up when you win and down when you lose. '
        'Everyone starts at 1000 — how high can you climb?',
  ),
];

/// Full-screen onboarding overlay shown on first launch.
///
/// Displays 3 tutorial steps with Next / Got It / Skip controls.
/// Calls [onComplete] when the user finishes or skips.
class OnboardingOverlay extends StatefulWidget {
  const OnboardingOverlay({super.key, required this.onComplete});

  /// Called after "Got It" or "Skip" — caller persists the flag.
  final VoidCallback onComplete;

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay> {
  int _currentStep = 0;

  void _next() {
    if (_currentStep < kOnboardingStepCount - 1) {
      setState(() => _currentStep++);
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: _StepCard(
                step: _steps[_currentStep],
                currentIndex: _currentStep,
                onNext: _next,
                colors: colors,
                textTheme: theme.textTheme,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: TextButton(
                onPressed: widget.onComplete,
                child: Text(
                  'Skip',
                  style: TextStyle(color: colors.onSurface),
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

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.currentIndex,
    required this.onNext,
    required this.colors,
    required this.textTheme,
  });

  final _StepData step;
  final int currentIndex;
  final VoidCallback onNext;
  final ColorScheme colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentIndex == kOnboardingStepCount - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kScreenPaddingH),
      child: Container(
        padding: const EdgeInsets.all(kCardPadding),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(kCardRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(step.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              step.title,
              style: textTheme.bodyLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              step.body,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.7),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _ProgressDots(current: currentIndex),
            const SizedBox(height: 24),
            _NextButton(
              label: isLastStep ? 'Got It' : 'Next',
              onTap: onNext,
              colors: colors,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(kOnboardingStepCount, (i) {
        final isActive = i == current;
        return Container(
          width: kDotSize,
          height: kDotSize,
          margin: EdgeInsets.only(right: i < kOnboardingStepCount - 1 ? kDotSpacing : 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? colors.primary
                : colors.onSurface.withValues(alpha: 0.25),
          ),
        );
      }),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({
    required this.label,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final VoidCallback onTap;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kButtonRadius),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
