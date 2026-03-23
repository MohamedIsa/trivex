/// Predefined trivia categories shown on [TopicScreen].
///
/// Each entry is a `(emoji, label)` record. The label is sent as
/// `GameConfig.topic` — it must be a good LLM-friendly subject string.
const List<({String emoji, String label})> kCategories = [
  (emoji: '🔬', label: 'Science'),
  (emoji: '📜', label: 'History'),
  (emoji: '🌍', label: 'Geography'),
  (emoji: '⚽', label: 'Sports'),
  (emoji: '🎭', label: 'Pop Culture'),
  (emoji: '💻', label: 'Technology'),
  (emoji: '🎬', label: 'Movies & TV'),
  (emoji: '🎵', label: 'Music'),
  (emoji: '🎨', label: 'Art & Literature'),
  (emoji: '🍕', label: 'Food & Cuisine'),
];
