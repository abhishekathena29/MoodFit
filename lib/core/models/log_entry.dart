import 'mood.dart';
import 'palette.dart';

/// Mirrors `LogEntry` from lib/moodfit-store.ts, extended with style,
/// aesthetic and a derived color-mood correlation tag.
class LogEntry {
  final String id;
  final String date; // yyyy-MM-dd
  final String mood;

  /// A key from kPalettes, or null for quick logs from Home that only
  /// capture mood.
  final String? palette;
  final String? note;
  final String? style;
  final String? aesthetic;

  const LogEntry({
    required this.id,
    required this.date,
    required this.mood,
    this.palette,
    this.note,
    this.style,
    this.aesthetic,
  });

  /// A short label describing how this outfit's palette lined up with the
  /// logged mood — e.g. "warm:cheerful" — used to build the color-mood
  /// correlation stats on Insights.
  String get colorMoodTag => '$palette:$mood';

  /// Whether the palette worn is one the research says people tend to
  /// reach for in the logged mood. Null when no palette was logged.
  bool? get paletteMatchesMood {
    if (palette == null) return null;
    final m = moodByKey(mood);
    if (m == null) return null;
    return m.palettes.contains(palette);
  }

  /// Old logs used a different mood/palette vocabulary; keys are mapped to
  /// the research-based set on read so the rest of the app only sees one.
  factory LogEntry.fromJson(Map<String, dynamic> json) {
    final rawPalette = json['palette'] as String?;
    return LogEntry(
      id: json['id'] as String,
      date: json['date'] as String,
      mood: normalizeMoodKey(json['mood'] as String),
      palette: rawPalette == null ? null : normalizePaletteKey(rawPalette),
      note: json['note'] as String?,
      style: json['style'] as String?,
      aesthetic: json['aesthetic'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'mood': mood,
        if (palette != null) 'palette': palette,
        if (note != null) 'note': note,
        if (style != null) 'style': style,
        if (aesthetic != null) 'aesthetic': aesthetic,
      };
}
