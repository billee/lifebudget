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
      '''Welcome to LifeBudget — your simple daily budgeting companion!\n\n1. Set Your Income\n   Tap + on Home to log your monthly income.\n\n2. Define Expected Expenses\n   Go to the Budget tab. Pick a starter template or add expenses one by one (rent, food, commute).\n\n3. Log Daily Spending\n   Tap the + button to quickly log expenses or income as they happen.\n\n4. Check Your Daily Allowance\n   The home screen shows how much you can safely spend today based on your remaining budget.\n\n5. Pay What's Due\n   Use Pay Bill on the + button when rent or bills are due — you'll get a reminder badge.\n\n6. Had a Rough Day?\n   Tap "I slipped up" on Home or the + menu. No judgment — just get back on track.\n\nThat's it! Small steps every day lead to big results.'''
    ),
    'tips': (
      'Tips',
      '''Here are some tips to make the most of LifeBudget:\n\n• Log expenses as they happen — don't wait until the end of the day.\n\n• Set realistic daily allowances. It's better to under-promise and over-deliver.\n\n• New to budgeting? Use a starter template on the Budget tab to set up envelopes quickly.\n\n• If you slip up, use the "I Slipped Up" feature. No judgment — just get back on track.\n\n• Separate "needs" from "wants" in your jars to see where money really goes.\n\n• Want an emergency cushion? Add "Emergency Fund" as an expected expense on the Budget tab — it becomes one of your jars on Home.\n\n• Have debts? Add each payment (credit card minimum, loan installment, etc.) as an expected expense with a due date on the Budget tab. When it's due, tap Pay Bill on the + button — you'll get a reminder badge so nothing slips through.\n\n• Turn on Survival Mode in Settings when money is tight — a simpler home screen with just the essentials.\n\n• Celebrate small wins — logging every day is already a victory. 🎉'''
    ),
    'disclaimer': (
      'Disclaimer',
      '''LifeBudget is a personal budgeting tool to help you track income, spending, and savings. Please read this carefully.\n\nNot financial advice\n\nLifeBudget does not provide financial, legal, tax, or investment advice. Daily allowances, projections, insights, tips, and other information in the app are general estimates based on the data you enter. They are for personal awareness only — not recommendations about what you should do with your money.\n\nEstimates only\n\nNumbers shown in the app (including daily spending allowance, jar balances, savings rates, and reminders) depend on the accuracy and completeness of your entries. Actual results may differ. The app cannot predict unexpected expenses, income changes, interest rates, or other real-world factors.\n\nYour responsibility\n\nYou are solely responsible for your financial decisions and for verifying that the information you enter is correct. For important decisions — such as debt, loans, investments, taxes, or major purchases — consult a qualified financial advisor, accountant, or other professional.\n\nNo guarantees\n\nLifeBudget is provided "as is" without warranties of any kind. We do not guarantee that using the app will improve your finances, help you save money, or achieve any particular outcome.\n\nEmergencies and hardship\n\nIf you are in financial distress, contact a licensed professional or local support services. LifeBudget is not a substitute for professional help.\n\nBy using LifeBudget, you acknowledge that you understand and accept this disclaimer.'''
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
      '''LifeBudget v1.0\n\nA simple, thoughtful budgeting app designed to help you spend mindfully and save consistently.\n\nBuilt with Flutter ❤️\n\nLifeBudget focuses on daily awareness rather than monthly overwhelm. By showing you what you can safely spend each day, it turns budgeting into a daily habit instead of a chore.\n\nFeatures:\n• Daily spending allowance\n• Jar-based budgeting with starter templates\n• Pay bills & due expense reminders\n• I Slipped Up — compassionate recovery\n• Survival mode for tight times\n\nWe hope LifeBudget helps you build a healthier relationship with money.'''
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
