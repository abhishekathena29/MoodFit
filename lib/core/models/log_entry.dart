/// Mirrors `LogEntry` from lib/moodfit-store.ts, extended with style,
/// aesthetic and a derived color-mood correlation tag.
class LogEntry {
  final String id;
  final String date; // yyyy-MM-dd
  final String mood;
  final String palette; // sage | blue-mist | beige | amber-warm
  final String? note;
  final String? style;
  final String? aesthetic;

  const LogEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.palette,
    this.note,
    this.style,
    this.aesthetic,
  });

  /// A short label describing how this outfit's palette lined up with the
  /// logged mood — e.g. "Sage + Focused" — used to build the color-mood
  /// correlation stats on Insights.
  String get colorMoodTag => '$palette:$mood';

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
        id: json['id'] as String,
        date: json['date'] as String,
        mood: json['mood'] as String,
        palette: json['palette'] as String? ?? 'sage',
        note: json['note'] as String?,
        style: json['style'] as String?,
        aesthetic: json['aesthetic'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'mood': mood,
        'palette': palette,
        if (note != null) 'note': note,
        if (style != null) 'style': style,
        if (aesthetic != null) 'aesthetic': aesthetic,
      };
}
