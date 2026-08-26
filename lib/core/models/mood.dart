/// Mirrors `MoodKey` / `MOODS` from lib/moodfit-store.ts.
class MoodDef {
  final String key;
  final String label;
  final bool warm;

  const MoodDef({required this.key, required this.label, this.warm = false});
}

const List<MoodDef> kMoods = [
  MoodDef(key: 'grateful', label: 'Grateful'),
  MoodDef(key: 'focused', label: 'Focused'),
  MoodDef(key: 'quiet', label: 'Quiet'),
  MoodDef(key: 'bright', label: 'Bright'),
  MoodDef(key: 'tired', label: 'Tired'),
  MoodDef(key: 'heavy', label: 'Heavy', warm: true),
];

MoodDef? moodByKey(String key) {
  for (final m in kMoods) {
    if (m.key == key) return m;
  }
  return null;
}
