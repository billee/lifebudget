class ExpectedExpense {
  final int? id;
  final String title;
  final String frequency; // 'daily' or 'monthly'
  final double amount;
  final String month; // 'YYYY-MM'
  final DateTime? dueDate;
  final bool isPaid; // NEW

  ExpectedExpense({
    this.id,
    required this.title,
    required this.frequency,
    required this.amount,
    required this.month,
    this.dueDate,
    this.isPaid = false, // default to not paid
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'frequency': frequency,
      'amount': amount,
      'month': month,
      'due_date': dueDate?.toIso8601String().substring(0, 10),
      'is_paid': isPaid ? 1 : 0,
    };
  }

  factory ExpectedExpense.fromMap(Map<String, dynamic> map) {
    return ExpectedExpense(
      id: map['id'],
      title: map['title'],
      frequency: map['frequency'],
      amount: map['amount'],
      month: map['month'],
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      isPaid: (map['is_paid'] ?? 0) == 1,
    );
  }

  ExpectedExpense copyWith({
    int? id,
    String? title,
    String? frequency,
    double? amount,
    String? month,
    DateTime? dueDate,
    bool? isPaid,
  }) {
    return ExpectedExpense(
      id: id ?? this.id,
      title: title ?? this.title,
      frequency: frequency ?? this.frequency,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}
