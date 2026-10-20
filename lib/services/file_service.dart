import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  Future<Uint8List?> pickFileBytes();
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
  Future<Uint8List?> pickFileBytes() async {
    final file = await FilePicker.pickFile(dialogTitle: 'Choose a Hisab backup');
    return file == null ? null : await file.readAsBytes();
  }
}

final fileServiceProvider = Provider<FileService>((ref) => const PlatformFileService());
