import 'package:flutter_test/flutter_test.dart';

import 'package:trivex/core/env.dart';

void main() {
  group('Env', () {
    test(
      'workerBaseUrl returns production URL when WORKER_URL is not defined',
      () {
        // String.fromEnvironment returns the defaultValue when the key is
        // not provided via --dart-define. In the test runner no defines are
        // passed, so the production fallback must be returned.
        expect(
          Env.workerBaseUrl,
          'https://trivex-worker.trivex.workers.dev',
        );
      },
    );
  });
}
