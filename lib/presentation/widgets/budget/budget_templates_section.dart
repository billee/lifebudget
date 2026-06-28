import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/budget_templates.dart';
import 'budget_template_sheet.dart';

/// Horizontal starter templates shown on the Budget tab.
class BudgetTemplatesSection extends ConsumerWidget {
  const BudgetTemplatesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Starter Templates',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pick a situation — adjust amounts — add envelopes in one tap.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: budgetTemplates.map((template) {
            return ActionChip(
              avatar: Icon(template.icon, size: 18, color: AppColors.primary),
              label: Text(template.name),
              labelStyle: const TextStyle(fontSize: 13),
              backgroundColor: Colors.white,
              side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
              onPressed: () =>
                  showBudgetTemplateSheet(context, ref, template),
            );
          }).toList(),
        ),
      ],
    );
  }
}
