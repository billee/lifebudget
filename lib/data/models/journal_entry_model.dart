class JournalEntry {
  final int? id;
  final DateTime date;
  final String mood; // 'stressed', 'okay', 'hopeful'
  final String? wentWell;
  final String? doDifferently;

  JournalEntry({
    this.id,
    required this.date,
    required this.mood,
    this.wentWell,
    this.doDifferently,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'mood': mood,
      'went_well': wentWell,
      'do_differently': doDifferently,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as int,
      date: DateTime.parse(map['date'] as String),
      mood: map['mood'] as String,
      wentWell: map['went_well'] as String?,
      doDifferently: map['do_differently'] as String?,
    );
  }
}
