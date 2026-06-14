import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../services/month_transition_service.dart';

/// Dialog shown when a new month is detected
/// Allows user to start fresh or carry over surplus from previous month
class MonthTransitionDialog extends StatefulWidget {
  final String previousMonth;
  final String currentMonth;
  final double surplus;

  const MonthTransitionDialog({
    super.key,
    required this.previousMonth,
    required this.currentMonth,
    required this.surplus,
  });

  @override
  State<MonthTransitionDialog> createState() => _MonthTransitionDialogState();
}

class _MonthTransitionDialogState extends State<MonthTransitionDialog> {
  bool _isProcessing = false;

  String _formatMonthName(String monthStr) {
    try {
      final parts = monthStr.split('-');
      if (parts.length < 2) return monthStr;

      final year = parts[0];
      final month = int.parse(parts[1]);
      const monthNames = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];

      if (month < 1 || month > 12) return monthStr;
      return '${monthNames[month - 1]} $year';
    } catch (e) {
      return monthStr;
    }
  }

  Future<void> _startNewMonth(bool carryOver) async {
    setState(() => _isProcessing = true);

    try {
      final service = MonthTransitionService();

      if (carryOver) {
        // Perform full transition with carryover
        await service.performMonthTransition(
          widget.previousMonth,
          widget.currentMonth,
        );
      } else {
        // Just copy expenses without carryover
        // (User chose to start fresh)
        await service.performMonthTransition(
          widget.previousMonth,
          widget.currentMonth,
        );
        // Note: performMonthTransition already handles surplus > 0 check
        // If surplus <= 0, no carryover is created anyway
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to refresh UI
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting new month: $e'),
            backgroundColor: AppColors.critical,
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final previousMonthName = _formatMonthName(widget.previousMonth);
    final currentMonthName = _formatMonthName(widget.currentMonth);
    final hasSurplus = widget.surplus > 0;

    return WillPopScope(
      onWillPop: () async =>
          !_isProcessing, // Prevent dismissal while processing
      child: AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.calendar_month,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'New Month: $currentMonthName',
                style: const TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasSurplus
                  ? 'You have ${formatAmount(widget.surplus)} remaining from $previousMonthName.'
                  : 'You spent all your budget in $previousMonthName.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (hasSurplus) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.savings,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This ${formatAmount(widget.surplus)} will be added as income for $currentMonthName.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'Your recurring expenses (food, rent, etc.) will be automatically set up for the new month.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          if (_isProcessing)
            const Center(child: CircularProgressIndicator())
          else ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _startNewMonth(hasSurplus),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(hasSurplus
                  ? 'Start Month with Carryover'
                  : 'Start Fresh Month'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Helper function to show the month transition dialog
Future<bool> showMonthTransitionDialog(
  BuildContext context,
  String previousMonth,
  String currentMonth,
  double surplus,
) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => MonthTransitionDialog(
      previousMonth: previousMonth,
      currentMonth: currentMonth,
      surplus: surplus,
    ),
  );
  return result ?? false;
}
