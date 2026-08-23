import '../../core/money/money.dart';
import 'product_type.dart';

/// A catalogue entry an invoice line can be built from.
///
/// A domain model, not a Drift row (§3). Note that invoice lines **snapshot**
/// what they take from here (D-004): changing a price tomorrow must not rewrite
/// an invoice issued today, so nothing downstream may resolve an invoice's
/// pricing by looking a product up again.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.unit,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  final String id;
  final String name;
  final ProductType type;

  /// Integer Rial behind a value type (D-002). The repository is the single
  /// boundary that converts to and from the schema's plain `int`.
  final Money price;

  /// Unit of measure: عدد, کیلوگرم, ساعت, متر. Free text, because the set of
  /// units a workshop uses is not something this app should presume to fix.
  final String unit;

  final String? description;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isService => type == ProductType.service;

  @override
  bool operator ==(Object other) =>
      other is Product && other.id == id && other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, updatedAt);

  @override
  String toString() => 'Product($id)';
}

/// The editable fields of a product -- what a form produces.
class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.type,
    required this.price,
    required this.unit,
    this.description,
  });

  final String name;
  final ProductType type;
  final Money price;
  final String unit;
  final String? description;

  factory ProductDraft.from(Product product) => ProductDraft(
    name: product.name,
    type: product.type,
    price: product.price,
    unit: product.unit,
    description: product.description,
  );
}
