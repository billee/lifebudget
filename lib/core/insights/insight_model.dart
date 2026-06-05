enum InsightType { warning, tip, achievement }

class Insight {
  final InsightType type;
  final String title;
  final String message;
  final String action;
  final String? metric;
  final String? jarName; // null = global insight

  const Insight({
    required this.type,
    required this.title,
    required this.message,
    required this.action,
    this.metric,
    this.jarName,
  });
}
