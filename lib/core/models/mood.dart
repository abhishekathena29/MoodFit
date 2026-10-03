/// The eight mood groups from the outfit-mood research. Each mood also
/// carries what people tend to reach for when they feel this way — the
/// "when a person feels like this, what do they wear?" half of the data —
/// so Log, Home and Insights can surface it next to the mood itself.
class MoodDef {
  final String key;
  final String label;
  final String emoji;

  /// 0–100, roughly how upbeat the mood is — drives bar heights in the
  /// Home weekly chart and picks the "best" outfit to recall.
  final int energy;

  /// Lower-energy / harder moods — rendered with the amber "gentle care"
  /// tint and counted as non-positive in Insights.
  final bool heavy;

  /// e.g. "Bright, warm, energetic colors".
  final String colorHint;

  /// e.g. ['red', 'yellow', 'orange', 'hot pink'].
  final List<String> colorExamples;

  /// Palette keys (see palette.dart) that match [colorHint].
  final List<String> palettes;

  /// Aesthetic keys (see style.dart) people tend to wear in this mood.
  final List<String> aesthetics;

  const MoodDef({
    required this.key,
    required this.label,
    required this.emoji,
    required this.energy,
    required this.colorHint,
    required this.colorExamples,
    required this.palettes,
    required this.aesthetics,
    this.heavy = false,
  });
}

const List<MoodDef> kMoods = [
  MoodDef(
    key: 'excited',
    label: 'Excited & Lively',
    emoji: '⚡',
    energy: 95,
    colorHint: 'Bright, warm, energetic colors',
    colorExamples: ['red', 'yellow', 'orange', 'hot pink'],
    palettes: ['warm', 'vibrant'],
    aesthetics: ['streetwear', 'y2k', 'kidcore'],
  ),
  MoodDef(
    key: 'cheerful',
    label: 'Cheerful & Happy',
    emoji: '☀️',
    energy: 85,
    colorHint: 'Bright, warm, saturated colors — or personal favourites',
    colorExamples: ['pink', 'orange', 'yellow', 'fresh greens', 'fresh blues'],
    palettes: ['warm', 'vibrant'],
    aesthetics: ['kidcore', 'y2k', 'cottagecore'],
  ),
  MoodDef(
    key: 'relaxed',
    label: 'Relaxed & Carefree',
    emoji: '🌿',
    energy: 70,
    colorHint: 'Soft, calming, neutral shades',
    colorExamples: ['blue', 'green', 'white', 'off-white', 'pink', 'beige', 'earth tones'],
    palettes: ['neutral', 'cool', 'muted'],
    aesthetics: ['cottagecore', 'streetwear', 'grunge'],
  ),
  MoodDef(
    key: 'calm',
    label: 'Calm & Serene',
    emoji: '🌊',
    energy: 60,
    colorHint: 'Soft blues, neutral greens, gentle neutrals',
    colorExamples: [],
    palettes: ['cool', 'neutral', 'muted'],
    aesthetics: ['old-money', 'cottagecore', 'minimalist'],
  ),
  MoodDef(
    key: 'gloomy',
    label: 'Gloomy & Sad',
    emoji: '🌧️',
    energy: 20,
    heavy: true,
    colorHint: 'Dark, muted, neutral colors',
    colorExamples: ['black', 'grey', 'brown', 'dark blue'],
    palettes: ['muted', 'neutral'],
    aesthetics: ['grunge', 'streetwear', 'dark-academia', 'goth', 'emo'],
  ),
  MoodDef(
    key: 'bored',
    label: 'Bored & Weary',
    emoji: '🥱',
    energy: 35,
    heavy: true,
    colorHint: 'Muted, neutral, low-energy colors',
    colorExamples: ['grey', 'beige', 'brown', 'navy blue'],
    palettes: ['muted', 'neutral'],
    aesthetics: ['minimalist', 'streetwear'],
  ),
  MoodDef(
    key: 'irritated',
    label: 'Irritated & Annoyed',
    emoji: '😤',
    energy: 30,
    heavy: true,
    colorHint: 'Dark, intense colors — or muted tones',
    colorExamples: ['black', 'red', 'grey', 'brown'],
    palettes: ['muted', 'neutral', 'warm'],
    aesthetics: ['streetwear', 'grunge'],
  ),
  MoodDef(
    key: 'tense',
    label: 'Tense & Nervous',
    emoji: '😬',
    energy: 30,
    heavy: true,
    colorHint: 'Neutral, dark, grounding colors',
    colorExamples: ['black', 'grey', 'brown', 'navy'],
    palettes: ['neutral', 'muted'],
    aesthetics: ['minimalist', 'streetwear', 'grunge'],
  ),
];

/// Mood keys from before the research-based set, mapped to their closest
/// new group so older Firestore logs still render and count in Insights.
const Map<String, String> _kLegacyMoods = {
  'grateful': 'cheerful',
  'bright': 'excited',
  'focused': 'calm',
  'quiet': 'calm',
  'tired': 'bored',
  'heavy': 'gloomy',
};

String normalizeMoodKey(String key) => _kLegacyMoods[key] ?? key;

MoodDef? moodByKey(String key) {
  final k = normalizeMoodKey(key);
  for (final m in kMoods) {
    if (m.key == k) return m;
  }
  return null;
}
