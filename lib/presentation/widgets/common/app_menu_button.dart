import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

/// Reusable hamburger menu button that shows a popup with:
/// Privacy Policy, Terms of Use, How to Use, Tips, and About.
class AppMenuButton extends StatelessWidget {
  /// Override icon color (e.g. white for dark headers).
  final Color? iconColor;

  const AppMenuButton({super.key, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.menu_rounded, color: iconColor ?? Colors.white),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'settings') {
          context.go('/profile/settings');
        } else {
          context.go('/profile/info/$value');
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'settings',
          child: Row(children: [
            Icon(Icons.settings, size: 20, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Settings'),
          ]),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'how_to_use',
          child: Row(children: [
            Icon(Icons.help_outline, size: 20, color: AppColors.primary),
            SizedBox(width: 12),
            Text('How to Use'),
          ]),
        ),
        const PopupMenuItem(
          value: 'tips',
          child: Row(children: [
            Icon(Icons.lightbulb_outline, size: 20, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Tips'),
          ]),
        ),
        const PopupMenuItem(
          value: 'privacy',
          child: Row(children: [
            Icon(Icons.lock_outline, size: 20, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Privacy Policy'),
          ]),
        ),
        const PopupMenuItem(
          value: 'terms',
          child: Row(children: [
            Icon(Icons.description_outlined,
                size: 20, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Terms of Use'),
          ]),
        ),
        const PopupMenuItem(
          value: 'about',
          child: Row(children: [
            Icon(Icons.info_outline, size: 20, color: AppColors.primary),
            SizedBox(width: 12),
            Text('About'),
          ]),
        ),
      ],
    );
  }
}
