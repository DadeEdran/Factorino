import 'dart:io';

import '../../core/security/database_encryption_key.dart';
import 'app_database.dart';
import 'encrypted_database.dart';

/// Opens the application database and refuses to hand back one that is not
/// encrypted.
///
/// The order here is the whole point:
///
/// 1. take the key from the OS keystore (generating it on first launch),
/// 2. open through [openEncryptedDatabase] -- the only sanctioned opener,
/// 3. run one statement, which materialises the file and runs migrations,
/// 4. **then** assert the bytes on disk are not a plaintext SQLite database.
///
/// Step 4 has to come last: before the first write the file may not exist at
/// all, and "no file" must never be mistaken for "encrypted" (D-020).
Future<AppDatabase> openAppDatabase({
  DatabaseKeyStore keyStore = const SecureStorageDatabaseKeyStore(),
  File? file,
}) async {
  final target = file ?? await defaultDatabaseFile();
  final key = await keyStore.obtain();

  final database = AppDatabase(openEncryptedDatabase(file: target, key: key));

  try {
    // soft-delete-exempt: touches no table; forces the file to materialise
    // so the header assertion below has something to inspect.
    await database.customSelect('select 1').get();
    assertDatabaseFileIsEncrypted(target);
  } catch (_) {
    // Do not leave a half-open connection behind on a failed startup.
    await database.close();
    rethrow;
  }

  return database;
}
