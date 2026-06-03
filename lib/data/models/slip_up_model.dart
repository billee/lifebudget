class SlipUp {
  final int? id;
  final DateTime date;
  final double? amount;
  final String mood; // 'stressed', 'guilty', 'okay', 'hopeful'
  final String? note;

  SlipUp({
    this.id,
    required this.date,
    this.amount,
    required this.mood,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'amount': amount,
      'mood': mood,
      'note': note,
    };
  }

  factory SlipUp.fromMap(Map<String, dynamic> map) {
    return SlipUp(
      id: map['id'] as int,
      date: DateTime.parse(map['date'] as String),
      amount: (map['amount'] as num?)?.toDouble(),
      mood: map['mood'] as String,
      note: map['note'] as String?,
    );
  }
}
