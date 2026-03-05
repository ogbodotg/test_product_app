import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/product.dart';

part 'app_database.g.dart';

class CachedProducts extends Table {
  IntColumn get id => integer()();

  TextColumn get title => text()();

  TextColumn get description => text()();

  RealColumn get price => real().nullable()();

  RealColumn get discountPercentage => real().withDefault(const Constant(0))();

  RealColumn get rating => real().withDefault(const Constant(0))();

  IntColumn get stock => integer().withDefault(const Constant(0))();

  TextColumn get brand => text()();

  TextColumn get category => text()();

  TextColumn get thumbnailUrl => text().nullable()();

  TextColumn get imagesJson => text().withDefault(const Constant('[]'))();

  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();

  TextColumn get sku => text().nullable()();

  RealColumn get weight => real().nullable()();

  TextColumn get dimensionsJson => text().nullable()();

  TextColumn get warrantyInformation => text().nullable()();

  TextColumn get shippingInformation => text().nullable()();

  TextColumn get availabilityStatus => text().nullable()();

  TextColumn get returnPolicy => text().nullable()();

  IntColumn get minimumOrderQuantity => integer().nullable()();

  TextColumn get reviewsJson => text().withDefault(const Constant('[]'))();

  TextColumn get metaJson => text().nullable()();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CacheMeta extends Table {
  TextColumn get key => text()();

  IntColumn get value => integer()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [CachedProducts, CacheMeta])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'catalog_cache_db'));

  static const String _productsLastSyncKey = 'products_last_sync';

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(cachedProducts, cachedProducts.tagsJson);
        await migrator.addColumn(cachedProducts, cachedProducts.sku);
        await migrator.addColumn(cachedProducts, cachedProducts.weight);
        await migrator.addColumn(cachedProducts, cachedProducts.dimensionsJson);
        await migrator.addColumn(
          cachedProducts,
          cachedProducts.warrantyInformation,
        );
        await migrator.addColumn(
          cachedProducts,
          cachedProducts.shippingInformation,
        );
        await migrator.addColumn(
          cachedProducts,
          cachedProducts.availabilityStatus,
        );
        await migrator.addColumn(cachedProducts, cachedProducts.returnPolicy);
        await migrator.addColumn(
          cachedProducts,
          cachedProducts.minimumOrderQuantity,
        );
        await migrator.addColumn(cachedProducts, cachedProducts.reviewsJson);
        await migrator.addColumn(cachedProducts, cachedProducts.metaJson);
      }
    },
  );

  Future<void> upsertProducts(List<Product> products) async {
    if (products.isEmpty) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        cachedProducts,
        products.map((product) {
          return CachedProductsCompanion.insert(
            id: Value(product.id),
            title: product.title,
            description: product.description,
            price: Value(product.price),
            discountPercentage: Value(product.discountPercentage),
            rating: Value(product.rating),
            stock: Value(product.stock),
            brand: product.brand,
            category: product.category,
            thumbnailUrl: Value(product.thumbnailUrl),
            imagesJson: Value(jsonEncode(product.images)),
            tagsJson: Value(jsonEncode(product.tags)),
            sku: Value(product.sku),
            weight: Value(product.weight),
            dimensionsJson: Value(
              product.dimensions == null
                  ? null
                  : jsonEncode(product.dimensions!.toJson()),
            ),
            warrantyInformation: Value(product.warrantyInformation),
            shippingInformation: Value(product.shippingInformation),
            availabilityStatus: Value(product.availabilityStatus),
            returnPolicy: Value(product.returnPolicy),
            minimumOrderQuantity: Value(product.minimumOrderQuantity),
            reviewsJson: Value(
              jsonEncode(
                product.reviews.map((review) => review.toJson()).toList(),
              ),
            ),
            metaJson: Value(
              product.meta == null ? null : jsonEncode(product.meta!.toJson()),
            ),
            updatedAt: now,
          );
        }).toList(),
      );
    });
  }

  Future<List<Product>> queryProducts({
    required int limit,
    required int offset,
    required String searchQuery,
    String? category,
  }) async {
    final query = select(cachedProducts);

    if (category != null && category.isNotEmpty) {
      query.where((tbl) => tbl.category.equals(category));
    }

    if (searchQuery.isNotEmpty) {
      query.where(
        (tbl) => tbl.title.lower().contains(searchQuery.toLowerCase()),
      );
    }

    query
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)])
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map(_toDomainProduct).toList();
  }

  Future<int> countProducts({
    required String searchQuery,
    String? category,
  }) async {
    final countExpr = cachedProducts.id.count();
    final query = selectOnly(cachedProducts)..addColumns([countExpr]);

    if (category != null && category.isNotEmpty) {
      query.where(cachedProducts.category.equals(category));
    }

    if (searchQuery.isNotEmpty) {
      query.where(
        cachedProducts.title.lower().contains(searchQuery.toLowerCase()),
      );
    }

    final row = await query.getSingle();
    return row.read(countExpr) ?? 0;
  }

  Future<List<String>> getDistinctCategories() async {
    final rows = await customSelect(
      'SELECT DISTINCT category FROM cached_products ORDER BY category ASC',
    ).get();

    return rows
        .map((row) => row.data['category'])
        .whereType<String>()
        .where((category) => category.trim().isNotEmpty)
        .toList();
  }

  Future<Product?> getProductById(int id) async {
    final row = await (select(
      cachedProducts,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

    if (row == null) {
      return null;
    }

    return _toDomainProduct(row);
  }

  Future<void> markProductsSynced() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await into(cacheMeta).insertOnConflictUpdate(
      CacheMetaCompanion.insert(key: _productsLastSyncKey, value: now),
    );
  }

  Future<DateTime?> getLastProductsSync() async {
    final row = await (select(
      cacheMeta,
    )..where((tbl) => tbl.key.equals(_productsLastSyncKey))).getSingleOrNull();

    if (row == null) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(row.value);
  }

  Product _toDomainProduct(CachedProduct row) {
    final dimensionsMap = _decodeJsonMap(row.dimensionsJson);
    final metaMap = _decodeJsonMap(row.metaJson);

    return Product(
      id: row.id,
      title: row.title,
      description: row.description,
      price: row.price,
      discountPercentage: row.discountPercentage,
      rating: row.rating,
      stock: row.stock,
      brand: row.brand,
      category: row.category,
      thumbnailUrl: row.thumbnailUrl,
      images: _decodeStringList(row.imagesJson),
      tags: _decodeStringList(row.tagsJson),
      sku: row.sku,
      weight: row.weight,
      dimensions: dimensionsMap == null
          ? null
          : ProductDimensions.fromJson(dimensionsMap),
      warrantyInformation: row.warrantyInformation,
      shippingInformation: row.shippingInformation,
      availabilityStatus: row.availabilityStatus,
      returnPolicy: row.returnPolicy,
      minimumOrderQuantity: row.minimumOrderQuantity,
      reviews: _decodeJsonListOfMaps(
        row.reviewsJson,
      ).map(ProductReview.fromJson).toList(),
      meta: metaMap == null ? null : ProductMeta.fromJson(metaMap),
    );
  }

  List<String> _decodeStringList(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const <String>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <String>[];
      }

      return decoded.whereType<String>().toList();
    } catch (_) {
      return const <String>[];
    }
  }

  Map<String, dynamic>? _decodeJsonMap(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }

      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> _decodeJsonListOfMaps(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <Map<String, dynamic>>[];
      }

      return decoded
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }
}
