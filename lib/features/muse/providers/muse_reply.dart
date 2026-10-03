import 'dart:math';

/// Local, rule-based fallback for the Muse chat tab — used when the Groq
/// config is missing or a request fails. A small keyword matcher that answers fashion questions directly and, every few turns,
/// folds in a gentle, low-key check-in on how the person is actually doing.
/// It never leads with mental health — fashion is always the door in.
class MuseReply {
  MuseReply._();

  static final _random = Random();

  static const _moodKeywords = [
    'sad', 'anxious', 'anxiety', 'stressed', 'stress', 'down', 'heavy', 'lonely',
    'overwhelmed', 'tired', 'exhausted', 'depressed', 'low', 'upset', 'crying',
    'numb', 'burnt out', 'burnout',
  ];

  static const _fashionKeywords = [
    'wear', 'outfit', 'style', 'color', 'colour', 'palette', 'dress', 'look',
    'aesthetic', 'clothes', 'clothing', 'fit', 'wardrobe', 'trend', 'fashion',
    'layer', 'accessorize', 'accessorise', 'shoes', 'jacket',
  ];

  static const _greetingKeywords = ['hi', 'hello', 'hey', 'yo', 'sup'];

  static const List<String> _fashionTips = [
    "Muted colors — low saturation, low intensity — tend to feel calm, grounded and secure. "
        "Good for days that feel a little scattered.",
    "Warm reds, oranges and yellows tend to feel energetic, confident and optimistic. If today "
        "feels foggy, a warm layer can lift the whole outfit — and the mood with it.",
    "Cool greens, blues and purples usually read calm, composed and focused. Handy when you've "
        "got something big to concentrate on.",
    "Neutrals feel grounded, steady and crisp — people often reach for them on tense or nervous "
        "days because they're so easy to settle into.",
    "Complementary pairs (like blue + orange) feel bold and stimulating. Tetradic combos can be "
        "expressive — but a little overstimulating on a tired day.",
    "Minimalist looks tend to feel calm, focused and disciplined. Old money reads composed and "
        "unfazed. Both are common picks on calm, serene days.",
    "Cottagecore and boho feel dreamy and relaxed; Y2K and streetwear feel confident and "
        "carefree — they show up most on excited or cheerful days.",
    "Dark academia tends to feel pensive and introspective. Light academia leans joyful, curious "
        "and inspired — same structure, very different mood.",
  ];

  static const List<String> _nudges = [
    "By the way — how are you actually feeling under today's fit? No pressure to answer.",
    "Small thing, but: what's your mood been like the last day or two? I'm just checking in.",
    "Not to change the subject, but I noticed a few heavier logs recently. Want to talk about it, "
        "or just note it and move on — either's fine.",
    "Quick check-in: if today had a mood color, what would it be?",
  ];

  static const List<String> _moodResponses = [
    "That sounds like a lot to carry. You don't have to dress it up — logging it as 'Gloomy & Sad' "
        "or 'Tense & Nervous' is enough for today. There's a Support section on your Profile tab if you want someone "
        "to talk to.",
    "Thanks for telling me. Hard days are still worth logging honestly — it's how patterns show "
        "up later. Be gentle with yourself, and check the Profile tab if you want more support.",
    "I hear you. Clothes can't fix a hard day, but a soft, familiar outfit sometimes helps take "
        "one decision off your plate. And if it's more than that, the Support section on Profile "
        "is there whenever you need it.",
  ];

  static const List<String> _fallbacks = [
    "I'm mostly good for outfit and color questions right now — ask me what to wear, or how a "
        "palette tends to feel.",
    "Tell me about today's outfit — palette, style, aesthetic — and I'll tell you what it usually "
        "correlates with.",
    "Not sure I follow, but I'm here for fashion talk (and I'll gently ask how you're doing too).",
  ];

  static String greeting([String name = '']) =>
      "Hey${name.isEmpty ? '' : ' $name'}! I'm Muse — ask me about outfits, palettes or style, and I'll keep half an eye on how "
      "you're feeling too.";

  static String reply(String input, {required int turnCount}) {
    final text = input.toLowerCase();

    final hasMood = _moodKeywords.any(text.contains);
    if (hasMood) {
      return _pick(_moodResponses);
    }

    final hasFashion = _fashionKeywords.any(text.contains);
    if (hasFashion) {
      final tip = _pick(_fashionTips);
      // Subtle, occasional — not every single fashion answer gets a nudge.
      if (turnCount > 0 && turnCount % 3 == 0) {
        return '$tip\n\n${_pick(_nudges)}';
      }
      return tip;
    }

    final hasGreeting = _greetingKeywords.any((g) => text == g || text.startsWith('$g '));
    if (hasGreeting) {
      return greeting();
    }

    return _pick(_fallbacks);
  }

  static String _pick(List<String> options) => options[_random.nextInt(options.length)];
}
