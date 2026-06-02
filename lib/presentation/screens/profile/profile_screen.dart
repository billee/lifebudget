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
  final Map<String, double> _allocated = {
    'rent': 0,
    'food': 0,
    'transport': 0,
    'health': 0,
    'fun': 0,
    'savings': 0,
  };

  double _totalIncome = 0;

  void _syncFromAllocations(List<JarAllocation> allocs, double totalIncome) {
    for (final alloc in allocs) {
      if (_allocated.containsKey(alloc.jarName)) {
        _allocated[alloc.jarName] = totalIncome * (alloc.percentage / 100);
      }
    }
  }

  double get _totalAllocated => _allocated.values.fold(0, (sum, v) => sum + v);
  bool get _isOverBudget => _totalAllocated > _totalIncome && _totalIncome > 0;

  Future<void> _save() async {
    if (_totalIncome <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some income first!')),
      );
      return;
    }

    final month =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    final repo = ref.read(budgetRepositoryProvider);
    final newAllocs = _allocated.entries.map((e) {
      final percentage = (e.value / _totalIncome) * 100;
      return JarAllocation(
          month: month, jarName: e.key, percentage: percentage);
    }).toList();

    await repo.saveJarAllocations(month, newAllocs);
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

    _totalIncome = summariesAsync.valueOrNull?['__total_income__'] ?? 0;

    // Sync once when allocations load (but only if we haven't manually adjusted)
    allocationsAsync.whenData((allocs) {
      // Only sync if the user hasn't made changes yet (all zeros)
      bool allZero = _allocated.values.every((v) => v == 0);
      if (allZero) {
        _syncFromAllocations(allocs, _totalIncome);
      }
    });

    final double sliderMax = _totalIncome > 0 ? _totalIncome : 1000.0;
    final int divisions = ((sliderMax / 100).ceil()).clamp(1, 1000);

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
                            Text('₱ ${_totalIncome.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('How would you like to split your income?',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Jar sliders
                  ..._allocated.entries.map((entry) {
                    final jarName = entry.key;
                    final amount = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                jarName[0].toUpperCase() + jarName.substring(1),
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '₱${amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: amount.clamp(0, sliderMax),
                            min: 0,
                            max: sliderMax,
                            divisions: divisions,
                            label: '₱${amount.toStringAsFixed(0)}',
                            activeColor: AppColors.primary,
                            onChanged: (newValue) {
                              setState(() {
                                _allocated[jarName] = newValue;
                              });
                            },
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  // Total and warning
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total allocated: ₱${_totalAllocated.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (_isOverBudget)
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.warning),
                    ],
                  ),
                  if (_isOverBudget)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 20, color: AppColors.warning),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "You're allocating more than your income. That's okay if you have savings, but double-check.",
                              style: TextStyle(
                                  color: AppColors.warning, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

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
