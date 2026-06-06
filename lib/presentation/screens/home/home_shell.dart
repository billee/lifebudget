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
  double _fabOffsetX = 20;
  double _fabOffsetY = 90;

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
            right: _fabOffsetX,
            bottom: _fabOffsetY,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _fabOffsetX -= details.delta.dx;
                  _fabOffsetY -= details.delta.dy;
                  // Clamp within screen bounds
                  final screenWidth = MediaQuery.of(context).size.width;
                  final screenHeight = MediaQuery.of(context).size.height;
                  _fabOffsetX = _fabOffsetX.clamp(8, screenWidth - 50);
                  _fabOffsetY = _fabOffsetY.clamp(8, screenHeight - 120);
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
