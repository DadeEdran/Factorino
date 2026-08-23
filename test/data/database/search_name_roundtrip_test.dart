import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:factorino/core/formatting/persian_text.dart';
import 'package:factorino/core/security/database_encryption_key.dart';
import 'package:factorino/data/database/app_database.dart';
import 'package:factorino/data/database/database_bootstrap.dart';
import 'package:factorino/data/database/soft_delete.dart';
import 'package:flutter_test/flutter_test.dart';

/// The round trip D-025 actually depends on: a name normalized by [searchKey]
/// on the way **in** is found by a term normalized by [searchKey] on the way
/// **out**, through a real `LIKE` query against a real encrypted database.
///
/// Testing the normalizer alone would not have caught this. The normalizer can
/// be perfect and the search still fail -- if one side folds and the other does
/// not, if the column is compared against the raw term, or if SQLite's `LIKE`
/// treats the stored bytes differently from what Dart produced. The failure is
/// silent in every one of those cases: no error, no exception, just a customer
/// who cannot be found.
///
/// The repository that will own these writes arrives in increment (d). This
/// test establishes the contract it has to meet, against the schema that
/// already exists.
class _FixedKeyStore implements DatabaseKeyStore {
  @override
  Future<DatabaseEncryptionKey> obtain() async =>
      DatabaseEncryptionKey.fromHex('7f' * DatabaseEncryptionKey.lengthBytes);
}

void main() {
  late Directory directory;
  late AppDatabase db;

  setUp(() async {
    directory = Directory.systemTemp.createTempSync('factorino_search');
    db = await openAppDatabase(
      keyStore: _FixedKeyStore(),
      file: File('${directory.path}${Platform.pathSeparator}test.db'),
    );
  });

  tearDown(() async {
    await db.close();
    try {
      directory.deleteSync(recursive: true);
    } on FileSystemException {
      // Windows holds the handle briefly after close.
    }
  });

  /// Writes a customer the way a repository must: display name as entered,
  /// `search_name` from [searchKey]. Both in one statement, so they cannot
  /// diverge.
  Future<String> saveCustomer(String fullName) async {
    final row = await db
        .into(db.customers)
        .insertReturning(
          CustomersCompanion.insert(
            fullName: fullName,
            searchName: Value(searchKey(fullName)),
          ),
        );
    return row.id;
  }

  /// Searches the way a repository must: the user's term through the same
  /// function, then a parameterized LIKE against the indexed column (D-018 --
  /// the term is bound, never interpolated).
  Future<List<String>> search(String term) async {
    final key = searchKey(term);
    final query = db.selectAlive(db.customers)
      ..where((row) => row.searchName.like('%$key%'));
    final rows = await query.get();
    return rows.map((row) => row.fullName).toList();
  }

  group('the §9 example, end to end through SQLite', () {
    test('a customer saved as "علي" is found by typing "علی"', () async {
      await saveCustomer('علي رضایی');
      expect(await search('علی'), <String>['علي رضایی']);
    });

    test('and the reverse: saved Persian, searched Arabic', () async {
      await saveCustomer('علی رضایی');
      expect(await search('علي'), <String>['علی رضایی']);
    });

    test('the kaf variants match in both directions', () async {
      await saveCustomer('كوروش كريمي');
      expect(await search('کوروش'), hasLength(1));
      expect(await search('کریمی'), hasLength(1));
    });
  });

  group('ZWNJ', () {
    test(
      'a name stored with ZWNJ is found without it, and vice versa',
      () async {
        await saveCustomer('علی‌رضا محمدی');

        expect(await search('علی‌رضا'), hasLength(1)); // with ZWNJ
        expect(await search('علیرضا'), hasLength(1)); // joined
        expect(await search('علی رضا'), hasLength(1)); // spaced
      },
    );

    test('a name stored joined is found when typed with ZWNJ', () async {
      await saveCustomer('کتابها');
      expect(await search('کتاب‌ها'), hasLength(1));
    });
  });

  group('digits', () {
    test(
      'all three digit sets match a name stored with any one of them',
      () async {
        await saveCustomer('کالای ۱۲۳');

        expect(await search('کالای 123'), hasLength(1)); // Latin
        expect(await search('کالای ۱۲۳'), hasLength(1)); // Persian
        expect(await search('کالای ١٢٣'), hasLength(1)); // Arabic-Indic
        expect(await search('123'), hasLength(1));
      },
    );

    test(
      'the owner\'s case: both letter variants and three digit sets at once',
      () async {
        // Stored with Arabic letters, a ZWNJ, and mixed digit sets; searched
        // with Persian letters, a space, and Latin digits. Nothing about these
        // two strings is byte-equal.
        await saveCustomer('كالاي‌شماره ۱٢3');

        final found = await search('کالای شماره 123');
        expect(found, hasLength(1));
        expect(
          found.single,
          'كالاي‌شماره ۱٢3',
          reason: 'display name unchanged',
        );
      },
    );
  });

  group('the index still discriminates', () {
    test('a different customer is not returned', () async {
      await saveCustomer('علی رضایی');
      await saveCustomer('محمد حسینی');

      expect(await search('علی'), <String>['علی رضایی']);
      expect(await search('محمد'), <String>['محمد حسینی']);
      expect(await search('نادر'), isEmpty);
    });

    test('a soft-deleted customer is not returned', () async {
      // The two rules compose: search goes through selectAlive as well.
      final id = await saveCustomer('علی رضایی');
      await (db.update(db.customers)..where((row) => row.id.equals(id))).write(
        CustomersCompanion(
          deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

      expect(await search('علی'), isEmpty);
    });
  });

  group('what is stored', () {
    test(
      'the display name is preserved exactly as the user typed it',
      () async {
        const asTyped = 'كالاي‌شماره ۱٢3';
        await saveCustomer(asTyped);

        final row = await db.selectAlive(db.customers).getSingle();
        expect(row.fullName, asTyped, reason: 'never normalize what is shown');
        expect(row.searchName, searchKey(asTyped));
        expect(row.searchName, isNot(asTyped));
      },
    );

    test('the search key is a key, not a display string', () async {
      await saveCustomer('شرکت   سهامی خاص');
      final row = await db.selectAlive(db.customers).getSingle();

      expect(row.searchName.contains(' '), isFalse);
      expect(row.fullName.contains(' '), isTrue);
    });
  });
}
