import 'package:flutter/material.dart';

import '../models/mood.dart';
import '../models/style.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// "calm, grounded, secure" → "Calm, grounded, secure".
String feelingsSentence(List<String> feelings) {
  final s = feelings.join(', ');
  return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// A small, soft-background note that surfaces what the outfit-mood
/// research says about the current selection — e.g. "Often feels" under
/// a palette, or "People often reach for" under a mood.
class ResearchHint extends StatelessWidget {
  final String title;
  final String body;

  const ResearchHint({super.key, required this.title, required this.body});

  /// What people tend to wear when they feel [mood] — colors plus
  /// aesthetics.
  factory ResearchHint.forMood(MoodDef mood) {
    final colors = mood.colorExamples.isEmpty
        ? mood.colorHint
        : '${mood.colorHint} (${mood.colorExamples.join(', ')})';
    final aesthetics = mood.aesthetics.map((k) => aestheticByKey(k)?.label ?? k).join(', ');
    return ResearchHint(
      title: 'Feeling ${mood.label.toLowerCase()}? People often reach for',
      body: '$colors.\nAesthetics: $aesthetics.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: AppTheme.mono(fontSize: 9, color: AppColors.sage)),
          const SizedBox(height: 4),
          Text(body, style: AppTheme.sans(fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}
