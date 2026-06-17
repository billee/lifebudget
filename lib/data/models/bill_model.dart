class BillModel {
  final int? id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final String
      category; // Which budget category to use (e.g., "Rent", "Utilities")
  final bool isRecurring; // Monthly recurring or one-time
  final bool isPaid; // Has this bill been paid?
  final DateTime? paidDate; // When was it paid?

  BillModel({
    this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.category,
    this.isRecurring = false,
    this.isPaid = false,
    this.paidDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'category': category,
      'isRecurring': isRecurring ? 1 : 0,
      'isPaid': isPaid ? 1 : 0,
      'paidDate': paidDate?.toIso8601String(),
    };
  }

  factory BillModel.fromMap(Map<String, dynamic> map) {
    return BillModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      dueDate: DateTime.parse(map['dueDate'] as String),
      category: map['category'] as String,
      isRecurring: (map['isRecurring'] as int) == 1,
      isPaid: (map['isPaid'] as int) == 1,
      paidDate: map['paidDate'] != null
          ? DateTime.parse(map['paidDate'] as String)
          : null,
    );
  }

  BillModel copyWith({
    int? id,
    String? title,
    double? amount,
    DateTime? dueDate,
    String? category,
    bool? isRecurring,
    bool? isPaid,
    DateTime? paidDate,
  }) {
    return BillModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      isRecurring: isRecurring ?? this.isRecurring,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
    );
  }

  // Check if bill is due soon (within X days)
  bool isDueSoon({int days = 3}) {
    if (isPaid) return false;
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    return difference >= 0 && difference <= days;
  }

  // Check if bill is overdue
  bool isOverdue() {
    if (isPaid) return false;
    return dueDate.isBefore(DateTime.now());
  }

  // Days until due (negative if overdue)
  int daysUntilDue() {
    return dueDate.difference(DateTime.now()).inDays;
  }
}
