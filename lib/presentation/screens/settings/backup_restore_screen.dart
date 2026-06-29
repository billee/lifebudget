import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/backup_service.dart';
import '../../widgets/common/lifebudget_scaffold.dart';
import '../../widgets/common/app_menu_button.dart';
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/expected_expenses_provider.dart';
import '../../providers/user_provider.dart'; // NEW
import '../../providers/settings_provider.dart'; // NEW (for reminder settings)

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _isLoading = false;

  Future<void> _performBackup() async {
    setState(() => _isLoading = true);
    try {
      final service = BackupService();
      final path = await service.exportBackup(share: false);
      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Backup failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _performRestore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Data?'),
        content: const Text(
            'This will replace all current data with the backup. Are you sure?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.critical),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final service = BackupService();
      final success = await service.importBackup();
      if (success && mounted) {
        // Invalidate all relevant providers to refresh UI
        ref.invalidate(budgetStateProvider);
        ref.invalidate(allTransactionsProvider);
        ref.invalidate(expectedExpensesProvider);
        ref.invalidate(userNameProvider); // refresh user name
        ref.invalidate(reminderSettingsProvider); // refresh reminder settings

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data restored successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Restore failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LifeBudgetScaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [AppMenuButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.backup, size: 80, color: AppColors.primary),
            const SizedBox(height: 24),
            const Text(
              'Backup your data or restore from a previous backup.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 48),
            _buildActionButton(
              icon: Icons.download_outlined,
              label: 'Create Backup',
              color: AppColors.primary,
              onTap: _isLoading ? null : _performBackup,
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              icon: Icons.restore_outlined,
              label: 'Restore from Backup',
              color: AppColors.critical,
              onTap: _isLoading ? null : _performRestore,
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 24),
        label: Text(label, style: const TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
