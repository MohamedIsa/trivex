import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/theme_mode_provider.dart' show kPrefsBoxName;

part 'onboarding_repository.g.dart';

/// Hive key storing whether the user has completed onboarding.
const String kOnboardingCompleteKey = 'onboarding_complete';

/// Reads and writes the onboarding-complete flag in the shared prefs box.
class OnboardingRepository {
  Box get _box => Hive.box(kPrefsBoxName);

  /// Returns `true` when the user has finished or skipped onboarding.
  bool isComplete() => (_box.get(kOnboardingCompleteKey) as bool?) ?? false;

  /// Marks onboarding as complete so the overlay never appears again.
  Future<void> markComplete() async {
    await _box.put(kOnboardingCompleteKey, true);
  }
}

/// Riverpod provider for [OnboardingRepository].
@Riverpod(keepAlive: true)
OnboardingRepository onboardingRepository(OnboardingRepositoryRef ref) {
  return OnboardingRepository();
}
