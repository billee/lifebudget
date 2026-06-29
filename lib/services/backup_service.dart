import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database/database_helper.dart';

class BackupService {
  final db = DatabaseHelper.instance;

  /// Export all data (SQLite + SharedPreferences) to a JSON file.
  Future<String?> exportBackup({bool share = false}) async {
    try {
      // 1. Fetch SQLite data
      final data = await db.exportAllData();

      // 2. Fetch SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final prefsData = {
        'userName': prefs.getString('user_name') ?? '',
        'reminderEnabled': prefs.getBool('reminder_enabled') ?? false,
        'reminderHour': prefs.getInt('reminder_hour') ?? 20,
        'reminderMinute': prefs.getInt('reminder_minute') ?? 0,
        'survivalMode': prefs.getBool('survival_mode') ?? false,
      };

      // 3. Build backup envelope with metadata
      final backup = {
        'version': 1,
        'createdAt': DateTime.now().toIso8601String(),
        'appName': 'LifeBudget',
        'data': data,
        'preferences': prefsData, // new
      };

      // 4. Convert to JSON bytes
      final jsonString = jsonEncode(backup);
      final bytes = utf8.encode(jsonString) as Uint8List;

      if (share) {
        // Write to temporary file and share it
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(
            '${tempDir.path}/LifeBudget_backup_${DateTime.now().millisecondsSinceEpoch}.json');
        await tempFile.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(tempFile.path)],
            text: 'LifeBudget backup');
        return tempFile.path;
      } else {
        // Let user choose where to save, passing the bytes directly
        String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Backup',
          fileName:
              'LifeBudget_backup_${DateTime.now().millisecondsSinceEpoch}.json',
          bytes: bytes,
        );
        return outputPath; // null if user cancelled
      }
    } catch (e) {
      throw Exception('Export failed: $e');
    }
  }

  /// Restore data from a backup file (SQLite + SharedPreferences).
  /// Returns true on success.
  Future<bool> importBackup() async {
    try {
      // 1. Pick a file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select a LifeBudget backup file',
        allowedExtensions: ['json'],
        type: FileType.custom,
      );
      if (result == null || result.files.isEmpty) return false;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final backup = jsonDecode(jsonString) as Map<String, dynamic>;

      // 2. Validate backup structure
      if (backup['appName'] != 'LifeBudget' || backup['version'] == null) {
        throw Exception('Invalid backup file');
      }

      // (Optional) check version compatibility
      final version = backup['version'] as int;
      if (version > 1) {
        throw Exception('Backup version $version is newer than this app');
      }

      // 3. Extract and restore SQLite data
      final data = backup['data'] as Map<String, dynamic>;
      await db.importAllData(data);

      // 4. Extract and restore SharedPreferences
      final prefsData = backup['preferences'] as Map<String, dynamic>?;
      if (prefsData != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', prefsData['userName'] ?? '');
        await prefs.setBool(
            'reminder_enabled', prefsData['reminderEnabled'] ?? false);
        await prefs.setInt('reminder_hour', prefsData['reminderHour'] ?? 20);
        await prefs.setInt('reminder_minute', prefsData['reminderMinute'] ?? 0);
        await prefs.setBool(
            'survival_mode', prefsData['survivalMode'] ?? false);
      }

      return true;
    } catch (e) {
      throw Exception('Restore failed: $e');
    }
  }
}
