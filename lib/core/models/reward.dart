/// Mirrors `REWARDS` from lib/moodfit-store.ts.
class Reward {
  final int at;
  final String name;
  final String emoji;
  final String desc;

  const Reward({required this.at, required this.name, required this.emoji, required this.desc});
}

const List<Reward> kRewards = [
  Reward(at: 3, name: 'First Bloom', emoji: '🌱', desc: 'Logged 3 days in a row'),
  Reward(at: 7, name: 'Weekly Weaver', emoji: '🧵', desc: 'A full week of reflection'),
  Reward(at: 14, name: 'Steady Light', emoji: '🕯️', desc: 'Two weeks of tuning in'),
  Reward(at: 30, name: 'Palette Sage', emoji: '🪴', desc: 'A month of wardrobe wisdom'),
];

class LevelInfo {
  final int level;
  final int into;
  final int next;

  const LevelInfo({required this.level, required this.into, required this.next});
}

LevelInfo levelFromXp(int xp) {
  final level = (xp ~/ 100) + 1;
  final into = xp % 100;
  return LevelInfo(level: level, into: into, next: 100);
}
