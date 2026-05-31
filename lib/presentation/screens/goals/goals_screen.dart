import 'package:flutter/material.dart';
import '../../widgets/common/lifebudget_scaffold.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LifeBudgetScaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: const Center(child: Text('Goals coming soon!')),
    );
  }
}
