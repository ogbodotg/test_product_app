import 'product.dart';

class PaginatedProducts {
  const PaginatedProducts({
    required this.products,
    required this.total,
    required this.nextRemoteSkip,
    required this.fromCache,
  });

  final List<Product> products;
  final int total;
  final int nextRemoteSkip;
  final bool fromCache;

  bool get hasMore => nextRemoteSkip < total;
}
