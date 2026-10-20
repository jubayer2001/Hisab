import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'google_config.dart';

/// A problem talking to the cloud, worded for the person using the app.
class CloudException implements Exception {
  const CloudException(this.message, {this.offline = false, this.needsSignIn = false});

  final String message;

  /// The phone could not reach Google (no internet, or a bad connection). Worth retrying later.
  final bool offline;

  /// Google no longer accepts the saved sign-in. The person has to sign in again.
  final bool needsSignIn;

  @override
  String toString() => message;
}

/// Where the cloud copy of the backup lives, for the app to use without caring that it is
/// Google Drive. One account, one backup file.
///
/// A small interface so tests can use a fake instead of the real Google account and network.
abstract class CloudBackupService {
  /// False when the app was built without a Google client ID, so sign-in cannot work.
  bool get isConfigured;

  /// Shows Google's account picker and permission screen. The account's email.
  /// Throws [CloudException] if the person cancels or something fails.
  Future<String> signIn();

  /// Forgets the account on this phone. The backup in the cloud is left untouched.
  Future<void> signOut();

  /// The cloud backup's bytes and when it was saved, or null if there is none yet.
  Future<({Uint8List bytes, DateTime modified})?> download();

  /// Saves [bytes] as the cloud backup. When it was saved.
  Future<DateTime> upload(Uint8List bytes);

  /// Deletes the cloud backup, including the day-old safety copy kept next to it.
  Future<void> deleteBackup();
}

const _driveScope = 'https://www.googleapis.com/auth/drive.appdata';
const _fileName = 'hisab-backup.json';
const _previousName = 'hisab-backup-previous.json';
const _api = 'https://www.googleapis.com/drive/v3';
const _upload = 'https://www.googleapis.com/upload/drive/v3';

/// Keeps the backup in the app's own hidden folder in the person's Google Drive
/// ("appDataFolder"). Hisab can see only that folder: not their other files, and no other
/// app can see it.
///
/// Before a backup is overwritten, a day-old copy of it is kept as a second file, so one bad
/// upload can never be the only thing left.
class GoogleCloudBackupService implements CloudBackupService {
  GoogleCloudBackupService({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;
  bool _started = false;

  @override
  bool get isConfigured => googleServerClientId.isNotEmpty;

  Future<void> _start() async {
    if (_started) return;
    await GoogleSignIn.instance.initialize(serverClientId: googleServerClientId);
    _started = true;
  }

  @override
  Future<String> signIn() async {
    if (!isConfigured) throw const CloudException('Google sign-in is not set up in this version of Hisab.');
    try {
      await _start();
      final account = await GoogleSignIn.instance.authenticate(scopeHint: const [_driveScope]);
      await account.authorizationClient.authorizeScopes(const [_driveScope]);
      return account.email;
    } on GoogleSignInException catch (e) {
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
          throw const CloudException('Sign-in was cancelled.');
        default:
          throw CloudException(_signInProblem(e));
      }
    } on SocketException {
      throw const CloudException('No internet connection. Try again when you are online.', offline: true);
    }
  }

  String _signInProblem(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google sign-in is not set up correctly for this version of Hisab.';
      default:
        return 'Could not sign in with Google. Check your internet connection and try again.';
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _start();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Signing out locally must never fail the person's request.
    }
  }

  /// The permission to use the app folder, without showing anything. Throws
  /// [CloudException.needsSignIn] if it has to be asked for again.
  Future<String> _token() async {
    await _start();
    final auth = await GoogleSignIn.instance.authorizationClient.authorizationForScopes(const [_driveScope]);
    if (auth == null) {
      throw const CloudException('Sign in with Google again to keep backing up.', needsSignIn: true);
    }
    return auth.accessToken;
  }

