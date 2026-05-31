import 'package:flutter/material.dart';
import 'jar_card_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class JarRowWidget extends StatelessWidget {
  const JarRowWidget({super.key});

  // Mock jar data – each jar now uses an IconData instead of an emoji
  final jars = const [
    _JarData(AppStrings.jarFood, AppColors.food, 1200, 800, Icons.restaurant),
    _JarData(AppStrings.jarRent, AppColors.rent, 5000, 0, Icons.home),
    _JarData(AppStrings.jarTransport, AppColors.transport, 800, 200,
        Icons.directions_bus),
    _JarData(AppStrings.jarFun, AppColors.fun, 500, 300, Icons.celebration),
    _JarData(
        AppStrings.jarHealth, AppColors.health, 300, 100, Icons.local_hospital),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: jars.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final jar = jars[index];
          return JarCardWidget(
            icon: jar.icon,
            name: jar.name,
            remaining: jar.remaining,
            total: jar.remaining + jar.used,
            color: jar.color,
          );
        },
      ),
    );
  }
}

class _JarData {
  final String name;
  final Color color;
  final double remaining;
  final double used;
  final IconData icon;

  const _JarData(this.name, this.color, this.remaining, this.used, this.icon);
}
