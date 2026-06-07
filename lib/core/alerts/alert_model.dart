import 'package:flutter/material.dart';

/// Type of alert — determines icon and priority.
enum AlertType { warning, info, achievement }

/// A single notification alert for the user.
class BudgetAlert {
  final String title;
  final String message;
  final IconData icon;
  final AlertType type;
  final DateTime timestamp;

  const BudgetAlert({
    required this.title,
    required this.message,
    required this.icon,
    required this.type,
    required this.timestamp,
  });

  Color get color {
    switch (type) {
      case AlertType.warning:
        return Colors.orange;
      case AlertType.info:
        return Colors.blue;
      case AlertType.achievement:
        return const Color(0xFF4CAF50);
    }
  }
}
