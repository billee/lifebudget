import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import 'fab_speed_dial.dart';

class HomeShell extends StatefulWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  // Initial distance from bottom (in logical pixels)
  double _fabBottomOffset = 90.0;

  // Clamp limits to keep FAB from going off-screen or behind nav bar
  static const double _minOffset = 70.0;
  static const double _maxOffset = 250.0;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/budget')) return 1;
    if (location.startsWith('/journal')) return 2;
    if (location.startsWith('/goals')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/budget');
        break;
      case 2:
        context.go('/journal');
        break;
      case 3:
        context.go('/goals');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    return Scaffold(
      body: Stack(
        children: [
          widget.child,
          // Draggable FAB cluster
          Positioned(
            right: 20,
            bottom: _fabBottomOffset,
            child: GestureDetector(
              // Handle vertical drag to reposition the whole FAB cluster
              onVerticalDragUpdate: (details) {
                setState(() {
                  // details.delta.dy is negative when dragging up
                  _fabBottomOffset -= details.delta.dy;
                  _fabBottomOffset = _fabBottomOffset.clamp(
                    _minOffset,
                    _maxOffset,
                  );
                });
              },
              child: const FabSpeedDial(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => _onTap(context, index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: AppStrings.navHome,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded),
              label: AppStrings.navBudget,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_rounded),
              label: AppStrings.navJournal,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.flag_rounded),
              label: AppStrings.navGoals,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: AppStrings.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}
