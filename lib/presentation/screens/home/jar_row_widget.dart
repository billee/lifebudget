import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'jar_card_widget.dart';
import '../../../core/constants/app_colors.dart';

class JarRowWidget extends StatelessWidget {
  final Map<String, double> jarSpent;
  const JarRowWidget({super.key, required this.jarSpent});

  static const _jarBudgets = {
    'food': 1200.0,
    'rent': 5000.0,
    'transport': 800.0,
    'fun': 500.0,
    'health': 300.0,
  };

  final _jarMeta = const {
    'food': _JarMeta(AppColors.food, FontAwesomeIcons.utensils),
    'rent': _JarMeta(AppColors.rent, FontAwesomeIcons.house),
    'transport': _JarMeta(AppColors.transport, FontAwesomeIcons.bus),
    'fun': _JarMeta(AppColors.fun, FontAwesomeIcons.faceSmile),
    'health': _JarMeta(AppColors.health, FontAwesomeIcons.hospital),
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _jarBudgets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final jarName = _jarBudgets.keys.elementAt(index);
          final total = _jarBudgets[jarName]!;
          final spent = jarSpent[jarName] ?? 0.0;
          final remaining = total - spent;
          final meta = _jarMeta[jarName]!;
          return JarCardWidget(
            icon: meta.icon,
            name: jarName[0].toUpperCase() + jarName.substring(1),
            remaining: remaining < 0 ? 0 : remaining,
            total: total,
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
