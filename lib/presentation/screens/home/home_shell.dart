import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/common/lifebudget_scaffold.dart'; // ← moved to top
import '../../widgets/common/ad_banner_widget.dart';
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
  bool _fabExpanded = false;
  final _fabKey = GlobalKey<FabSpeedDialState>();

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
          // Tap-outside-to-dismiss overlay (only when FAB is expanded)
          if (_fabExpanded)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _fabKey.currentState?.collapse();
                },
                child: Container(color: Colors.transparent),
              ),
            ),
          Positioned(
            right: _fabOffsetX < MediaQuery.of(context).size.width / 2
                ? _fabOffsetX
                : null,
            left: _fabOffsetX >= MediaQuery.of(context).size.width / 2
                ? MediaQuery.of(context).size.width - _fabOffsetX - 34
                : null,
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
              child: FabSpeedDial(
                key: _fabKey,
                isOnLeftSide:
                    _fabOffsetX >= MediaQuery.of(context).size.width / 2,
                onExpandedChanged: (expanded) {
                  setState(() => _fabExpanded = expanded);
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AdBannerWidget(),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              backgroundColor: AppColors.primary,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              currentIndex: widget.navigationShell.currentIndex,
              onTap: _onTap,
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded), label: AppStrings.navHome),
                BottomNavigationBarItem(
                    icon: Icon(Icons.account_balance_wallet_rounded),
                    label: AppStrings.navBudget),
                BottomNavigationBarItem(
                    icon: Icon(Icons.book_rounded),
                    label: AppStrings.navJournal),
                BottomNavigationBarItem(
                    icon: Icon(Icons.flag_rounded), label: AppStrings.navGoals),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person_rounded),
                    label: AppStrings.navProfile),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
