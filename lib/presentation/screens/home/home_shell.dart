import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/common/lifebudget_scaffold.dart'; // ← moved to top
import 'fab_speed_dial.dart';

class HomeShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const HomeShell({super.key, required this.navigationShell});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  double _fabBottomOffset = 90.0;
  static const double _minOffset = 70.0;
  static const double _maxOffset = 250.0;

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LifeBudgetScaffold(
      body: Stack(
        children: [
          widget.navigationShell,
          Positioned(
            right: 20,
            bottom: _fabBottomOffset,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  _fabBottomOffset -= details.delta.dy;
                  _fabBottomOffset =
                      _fabBottomOffset.clamp(_minOffset, _maxOffset);
                });
              },
              child: const FabSpeedDial(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: widget.navigationShell.currentIndex,
          onTap: _onTap,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: AppStrings.navHome),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_rounded),
                label: AppStrings.navBudget),
            BottomNavigationBarItem(
                icon: Icon(Icons.book_rounded), label: AppStrings.navJournal),
            BottomNavigationBarItem(
                icon: Icon(Icons.flag_rounded), label: AppStrings.navGoals),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded), label: AppStrings.navProfile),
          ],
        ),
      ),
    );
  }
}
