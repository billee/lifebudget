import 'package:flutter/material.dart';
import '../../widgets/common/lifebudget_scaffold.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LifeBudgetScaffold(
      appBar: AppBar(title: const Text('Budget')),
      body: const Center(child: Text('Budget coming soon — stay tuned!')),
    );
  }
}
