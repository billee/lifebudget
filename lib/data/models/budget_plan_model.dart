class JarAllocation {
  final int? id;
  final String month;
  final String jarName;
  final double percentage; // 0.0 - 100.0

  JarAllocation({
    this.id,
    required this.month,
    required this.jarName,
    required this.percentage,
  });

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'jar_name': jarName,
      'percentage': percentage,
    };
  }

  factory JarAllocation.fromMap(Map<String, dynamic> map) {
    return JarAllocation(
      id: map['id'] as int,
      month: map['month'] as String,
      jarName: map['jar_name'] as String,
      percentage: (map['percentage'] as num).toDouble(),
    );
  }
}
