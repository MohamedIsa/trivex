/// Predefined trivia categories shown on [TopicScreen].
///
/// Each entry carries an `emoji`, an English `en` label, and an Arabic `ar`
/// label.  The displayed label depends on the local EN / عربي toggle; the
/// chosen label string is sent as `GameConfig.topic`.
const List<({String emoji, String en, String ar})> kCategories = [
  (emoji: '🔬', en: 'Science', ar: 'علوم'),
  (emoji: '📜', en: 'History', ar: 'تاريخ'),
  (emoji: '🌍', en: 'Geography', ar: 'جغرافيا'),
  (emoji: '⚽', en: 'Sports', ar: 'رياضة'),
  (emoji: '🎭', en: 'Pop Culture', ar: 'ثقافة شعبية'),
  (emoji: '💻', en: 'Technology', ar: 'تكنولوجيا'),
  (emoji: '🎬', en: 'Movies & TV', ar: 'أفلام وتلفزيون'),
  (emoji: '🎵', en: 'Music', ar: 'موسيقى'),
  (emoji: '🎨', en: 'Art & Literature', ar: 'فن وأدب'),
  (emoji: '🍕', en: 'Food & Cuisine', ar: 'طعام وطبخ'),
];
