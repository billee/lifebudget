import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'app_menu_button.dart';

/// Reusable full-screen info page (Privacy, Terms, Tips, About, etc.)
class InfoScreen extends StatelessWidget {
  final String title;
  final String body;

  const InfoScreen({super.key, required this.title, required this.body});

  /// Factory constructor to create InfoScreen from type
  factory InfoScreen.fromType(String type) {
    final data = _contentMap[type];
    if (data == null) {
      return const InfoScreen(title: 'Not Found', body: 'Page not found.');
    }
    return InfoScreen(title: data.$1, body: data.$2);
  }

  /// Content for each info page.
  static final Map<String, (String, String)> _contentMap = {
    'how_to_use': (
      'How to Use',
      '''Welcome to LifeBudget — your simple daily budgeting companion!\n\n1. Set Your Income\n   Go to the Budget tab and add your monthly income.\n\n2. Define Expected Expenses\n   Add recurring expenses (rent, food, commute) in the Budget tab. These help the app project your spending.\n\n3. Log Daily Spending\n   Tap the + button to quickly log expenses or income as they happen.\n\n4. Check Your Daily Allowance\n   The home screen shows how much you can safely spend today based on your remaining budget.\n\n5. Track Your Goals\n   Set savings goals in the Goals tab and watch your progress grow.\n\n6. Reflect in Your Journal\n   Use the Journal tab to note how your day went financially.\n\n7. Review Insights\n   The Insights card on the home screen gives you tips based on your spending patterns.\n\nThat's it! Small steps every day lead to big results.'''
    ),
    'tips': (
      'Tips',
      '''Here are some tips to make the most of LifeBudget:\n\n• Log expenses as they happen — don't wait until the end of the day.\n\n• Set realistic daily allowances. It's better to under-promise and over-deliver.\n\n• Use the "What If" screen to see how small weekly savings add up over months.\n\n• If you slip up, use the "I Slipped Up" feature. No judgment — just get back on track.\n\n• Review your Insights weekly. They learn from your patterns.\n\n• Keep your goals visible. Seeing progress motivates consistency.\n\n• Separate "needs" from "wants" in your jars to see where money really goes.\n\n• Want an emergency cushion? Add "Emergency Fund" as an expected expense on the Budget tab — it becomes one of your jars on Home.\n\n• Have debts? Add each payment (credit card minimum, loan installment, etc.) as an expected expense with a due date on the Budget tab. When it's due, tap Pay Bill on the + button — you'll get a reminder badge so nothing slips through.\n\n• Celebrate milestones — the app will cheer you on! 🎉'''
    ),
    'privacy': (
      'Privacy Policy',
      '''Your privacy matters to us.\n\nLifeBudget stores all your data locally on your device. We do not collect, transmit, or share any personal financial information.\n\n• No account required — your data stays on your phone.\n• No cloud sync — everything is stored in local storage.\n• No analytics on your financial data.\n• Ad banners are provided by Google AdMob, which may use device identifiers for ad personalization. You can opt out in your device settings.\n\nIf you ever export or share data from the app, that data is under your control.\n\nWe believe budgeting should be private. Period.'''
    ),
    'terms': (
      'Terms of Use',
      '''By using LifeBudget, you agree to the following:\n\n• This app is provided "as is" for personal budgeting purposes.\n• Financial projections and insights are estimates only and should not be considered financial advice.\n• You are responsible for the accuracy of the data you enter.\n• The app may display ads through Google AdMob.\n• We reserve the right to update these terms at any time.\n\nLifeBudget is a tool to help you track spending — it does not guarantee financial outcomes.\n\nThank you for using LifeBudget!'''
    ),
    'about': (
      'About',
      '''LifeBudget v1.0\n\nA simple, thoughtful budgeting app designed to help you spend mindfully and save consistently.\n\nBuilt with Flutter ❤️\n\nLifeBudget focuses on daily awareness rather than monthly overwhelm. By showing you what you can safely spend each day, it turns budgeting into a daily habit instead of a chore.\n\nFeatures:\n• Daily spending allowance\n• Jar-based budgeting\n• Savings goal tracking\n• Spending insights\n• Journal reflections\n• What-if projections\n\nWe hope LifeBudget helps you build a healthier relationship with money.'''
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [AppMenuButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          body,
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
