import 'package:flutter/material.dart';
import '../../widgets/common/lifebudget_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LifeBudgetScaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Profile coming soon!')),
    );
  }
}
