/// API constants — swap [kWorkerBaseUrl] to point at dev or prod.
const String kWorkerBaseUrl = 'https://trivex-worker.trivex.workers.dev';

/// HTTP timeout for the question-fetch request.
///
/// The 70B model (`llama-3.3-70b-instruct-fp8-fast`) typically responds
/// in 13–20 s from the Worker, with the Worker-side timeout at 30 s.
/// 45 s gives comfortable headroom for mobile network latency.
const Duration kFetchTimeout = Duration(seconds: 45);
