import 'dart:io';

import 'package:factorino/data/backup/backup_service.dart';
import 'package:factorino/data/database/app_database.dart';
import 'package:factorino/data/database/encrypted_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../repositories/repository_harness.dart';

/// `pragma key` cannot take a bound variable, so the passphrase reaches SQL as
/// an escaped string literal (D-069). **This is the one place in the codebase
/// where a mistake is silent and unrecoverable**: a wrongly-escaped passphrase
/// keys the file with a string other than the one the user typed, the export
/// reports success, and the user discovers it on the day they need the backup —
/// by which time they have deleted the data it was standing in for.
///
/// So this is not a test of the escaping function. It is a test that a file
/// written with a passphrase **reopens with that same passphrase**, over the
/// characters an Iranian user will actually type (project owner, 2026-09-01).
void main() {
  late RepositoryHarness harness;
  late Directory outDir;

  setUp(() async {
    harness = await RepositoryHarness.open();
    outDir = Directory.systemTemp.createTempSync('factorino_pass');
    await harness.customer(name: 'شرکت آزمون');
  });

  tearDown(() async {
    await harness.close();
    try {
      outDir.deleteSync(recursive: true);
    } on FileSystemException {
      // Windows holds the handle briefly after close.
    }
  });

  /// Every case is a real thing someone types, not a fuzzing corpus.
  final Map<String, String> passphrases = <String, String>{
    'apostrophe': "o'brien-1405",
    'apostrophe, repeated': "it's o'brien's",
    'apostrophe only': "'",
    'double quote': 'say "hello" 1405',
    'backslash': r'C:\Users\backup',
    'backslash before a quote': r"tricky\'value",
    'Persian digits': 'گذرواژه۱۴۰۵',
    'Arabic-Indic digits': 'گذرواژه١٤٠٥',
    'Latin digits': 'gozarvazhe1405',
    'ZWNJ': 'نیم\u200Cفاصله',
    'Persian script, spaced': 'گذرواژهٔ من برای پشتیبان',
    'leading space': ' leading',
    'trailing space': 'trailing ',
    'space at both ends': '  both  ',
    'semicolon and comment marker': "'; drop table customers; --",
    'percent and underscore': 'a%b_c',
    'emoji': 'پشتیبان🔐۱۴۰۵',
    'long': 'ط' * 200,
  };

  group('a container reopens with the passphrase that wrote it', () {
    passphrases.forEach((String label, String passphrase) {
      test(label, () async {
        final File file = File(
          '${outDir.path}${Platform.pathSeparator}pass.backup',
        );

        final BackupSummary summary = await DriftBackupService(harness.db)
            .exportTo(file: file, passphrase: passphrase);

        // The export itself now verifies the reopen (D-069), so reaching here
        // is already most of the assertion. Reopening again, cold, is what a
        // restore does on another device.
        expect(summary.rowCounts['customers'], 1);

        final AppDatabase reopened = AppDatabase(
          openPassphraseKeyedDatabase(file: file, passphrase: passphrase),
        );
        addTearDown(reopened.close);

        final List<CustomerRow> rows = await reopened
            .select(reopened.customers)
            .get();
        expect(rows, hasLength(1));
        expect(rows.single.fullName, 'شرکت آزمون');
      });
    });
  });

  group('and refuses one that did not', () {
    test('an apostrophe passphrase does not open with the escaped form', () {
      // The failure mode the escaping could produce: if `''` were stored
      // rather than `'`, this is the string that would wrongly work.
      return _refuses(harness, outDir, "o'brien", "o''brien");
    });

    test('a trailing space is part of the passphrase', () {
      // Trimming input is a reflex on text fields and would silently change the
      // key. A password is not a name.
      return _refuses(harness, outDir, 'trailing ', 'trailing');
    });

    test('a leading space is part of the passphrase', () {
      return _refuses(harness, outDir, ' leading', 'leading');
    });

    test('Persian digits are NOT normalized to Latin ones', () async {
      // §9 makes digit normalization mandatory for numeric input, and applying
      // that reflex to a password would be a defect: it shrinks the keyspace
      // and, worse, would make the stored key depend on a formatting rule that
      // could later change. The password is bytes, not a number.
      return _refuses(harness, outDir, 'گذرواژه۱۴۰۵', 'گذرواژه1405');
    });

    test('Arabic-Indic digits are not interchangeable with Persian ones', () {
      // ١٤٠٥ (U+0661…) and ۱۴۰۵ (U+06F1…) look alike and are different
      // codepoints. The normalizer maps them together for *search*; it must
      // not for a key.
      return _refuses(harness, outDir, 'گذرواژه١٤٠٥', 'گذرواژه۱۴۰۵');
    });

    test('a ZWNJ is part of the passphrase', () {
      // Invisible, and the difference between two passwords that look
      // identical on screen.
      return _refuses(harness, outDir, 'نیم\u200Cفاصله', 'نیمفاصله');
    });
  });
}

/// Writes with [written] and asserts [attempted] cannot open the result.
Future<void> _refuses(
  RepositoryHarness harness,
  Directory outDir,
  String written,
  String attempted,
) async {
  final File file = File(
    '${outDir.path}${Platform.pathSeparator}refuse.backup',
  );

  await DriftBackupService(harness.db)
      .exportTo(file: file, passphrase: written);

  Object? thrown;
  try {
    final AppDatabase db = AppDatabase(
      openPassphraseKeyedDatabase(file: file, passphrase: attempted),
    );
    await db.customSelect('select 1').get();
    await db.close();
  } catch (error) {
    thrown = error;
  }

  expect(
    thrown,
    isNotNull,
    reason:
        'a container written with one passphrase opened with a different one; '
        'the two are being folded together somewhere',
  );
}
