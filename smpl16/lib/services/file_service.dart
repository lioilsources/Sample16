import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileService {
  static Future<String> get _samplesDir async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/samples');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> get _tempDir async {
    final tmp = await getTemporaryDirectory();
    return tmp.path;
  }

  static Future<String> tempRecordingPath() async {
    final dir = await _tempDir;
    return '$dir/rec_${DateTime.now().millisecondsSinceEpoch}.wav';
  }

  /// Copies [sourcePath] into the app's samples directory, returns new path.
  static Future<String> importFile(String sourcePath, int slotIndex) async {
    final dir = await _samplesDir;
    final ext = sourcePath.split('.').last.toLowerCase();
    final dest = '$dir/slot_${slotIndex}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await File(sourcePath).copy(dest);
    return dest;
  }

  /// Deletes a file if it exists.
  static Future<void> deleteFile(String? path) async {
    if (path == null) return;
    final f = File(path);
    if (await f.exists()) await f.delete();
  }
}
