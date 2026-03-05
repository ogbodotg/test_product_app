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

class _ProductDetailBody extends StatefulWidget {
  const _ProductDetailBody({required this.product});

  final Product product;

  @override
  State<_ProductDetailBody> createState() => _ProductDetailBodyState();
}

class _ProductDetailBodyState extends State<_ProductDetailBody> {
  late final PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
  }

  @override
  void didUpdateWidget(covariant _ProductDetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
      _currentImageIndex = 0;
      _pageController.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrls =
        (widget.product.images.isNotEmpty
                ? widget.product.images
                      .map((value) => value as String?)
                      .toList()
                : <String?>[widget.product.thumbnailUrl])
            .toList();
    final totalImages = imageUrls.length;
    final safeCurrentIndex = _currentImageIndex.clamp(0, totalImages - 1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 260,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: totalImages,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (_, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: AppNetworkImage(
                          imageUrl: imageUrls[index],
                          height: 260,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  right: 16,
                  top: 12,
                  child: _ImageCountPill(
                    current: safeCurrentIndex + 1,
                    total: totalImages,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Text(
            widget.product.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(
                label: widget.product.brand,
                icon: Icons.business_outlined,
              ),
              _MetaChip(
                label: _readableCategory(widget.product.category),
                icon: Icons.category_outlined,
              ),
              _MetaChip(
                label: '${widget.product.rating.toStringAsFixed(1)} rating',
                icon: Icons.star_rounded,
                iconColor: Colors.amber.shade700,
              ),
              if (widget.product.sku != null)
                _MetaChip(
                  label: 'SKU: ${widget.product.sku}',
                  icon: Icons.qr_code,
                ),
            ],
          ),
          const SizedBox(height: 14),
          _PriceInfo(product: widget.product),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                widget.product.inStock ? Icons.check_circle : Icons.cancel,
                color: widget.product.inStock
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                _availabilityText(widget.product),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (widget.product.tags.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Tags',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.product.tags
                  .map(
                    (tag) =>
                        _MetaChip(label: '#$tag', icon: Icons.sell_outlined),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Description',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(widget.product.description, style: theme.textTheme.bodyLarge),
          _KeyDetailsSection(product: widget.product),
          _PolicySection(product: widget.product),
          _ReviewsSection(product: widget.product),
          _MetaSection(product: widget.product),
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

  String _availabilityText(Product product) {
    final status = product.availabilityStatus;
    if (status != null && status.isNotEmpty) {
      if (product.stock > 0) {
        return '$status (${product.stock} available)';
      }

      return status;
    }

    return product.inStock ? '${product.stock} items in stock' : 'Out of stock';
  }
}

class _ImageCountPill extends StatelessWidget {
  const _ImageCountPill({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.onPrimary.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$current / $total',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.icon, this.iconColor});

  final String label;
  final IconData icon;
  final Color? iconColor;

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
          Icon(icon, size: 16, color: iconColor),
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

class _KeyDetailsSection extends StatelessWidget {
  const _KeyDetailsSection({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final details = <MapEntry<String, String>>[];

    if (product.sku != null) {
      details.add(MapEntry('SKU', product.sku!));
    }

    if (product.minimumOrderQuantity != null) {
      details.add(
        MapEntry('Minimum Order', '${product.minimumOrderQuantity} units'),
      );
    }

    if (product.weight != null) {
      details.add(MapEntry('Weight', _formatDouble(product.weight!)));
    }

    final dimensions = product.dimensions;
    if (dimensions != null && dimensions.hasAny) {
      details.add(MapEntry('Dimensions', _formatDimensions(dimensions)));
    }

    if (details.isEmpty) {
      return const SizedBox.shrink();
    }

    return _InfoSection(
      title: 'Product Details',
      children: details
          .map((entry) => _InfoRow(label: entry.key, value: entry.value))
          .toList(),
    );
  }

  String _formatDouble(double value) {
    final hasFraction = value != value.toInt();
    return hasFraction ? value.toStringAsFixed(2) : value.toStringAsFixed(0);
  }

  String _formatDimensions(ProductDimensions dimensions) {
    final width = dimensions.width ?? 0;
    final height = dimensions.height ?? 0;
    final depth = dimensions.depth ?? 0;
    return '${_formatDouble(width)} x ${_formatDouble(height)} x ${_formatDouble(depth)}';
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    if (product.warrantyInformation != null) {
      rows.add(
        _InfoRow(label: 'Warranty', value: product.warrantyInformation!),
      );
    }

    if (product.shippingInformation != null) {
      rows.add(
        _InfoRow(label: 'Shipping', value: product.shippingInformation!),
      );
    }

    if (product.returnPolicy != null) {
      rows.add(_InfoRow(label: 'Return Policy', value: product.returnPolicy!));
    }

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return _InfoSection(title: 'Policies & Shipping', children: rows);
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    if (product.reviews.isEmpty) {
      return const SizedBox.shrink();
    }

    final reviews = product.reviews.take(3).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reviews (${product.reviews.length})',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...reviews.map(
            (review) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text('${review.rating}/5'),
                        const Spacer(),
                        Text(
                          _formatDate(review.date),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      review.comment,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${review.reviewerName} (${review.reviewerEmail})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Unknown date';
    }

    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$month/$day/${dateTime.year}';
  }
}

class _MetaSection extends StatelessWidget {
  const _MetaSection({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final meta = product.meta;
    if (meta == null) {
      return const SizedBox.shrink();
    }

    final rows = <Widget>[];

    if (meta.barcode != null) {
      rows.add(_InfoRow(label: 'Barcode', value: meta.barcode!));
    }

    if (meta.createdAt != null) {
      rows.add(
        _InfoRow(label: 'Created', value: _formatDateTime(meta.createdAt!)),
      );
    }

    if (meta.updatedAt != null) {
      rows.add(
        _InfoRow(
          label: 'Last Updated',
          value: _formatDateTime(meta.updatedAt!),
        ),
      );
    }

    if (meta.qrCodeUrl != null) {
      rows.add(_InfoRow(label: 'QR Code', value: meta.qrCodeUrl!));
    }

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return _InfoSection(title: 'Traceability', children: rows);
  }

  String _formatDateTime(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$month/$day/${dateTime.year} $hour:$minute';
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
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
          color: theme.colorScheme.primary,
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
            color: theme.colorScheme.primary,
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
              color: Colors.red.shade600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '-${product.discountPercentage.toStringAsFixed(0)}%',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.green.shade700,
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
