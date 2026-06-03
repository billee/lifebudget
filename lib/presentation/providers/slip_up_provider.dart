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
