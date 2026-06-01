import 'package:flutter/material.dart';
import 'honeycomb_background.dart';

class LifeBudgetScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool extendBodyBehindAppBar;

  const LifeBudgetScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      body: Stack(
        children: [
          // RepaintBoundary caches the honeycomb bitmap – big performance boost
          // const Positioned.fill(
          //   child: RepaintBoundary(
          //     child: HoneycombBackground(),
          //   ),
          // ),
          // Actual content on top
          body,
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
