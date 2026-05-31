import 'package:flutter/material.dart';
import 'jar_card_widget.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

class JarRowWidget extends StatelessWidget {
  const JarRowWidget({super.key});

  // Mock jar data
  final jars = const [
    _JarData(AppStrings.jarFood, AppColors.food, 1200, 800), // remaining, used
    _JarData(AppStrings.jarRent, AppColors.rent, 5000, 0),
    _JarData(AppStrings.jarTransport, AppColors.transport, 800, 200),
    _JarData(AppStrings.jarFun, AppColors.fun, 500, 300),
    _JarData(AppStrings.jarHealth, AppColors.health, 300, 100),
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
            emoji: jar.emoji,
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
  String get emoji {
    switch (name) {
      case AppStrings.jarFood:
        return '🍚';
      case AppStrings.jarRent:
        return '🏠';
      case AppStrings.jarTransport:
        return '🚌';
      case AppStrings.jarFun:
        return '😊';
      case AppStrings.jarHealth:
        return '💊';
      default:
        return '💵';
    }
  }

  const _JarData(this.name, this.color, this.remaining, this.used);
}
