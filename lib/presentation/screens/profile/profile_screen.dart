import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/budget_plan_model.dart'; // was ../../  now ../../../
import '../../../data/repositories/budget_repository.dart'; // same
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart'; // for jarSummariesProvider
import '../../widgets/common/lifebudget_scaffold.dart';
import '../../../core/constants/app_colors.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _totalBudgetController;
  late Map<String, TextEditingController> _jarControllers;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _totalBudgetController = TextEditingController();
    _jarControllers = {
      'food': TextEditingController(),
      'rent': TextEditingController(),
      'transport': TextEditingController(),
      'fun': TextEditingController(),
      'health': TextEditingController(),
    };
  }

  @override
  void dispose() {
    _totalBudgetController.dispose();
    _jarControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> _loadBudget(BudgetPlan plan) async {
    _totalBudgetController.text = plan.totalBudget.toStringAsFixed(0);
    for (final alloc in plan.allocations) {
      _jarControllers[alloc.jarName]?.text =
          alloc.allocatedAmount.toStringAsFixed(0);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(budgetRepositoryProvider);
      final month = DateTime.now().year.toString() +
          '-' +
          DateTime.now().month.toString().padLeft(2, '0');
      final totalBudget = double.tryParse(_totalBudgetController.text) ?? 0;
      final allocations = _jarControllers.entries.map((e) {
        return JarAllocation(
          month: month,
          jarName: e.key,
          allocatedAmount: double.tryParse(e.value.text) ?? 0,
        );
      }).toList();

      final plan = BudgetPlan(
          month: month, totalBudget: totalBudget, allocations: allocations);
      await repo.updateBudget(plan);

      // Invalidate providers to refresh UI
      ref.invalidate(budgetProvider);
      ref.invalidate(jarSummariesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Budget updated!'),
              backgroundColor: AppColors.primary),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetAsync = ref.watch(budgetProvider);

    return LifeBudgetScaffold(
      appBar: AppBar(
        title: const Text('Your Budget', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: budgetAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (plan) {
          // Load controllers once
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _loadBudget(plan));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Monthly Budget',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _totalBudgetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Total Monthly Budget',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Jar Allocations',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._jarControllers.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: entry.value,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText:
                            '${entry.key[0].toUpperCase()}${entry.key.substring(1)}',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(color: Colors.white))
                        : const Text('Save Budget',
                            style:
                                TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
