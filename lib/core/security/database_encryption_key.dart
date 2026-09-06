import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The raw key material used to encrypt the database at rest.
///
/// Wrapped in a type of its own rather than passed around as a bare [String]
/// so that a key can never be produced by accident from an arbitrary value,
/// and so that [toString] can be overridden to keep the key out of logs and
/// crash reports (the project spec — the key is never logged).
class DatabaseEncryptionKey {
  DatabaseEncryptionKey.fromHex(this.hex) {
    if (hex.length != lengthBytes * 2 || !_isHex.hasMatch(hex)) {
      throw ArgumentError.value(
        '<redacted>',
        'hex',
        'expected ${lengthBytes * 2} lowercase hex characters',
      );
    }
  }

  /// Generates a new key from the platform's cryptographically secure RNG.
  factory DatabaseEncryptionKey.generate() {
    final random = Random.secure();
    final bytes = Uint8List(lengthBytes);
    for (var i = 0; i < lengthBytes; i++) {
      bytes[i] = random.nextInt(256);
    }
    return DatabaseEncryptionKey.fromHex(
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    );
  }

  /// 256-bit key, matching the SQLCipher-compatible cipher configured in
  /// [connectionSetupStatements].
  static const int lengthBytes = 32;

  static final RegExp _isHex = RegExp(r'^[0-9a-f]+$');

  /// Lowercase hex, without an `0x` prefix or `x'...'` wrapper.
  final String hex;

  /// Never render the key, however this object is interpolated.
  @override
  String toString() => 'DatabaseEncryptionKey(<redacted>)';
}

/// Where the database key is kept between launches.
abstract class DatabaseKeyStore {
  /// Returns the existing key, generating and persisting one on first launch.
  Future<DatabaseEncryptionKey> obtain();
}

/// Backed by the OS keystore: Android Keystore via `EncryptedSharedPreferences`,
/// DPAPI on Windows.
///
/// Losing this key means losing the data. That consequence is the reason the
/// backup feature is in the MVP rather than a later phase.
class SecureStorageDatabaseKeyStore implements DatabaseKeyStore {
  const SecureStorageDatabaseKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? _defaultStorage;

  /// Versioned so a future key-rotation or cipher change can migrate rather
  /// than silently read a key that no longer opens the file.
  static const String entryKey = 'factorino.db.key.v1';

  /// `resetOnError: false` is the important setting here, and it is not the
  /// package default. The default (`true`) clears the stored entry when a read
  /// fails, which for an ordinary token is a harmless re-login but here would
  /// discard the only key that can open the user's database -- turning a
  /// transient keystore error into permanent, silent loss of every invoice.
  /// Failing loudly is the correct behaviour; the backup feature
  /// is the recovery path.
  static const FlutterSecureStorage _defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: false),
    wOptions: WindowsOptions(),
  );

  final FlutterSecureStorage _storage;

  @override
  Future<DatabaseEncryptionKey> obtain() async {
    final existing = await _storage.read(key: entryKey);
    if (existing != null && existing.isNotEmpty) {
      return DatabaseEncryptionKey.fromHex(existing);
    }
    final generated = DatabaseEncryptionKey.generate();
    await _storage.write(key: entryKey, value: generated.hex);
    return generated;
  }
}
