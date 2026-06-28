import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/home_shell.dart';
import '../screens/budget/budget_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../widgets/common/info_screen.dart';
import '../screens/transactions/log_expense_screen.dart';
import '../screens/transactions/log_income_screen.dart';
import '../screens/jars/jar_detail_screen.dart';
import '../screens/bills/bills_screen.dart';
import '../screens/debt/debt_screen.dart';
import '../screens/summary/monthly_summary_screen.dart';
import '../screens/emergency/emergency_fund_screen.dart';
import '../screens/trends/spending_trends_screen.dart';
import '../screens/slip_up/slip_up_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          HomeShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
              routes: [
                // Nested routes for home branch (full-screen dialogs)
                GoRoute(
                  path: 'log-expense',
                  builder: (context, state) => const LogExpenseScreen(),
                ),
                GoRoute(
                  path: 'log-income',
                  builder: (context, state) => const LogIncomeScreen(),
                ),
                GoRoute(
                  path: 'jar/:jarName',
                  builder: (context, state) {
                    final jarName = state.pathParameters['jarName']!;
                    return JarDetailScreen(jarName: jarName);
                  },
                ),
                GoRoute(
                  path: 'bills',
                  builder: (context, state) => const BillsScreen(),
                ),
                GoRoute(
                  path: 'debts',
                  builder: (context, state) => const DebtScreen(),
                ),
                GoRoute(
                  path: 'summary',
                  builder: (context, state) => const MonthlySummaryScreen(),
                ),
                GoRoute(
                  path: 'emergency-fund',
                  builder: (context, state) => const EmergencyFundScreen(),
                ),
                GoRoute(
                  path: 'trends',
                  builder: (context, state) => const SpendingTrendsScreen(),
                ),
                GoRoute(
                  path: 'slip-up',
                  builder: (context, state) => const SlipUpScreen(),
                ),
              ],
            ),
          ],
        ),
        // ... other branches unchanged
        StatefulShellBranch(
          routes: [
            GoRoute(
                path: '/budget',
                builder: (context, state) => const BudgetScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(
                  path: 'settings',
                  builder: (context, state) => const SettingsScreen(),
                ),
                GoRoute(
                  path: 'info/:type',
                  builder: (context, state) {
                    final type = state.pathParameters['type']!;
                    return InfoScreen.fromType(type);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
