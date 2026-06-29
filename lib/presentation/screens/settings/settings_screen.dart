import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../providers/user_provider.dart';
import '../../../services/notification_service.dart';
import '../../widgets/common/lifebudget_scaffold.dart';
import '../../widgets/common/app_menu_button.dart';
import '../../../services/backup_service.dart'; // for BackupService
import '../../providers/budget_provider.dart'; // for budgetStateProvider
import '../../providers/transaction_provider.dart'; // for allTransactionsProvider
import '../../providers/expected_expenses_provider.dart'; // for expectedExpensesProvider

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    final nameAsync = ref.read(userNameProvider);
    nameAsync.whenData((name) => _nameController.text = name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await ref.read(updateUserName(name).future);
      setState(() => _isEditingName = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated')),
        );
      }
    }
  }

  Future<void> _selectReminderTime() async {
    final settings = ref.read(reminderSettingsProvider);
    final picked = await showTimePicker(
      context: context,
      initialTime: settings.time,
    );
    if (picked != null) {
      await ref.read(reminderSettingsProvider.notifier).setTime(picked);
      // Reschedule notification with new time if enabled
      if (settings.enabled) {
        await NotificationService.instance.scheduleDailyReminder(
          enabled: true,
          time: picked,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminderSettings = ref.watch(reminderSettingsProvider);
    final nameAsync = ref.watch(userNameProvider);
    final currentName = nameAsync.value ?? '';

    return LifeBudgetScaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [AppMenuButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          _buildSectionHeader('Profile'),
          _buildCard([
            ListTile(
              leading:
                  const Icon(Icons.person_outline, color: AppColors.primary),
              title: const Text('Your Name'),
              subtitle: _isEditingName
                  ? TextField(
                      controller: _nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check,
                                  color: AppColors.primary),
                              onPressed: _saveName,
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: AppColors.critical),
                              onPressed: () {
                                setState(() {
                                  _isEditingName = false;
                                  _nameController.text = currentName;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      onSubmitted: (_) => _saveName(),
                    )
                  : Text(currentName),
              trailing: _isEditingName
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.primary),
                      onPressed: () {
                        _nameController.text = currentName;
                        setState(() => _isEditingName = true);
                      },
                    ),
            ),
          ]),

          const SizedBox(height: 24),

          // Reminders Section
          _buildSectionHeader('Reminders'),
          _buildCard([
            SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined,
                  color: AppColors.primary),
              title: const Text('Daily Reminder'),
              subtitle: reminderSettings.enabled
                  ? Text('Every day at ${_formatTime(reminderSettings.time)}')
                  : const Text('Off'),
              value: reminderSettings.enabled,
              activeColor: AppColors.primary,
              onChanged: (value) async {
                await ref
                    .read(reminderSettingsProvider.notifier)
                    .setEnabled(value);
                await NotificationService.instance.scheduleDailyReminder(
                  enabled: value,
                  time: reminderSettings.time,
                );
                // Show helpful message when enabling
                if (value && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Reminder set! Make sure LifeBudget notifications are enabled in your phone settings.',
                      ),
                      backgroundColor: AppColors.primary,
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'OK',
                        textColor: Colors.white,
                        onPressed: () {},
                      ),
                    ),
                  );
                }
              },
            ),
            if (reminderSettings.enabled)
              ListTile(
                leading: const SizedBox(width: 40),
                title: const Text('Reminder Time'),
                subtitle: Text(_formatTime(reminderSettings.time)),
                trailing:
                    const Icon(Icons.access_time, color: AppColors.primary),
                onTap: _selectReminderTime,
              ),
            ListTile(
              leading: const SizedBox(width: 40),
              title: const Text('Test Notification'),
              subtitle: const Text('Tap to test if notifications work'),
              trailing: const Icon(Icons.notifications_active,
                  color: AppColors.primary),
              onTap: () async {
                await NotificationService.instance.showTestNotification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Test notification sent! Check your notifications.'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Budget display
          _buildSectionHeader('Budget'),
          _buildCard([
            SwitchListTile(
              secondary:
                  const Icon(Icons.shield_outlined, color: AppColors.primary),
              title: const Text('Survival Mode'),
              subtitle: const Text(
                'Simpler home screen — hides safely spend extras',
              ),
              value: reminderSettings.survivalMode,
              activeColor: AppColors.primary,
              onChanged: (value) async {
                await ref
                    .read(reminderSettingsProvider.notifier)
                    .setSurvivalMode(value);
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Data Section
          _buildSectionHeader('Data'),
          _buildCard([
            ListTile(
              leading:
                  const Icon(Icons.download_outlined, color: AppColors.primary),
              title: const Text('Backup'),
              subtitle: const Text('Save your data to a file'),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary),
              onTap: () async {
                try {
                  final service = BackupService();
                  final path = await service.exportBackup(share: false);
                  if (path != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Backup saved successfully!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Backup failed: $e'),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading:
                  const Icon(Icons.restore_outlined, color: AppColors.primary),
              title: const Text('Restore'),
              subtitle: const Text('Restore data from a backup file'),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary),
              onTap: () async {
                // Show confirmation dialog first
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
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.critical),
                        child: const Text('Restore'),
                      ),
                    ],
                  ),
                );
                if (confirm != true) return;

                try {
                  final service = BackupService();
                  final success = await service.importBackup();
                  if (success && mounted) {
                    // Invalidate providers to refresh UI
                    ref.invalidate(budgetStateProvider);
                    ref.invalidate(allTransactionsProvider);
                    ref.invalidate(expectedExpensesProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Data restored successfully!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Restore failed: $e'),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          ]),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          _buildCard([
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.primary),
              title: const Text('Version'),
              subtitle: const Text('1.0.0'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
