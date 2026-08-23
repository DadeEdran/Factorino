import 'dart:math';

import 'package:factorino/core/utils/uuid.dart';
import 'package:flutter_test/flutter_test.dart';

/// D-001 makes UUID v4 the primary key of every table, so that two devices
/// creating rows offline cannot collide when they sync. That guarantee is only
/// as good as the generator, and this one is ours rather than a package's.
void main() {
  final format = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  test('matches the RFC 4122 v4 shape', () {
    for (var i = 0; i < 200; i++) {
      expect(uuidV4(), matches(format));
    }
  });

  test('sets the version and variant bits, whatever the RNG returns', () {
    // Both extremes: an RNG stuck at 0x00 and one stuck at 0xff would each
    // produce a malformed UUID if the bit masking were wrong.
    expect(uuidV4(_ConstantRandom(0x00)), matches(format));
    expect(uuidV4(_ConstantRandom(0xff)), matches(format));

    expect(
      uuidV4(_ConstantRandom(0x00)),
      '00000000-0000-4000-8000-000000000000',
    );
    expect(
      uuidV4(_ConstantRandom(0xff)),
      'ffffffff-ffff-4fff-bfff-ffffffffffff',
    );
  });

  test('does not repeat', () {
    final seen = <String>{};
    for (var i = 0; i < 10000; i++) {
      expect(seen.add(uuidV4()), isTrue, reason: 'duplicate UUID generated');
    }
  });

  test('uses 122 bits of entropy, not a predictable sequence', () {
    // A weak generator that varied only in its low bytes would still match the
    // format test above. Check that the leading bytes actually move.
    final firstBytes = List.generate(500, (_) => uuidV4().substring(0, 8));
    expect(firstBytes.toSet().length, greaterThan(490));
  });
}

class _ConstantRandom implements Random {
  _ConstantRandom(this.value);

  final int value;

  @override
  int nextInt(int max) => value % max;

  @override
  bool nextBool() => throw UnimplementedError();

  @override
  double nextDouble() => throw UnimplementedError();
}
