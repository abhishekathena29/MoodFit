import 'dart:math';

/// Local, rule-based reply engine for the Muse chat tab. There's no LLM or
/// network call here — MoodFit is local-first, so this is a small keyword
/// matcher that answers fashion questions directly and, every few turns,
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
    "Sage and other soft greens tend to read calm and grounded — good for days that "
        "feel a little scattered. Pair with warm beige to keep it from feeling cold.",
    "Cooler blues (blue-mist) read quiet and focused on most people. If today feels "
        "foggy, a warm amber layer on top can lift the whole outfit — and the mood with it.",
    "Amber and warm tones show up on your heavier days more than any other palette. "
        "That's not a rule, just a pattern — try it on a good day too and see how it feels.",
    "Minimalist silhouettes pair really well with a 'quiet' mood tag — fewer decisions, "
        "fewer things pulling at your attention.",
    "Boho and cottagecore looks tend to log alongside 'grateful' and 'bright' moods in "
        "your history — soft textures, easy movement.",
    "Structured, classic pieces show up a lot on 'focused' days. If you've got something "
        "big today, that might be the fit to reach for.",
    "A pop of one warm color in an otherwise neutral outfit is a small, low-effort way "
        "to shift how a look — and a day — feels.",
  ];

  static const List<String> _nudges = [
    "By the way — how are you actually feeling under today's fit? No pressure to answer.",
    "Small thing, but: what's your mood been like the last day or two? I'm just checking in.",
    "Not to change the subject, but I noticed a few heavier logs recently. Want to talk about it, "
        "or just note it and move on — either's fine.",
    "Quick check-in: if today had a mood color, what would it be?",
  ];

  static const List<String> _moodResponses = [
    "That sounds like a lot to carry. You don't have to dress it up — logging it as 'Heavy' "
        "is enough for today. There's a Support section on your Profile tab if you want someone "
        "to talk to.",
    "Thanks for telling me. Heavy days are still worth logging honestly — it's how patterns show "
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

  static String greeting() =>
      "Hey! I'm Muse — ask me about outfits, palettes or style, and I'll keep half an eye on how "
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
