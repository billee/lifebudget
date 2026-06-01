class BudgetPlan {
  final int? id;
  final String month;
  final double totalBudget;
  final List<JarAllocation> allocations;

  BudgetPlan({
    this.id,
    required this.month,
    required this.totalBudget,
    required this.allocations,
  });

  BudgetPlan copyWith(
      {int? id, double? totalBudget, List<JarAllocation>? allocations}) {
    return BudgetPlan(
      id: id ?? this.id,
      month: month,
      totalBudget: totalBudget ?? this.totalBudget,
      allocations: allocations ?? this.allocations,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'total_budget': totalBudget,
    };
  }

  factory BudgetPlan.fromMap(Map<String, dynamic> map,
      {List<JarAllocation>? allocations}) {
    return BudgetPlan(
      id: map['id'] as int,
      month: map['month'] as String,
      totalBudget: (map['total_budget'] as num).toDouble(),
      allocations: allocations ?? [],
    );
  }
}

class JarAllocation {
  final int? id;
  final String month;
  final String jarName;
  final double allocatedAmount;

  JarAllocation({
    this.id,
    required this.month,
    required this.jarName,
    required this.allocatedAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'jar_name': jarName,
      'allocated_amount': allocatedAmount,
    };
  }

  factory JarAllocation.fromMap(Map<String, dynamic> map) {
    return JarAllocation(
      id: map['id'] as int,
      month: map['month'] as String,
      jarName: map['jar_name'] as String,
      allocatedAmount: (map['allocated_amount'] as num).toDouble(),
    );
  }
}
