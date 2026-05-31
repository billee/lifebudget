import 'package:flutter/material.dart';
import 'core/themes/app_theme.dart';
import 'presentation/navigation/app_router.dart';

class LifeBudgetApp extends StatelessWidget {
  const LifeBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LifeBudget',
      theme: AppTheme.light(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
