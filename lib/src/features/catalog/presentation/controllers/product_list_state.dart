import '../../domain/product.dart';

enum ProductListPhase { initial, loading, loaded, empty, error }

enum CatalogDataSource { network, cache }

class ProductListState {
  const ProductListState({
    required this.phase,
    required this.products,
    required this.categories,
    required this.searchQuery,
    required this.selectedCategory,
    required this.isPaginating,
    required this.hasMore,
    required this.errorMessage,
    required this.dataSource,
    required this.lastCacheSync,
  });

  factory ProductListState.initial() {
    return const ProductListState(
      phase: ProductListPhase.initial,
      products: [],
      categories: [],
      searchQuery: '',
      selectedCategory: null,
      isPaginating: false,
      hasMore: true,
      errorMessage: null,
      dataSource: CatalogDataSource.network,
      lastCacheSync: null,
    );
  }

  final ProductListPhase phase;
  final List<Product> products;
  final List<String> categories;
  final String searchQuery;
  final String? selectedCategory;
  final bool isPaginating;
  final bool hasMore;
  final String? errorMessage;
  final CatalogDataSource dataSource;
  final DateTime? lastCacheSync;

  bool get isInitialLoading =>
      (phase == ProductListPhase.initial ||
          phase == ProductListPhase.loading) &&
      products.isEmpty;

  ProductListState copyWith({
    ProductListPhase? phase,
    List<Product>? products,
    List<String>? categories,
    String? searchQuery,
    Object? selectedCategory = _sentinel,
    bool? isPaginating,
    bool? hasMore,
    Object? errorMessage = _sentinel,
    CatalogDataSource? dataSource,
    Object? lastCacheSync = _sentinel,
  }) {
    return ProductListState(
      phase: phase ?? this.phase,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory == _sentinel
          ? this.selectedCategory
          : selectedCategory as String?,
      isPaginating: isPaginating ?? this.isPaginating,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      dataSource: dataSource ?? this.dataSource,
      lastCacheSync: lastCacheSync == _sentinel
          ? this.lastCacheSync
          : lastCacheSync as DateTime?,
    );
  }
}

const Object _sentinel = Object();
