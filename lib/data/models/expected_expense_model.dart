class ExpectedExpense {
  final int? id;
  final String title;
  final String frequency; // 'daily', 'weekly', 'monthly'
  final double amount;
  final String month; // e.g. '2026-06'

  ExpectedExpense({
    this.id,
    required this.title,
    required this.frequency,
    required this.amount,
    required this.month,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'frequency': frequency,
      'amount': amount,
      'month': month,
    };
  }

  factory ExpectedExpense.fromMap(Map<String, dynamic> map) {
    return ExpectedExpense(
      id: map['id'] as int,
      title: map['title'] as String,
      frequency: map['frequency'] as String,
      amount: (map['amount'] as num).toDouble(),
      month: map['month'] as String,
    );
  }
}
