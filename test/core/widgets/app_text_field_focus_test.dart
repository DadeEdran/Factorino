import 'package:factorino/core/localization/generated/app_strings.dart';
import 'package:factorino/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Focusing a **numeric** field selects what is in it, so typing replaces.
///
/// **Reported from the phone.** Changing a quantity from ۱ to ۳ meant clearing
/// the ۱ by hand first. A number is replaced far more often than it is edited
/// in place, and every numeric field in the application has the same problem —
/// so the behaviour belongs in the shared field rather than at nine call sites.
///
/// **Prose deliberately keeps the caret.** Tapping into a note or an address is
/// nearly always to put the cursor somewhere; selecting it all there would arm
/// the next keystroke to destroy what is written.
void main() {
  Future<TextEditingController> pump(
    WidgetTester tester, {
    required String initial,
    required TextInputType? keyboardType,
    int maxLines = 1,
  }) async {
    final TextEditingController controller = TextEditingController(
      text: initial,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fa'),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AppStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: AppTextField(
            controller: controller,
            label: 'مقدار',
            maxLength: 200,
            keyboardType: keyboardType,
            maxLines: maxLines,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('a numeric field selects all of itself when focused', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = await pump(
      tester,
      initial: '۱',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();

    expect(
      controller.selection,
      const TextSelection(baseOffset: 0, extentOffset: 1),
      reason: 'typing must replace the value, not append to it',
    );
  });

  testWidgets('so does a phone field, which is a number the user retypes', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = await pump(
      tester,
      initial: '09121234567',
      keyboardType: TextInputType.phone,
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 0);
    expect(controller.selection.extentOffset, '09121234567'.length);
  });

  testWidgets('a prose field keeps the caret where it was put', (
    WidgetTester tester,
  ) async {
    // The half that would be a defect rather than a convenience.
    final TextEditingController controller = await pump(
      tester,
      initial: 'تهران، خیابان ولیعصر',
      keyboardType: null,
      maxLines: 3,
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();

    expect(
      controller.selection.baseOffset == 0 &&
          controller.selection.extentOffset == controller.text.length,
      isFalse,
      reason:
          'selecting an address on focus arms the next keystroke to delete it',
    );
  });

  testWidgets('an empty numeric field is left alone', (
    WidgetTester tester,
  ) async {
    // Nothing to select, and a selection over an empty string is a shape worth
    // never constructing.
    final TextEditingController controller = await pump(
      tester,
      initial: '',
      keyboardType: TextInputType.number,
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();

    expect(controller.text, isEmpty);
    expect(controller.selection.extentOffset <= 0, isTrue);
  });
}
