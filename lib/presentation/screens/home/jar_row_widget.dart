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

  // Color and icon for each jar
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
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: allocations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final alloc = allocations[index];
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
