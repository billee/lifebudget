class DebtModel {
  final int? id;
  final String name; // e.g., "Credit Card", "Student Loan", "Car Loan"
  final double totalAmount; // Original debt amount
  final double currentBalance; // Current remaining balance
  final double interestRate; // Annual interest rate (0 if no interest)
  final double minimumPayment; // Minimum monthly payment
  final DateTime dueDate; // Next payment due date
  final String? notes; // Additional notes

  DebtModel({
    this.id,
    required this.name,
    required this.totalAmount,
    required this.currentBalance,
    this.interestRate = 0,
    required this.minimumPayment,
    required this.dueDate,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'totalAmount': totalAmount,
      'currentBalance': currentBalance,
      'interestRate': interestRate,
      'minimumPayment': minimumPayment,
      'dueDate': dueDate.toIso8601String(),
      'notes': notes,
    };
  }

  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      currentBalance: (map['currentBalance'] as num).toDouble(),
      interestRate: (map['interestRate'] as num?)?.toDouble() ?? 0,
      minimumPayment: (map['minimumPayment'] as num).toDouble(),
      dueDate: DateTime.parse(map['dueDate'] as String),
      notes: map['notes'] as String?,
    );
  }

  DebtModel copyWith({
    int? id,
    String? name,
    double? totalAmount,
    double? currentBalance,
    double? interestRate,
    double? minimumPayment,
    DateTime? dueDate,
    String? notes,
  }) {
    return DebtModel(
      id: id ?? this.id,
      name: name ?? this.name,
      totalAmount: totalAmount ?? this.totalAmount,
      currentBalance: currentBalance ?? this.currentBalance,
      interestRate: interestRate ?? this.interestRate,
      minimumPayment: minimumPayment ?? this.minimumPayment,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
    );
  }

  // Calculate progress percentage (0-100)
  double get progressPercentage {
    if (totalAmount == 0) return 100;
    final paid = totalAmount - currentBalance;
    return (paid / totalAmount * 100).clamp(0, 100);
  }

  // Check if debt is paid off
  bool get isPaidOff => currentBalance <= 0;

  // Calculate amount paid
  double get amountPaid => totalAmount - currentBalance;

  // Check if payment is due soon (within X days)
  bool isDueSoon({int days = 7}) {
    if (isPaidOff) return false;
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    return difference >= 0 && difference <= days;
  }

  // Check if payment is overdue
  bool isOverdue() {
    if (isPaidOff) return false;
    return dueDate.isBefore(DateTime.now());
  }

  // Days until next payment (negative if overdue)
  int daysUntilDue() {
    return dueDate.difference(DateTime.now()).inDays;
  }
}
