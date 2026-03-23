/// Compile-time environment configuration via `--dart-define`.
///
/// Defaults fall back to production values so no flag is needed for a
/// release build.  Override with:
///
/// ```sh
/// flutter run --dart-define=WORKER_URL=http://localhost:8787
/// ```
class Env {
  Env._();

  /// Base URL for the Cloudflare Worker (question generation API).
  ///
  /// Override at compile time with `--dart-define=WORKER_URL=<url>`.
  /// Falls back to the production Worker URL when unset.
  static const String workerBaseUrl = String.fromEnvironment(
    'WORKER_URL',
    defaultValue: 'https://trivex-worker.trivex.workers.dev',
  );
}
