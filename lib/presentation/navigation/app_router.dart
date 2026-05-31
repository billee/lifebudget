import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/home_shell.dart'; // ← this is crucial
import '../screens/budget/budget_screen.dart';
import '../screens/journal/journal_screen.dart'; // now exists
import '../screens/goals/goals_screen.dart'; // now exists
import '../screens/profile/profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => HomeShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/budget',
          builder: (context, state) => const BudgetScreen(),
        ),
        GoRoute(
          path: '/journal',
          builder: (context, state) => const JournalScreen(),
        ),
        GoRoute(
          path: '/goals',
          builder: (context, state) => const GoalsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
