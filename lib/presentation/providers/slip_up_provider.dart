import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/slip_up_repository.dart';
import '../../data/models/slip_up_model.dart';

final slipUpRepositoryProvider = Provider<SlipUpRepository>((ref) {
  return SlipUpRepository();
});

final recentSlipUpsProvider = FutureProvider<List<SlipUp>>((ref) async {
  final repo = ref.watch(slipUpRepositoryProvider);
  return await repo.getRecent();
});

final daysSinceLastSlipUpProvider = FutureProvider<int?>((ref) async {
  final repo = ref.watch(slipUpRepositoryProvider);
  final recent = await repo.getRecent(limit: 1);
  if (recent.isEmpty) return null; // never slipped up
  final lastDate = recent.first.date;
  final now = DateTime.now();
  return now.difference(lastDate).inDays;
});
