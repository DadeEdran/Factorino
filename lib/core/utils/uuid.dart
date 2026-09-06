import 'package:uuid/data.dart';
import 'package:uuid/uuid.dart';

/// RFC 4122 version 4 UUID, from `package:uuid`.
///
/// A hand-rolled generator lived here briefly and was **reversed by the project
/// owner** (D-024). The reasoning: a bit-masking bug in a hand-rolled generator
/// surfaces in roughly one run in sixteen, on the primary key of every row, and
/// once sync exists any strange conflict would put our own generator first in
/// the suspect list. The project spec exists to prevent gratuitous dependencies,
/// and ID generation for records that must merge across devices is not that.
///
/// Kept as a one-line wrapper rather than calling `Uuid()` at each site, so the
/// package appears in exactly one place: the schema references this tear-off as
/// a column default, and swapping the implementation again would touch one
/// file. The property tests in `test/core/utils/uuid_test.dart` point here and
/// so survived the swap unchanged.
String uuidV4([List<int>? randomBytes]) {
  return randomBytes == null
      ? _uuid.v4()
      : _uuid.v4(config: V4Options(randomBytes, null));
}

const Uuid _uuid = Uuid();
