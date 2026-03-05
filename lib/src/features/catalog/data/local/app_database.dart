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
  int get schemaVersion => 1;

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
    final imagesDynamic = jsonDecode(row.imagesJson);
    final images = imagesDynamic is List
        ? imagesDynamic.whereType<String>().toList()
        : const <String>[];

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
      images: images,
    );
  }
}
