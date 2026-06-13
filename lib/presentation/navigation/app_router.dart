import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/home_shell.dart';
import '../screens/budget/budget_screen.dart';
import '../screens/journal/journal_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/transactions/log_expense_screen.dart';
import '../screens/transactions/log_income_screen.dart';
import '../screens/jars/jar_detail_screen.dart';

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
                path: '/journal',
                builder: (context, state) => const JournalScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen()),
          ],
        ),
      ],
    ),
  ],
);
