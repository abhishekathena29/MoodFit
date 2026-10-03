import 'dart:ui' show Color;

/// The color schemes from the outfit-mood research, each with how wearing
/// it tends to make a person feel — the "how does wearing these colors
/// make a person feel?" half of the data.
class PaletteDef {
  final String key;
  final String label;
  final String description;

  /// One color for single-hue schemes, 2–4 for harmonies (complementary,
  /// triadic, tetradic) so the swatch shows the combination.
  final List<Color> swatch;
  final List<String> feelings;

  const PaletteDef({
    required this.key,
    required this.label,
    required this.description,
    required this.swatch,
    required this.feelings,
  });
}

const List<PaletteDef> kPalettes = [
  PaletteDef(
    key: 'muted',
    label: 'Muted',
    description: 'Low saturation and intensity',
    swatch: [Color(0xFF9A9E92)],
    feelings: ['calm', 'grounded', 'secure', 'relieved', 'thoughtful', 'focused', 'indifferent'],
  ),
  PaletteDef(
    key: 'warm',
    label: 'Warm',
    description: 'Reddish, orangish or yellowish hues',
    swatch: [Color(0xFFE69B4C)],
    feelings: ['energetic', 'confident', 'bold', 'cheerful', 'passionate', 'excited', 'hopeful', 'optimistic', 'cozy'],
  ),
  PaletteDef(
    key: 'cool',
    label: 'Cool',
    description: 'Greenish, bluish and purplish hues',
    swatch: [Color(0xFF6D8AA3)],
    feelings: ['calm', 'relaxed', 'composed', 'introspective', 'focused'],
  ),
  PaletteDef(
    key: 'vibrant',
    label: 'Vibrant',
    description: 'High saturation and intensity',
    swatch: [Color(0xFFE8436B)],
    feelings: ['energetic', 'confident', 'joyful', 'engaged', 'outgoing'],
  ),
  PaletteDef(
    key: 'neutral',
    label: 'Neutral',
    description: "Colors that don't appear on the color wheel",
    swatch: [Color(0xFFE5DDD0)],
    feelings: ['grounded', 'destressed', 'calm', 'steady', 'clean', 'crisp'],
  ),
  PaletteDef(
    key: 'complementary',
    label: 'Complementary',
    description: 'Two colors opposite each other on the color wheel',
    swatch: [Color(0xFF3F6FD1), Color(0xFFF29A38)],
    feelings: ['energetic', 'bold', 'stimulated', 'gratified'],
  ),
  PaletteDef(
    key: 'triadic',
    label: 'Triadic',
    description: 'Three colors evenly spaced on the color wheel',
    swatch: [Color(0xFFE04848), Color(0xFFF2C94C), Color(0xFF3F6FD1)],
    feelings: ['energetic', 'bold', 'balanced'],
  ),
  PaletteDef(
    key: 'tetradic',
    label: 'Tetradic',
    description: 'Two complementary pairs together',
    swatch: [Color(0xFFE04848), Color(0xFF4CAF6E), Color(0xFF3F6FD1), Color(0xFFF29A38)],
    feelings: ['confident', 'energetic', 'expressive', 'overstimulated'],
  ),
];

/// Palette keys from before the research-based set, mapped to their
/// closest scheme so older Firestore logs still render.
const Map<String, String> _kLegacyPalettes = {
  'sage': 'muted',
  'blue-mist': 'cool',
  'beige': 'neutral',
  'amber-warm': 'warm',
};

String normalizePaletteKey(String key) => _kLegacyPalettes[key] ?? key;

PaletteDef? paletteByKey(String? key) {
  if (key == null) return null;
  final k = normalizePaletteKey(key);
  for (final p in kPalettes) {
    if (p.key == k) return p;
  }
  return null;
}
