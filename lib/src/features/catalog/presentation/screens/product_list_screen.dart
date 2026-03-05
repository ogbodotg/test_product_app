import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/app_search_bar.dart';
import '../../../../design_system/components/category_filter_chip.dart';
import '../../../../design_system/components/loading_skeleton.dart';
import '../../../../design_system/components/product_card.dart';
import '../../../../design_system/components/states_view.dart';
import '../controllers/product_list_state.dart';
import '../providers/catalog_providers.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({
    required this.embedded,
    required this.selectedProductId,
    required this.useWideNavigation,
    super.key,
  });

  final bool embedded;
  final int? selectedProductId;
  final bool useWideNavigation;

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    if (_scrollController.position.extentAfter < 400) {
      ref.read(productListControllerProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ProductListState>(productListControllerProvider, (
      previous,
      next,
    ) {
      if (next.errorMessage == null || next.phase == ProductListPhase.error) {
        return;
      }

      if (previous?.errorMessage == next.errorMessage) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(next.errorMessage!)));
    });

    final state = ref.watch(productListControllerProvider);

    if (_searchController.text != state.searchQuery) {
      _searchController.value = TextEditingValue(
        text: state.searchQuery,
        selection: TextSelection.collapsed(offset: state.searchQuery.length),
      );
    }

    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: AppSearchBar(
            controller: _searchController,
            onChanged: (value) {
              ref
                  .read(productListControllerProvider.notifier)
                  .onSearchQueryChanged(value);
            },
          ),
        ),
        _CategoryRow(state: state),
        if (state.dataSource == CatalogDataSource.cache)
          _CacheBanner(lastSync: state.lastCacheSync),
        Expanded(child: _buildBody(context, state)),
      ],
    );

    if (widget.embedded) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: content,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(productListControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildBody(BuildContext context, ProductListState state) {
    if (state.isInitialLoading) {
      return const SkeletonCardList();
    }

    if (state.phase == ProductListPhase.error) {
      return StatusView(
        icon: Icons.error_outline,
        title: 'Unable to load products',
        message: state.errorMessage ?? 'Something went wrong.',
        actionLabel: 'Retry',
        onAction: () =>
            ref.read(productListControllerProvider.notifier).refresh(),
      );
    }

    if (state.phase == ProductListPhase.empty) {
      return const StatusView(
        icon: Icons.search_off_rounded,
        title: 'No products found',
        message: 'Try a different search keyword or category filter.',
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(productListControllerProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.products.length + (state.isPaginating ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.products.length) {
            return const PaginationLoader();
          }

          final product = state.products[index];

          return ProductCard(
            product: product,
            selected: product.id == widget.selectedProductId,
            onTap: () {
              final route = '/products/${product.id}';
              if (widget.useWideNavigation) {
                context.go(route);
              } else {
                context.push(route);
              }
            },
          );
        },
      ),
    );
  }
}

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({required this.state});

  final ProductListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: CategoryFilterChip(
              label: 'All',
              selected: state.selectedCategory == null,
              onSelected: (_) {
                ref
                    .read(productListControllerProvider.notifier)
                    .toggleCategory(null);
              },
            ),
          ),
          ...state.categories.map((category) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: CategoryFilterChip(
                label: _readableCategory(category),
                selected: state.selectedCategory == category,
                onSelected: (_) {
                  ref
                      .read(productListControllerProvider.notifier)
                      .toggleCategory(category);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  String _readableCategory(String value) {
    final words = value.split('-').where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) {
      return value;
    }

    return words
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class _CacheBanner extends StatelessWidget {
  const _CacheBanner({required this.lastSync});

  final DateTime? lastSync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 18,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              lastSync == null
                  ? 'Showing cached data'
                  : 'Showing cached data from ${_formatTimestamp(lastSync!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$month/$day ${dateTime.year} $hour:$minute';
  }
}
