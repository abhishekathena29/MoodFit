/// Style and aesthetic tags a log entry can carry alongside mood and
/// palette — lets Insights correlate not just color, but silhouette and
/// vibe, with how an outfit made someone feel.
class StyleDef {
  final String key;
  final String label;

  const StyleDef({required this.key, required this.label});
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
  StyleDef(key: 'minimalist', label: 'Minimalist'),
  StyleDef(key: 'cottagecore', label: 'Cottagecore'),
  StyleDef(key: 'streetwear', label: 'Streetwear'),
  StyleDef(key: 'preppy', label: 'Preppy'),
  StyleDef(key: 'vintage', label: 'Vintage'),
  StyleDef(key: 'glam', label: 'Glam'),
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