  /// Runs a request, retrying once with a fresh permission if Google says the old one expired.
  Future<http.Response> _send(Future<http.Response> Function(Map<String, String> headers) request) async {
    try {
      var token = await _token();
      var response = await request({'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 40));
      if (response.statusCode == 401) {
        await GoogleSignIn.instance.authorizationClient.clearAuthorizationToken(accessToken: token);
        token = await _token();
        response = await request({'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 40));
      }
      if (response.statusCode == 401) {
        throw const CloudException('Sign in with Google again to keep backing up.', needsSignIn: true);
      }
      if (response.body.contains('accessNotConfigured') || response.body.contains('SERVICE_DISABLED')) {
        throw const CloudException('Google Drive is not switched on for this app yet.');
      }
      if (response.statusCode >= 400) {
        throw CloudException('Google Drive refused the request (${response.statusCode}).');
      }
      return response;
    } on SocketException {
      throw const CloudException('No internet connection.', offline: true);
    } on TimeoutException {
      throw const CloudException('The connection is too slow right now.', offline: true);
    } on http.ClientException {
      throw const CloudException('No internet connection.', offline: true);
    } on GoogleSignInException {
      throw const CloudException('Sign in with Google again to keep backing up.', needsSignIn: true);
    }
  }

  Future<({String id, DateTime modified})?> _find(String name) async {
    final uri = Uri.parse('$_api/files').replace(queryParameters: {
      'spaces': 'appDataFolder',
      'q': "name = '$name' and trashed = false",
      'fields': 'files(id,modifiedTime)',
      'orderBy': 'modifiedTime desc',
      'pageSize': '1',
    });
    final response = await _send((h) => _http.get(uri, headers: h));
    final files = (jsonDecode(response.body) as Map<String, dynamic>)['files'] as List;
    if (files.isEmpty) return null;
    final f = files.first as Map<String, dynamic>;
    return (id: f['id'] as String, modified: DateTime.parse(f['modifiedTime'] as String).toLocal());
  }

  /// Every file in the app folder with this name (there is normally only one).
  Future<List<String>> _findAll(String name) async {
    final uri = Uri.parse('$_api/files').replace(queryParameters: {
      'spaces': 'appDataFolder',
      'q': "name = '$name' and trashed = false",
      'fields': 'files(id)',
      'pageSize': '100',
    });
    final response = await _send((h) => _http.get(uri, headers: h));
    final files = (jsonDecode(response.body) as Map<String, dynamic>)['files'] as List;
    return [for (final f in files) (f as Map<String, dynamic>)['id'] as String];
  }

  @override
  Future<void> deleteBackup() async {
    for (final name in const [_fileName, _previousName]) {
      for (final id in await _findAll(name)) {
        await _send((h) => _http.delete(Uri.parse('$_api/files/$id'), headers: h));
      }
    }
  }

  @override
  Future<({Uint8List bytes, DateTime modified})?> download() async {
    final file = await _find(_fileName);
    if (file == null) return null;
    final response = await _send((h) => _http.get(Uri.parse('$_api/files/${file.id}?alt=media'), headers: h));
    return (bytes: response.bodyBytes, modified: file.modified);
  }

  @override
  Future<DateTime> upload(Uint8List bytes) async {
    final existing = await _find(_fileName);
    if (existing == null) {
      return _create(bytes);
    }
    await _keepPrevious(existing);
    final response = await _send((h) => _http.patch(
          Uri.parse('$_upload/files/${existing.id}?uploadType=media&fields=modifiedTime'),
          headers: {...h, 'Content-Type': 'application/json'},
          body: bytes,
        ));
    return DateTime.parse((jsonDecode(response.body) as Map<String, dynamic>)['modifiedTime'] as String).toLocal();
  }

  Future<DateTime> _create(Uint8List bytes) async {
    const boundary = 'hisab-boundary-7d1f';
    final head = utf8.encode('--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n'
        '${jsonEncode({'name': _fileName, 'parents': ['appDataFolder']})}\r\n'
        '--$boundary\r\nContent-Type: application/json\r\n\r\n');
    final tail = utf8.encode('\r\n--$boundary--');
    final body = Uint8List.fromList([...head, ...bytes, ...tail]);
    final response = await _send((h) => _http.post(
          Uri.parse('$_upload/files?uploadType=multipart&fields=modifiedTime'),
          headers: {...h, 'Content-Type': 'multipart/related; boundary=$boundary'},
          body: body,
        ));
    return DateTime.parse((jsonDecode(response.body) as Map<String, dynamic>)['modifiedTime'] as String).toLocal();
  }

  /// Before the current backup is overwritten, keeps a copy of it, but at most one a day.
  /// A failure here is not worth losing the new backup over, so it is swallowed.
  Future<void> _keepPrevious(({String id, DateTime modified}) current) async {
    try {
      final previous = await _find(_previousName);
      if (previous != null && current.modified.difference(previous.modified) < const Duration(hours: 20)) return;
      if (previous != null) {
        await _send((h) => _http.delete(Uri.parse('$_api/files/${previous.id}'), headers: h));
      }
      await _send((h) => _http.post(
            Uri.parse('$_api/files/${current.id}/copy'),
            headers: {...h, 'Content-Type': 'application/json'},
            body: jsonEncode({'name': _previousName, 'parents': ['appDataFolder']}),
          ));
    } on CloudException catch (e) {
      if (e.needsSignIn) rethrow;
    }
  }
}

final cloudBackupServiceProvider = Provider<CloudBackupService>((ref) => GoogleCloudBackupService());
