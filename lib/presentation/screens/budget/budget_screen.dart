import 'package:flutter/material.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budget')),
      body: const Center(
        child: Text(
          'Budget coming soon — stay tuned!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
