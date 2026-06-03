import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final userNameProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('user_name') ?? 'you';
});

final updateUserName = FutureProvider.family<void, String>((ref, name) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('user_name', name);
  ref.invalidate(userNameProvider);
});
