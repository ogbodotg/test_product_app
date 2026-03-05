import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/app_network_image.dart';
import '../../../../design_system/components/states_view.dart';
import '../../domain/product.dart';
import '../providers/catalog_providers.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({
    required this.productId,
    required this.embedded,
    super.key,
  });

  final int productId;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(productDetailProvider(productId));

    final body = detailAsync.when(
      loading: () => const _DetailLoading(),
      error: (error, stackTrace) => StatusView(
        icon: Icons.error_outline,
        title: 'Unable to load detail',
        message: 'We could not retrieve product #$productId.',
        actionLabel: 'Retry',
        onAction: () {
          ref.invalidate(productDetailProvider(productId));
        },
      ),
      data: (product) => _ProductDetailBody(product: product),
    );

    if (embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Product Detail')),
      body: body,
    );
  }
}

class _ProductDetailBody extends StatelessWidget {
  const _ProductDetailBody({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrls =
        (product.images.isNotEmpty ? product.images : [product.thumbnailUrl])
            .whereType<String>()
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AppNetworkImage(
                    imageUrl: imageUrls.isEmpty ? null : imageUrls[index],
                    height: 260,
                    width: 320,
                    fit: BoxFit.cover,
                  ),
                );
              },
              separatorBuilder: (_, index) => const SizedBox(width: 12),
              itemCount: imageUrls.isEmpty ? 1 : imageUrls.length,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            product.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: product.brand, icon: Icons.business_outlined),
              _MetaChip(
                label: _readableCategory(product.category),
                icon: Icons.category_outlined,
              ),
              _MetaChip(
                label: '${product.rating.toStringAsFixed(1)} rating',
                icon: Icons.star_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PriceInfo(product: product),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                product.inStock ? Icons.check_circle : Icons.cancel,
                color: product.inStock
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                product.inStock
                    ? '${product.stock} items in stock'
                    : 'Out of stock',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Description',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(product.description, style: theme.textTheme.bodyLarge),
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceInfo extends StatelessWidget {
  const _PriceInfo({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (product.price == null) {
      return Text(
        'Price unavailable',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.error,
        ),
      );
    }

    final discountedPrice = product.discountedPrice;

    if (!product.hasDiscount || discountedPrice == null) {
      return Text(
        _money(product.price!),
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _money(discountedPrice),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            _money(product.price!),
            style: theme.textTheme.bodyLarge?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '-${product.discountPercentage.toStringAsFixed(0)}%',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  String _money(double value) => '\$${value.toStringAsFixed(2)}';
}

class _DetailLoading extends StatelessWidget {
  const _DetailLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
