import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ShadowLogger {
  static File? _logFile;

  static Future<void> init({Directory? overrideDir}) async {
    final dir = overrideDir ?? await getApplicationDocumentsDirectory();
    _logFile = File('${dir.path}/shadow_transaction_log.txt');
  }

  /// Appends a transaction record to the local file system.
  /// This is the "Fail-Safe" if SQLite is corrupted or inaccessible.
  static Future<void> performShadowWrite(String transactionData) async {
    if (_logFile == null) await init();
    
    final timestamp = DateTime.now().toIso8601String();
    final entry = "[$timestamp] $transactionData\n";
    
    // synchronous append might be safer for "Do not lose data" but blocking UI.
    // robust method: writeAsString with mode: FileMode.append
    try {
      await _logFile!.writeAsString(entry, mode: FileMode.append, flush: true);
    } catch (e) {
      print("CRITICAL ERROR: SHADOW LOG WRITE FAILED: $e");
      // In a real scenario, we might want to halt or cache in memory
    }
  }
}
