import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../data/product_repository.dart';
import '../../domain/product.dart';
import 'product_list_state.dart';

class ProductListController extends StateNotifier<ProductListState> {
  ProductListController(
    this._repository, {
    Duration debounceDuration = const Duration(milliseconds: 450),
    this.pageSize = 20,
  }) : _debounceDuration = debounceDuration,
       super(ProductListState.initial()) {
    unawaited(_initialize());
  }

  final IProductRepository _repository;
  final Duration _debounceDuration;
  final int pageSize;

  Timer? _searchDebounce;
  int _remoteSkip = 0;
  int _requestId = 0;

  Future<void> _initialize() async {
    await _loadCategories();
    await refresh();
  }

  Future<void> _loadCategories() async {
    final categories = await _repository.fetchCategories();
    state = state.copyWith(categories: categories);
  }

  void onSearchQueryChanged(String query) {
    state = state.copyWith(searchQuery: query);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_debounceDuration, () {
      unawaited(refresh());
    });
  }

  Future<void> toggleCategory(String? category) async {
    final normalized = category?.trim();
    final nextSelection = state.selectedCategory == normalized
        ? null
        : normalized;

    state = state.copyWith(selectedCategory: nextSelection);
    await refresh();
  }

  Future<void> refresh() async {
    _searchDebounce?.cancel();

    final requestId = ++_requestId;
    _remoteSkip = 0;

    state = state.copyWith(
      phase: ProductListPhase.loading,
      products: const [],
      hasMore: true,
      errorMessage: null,
      isPaginating: false,
      dataSource: CatalogDataSource.network,
    );

    await _fetchPage(requestId: requestId, isPagination: false);
  }

  Future<void> loadNextPage() async {
    if (!state.hasMore || state.isPaginating || state.isInitialLoading) {
      return;
    }

    state = state.copyWith(isPaginating: true, errorMessage: null);

    await _fetchPage(requestId: _requestId, isPagination: true);
  }

  Future<void> _fetchPage({
    required int requestId,
    required bool isPagination,
  }) async {
    final baseProducts = isPagination ? state.products : <Product>[];
    final collectedProducts = <Product>[];

    bool reachedEnd = false;
    bool usedCache = false;

    try {
      while (true) {
        final page = await _repository.fetchProducts(
          remoteSkip: _remoteSkip,
          localOffset: baseProducts.length + collectedProducts.length,
          limit: pageSize,
          searchQuery: state.searchQuery,
          category: state.selectedCategory,
        );

        if (requestId != _requestId) {
          return;
        }

        _remoteSkip = page.nextRemoteSkip;
        usedCache = usedCache || page.fromCache;
        reachedEnd = !page.hasMore;

        if (page.products.isNotEmpty) {
          collectedProducts.addAll(page.products);
        }

        final shouldContinue =
            collectedProducts.isEmpty && !reachedEnd && !page.fromCache;

        if (!shouldContinue) {
          break;
        }
      }

      final merged = <Product>[...baseProducts, ...collectedProducts];
      final cacheSync = await _repository.getLastCacheSync();

      state = state.copyWith(
        phase: merged.isEmpty
            ? ProductListPhase.empty
            : ProductListPhase.loaded,
        products: merged,
        hasMore: !reachedEnd,
        isPaginating: false,
        errorMessage: null,
        dataSource: usedCache
            ? CatalogDataSource.cache
            : CatalogDataSource.network,
        lastCacheSync: cacheSync,
      );
    } catch (error, stackTrace) {
      AppLogger.error('Failed to load product list', error, stackTrace);

      if (requestId != _requestId) {
        return;
      }

      if (isPagination && state.products.isNotEmpty) {
        state = state.copyWith(
          isPaginating: false,
          errorMessage: 'Could not load more products. Pull to retry.',
        );
        return;
      }

      state = state.copyWith(
        phase: ProductListPhase.error,
        products: const [],
        hasMore: false,
        isPaginating: false,
        errorMessage: 'Could not load products. Please try again.',
      );
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
