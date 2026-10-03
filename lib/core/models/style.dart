/// Style and aesthetic tags a log entry can carry alongside mood and
/// palette — lets Insights correlate not just color, but silhouette and
/// vibe, with how an outfit made someone feel.
class StyleDef {
  final String key;
  final String label;

  /// How wearing this tends to make a person feel, from the outfit-mood
  /// research. Empty when the research has no data for it.
  final List<String> feelings;

  const StyleDef({required this.key, required this.label, this.feelings = const []});
}

const List<StyleDef> kStyles = [
  StyleDef(key: 'casual', label: 'Casual'),
  StyleDef(key: 'formal', label: 'Formal'),
  StyleDef(key: 'sporty', label: 'Sporty'),
  StyleDef(key: 'boho', label: 'Boho'),
  StyleDef(key: 'edgy', label: 'Edgy'),
  StyleDef(key: 'classic', label: 'Classic'),
];

const List<StyleDef> kAesthetics = [
  StyleDef(
    key: 'old-money',
    label: 'Old Money',
    feelings: ['calm', 'composed', 'confident', 'modest', 'unfazed'],
  ),
  StyleDef(
    key: 'streetwear',
    label: 'Streetwear',
    feelings: ['confident', 'creative', 'carefree', 'rebellious'],
  ),
  StyleDef(
    key: 'grunge',
    label: 'Grunge',
    feelings: ['moody', 'rebellious', 'detached', 'carefree', 'introspective', 'melancholic'],
  ),
  StyleDef(
    key: 'y2k',
    label: 'Y2K',
    feelings: ['optimistic', 'defiant', 'nostalgic', 'confident', 'carefree', 'bold', 'nonchalant'],
  ),
  StyleDef(
    key: 'dark-academia',
    label: 'Dark Academia',
    feelings: ['pensive', 'nostalgic', 'introspective', 'focused', 'solitary'],
  ),
  StyleDef(
    key: 'light-academia',
    label: 'Light Academia',
    feelings: ['joyful', 'optimistic', 'calm', 'curious', 'comfortable', 'inspired', 'connected'],
  ),
  StyleDef(
    key: 'boho',
    label: 'Boho',
    feelings: ['carefree', 'relaxed', 'expressive', 'creative', 'connected', 'dreamy'],
  ),
  StyleDef(
    key: 'fairycore',
    label: 'Fairycore',
    feelings: ['whimsical', 'calm', 'nostalgic', 'solitary', 'non-confrontational', 'dreamy', 'childlike'],
  ),
  StyleDef(
    key: 'minimalist',
    label: 'Minimalist',
    feelings: ['calm', 'focused', 'confident', 'disciplined'],
  ),
  StyleDef(
    key: 'cottagecore',
    label: 'Cottagecore',
    feelings: ['calm', 'nostalgic', 'mindful', 'dreamy', 'content'],
  ),
  // Only appear in the "what people wear in this mood" data, so no
  // feelings yet — still loggable so suggestions can be acted on.
  StyleDef(key: 'kidcore', label: 'Kidcore'),
  StyleDef(key: 'goth', label: 'Goth'),
  StyleDef(key: 'emo', label: 'Emo'),
];

StyleDef? styleByKey(String? key) {
  if (key == null) return null;
  for (final s in kStyles) {
    if (s.key == key) return s;
  }
  return null;
}

StyleDef? aestheticByKey(String? key) {
  if (key == null) return null;
  for (final a in kAesthetics) {
    if (a.key == key) return a;
  }
  return null;
}
