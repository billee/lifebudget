import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'info_screen.dart';

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
        _navigateToInfo(context, value);
      },
      itemBuilder: (context) => [
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

  void _navigateToInfo(BuildContext context, String key) {
    final data = _contentMap[key]!;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InfoScreen(title: data.$1, body: data.$2),
      ),
    );
  }

  /// Content for each info page.
  static final Map<String, (String, String)> _contentMap = {
    'how_to_use': (
      'How to Use',
      '''Welcome to LifeBudget — your simple daily budgeting companion!

1. Set Your Income
   Go to the Budget tab and add your monthly income.

2. Define Expected Expenses
   Add recurring expenses (rent, food, commute) in the Budget tab. These help the app project your spending.

3. Log Daily Spending
   Tap the + button to quickly log expenses or income as they happen.

4. Check Your Daily Allowance
   The home screen shows how much you can safely spend today based on your remaining budget.

5. Track Your Goals
   Set savings goals in the Goals tab and watch your progress grow.

6. Reflect in Your Journal
   Use the Journal tab to note how your day went financially.

7. Review Insights
   The Insights card on the home screen gives you tips based on your spending patterns.

That's it! Small steps every day lead to big results.'''
    ),
    'tips': (
      'Tips',
      '''Here are some tips to make the most of LifeBudget:

• Log expenses as they happen — don't wait until the end of the day.

• Set realistic daily allowances. It's better to under-promise and over-deliver.

• Use the "What If" screen to see how small weekly savings add up over months.

• If you slip up, use the "I Slipped Up" feature. No judgment — just get back on track.

• Review your Insights weekly. They learn from your patterns.

• Keep your goals visible. Seeing progress motivates consistency.

• Separate "needs" from "wants" in your jars to see where money really goes.

• Celebrate milestones — the app will cheer you on! 🎉'''
    ),
    'privacy': (
      'Privacy Policy',
      '''Your privacy matters to us.

LifeBudget stores all your data locally on your device. We do not collect, transmit, or share any personal financial information.

• No account required — your data stays on your phone.
• No cloud sync — everything is stored in local storage.
• No analytics on your financial data.
• Ad banners are provided by Google AdMob, which may use device identifiers for ad personalization. You can opt out in your device settings.

If you ever export or share data from the app, that data is under your control.

We believe budgeting should be private. Period.'''
    ),
    'terms': (
      'Terms of Use',
      '''By using LifeBudget, you agree to the following:

• This app is provided "as is" for personal budgeting purposes.
• Financial projections and insights are estimates only and should not be considered financial advice.
• You are responsible for the accuracy of the data you enter.
• The app may display ads through Google AdMob.
• We reserve the right to update these terms at any time.

LifeBudget is a tool to help you track spending — it does not guarantee financial outcomes.

Thank you for using LifeBudget!'''
    ),
    'about': (
      'About',
      '''LifeBudget v1.0

A simple, thoughtful budgeting app designed to help you spend mindfully and save consistently.

Built with Flutter ❤️

LifeBudget focuses on daily awareness rather than monthly overwhelm. By showing you what you can safely spend each day, it turns budgeting into a daily habit instead of a chore.

Features:
• Daily spending allowance
• Jar-based budgeting
• Savings goal tracking
• Spending insights
• Journal reflections
• What-if projections

We hope LifeBudget helps you build a healthier relationship with money.'''
    ),
  };
}
