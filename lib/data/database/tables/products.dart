import 'package:drift/drift.dart';

import '../../models/product_type.dart';
import 'sync_columns.dart';

/// The catalogue an invoice line can be built from.
///
/// Note that invoice lines **snapshot** what they took from here rather than
/// referencing it at read time (D-004): changing a price tomorrow must not
/// rewrite an invoice issued today.
@TableIndex(name: 'idx_products_deleted_at', columns: {#deletedAt})
@TableIndex(name: 'idx_products_search_name', columns: {#searchName})
@DataClassName('ProductRow')
class Products extends Table with SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 160)();

  IntColumn get type => intEnum<ProductType>()();

  /// Integer **Rial**, never a double (D-002). Toman is a display unit only.
  IntColumn get priceRial => integer()();

  /// Unit of measure: عدد, کیلوگرم, ساعت, متر ... Free text, because the set of
  /// units a workshop uses is not something this app should presume to fix.
  TextColumn get unit => text().withLength(min: 1, max: 30)();

  TextColumn get description => text().withLength(max: 2000).nullable()();

  /// Normalized [name] for accent- and ZWNJ-insensitive search (§9).
  /// See the note on `Customers.searchName`.
  TextColumn get searchName =>
      text().withLength(max: 200).withDefault(const Constant(''))();
}
