/// Verset du jour (table `daily_verses`).
class DailyVerse {
  const DailyVerse({required this.text, required this.reference, required this.date});

  final String text;
  final String reference;
  final DateTime date;

  factory DailyVerse.fromMap(Map<String, dynamic> m) => DailyVerse(
        text: m['verse_text'] as String,
        reference: m['reference'] as String,
        date: DateTime.parse(m['display_date'] as String),
      );
}
