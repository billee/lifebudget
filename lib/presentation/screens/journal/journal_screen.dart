import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/journal_entry_model.dart';
import '../../providers/journal_provider.dart';
import '../../widgets/common/lifebudget_scaffold.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  String _mood = 'okay';
  final _wentWellController = TextEditingController();
  final _doDifferentlyController = TextEditingController();
  bool _submitted = false;

  final Map<String, String> _moodEmojis = {
    'stressed': '😔',
    'okay': '😐',
    'hopeful': '🙂',
  };

  @override
  void dispose() {
    _wentWellController.dispose();
    _doDifferentlyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final entry = JournalEntry(
      date: DateTime.now(),
      mood: _mood,
      wentWell: _wentWellController.text.trim().isEmpty
          ? null
          : _wentWellController.text.trim(),
      doDifferently: _doDifferentlyController.text.trim().isEmpty
          ? null
          : _doDifferentlyController.text.trim(),
    );

    final repo = ref.read(journalRepositoryProvider);
    await repo.insert(entry);
    ref.invalidate(journalEntriesProvider);
    ref.invalidate(lastJournalEntryProvider);

    setState(() => _submitted = true);

    // Clear form
    _wentWellController.clear();
    _doDifferentlyController.clear();
    setState(() => _mood = 'okay');
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(journalEntriesProvider);

    return LifeBudgetScaffold(
      appBar: AppBar(
        title: const Text('Journal', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Weekly Check‑In Form ----
            const Text(
              'Weekly Check‑in',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'A quick reflection — just for you.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Mood selector
            const Text('How are you feeling about money this week?'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: _moodEmojis.entries.map((entry) {
                return ChoiceChip(
                  label: Text('${entry.value} ${entry.key}'),
                  selected: _mood == entry.key,
                  onSelected: (selected) {
                    setState(() => _mood = entry.key);
                  },
                  selectedColor: AppColors.primary.withOpacity(0.2),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // What went well
            TextField(
              controller: _wentWellController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: "What's one thing that went well? (optional)",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // What to do differently
            TextField(
              controller: _doDifferentlyController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText:
                    "What's one thing you'd like to do differently next week? (optional)",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Reflection',
                    style: TextStyle(fontSize: 16)),
              ),
            ),

            if (_submitted)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Thank you for reflecting. 🌱',
                  style: TextStyle(
                      color: AppColors.onTrack, fontWeight: FontWeight.bold),
                ),
              ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // ---- Past Entries ----
            const Text(
              'Your Past Reflections',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            entriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (entries) {
                if (entries.isEmpty) {
                  return const Center(
                    child: Text(
                      'No entries yet. Your first reflection is waiting.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final emoji = _moodEmojis[entry.mood] ?? '😶';
                    final dateStr = '${entry.date.month}/${entry.date.day}';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading:
                            Text(emoji, style: const TextStyle(fontSize: 28)),
                        title: Text('$dateStr — ${entry.mood}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (entry.wentWell != null)
                              Text('👍 ${entry.wentWell}'),
                            if (entry.doDifferently != null)
                              Text('🔜 ${entry.doDifferently}'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
