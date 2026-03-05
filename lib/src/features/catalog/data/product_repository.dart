import '../domain/paginated_products.dart';
import '../domain/product.dart';
import 'local/app_database.dart';
import 'remote/product_api_service.dart';

abstract class IProductRepository {
  Future<List<String>> fetchCategories();

  Future<PaginatedProducts> fetchProducts({
    required int remoteSkip,
    required int localOffset,
    required int limit,
    required String searchQuery,
    String? category,
  });

  Future<Product> fetchProductById(int id);

  Future<DateTime?> getLastCacheSync();
}

class ProductRepository implements IProductRepository {
  ProductRepository(this._apiService, this._database);

  final ProductApiService _apiService;
  final AppDatabase _database;

  @override
  Future<List<String>> fetchCategories() async {
    try {
      return await _apiService.fetchCategories();
    } catch (_) {
      return _database.getDistinctCategories();
    }
  }

  @override
  Future<PaginatedProducts> fetchProducts({
    required int remoteSkip,
    required int localOffset,
    required int limit,
    required String searchQuery,
    String? category,
  }) async {
    final query = searchQuery.trim();
    final normalizedCategory = category?.trim();

    try {
      final page = await _fetchRemotePage(
        remoteSkip: remoteSkip,
        limit: limit,
        searchQuery: query,
        category: normalizedCategory,
      );

      if (page.products.isNotEmpty) {
        await _database.upsertProducts(page.products);
        await _database.markProductsSynced();
      }

      return page;
    } catch (_) {
      final products = await _database.queryProducts(
        limit: limit,
        offset: localOffset,
        searchQuery: query,
        category: normalizedCategory,
      );
      final total = await _database.countProducts(
        searchQuery: query,
        category: normalizedCategory,
      );

      if (products.isEmpty && total == 0) {
        rethrow;
      }

      return PaginatedProducts(
        products: products,
        total: total,
        nextRemoteSkip: remoteSkip + limit,
        fromCache: true,
      );
    }
  }

  @override
  Future<Product> fetchProductById(int id) async {
    try {
      final remote = await _apiService.fetchProductById(id);
      await _database.upsertProducts([remote]);
      await _database.markProductsSynced();
      return remote;
    } catch (_) {
      final cached = await _database.getProductById(id);
      if (cached != null) {
        return cached;
      }

      rethrow;
    }
  }

  @override
  Future<DateTime?> getLastCacheSync() {
    return _database.getLastProductsSync();
  }

  Future<PaginatedProducts> _fetchRemotePage({
    required int remoteSkip,
    required int limit,
    required String searchQuery,
    String? category,
  }) async {
    if (category != null && category.isNotEmpty) {
      final response = await _apiService.fetchProductsByCategory(
        category: category,
        limit: limit,
        skip: remoteSkip,
      );

      final filtered = searchQuery.isEmpty
          ? response.products
          : response.products
                .where(
                  (product) => product.title.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ),
                )
                .toList();

      return PaginatedProducts(
        products: filtered,
        total: response.total,
        nextRemoteSkip: response.skip + response.limit,
        fromCache: false,
      );
    }

    if (searchQuery.isNotEmpty) {
      final response = await _apiService.searchProducts(
        query: searchQuery,
        limit: limit,
        skip: remoteSkip,
      );

      return PaginatedProducts(
        products: response.products,
        total: response.total,
        nextRemoteSkip: response.skip + response.limit,
        fromCache: false,
      );
    }

    final response = await _apiService.fetchProducts(
      limit: limit,
      skip: remoteSkip,
    );

    return PaginatedProducts(
      products: response.products,
      total: response.total,
      nextRemoteSkip: response.skip + response.limit,
      fromCache: false,
    );
  }
}
