import 'dart:math';

/// RFC 4122 version 4 UUID, generated from the platform's secure RNG.
///
/// Written here rather than pulled from a package: The project spec asks whether
/// Dart already provides what a dependency would, and `Random.secure()` does.
/// A v4 UUID is 122 random bits with six fixed bits, which is a dozen lines and
/// is directly unit-testable -- against a dependency whose whole surface we
/// would use one function of.
///
/// Primary keys are UUIDs so that rows created offline on two devices cannot
/// collide when they later sync (D-001).
String uuidV4([Random? random]) {
  final rng = random ?? _secure;
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));

  // Version 4 in the high nibble of byte 6.
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  // RFC 4122 variant in the two high bits of byte 8.
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).toList();
  return '${hex.sublist(0, 4).join()}-'
      '${hex.sublist(4, 6).join()}-'
      '${hex.sublist(6, 8).join()}-'
      '${hex.sublist(8, 10).join()}-'
      '${hex.sublist(10, 16).join()}';
}

final Random _secure = Random.secure();
