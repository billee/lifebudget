import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'jar_card_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/budget_plan_model.dart'; // JarAllocation

class JarRowWidget extends StatelessWidget {
  final List<JarAllocation> allocations;
  final Map<String, double> jarSpent; // jar name → total spent
  final double totalIncome; // total income for the month

  const JarRowWidget({
    super.key,
    required this.allocations,
    required this.jarSpent,
    required this.totalIncome,
  });

  static const _jarMeta = {
    'rent': _JarMeta(AppColors.rent, FontAwesomeIcons.house),
    'food': _JarMeta(AppColors.food, FontAwesomeIcons.utensils),
    'transport': _JarMeta(AppColors.transport, FontAwesomeIcons.bus),
    'health': _JarMeta(AppColors.health, FontAwesomeIcons.hospital),
    'fun': _JarMeta(AppColors.fun, FontAwesomeIcons.faceSmile),
    'savings': _JarMeta(AppColors.primary, FontAwesomeIcons.piggyBank),
  };

  @override
  Widget build(BuildContext context) {
    // Sort jars: non-zero remaining first (by remaining desc), then zero remaining
    final sortedAllocs = List<JarAllocation>.from(allocations)
      ..sort((a, b) {
        final aAmount = totalIncome * (a.percentage / 100);
        final bAmount = totalIncome * (b.percentage / 100);
        final aSpent = jarSpent[a.jarName] ?? 0.0;
        final bSpent = jarSpent[b.jarName] ?? 0.0;
        final aRemaining = aAmount - aSpent;
        final bRemaining = bAmount - bSpent;

        // Zero remaining goes to the end
        if (aRemaining <= 0 && bRemaining > 0) return 1;
        if (bRemaining <= 0 && aRemaining > 0) return -1;
        // Both non-zero: sort by remaining descending
        if (aRemaining > 0 && bRemaining > 0)
          return bRemaining.compareTo(aRemaining);
        // Both zero: keep original order (or sort by allocated amount)
        return 0;
      });

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sortedAllocs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final alloc = sortedAllocs[index];
          final allocatedAmount = totalIncome * (alloc.percentage / 100);
          final spent = jarSpent[alloc.jarName] ?? 0.0;
          final remaining = allocatedAmount - spent;
          final meta = _jarMeta[alloc.jarName] ??
              _JarMeta(Colors.grey, FontAwesomeIcons.question);

          return JarCardWidget(
            icon: meta.icon,
            name: alloc.jarName[0].toUpperCase() + alloc.jarName.substring(1),
            remaining: remaining < 0 ? 0 : remaining,
            total: allocatedAmount,
            color: meta.color,
          );
        },
      ),
    );
  }
}

class _JarMeta {
  final Color color;
  final IconData icon;
  const _JarMeta(this.color, this.icon);
}
