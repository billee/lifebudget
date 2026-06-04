import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/journal_repository.dart';
import '../../data/models/journal_entry_model.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository();
});

final journalEntriesProvider = FutureProvider<List<JournalEntry>>((ref) async {
  final repo = ref.watch(journalRepositoryProvider);
  return await repo.getAll();
});

final lastJournalEntryProvider = FutureProvider<JournalEntry?>((ref) async {
  final repo = ref.watch(journalRepositoryProvider);
  return await repo.getMostRecent();
});
