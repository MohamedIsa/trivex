// API constants.

/// HTTP timeout for the question-fetch request.
///
/// The `llama-3.1-8b-instruct-fast` model typically responds in 2-3 s.
/// The Worker-side LLM timeout is 30 s; 45 s here gives comfortable
/// headroom for network latency.
const Duration kFetchTimeout = Duration(seconds: 45);
