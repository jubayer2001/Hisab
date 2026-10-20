import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/backup.dart';

/// Saving a file to, and picking a file from, the phone's storage.
///
/// A small interface so tests can use a fake instead of the real Android dialogs.
abstract class FileService {
  /// Opens the system "Save" dialog. Returns false if the user cancelled.
  /// [mimeType] tells Android what kind of file this is, so it keeps the right extension.
  Future<bool> saveBytes({
    required String fileName,
    required Uint8List bytes,
    String mimeType = 'application/octet-stream',
  });

  /// Opens the system file picker. Returns the file's bytes, or null if the user cancelled.
  /// A file bigger than [maxBytes] is refused before it is read into memory.
  Future<Uint8List?> pickFileBytes({int maxBytes = maxBackupBytes});
}

class PlatformFileService implements FileService {
  const PlatformFileService();

  @override
  Future<bool> saveBytes({
    required String fileName,
    required Uint8List bytes,
    String mimeType = 'application/octet-stream',
  }) async {
    final saved = await FilePicker.saveFile(
      dialogTitle: 'Save $fileName',
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );
    return saved != null;
  }

  @override
  Future<Uint8List?> pickFileBytes({int maxBytes = maxBackupBytes}) async {
    final file = await FilePicker.pickFile(dialogTitle: 'Choose a Hisab backup');
    if (file == null) return null;
    // An unknown size is checked again by the backup parser once the bytes are in.
    if ((await file.length() ?? 0) > maxBytes) throw const BackupException('That file is too large to be a Hisab backup.');
    return await file.readAsBytes();
  }
}

final fileServiceProvider = Provider<FileService>((ref) => const PlatformFileService());
