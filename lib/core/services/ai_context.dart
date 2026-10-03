import 'package:intl/intl.dart';

import '../models/fashion_profile.dart';
import '../models/mood.dart';
import '../models/palette.dart';
import '../models/style.dart';
import '../providers/user_data_provider.dart';

/// Builds the text the AI layer is grounded in: the outfit-mood research
/// tables plus what we know about this user (fashion profile and recent
/// logs). Kept separate from [AiService] so every prompt shares one source.
class AiContext {
  AiContext._();

  static String research() {
    final b = StringBuffer('OUTFIT-MOOD RESEARCH\n');
    b.writeln('How wearing a color scheme tends to feel:');
    for (final p in kPalettes) {
      b.writeln('- ${p.label} (${p.description}): ${p.feelings.join(', ')}');
    }
    b.writeln('How wearing an aesthetic tends to feel:');
    for (final a in kAesthetics.where((a) => a.feelings.isNotEmpty)) {
      b.writeln('- ${a.label}: ${a.feelings.join(', ')}');
    }
    b.writeln('What people tend to wear in each mood:');
    for (final m in kMoods) {
      final examples = m.colorExamples.isEmpty ? '' : ' (e.g. ${m.colorExamples.join(', ')})';
      final aesthetics = m.aesthetics.map((k) => aestheticByKey(k)?.label ?? k).join(', ');
      b.writeln('- ${m.label}: ${m.colorHint}$examples; aesthetics: $aesthetics');
    }
    return b.toString();
  }

  static String user(UserDataProvider store) {
    final b = StringBuffer('USER\n');
    b.writeln('Name: ${store.name.isEmpty ? 'unknown' : store.name}');
    final fp = store.fashionProfile;
    String labels(List<String> keys, String? Function(String) label) =>
        keys.isEmpty ? 'not shared' : keys.map((k) => label(k) ?? k).join(', ');
    b.writeln('Usual styles: ${labels(fp.styles, (k) => styleByKey(k)?.label)}');
    b.writeln('Aesthetics they like: ${labels(fp.aesthetics, (k) => aestheticByKey(k)?.label)}');
    b.writeln('Colors they reach for: ${labels(fp.palettes, (k) => paletteByKey(k)?.label)}');
    b.writeln('Getting dressed feels: ${optionByKey(kDressingFeelings, fp.dressingFeeling)?.label ?? 'not shared'}');
    b.writeln('Goals in the app: ${labels(fp.goals, (k) => optionByKey(kGoals, k)?.label)}');
    b.writeln('Streak: ${store.streak} days, ${store.logs.length} logs total');

    final recent = store.logs.take(14).toList();
    if (recent.isEmpty) {
      b.writeln('No outfit logs yet.');
    } else {
      b.writeln('Recent outfit logs (newest first):');
      final fmt = DateFormat('EEE d MMM');
      for (final l in recent) {
        final parts = [
          moodByKey(l.mood)?.label ?? l.mood,
          if (paletteByKey(l.palette) case final p?) '${p.label} colors',
          if (styleByKey(l.style) case final s?) s.label,
          if (aestheticByKey(l.aesthetic) case final a?) a.label,
          if (l.note != null) 'note: "${l.note}"',
        ];
        final date = DateTime.tryParse(l.date);
        b.writeln('- ${date == null ? l.date : fmt.format(date)}: ${parts.join(' · ')}');
      }
    }
    return b.toString();
  }
}
