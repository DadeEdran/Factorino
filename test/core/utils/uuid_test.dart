import 'package:factorino/core/utils/uuid.dart';
import 'package:flutter_test/flutter_test.dart';

/// D-001 makes UUID v4 the primary key of every table, so that two devices
/// creating rows offline cannot collide when they later sync.
///
/// These properties were written against a hand-rolled generator. D-024
/// reversed that in favour of `package:uuid`; the tests stayed and now point at
/// the wrapper, which is the point of keeping them — a dependency swap is
/// exactly when you want the old guarantees re-checked rather than assumed.
void main() {
  final format = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  test('matches the RFC 4122 v4 shape', () {
    for (var i = 0; i < 200; i++) {
      expect(uuidV4(), matches(format));
    }
  });

  test('sets the version and variant bits, whatever the bytes are', () {
    // Both extremes: all-zero and all-ones random material would each produce
    // a malformed UUID if the version/variant masking were wrong.
    final zeros = uuidV4(List<int>.filled(16, 0x00));
    final ones = uuidV4(List<int>.filled(16, 0xff));

    expect(zeros, matches(format));
    expect(ones, matches(format));
    expect(zeros, '00000000-0000-4000-8000-000000000000');
    expect(ones, 'ffffffff-ffff-4fff-bfff-ffffffffffff');
  });

  test('does not repeat', () {
    final seen = <String>{};
    for (var i = 0; i < 10000; i++) {
      expect(seen.add(uuidV4()), isTrue, reason: 'duplicate UUID generated');
    }
  });

  test('uses real entropy, not a predictable sequence', () {
    // A weak generator that varied only in its low bytes would still satisfy
    // the format test above. Check that the leading bytes actually move.
    final firstBytes = List.generate(500, (_) => uuidV4().substring(0, 8));
    expect(firstBytes.toSet().length, greaterThan(490));
  });
}
