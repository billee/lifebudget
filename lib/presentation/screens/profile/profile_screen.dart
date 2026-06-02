import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../providers/budget_provider.dart'; // jarAllocationsProvider, budgetRepositoryProvider
import '../../providers/transaction_provider.dart'; // jarSummariesProvider
import '../../widgets/common/lifebudget_scaffold.dart';
import '../../../data/models/budget_plan_model.dart'; // JarAllocation

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final Map<String, double> _percentages = {
    'rent': 30,
    'food': 25,
    'transport': 10,
    'health': 5,
    'fun': 10,
    'savings': 20,
  };

  @override
  void initState() {
    super.initState();
    // Load current percentages from the DB (we'll do it inside build to be reactive)
  }

  void _updatePercentages(List<JarAllocation> allocations) {
    for (final alloc in allocations) {
      _percentages[alloc.jarName] = alloc.percentage;
    }
  }

  double get _totalPercentage =>
      _percentages.values.fold(0, (sum, p) => sum + p);

  Future<void> _save() async {
    if (_totalPercentage != 100.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Percentages must add up to 100%!')),
      );
      return;
    }

    final month =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    final repo = ref.read(budgetRepositoryProvider);
    final newAllocations = _percentages.entries.map((e) {
      return JarAllocation(month: month, jarName: e.key, percentage: e.value);
    }).toList();

    await repo.saveJarAllocations(month, newAllocations);

    // Invalidate providers to refresh UI
    ref.invalidate(jarAllocationsProvider);
    ref.invalidate(jarSummariesProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your jars have been updated!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allocationsAsync = ref.watch(jarAllocationsProvider);
    final summariesAsync = ref.watch(jarSummariesProvider);

    // Update local percentages when allocations load
    allocationsAsync.whenData((allocs) => _updatePercentages(allocs));

    // Total income for display
    final totalIncome = summariesAsync.valueOrNull?['__total_income__'] ?? 0.0;

    return LifeBudgetScaffold(
      appBar: AppBar(
        title: const Text('Your Budget', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: allocationsAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Income received this month
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_money,
                            color: AppColors.primary),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Income received this month',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary)),
                            Text('₱ ${totalIncome.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Jar percentage sliders
                  const Text('Jar Percentages (must add up to 100%)',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ..._percentages.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key[0].toUpperCase()}${entry.key.substring(1)} — ${entry.value.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Slider(
                            value: entry.value,
                            min: 0,
                            max: 100,
                            divisions: 100,
                            label: '${entry.value.toStringAsFixed(0)}%',
                            activeColor: AppColors.primary,
                            onChanged: (newValue) {
                              setState(() {
                                _percentages[entry.key] = newValue;
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),

                  // Total percentage display
                  Text(
                    'Total: ${_totalPercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _totalPercentage == 100
                          ? AppColors.onTrack
                          : AppColors.critical,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
