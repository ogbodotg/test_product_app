import 'package:flutter_test/flutter_test.dart';
import 'package:ogbodo_product_app/src/features/catalog/data/product_repository.dart';
import 'package:ogbodo_product_app/src/features/catalog/domain/paginated_products.dart';
import 'package:ogbodo_product_app/src/features/catalog/domain/product.dart';
import 'package:ogbodo_product_app/src/features/catalog/presentation/controllers/product_list_controller.dart';
import 'package:ogbodo_product_app/src/features/catalog/presentation/controllers/product_list_state.dart';

void main() {
  group('ProductListController', () {
    test('loads initial products and transitions to loaded state', () async {
      final repository = _FakeProductRepository(
        categories: const ['smartphones'],
        fetchProductsHandler:
            ({
              required remoteSkip,
              required localOffset,
              required limit,
              required searchQuery,
              String? category,
            }) async {
              return PaginatedProducts(
                products: [_product(id: 1), _product(id: 2)],
                total: 2,
                nextRemoteSkip: 2,
                fromCache: false,
              );
            },
      );

      final controller = ProductListController(
        repository,
        debounceDuration: Duration.zero,
        pageSize: 2,
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.state.phase, ProductListPhase.loaded);
      expect(controller.state.products, hasLength(2));
      expect(controller.state.categories, ['smartphones']);
      expect(controller.state.hasMore, isFalse);
    });

    test(
      'applies search with debounce and transitions to empty state',
      () async {
        final repository = _FakeProductRepository(
          categories: const ['smartphones'],
          fetchProductsHandler:
              ({
                required remoteSkip,
                required localOffset,
                required limit,
                required searchQuery,
                String? category,
              }) async {
                if (searchQuery == 'zzzz') {
                  return const PaginatedProducts(
                    products: [],
                    total: 0,
                    nextRemoteSkip: 0,
                    fromCache: false,
                  );
                }

                return PaginatedProducts(
                  products: [_product(id: 1)],
                  total: 1,
                  nextRemoteSkip: 1,
                  fromCache: false,
                );
              },
        );

        final controller = ProductListController(
          repository,
          debounceDuration: const Duration(milliseconds: 1),
          pageSize: 1,
        );
        addTearDown(controller.dispose);

        await Future<void>.delayed(const Duration(milliseconds: 20));
        controller.onSearchQueryChanged('zzzz');
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(controller.state.searchQuery, 'zzzz');
        expect(controller.state.phase, ProductListPhase.empty);
        expect(controller.state.products, isEmpty);
      },
    );

    test('loads next page during pagination', () async {
      final repository = _FakeProductRepository(
        categories: const ['smartphones'],
        fetchProductsHandler:
            ({
              required remoteSkip,
              required localOffset,
              required limit,
              required searchQuery,
              String? category,
            }) async {
              if (remoteSkip == 0) {
                return PaginatedProducts(
                  products: [_product(id: 1)],
                  total: 3,
                  nextRemoteSkip: 1,
                  fromCache: false,
                );
              }

              return PaginatedProducts(
                products: [_product(id: 2)],
                total: 3,
                nextRemoteSkip: 3,
                fromCache: false,
              );
            },
      );

      final controller = ProductListController(
        repository,
        debounceDuration: Duration.zero,
        pageSize: 1,
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      await controller.loadNextPage();

      expect(controller.state.products.map((product) => product.id), [1, 2]);
      expect(controller.state.phase, ProductListPhase.loaded);
      expect(controller.state.hasMore, isFalse);
    });
  });
}

class _FakeProductRepository implements IProductRepository {
  _FakeProductRepository({
    required this.fetchProductsHandler,
    this.categories = const [],
  });

  final Future<PaginatedProducts> Function({
    required int remoteSkip,
    required int localOffset,
    required int limit,
    required String searchQuery,
    String? category,
  })
  fetchProductsHandler;

  final List<String> categories;

  @override
  Future<List<String>> fetchCategories() async => categories;

  @override
  Future<Product> fetchProductById(int id) async => _product(id: id);

  @override
  Future<PaginatedProducts> fetchProducts({
    required int remoteSkip,
    required int localOffset,
    required int limit,
    required String searchQuery,
    String? category,
  }) {
    return fetchProductsHandler(
      remoteSkip: remoteSkip,
      localOffset: localOffset,
      limit: limit,
      searchQuery: searchQuery,
      category: category,
    );
  }

  @override
  Future<DateTime?> getLastCacheSync() async => null;
}

Product _product({required int id}) {
  return Product(
    id: id,
    title: 'Product $id',
    description: 'Description $id',
    price: 100,
    discountPercentage: 0,
    rating: 4,
    stock: 5,
    brand: 'Brand',
    category: 'smartphones',
    thumbnailUrl: null,
    images: const [],
  );
}
