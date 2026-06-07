import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/transaction_provider.dart';
import '../../../data/models/transaction_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/common/app_menu_button.dart';

class JarDetailScreen extends ConsumerWidget {
  final String jarName;
  const JarDetailScreen({super.key, required this.jarName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(transactionRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('${jarName[0].toUpperCase()}${jarName.substring(1)}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: const [AppMenuButton()],
      ),
      body: FutureBuilder<List<TransactionModel>>(
        future: repo.getTransactionsByJar(jarName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final transactions = snapshot.data ?? [];
          if (transactions.isEmpty) {
            return const Center(
              child: Text(
                'No transactions yet.\nEvery journey starts with a first step.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final t = transactions[index];
              return ListTile(
                leading: Icon(
                  t.type == 'expense'
                      ? Icons.remove_circle_outline
                      : Icons.add_circle_outline,
                  color: t.type == 'expense'
                      ? AppColors.critical
                      : AppColors.onTrack,
                ),
                title: Text(t.type == 'expense'
                    ? '-₱${t.amount.toStringAsFixed(2)}'
                    : '+₱${t.amount.toStringAsFixed(2)}'),
                subtitle: Text(t.note ?? ''),
                trailing: Text(
                  '${t.date.month}/${t.date.day}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
