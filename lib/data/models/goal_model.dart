class Goal {
  final int? id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final String emoji;
  final bool isCompleted;
  final DateTime createdDate;

  Goal({
    this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.emoji,
    required this.isCompleted,
    required this.createdDate,
  });

  double get progressPercent =>
      targetAmount > 0 ? currentAmount / targetAmount : 0;

  Goal copyWith({
    int? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    String? emoji,
    bool? isCompleted,
    DateTime? createdDate,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      emoji: emoji ?? this.emoji,
      isCompleted: isCompleted ?? this.isCompleted,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'emoji': emoji,
      'is_completed': isCompleted ? 1 : 0,
      'created_date': createdDate.toIso8601String(),
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as int,
      title: map['title'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      currentAmount: (map['current_amount'] as num).toDouble(),
      emoji: map['emoji'] as String,
      isCompleted: (map['is_completed'] as int) == 1,
      createdDate: DateTime.parse(map['created_date'] as String),
    );
  }
}
