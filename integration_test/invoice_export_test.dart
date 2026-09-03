import 'dart:io';

import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/money/money.dart';
import 'package:factorino/data/database/app_database.dart';
import 'package:factorino/data/database/database_bootstrap.dart';
import 'package:factorino/data/database/encrypted_database.dart';
import 'package:factorino/data/backup/backup_file_gateway.dart';
import 'package:factorino/data/models/customer.dart';
import 'package:factorino/data/models/invoice.dart';
import 'package:factorino/data/models/invoice_detail.dart';
import 'package:factorino/data/models/invoice_draft.dart';
import 'package:factorino/data/models/seller_identity.dart';
import 'package:factorino/data/providers.dart';
import 'package:factorino/data/repositories/invoice_repository.dart';
import 'package:factorino/features/invoices/application/invoice_document_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

/// The invoice export, end to end through the real providers — Phase 7 (d).
///
/// **An integration test rather than a widget test, and the reason is the
/// filesystem.** What this exists to hold down is §7's answer: the working file
/// is written to app-private storage and **deleted on every path**, delivered
/// or not. A fake filesystem would let that assertion pass about a file that
/// never existed. `getApplicationSupportDirectory` needs a real platform, so
/// this is where the check belongs.
///
/// It also does what nothing else does: it drives the **real** render from the
/// **real** providers — the fonts out of `rootBundle`, the seller out of the
/// settings repository, the view out of a stored invoice — and so it is the
/// first thing to prove `core/pdf/` works when reached from the application
/// rather than from a test that constructs a view by hand.
///
/// The gateway is the one thing faked, because SAF cannot be driven by `adb`
/// (D-071) and the *confirmed* save has its own interactive proof.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Records what it was handed, and whether the file was really there at the
  /// moment of the call.
  ///
  /// **Checking existence inside the gateway is the point.** Asserting only
  /// that the file is gone afterwards would pass just as well if the controller
  /// had never written one — the cleanup would be trivially correct about
  /// nothing. This pins both halves: a real file went in, and no file stayed.
  late File? seenSource;
  late int seenBytes;
  late bool seenExisted;
  late String? seenName;
  late String seenHeader;

  BackupFileGateway gateway({required bool confirm}) => _FakeGateway(
    confirm: confirm,
    onDeliver: (File source, String name) {
      seenSource = source;
      seenExisted = source.existsSync();
      seenBytes = seenExisted ? source.lengthSync() : 0;
      seenHeader = seenExisted
          ? String.fromCharCodes(source.readAsBytesSync().take(5))
          : '';
      seenName = name;
    },
  );

  Future<(ProviderContainer, InvoiceDetail, AppStrings)> seed(
    WidgetTester tester, {
    required bool confirm,
    required SellerIdentity seller,
  }) async {
    final File file = await defaultDatabaseFile(name: 'export_probe.db');
    for (final String suffix in <String>['', '-wal', '-shm']) {
      final File stale = File('${file.path}$suffix');
      if (stale.existsSync()) stale.deleteSync();
    }
    final AppDatabase db = await openAppDatabase(file: file);
    addTearDown(() async {
      await db.close();
      for (final String suffix in <String>['', '-wal', '-shm']) {
        final File probe = File('${file.path}$suffix');
        if (probe.existsSync()) probe.deleteSync();
      }
    });

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(db),
        backupFileGatewayProvider.overrideWithValue(gateway(confirm: confirm)),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(settingsRepositoryProvider)
        .write(
          (await container.read(settingsRepositoryProvider).read()).copyWith(
            seller: seller,
          ),
        );

    final Customer customer = await container
        .read(customerRepositoryProvider)
        .create(
          const CustomerDraft(
            fullName: 'مریم احمدی‌نژاد',
            companyName: 'کارگاه نمونهٔ تهران',
            nationalId: '0079542311',
            address: 'تهران، خیابان ولیعصر، بالاتر از میدان ونک، پلاک ۱۲۳',
            mobile: '09121234567',
          ),
        );

    final InvoiceCreationResult created = await container
        .read(invoiceRepositoryProvider)
        .create(
          InvoiceDraft(
            customerId: customer.id,
            issueDate: DateTime.now().toUtc(),
            dueDate: DateTime.now().toUtc().add(const Duration(days: 30)),
            notes: 'پرداخت تا سررسید انجام شود.',
            discount: Money.rial(5000000),
            items: <InvoiceItemDraft>[
              InvoiceItemDraft(
                title: 'طراحی و پیاده‌سازی سامانهٔ نگه‌داری تجهیزات',
                unit: 'ساعت',
                quantityMilli: 2500,
                unitPrice: Money.rial(133333320),
              ),
            ],
          ),
        );
    final Invoice issued = await container
        .read(invoiceRepositoryProvider)
        .issue(created.invoice.id);

    final InvoiceDetail detail = (await container
        .read(invoiceRepositoryProvider)
        .findDetail(issued.id))!;

    // AppStrings needs a BuildContext, which is why this pumps at all.
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('fa'),
        localizationsDelegates: <LocalizationsDelegate<Object>>[
          AppStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: <Locale>[Locale('fa')],
        home: SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();
    final AppStrings strings = AppStrings.of(
      tester.element(find.byType(SizedBox)),
    );

    return (container, detail, strings);
  }

  testWidgets(
    'a confirmed export writes a real PDF and leaves nothing behind',
    (WidgetTester tester) async {
      final (container, detail, strings) = await seed(
        tester,
        confirm: true,
        seller: const SellerIdentity(
          name: 'مهندسی نوآوران فناوری پارسیان',
          phone: '02188776655',
          address: 'تهران، خیابان شریعتی، پلاک ۴۵۶، واحد ۲',
        ),
      );

      final InvoiceExportOutcome outcome = await container
          .read(invoiceDocumentControllerProvider.notifier)
          .export(detail: detail, strings: strings);

      debugPrint('=== PHASE 7 (d) EXPORT on ${Platform.operatingSystem} ===');
      debugPrint('outcome       : ${outcome.runtimeType}');
      debugPrint('handed a file : $seenExisted, $seenBytes bytes');
      debugPrint('offered name  : $seenName');

      expect(outcome, isA<InvoiceExportSaved>());
      expect(
        (outcome as InvoiceExportSaved).hadSeller,
        isTrue,
        reason: 'a stored seller must reach the document',
      );

      // The gateway was handed a real, non-trivial file.
      expect(seenExisted, isTrue, reason: 'the file must exist when offered');
      // **The magic header rather than a size guess.** A byte count is a
      // proxy: it says something was written, not that it was a document. This
      // says the file the user is handed is a PDF, and the size floor then
      // rules out the empty-but-valid page §12 requires this boundary to fail
      // loudly rather than produce. A real invoice with two embedded Vazirmatn
      // faces measures ~18 KB.
      expect(seenHeader, '%PDF-', reason: 'the file offered must be a PDF');
      expect(
        seenBytes,
        greaterThan(10000),
        reason:
            'two embedded font faces alone put a real page into the tens of '
            'kilobytes; a few hundred bytes would be an empty document',
      );
      expect(
        seenName,
        endsWith('.pdf'),
        reason: 'the offered name carries the extension the file actually is',
      );
      expect(
        seenName,
        contains(detail.invoice.number!),
        reason: "the user's own identifier for the document names the file",
      );

      // ---- the §7 property --------------------------------------------------
      expect(
        seenSource!.existsSync(),
        isFalse,
        reason:
            'the working copy holds the customer full record and the financial '
            'detail, unencrypted, and must not survive the operation that '
            'produced it',
      );

      // And app-private, not a shared directory.
      final Directory support = await getApplicationSupportDirectory();
      expect(
        seenSource!.path,
        startsWith(support.path),
        reason:
            'the working copy is written to app-private storage and moved from '
            'there (D-071), never to Downloads or external storage',
      );
    },
  );

  testWidgets('a cancelled export leaves nothing behind either', (
    WidgetTester tester,
  ) async {
    final (container, detail, strings) = await seed(
      tester,
      confirm: false,
      seller: SellerIdentity.none,
    );

    final InvoiceExportOutcome outcome = await container
        .read(invoiceDocumentControllerProvider.notifier)
        .export(detail: detail, strings: strings);

    debugPrint('cancelled     : ${outcome.runtimeType}');

    expect(
      outcome,
      isA<InvoiceExportCancelled>(),
      reason: 'cancelling is an ordinary outcome, not a failure (D-071)',
    );

    // **The path that would rot quietly.** A cancelled export is the one a
    // careless `finally` misses, and it is also the one nothing in the UI would
    // ever mention again: the user believes no file was produced.
    expect(seenExisted, isTrue, reason: 'a file was produced before the offer');
    expect(
      seenSource!.existsSync(),
      isFalse,
      reason: 'and it is gone even though the user declined to save it',
    );
  });

  testWidgets('an empty seller still produces a document, and says so', (
    WidgetTester tester,
  ) async {
    // D-077: an empty seller blocks nothing. The page prints without the
    // فروشنده block, and the outcome carries the fact so the screen can say so
    // afterwards rather than asking permission beforehand.
    final (container, detail, strings) = await seed(
      tester,
      confirm: true,
      seller: SellerIdentity.none,
    );

    final InvoiceExportOutcome outcome = await container
        .read(invoiceDocumentControllerProvider.notifier)
        .export(detail: detail, strings: strings);

    expect(outcome, isA<InvoiceExportSaved>());
    expect(
      (outcome as InvoiceExportSaved).hadSeller,
      isFalse,
      reason:
          'the notice the screen shows must be true of the file the user now '
          'holds, so the fact comes out of the render rather than being '
          're-derived from settings that may since have changed',
    );
    expect(seenHeader, '%PDF-', reason: 'it still printed a real document');
    expect(seenBytes, greaterThan(10000), reason: 'and a real page of it');
  });
}

class _FakeGateway implements BackupFileGateway {
  _FakeGateway({required this.confirm, required this.onDeliver});

  final bool confirm;
  final void Function(File source, String suggestedName) onDeliver;

  @override
  Future<DeliveredFile?> deliver({
    required File source,
    required String suggestedName,
  }) async {
    onDeliver(source, suggestedName);
    return confirm ? const DeliveredFile('confirmed') : null;
  }

  @override
  Future<bool> receive({required File destination}) async => false;
}
