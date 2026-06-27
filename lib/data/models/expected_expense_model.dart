class ExpectedExpense {
  final int? id;
  final String title;
  final String frequency; // 'daily' or 'monthly'
  final double amount;
  final String month; // Format: 'YYYY-MM'
  final DateTime? dueDate; // NEW: optional due date for the expense

  ExpectedExpense({
    this.id,
    required this.title,
    required this.frequency,
    required this.amount,
    required this.month,
    this.dueDate,
  });

  /// Converts this model to a Map for database insertion/update.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'frequency': frequency,
      'amount': amount,
      'month': month,
      'due_date': dueDate?.toIso8601String().substring(0, 10), // YYYY-MM-DD
    };
  }

  /// Creates an ExpectedExpense from a database Map.
  factory ExpectedExpense.fromMap(Map<String, dynamic> map) {
    return ExpectedExpense(
      id: map['id'],
      title: map['title'],
      frequency: map['frequency'],
      amount: map['amount'],
      month: map['month'],
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
    );
  }

  /// Returns a copy of this expense with optional updated fields.
  ExpectedExpense copyWith({
    int? id,
    String? title,
    String? frequency,
    double? amount,
    String? month,
    DateTime? dueDate,
  }) {
    return ExpectedExpense(
      id: id ?? this.id,
      title: title ?? this.title,
      frequency: frequency ?? this.frequency,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}
