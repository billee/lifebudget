import 'package:flutter/material.dart';

/// A single line item inside a starter budget template.
class BudgetTemplateItem {
  final String title;
  final String frequency; // 'daily' or 'monthly'
  final double suggestedAmount;
  /// Day of month for monthly items with a typical due date (optional).
  final int? dueDayOfMonth;

  const BudgetTemplateItem({
    required this.title,
    required this.frequency,
    required this.suggestedAmount,
    this.dueDayOfMonth,
  });
}

/// Pre-built envelope sets for common budgeting situations.
class BudgetTemplate {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final List<BudgetTemplateItem> items;

  const BudgetTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.items,
  });
}

/// Starter templates — amounts are suggestions users can edit before saving.
const budgetTemplates = <BudgetTemplate>[
  BudgetTemplate(
    id: 'paycheck_to_paycheck',
    name: 'Paycheck to Paycheck',
    description: 'Rent, food, commute, and bills — the basics.',
    icon: Icons.account_balance_wallet_outlined,
    items: [
      BudgetTemplateItem(
        title: 'Rent',
        frequency: 'monthly',
        suggestedAmount: 8000,
        dueDayOfMonth: 5,
      ),
      BudgetTemplateItem(
        title: 'Food',
        frequency: 'daily',
        suggestedAmount: 150,
      ),
      BudgetTemplateItem(
        title: 'Transport',
        frequency: 'daily',
        suggestedAmount: 50,
      ),
      BudgetTemplateItem(
        title: 'Electricity',
        frequency: 'monthly',
        suggestedAmount: 1500,
        dueDayOfMonth: 15,
      ),
      BudgetTemplateItem(
        title: 'Credit Card Minimum',
        frequency: 'monthly',
        suggestedAmount: 2000,
        dueDayOfMonth: 20,
      ),
    ],
  ),
  BudgetTemplate(
    id: 'student',
    name: 'Student',
    description: 'Food, commute, school costs, and load.',
    icon: Icons.school_outlined,
    items: [
      BudgetTemplateItem(
        title: 'Food',
        frequency: 'daily',
        suggestedAmount: 100,
      ),
      BudgetTemplateItem(
        title: 'Transport',
        frequency: 'daily',
        suggestedAmount: 40,
      ),
      BudgetTemplateItem(
        title: 'School',
        frequency: 'monthly',
        suggestedAmount: 3000,
        dueDayOfMonth: 1,
      ),
      BudgetTemplateItem(
        title: 'Load / Data',
        frequency: 'monthly',
        suggestedAmount: 500,
        dueDayOfMonth: 10,
      ),
    ],
  ),
  BudgetTemplate(
    id: 'family',
    name: 'Supporting a Family',
    description: 'Household essentials for parents and dependents.',
    icon: Icons.family_restroom_outlined,
    items: [
      BudgetTemplateItem(
        title: 'Rent',
        frequency: 'monthly',
        suggestedAmount: 12000,
        dueDayOfMonth: 5,
      ),
      BudgetTemplateItem(
        title: 'Food',
        frequency: 'daily',
        suggestedAmount: 300,
      ),
      BudgetTemplateItem(
        title: 'Utilities',
        frequency: 'monthly',
        suggestedAmount: 2500,
        dueDayOfMonth: 15,
      ),
      BudgetTemplateItem(
        title: 'School',
        frequency: 'monthly',
        suggestedAmount: 5000,
        dueDayOfMonth: 1,
      ),
      BudgetTemplateItem(
        title: 'Medicine',
        frequency: 'monthly',
        suggestedAmount: 1000,
      ),
    ],
  ),
  BudgetTemplate(
    id: 'essentials_only',
    name: 'Essentials Only',
    description: 'Bare minimum — food, shelter, and one bill.',
    icon: Icons.shield_outlined,
    items: [
      BudgetTemplateItem(
        title: 'Food',
        frequency: 'daily',
        suggestedAmount: 80,
      ),
      BudgetTemplateItem(
        title: 'Rent',
        frequency: 'monthly',
        suggestedAmount: 5000,
        dueDayOfMonth: 5,
      ),
      BudgetTemplateItem(
        title: 'Bills',
        frequency: 'monthly',
        suggestedAmount: 1000,
        dueDayOfMonth: 15,
      ),
    ],
  ),
];
