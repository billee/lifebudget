import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/budget_templates.dart';
import '../../../data/models/expected_expense_model.dart';
import '../../../services/month_transition_service.dart';
import '../../providers/budget_provider.dart';
import '../../providers/due_items_provider.dart';
import '../../providers/expected_expenses_provider.dart';

/// Bottom sheet to review template amounts and add envelopes to the budget.
Future<void> showBudgetTemplateSheet(
  BuildContext context,
  WidgetRef ref,
  BudgetTemplate template,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _BudgetTemplateSheet(template: template),
  );
}

class _BudgetTemplateSheet extends ConsumerStatefulWidget {
  final BudgetTemplate template;

  const _BudgetTemplateSheet({required this.template});

  @override
  ConsumerState<_BudgetTemplateSheet> createState() =>
      _BudgetTemplateSheetState();
}

class _BudgetTemplateSheetState extends ConsumerState<_BudgetTemplateSheet> {
  late final List<TextEditingController> _amountControllers;
  late final List<bool> _included;

  @override
  void initState() {
    super.initState();
    _amountControllers = widget.template.items
        .map((item) => TextEditingController(
              text: item.suggestedAmount.toStringAsFixed(0),
            ))
        .toList();
    _included = List.filled(widget.template.items.length, true);
  }

  @override
  void dispose() {
    for (final c in _amountControllers) {
      c.dispose();
    }
    super.dispose();
  }

  String _currentMonth() {
    final now = MonthTransitionService.debugOverrideDate ?? DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  Future<void> _apply() async {
    final existing = await ref.read(expectedExpensesProvider.future);
    final existingTitles = existing
        .map((e) => e.title.toLowerCase().trim())
        .toSet();

    final repo = ref.read(expectedExpenseRepositoryProvider);
    final month = _currentMonth();
    var added = 0;
    var skipped = 0;

    for (var i = 0; i < widget.template.items.length; i++) {
      if (!_included[i]) continue;

      final item = widget.template.items[i];
      final titleKey = item.title.toLowerCase().trim();
      if (existingTitles.contains(titleKey)) {
        skipped++;
        continue;
      }

      final amount = double.tryParse(_amountControllers[i].text.trim());
      if (amount == null || amount <= 0) continue;

      DateTime? dueDate;
      if (item.dueDayOfMonth != null) {
        final now = MonthTransitionService.debugOverrideDate ?? DateTime.now();
        final lastDay = DateTime(now.year, now.month + 1, 0).day;
        final day = item.dueDayOfMonth!.clamp(1, lastDay);
        dueDate = DateTime(now.year, now.month, day);
      }

      await repo.insert(ExpectedExpense(
        title: item.title,
        frequency: item.frequency,
        amount: amount,
        month: month,
        dueDate: dueDate,
      ));
      added++;
    }

    ref.invalidate(expectedExpensesProvider);
    ref.invalidate(budgetStateProvider);
    ref.invalidate(dueItemsProvider);

    if (!context.mounted) return;
    Navigator.of(context).pop();

    final message = skipped > 0
        ? 'Added $added envelope${added == 1 ? '' : 's'}. $skipped already existed — skipped.'
        : 'Added $added envelope${added == 1 ? '' : 's'} to your budget.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(added > 0 ? message : 'Nothing added — check amounts or duplicates.'),
        backgroundColor: added > 0 ? AppColors.onTrack : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(widget.template.icon,
                      color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.template.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.template.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Edit amounts to match your situation, then tap Add.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: widget.template.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = widget.template.items[index];
                    final freqLabel =
                        item.frequency[0].toUpperCase() + item.frequency.substring(1);
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _included[index],
                            activeColor: AppColors.primary,
                            onChanged: (v) {
                              setState(() => _included[index] = v ?? false);
                            },
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  freqLabel +
                                      (item.dueDayOfMonth != null
                                          ? ' • due day ${item.dueDayOfMonth}'
                                          : ''),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: _amountControllers[index],
                              enabled: _included[index],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                prefixText: '₱ ',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Add to Budget',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
