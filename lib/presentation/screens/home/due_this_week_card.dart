import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/due_items_provider.dart';
import '../../widgets/due_items_sheet.dart';

/// Shows bills and expected expenses due within the next 7 days (or overdue).
class DueThisWeekCard extends ConsumerWidget {
  const DueThisWeekCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueThisWeekAsync = ref.watch(dueItemsThisWeekProvider);

    return dueThisWeekAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        final preview = items.take(3).toList();
        final hasMore = items.length > preview.length;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: items.any((i) => i.isOverdue)
                  ? AppColors.critical.withOpacity(0.3)
                  : AppColors.primary.withOpacity(0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    items.any((i) => i.isOverdue)
                        ? Icons.warning_amber_rounded
                        : Icons.event_note,
                    size: 20,
                    color: items.any((i) => i.isOverdue)
                        ? AppColors.critical
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Due This Week',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => DueItemsSheet.show(context, ref),
                    child: const Text('Pay all'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ...preview.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₱${item.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DueItemTile.statusLabel(item),
                        style: TextStyle(
                          fontSize: 11,
                          color: DueItemTile.statusColor(item),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (hasMore)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+ ${items.length - preview.length} more',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
