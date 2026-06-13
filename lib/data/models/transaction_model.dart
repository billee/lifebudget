class TransactionModel {
  final int? id;
  final String type;
  final String jar;
  final double amount;
  final DateTime date;
  final String? note;
  final String? source; // new field: income source (e.g., Salary, Freelance)

  TransactionModel({
    this.id,
    required this.type,
    required this.jar,
    required this.amount,
    required this.date,
    this.note,
    this.source, // optional source
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'jar': jar,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'source': source, // include source
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int,
      type: map['type'] as String,
      jar: map['jar'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      source: map['source'] as String?, // read source, may be null for old rows
    );
  }
}
