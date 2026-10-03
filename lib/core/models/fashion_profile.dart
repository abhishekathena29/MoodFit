/// A selectable answer in the onboarding fashion quiz.
class OptionDef {
  final String key;
  final String label;
  final String emoji;

  const OptionDef({required this.key, required this.label, required this.emoji});
}

/// How getting dressed usually feels — single choice in onboarding.
const List<OptionDef> kDressingFeelings = [
  OptionDef(key: 'fun', label: 'A fun part of my day', emoji: '✨'),
  OptionDef(key: 'routine', label: 'Just part of the routine', emoji: '🔁'),
  OptionDef(key: 'comfort', label: 'About feeling comfortable', emoji: '🧸'),
  OptionDef(key: 'stressful', label: 'Sometimes stressful', emoji: '😮‍💨'),
];

/// What someone wants out of MoodFit — multi choice in onboarding.
const List<OptionDef> kGoals = [
  OptionDef(key: 'patterns', label: 'See how outfits affect my mood', emoji: '📈'),
  OptionDef(key: 'feel-better', label: 'Dress to feel better on hard days', emoji: '🌤️'),
  OptionDef(key: 'express', label: 'Express my style more', emoji: '🎨'),
  OptionDef(key: 'ideas', label: 'Get outfit ideas from Muse', emoji: '💬'),
  OptionDef(key: 'habit', label: 'Build a daily check-in habit', emoji: '🌱'),
];

OptionDef? optionByKey(List<OptionDef> options, String? key) {
  for (final o in options) {
    if (o.key == key) return o;
  }
  return null;
}

/// The user's fashion sense, captured in onboarding and editable from
/// Profile. Stored as `fashionProfile` on `users/{uid}` and fed into the AI
/// layer so Muse and the daily nudge speak to this person's taste.
class FashionProfile {
  final List<String> styles;
  final List<String> aesthetics;
  final List<String> palettes;
  final List<String> goals;
  final String? dressingFeeling;

  const FashionProfile({
    this.styles = const [],
    this.aesthetics = const [],
    this.palettes = const [],
    this.goals = const [],
    this.dressingFeeling,
  });

  bool get isEmpty =>
      styles.isEmpty && aesthetics.isEmpty && palettes.isEmpty && goals.isEmpty && dressingFeeling == null;

  FashionProfile copyWith({
    List<String>? styles,
    List<String>? aesthetics,
    List<String>? palettes,
    List<String>? goals,
    String? dressingFeeling,
  }) =>
      FashionProfile(
        styles: styles ?? this.styles,
        aesthetics: aesthetics ?? this.aesthetics,
        palettes: palettes ?? this.palettes,
        goals: goals ?? this.goals,
        dressingFeeling: dressingFeeling ?? this.dressingFeeling,
      );

  static List<String> _list(dynamic v) => (v as List?)?.whereType<String>().toList() ?? const [];

  factory FashionProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FashionProfile();
    return FashionProfile(
      styles: _list(json['styles']),
      aesthetics: _list(json['aesthetics']),
      palettes: _list(json['palettes']),
      goals: _list(json['goals']),
      dressingFeeling: json['dressingFeeling'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'styles': styles,
        'aesthetics': aesthetics,
        'palettes': palettes,
        'goals': goals,
        'dressingFeeling': dressingFeeling,
      };
}
