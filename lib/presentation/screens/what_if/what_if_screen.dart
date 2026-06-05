import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/number_formatter.dart';
import '../../providers/transaction_provider.dart';

class WhatIfScreen extends ConsumerStatefulWidget {
  const WhatIfScreen({super.key});

  @override
  ConsumerState<WhatIfScreen> createState() => _WhatIfScreenState();
}

class _WhatIfScreenState extends ConsumerState<WhatIfScreen> {
  double _weeklyAmount = 200;
  int _months = 3;

  @override
  Widget build(BuildContext context) {
    final allTxnsAsync = ref.watch(allTransactionsProvider);
    double monthlyIncome = 0;
    allTxnsAsync.whenData((txns) {
      for (final t in txns) {
        if (t.type == 'income') monthlyIncome += t.amount;
      }
    });
    final double sliderMax = (monthlyIncome * 0.2).clamp(500, 10000);
    final double projectedTotal = _weeklyAmount * 4.33 * _months;
    final String projectedString = formatAmount(projectedTotal);

    return Scaffold(
      appBar: AppBar(
        title: const Text('What If?', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Small steps, big futures.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'See how much you could have if you set aside a little each week.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Weekly amount slider
            const Text('How much could you set aside each week?',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _weeklyAmount,
                    min: 0,
                    max: sliderMax,
                    divisions: ((sliderMax) / 10).ceil(),
                    label: formatAmount(_weeklyAmount),
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _weeklyAmount = val),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(formatAmount(_weeklyAmount),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Number of months
            const Text('Over how many months?', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _months.toDouble(),
                    min: 1,
                    max: 12,
                    divisions: 11,
                    label: '$_months months',
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _months = val.round()),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text('$_months months',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Projection
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('You could have',
                      style: TextStyle(
                          fontSize: 16, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text(
                    '₱$projectedString',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'in $_months month${_months > 1 ? 's' : ''}.',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _inspirationMessage(_weeklyAmount, projectedTotal),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _inspirationMessage(double weekly, double total) {
    if (total < 500) return 'Enough for a small treat.';
    if (total < 2000) return 'A weekend getaway or a nice dinner out.';
    if (total < 10000) return 'A new gadget or a small emergency cushion.';
    return 'A real step toward something big.';
  }
}
