import 'package:flutter_test/flutter_test.dart';
import 'package:ogbodo_product_app/src/features/catalog/domain/product.dart';

void main() {
  group('Product.fromJson', () {
    test('applies defaults and validation for missing/invalid fields', () {
      final product = Product.fromJson({
        'id': '7',
        'title': '   ',
        'description': null,
        'price': -10,
        'discountPercentage': -8,
        'rating': 8,
        'stock': -2,
        'brand': null,
        'category': '',
        'thumbnail': 'not-a-url',
        'images': ['https://example.com/image.png', 'invalid-url'],
      });

      expect(product.id, 7);
      expect(product.title, 'Untitled product');
      expect(product.description, 'No description available.');
      expect(product.price, isNull);
      expect(product.discountPercentage, 0);
      expect(product.rating, 5);
      expect(product.stock, 0);
      expect(product.brand, 'Unknown brand');
      expect(product.category, 'Uncategorized');
      expect(product.thumbnailUrl, 'https://example.com/image.png');
      expect(product.images, ['https://example.com/image.png']);
      expect(product.tags, isEmpty);
      expect(product.reviews, isEmpty);
      expect(product.meta, isNull);
    });

    test('computes discounted price when valid values are present', () {
      final product = Product.fromJson({
        'id': 1,
        'title': 'Phone',
        'description': 'A phone',
        'price': 100,
        'discountPercentage': 10,
        'rating': 4.5,
        'stock': 12,
        'brand': 'BrandX',
        'category': 'smartphones',
        'thumbnail': 'https://example.com/thumb.png',
        'images': ['https://example.com/thumb.png'],
      });

      expect(product.price, 100);
      expect(product.hasDiscount, isTrue);
      expect(product.discountedPrice, 90);
    });

    test('parses rich detail fields from payload', () {
      final product = Product.fromJson({
        'id': 1,
        'title': 'Essence Mascara Lash Princess',
        'description': 'Long-lasting and cruelty-free formula.',
        'category': 'beauty',
        'price': 9.99,
        'discountPercentage': 10.48,
        'rating': 2.56,
        'stock': 99,
        'tags': ['beauty', 'mascara'],
        'brand': 'Essence',
        'sku': 'BEA-ESS-ESS-001',
        'weight': 4,
        'dimensions': {'width': 15.14, 'height': 13.08, 'depth': 22.99},
        'warrantyInformation': '1 week warranty',
        'shippingInformation': 'Ships in 3-5 business days',
        'availabilityStatus': 'In Stock',
        'reviews': [
          {
            'rating': 3,
            'comment': 'Would not recommend!',
            'date': '2025-04-30T09:41:02.053Z',
            'reviewerName': 'Eleanor Collins',
            'reviewerEmail': 'eleanor.collins@x.dummyjson.com',
          },
        ],
        'returnPolicy': 'No return policy',
        'minimumOrderQuantity': 48,
        'meta': {
          'createdAt': '2025-04-30T09:41:02.053Z',
          'updatedAt': '2025-04-30T09:41:02.053Z',
          'barcode': '5784719087687',
          'qrCode': 'https://cdn.dummyjson.com/public/qr-code.png',
        },
        'images': [
          'https://cdn.dummyjson.com/product-images/beauty/essence-mascara-lash-princess/1.webp',
        ],
        'thumbnail':
            'https://cdn.dummyjson.com/product-images/beauty/essence-mascara-lash-princess/thumbnail.webp',
      });

      expect(product.tags, ['beauty', 'mascara']);
      expect(product.sku, 'BEA-ESS-ESS-001');
      expect(product.weight, 4);
      expect(product.dimensions, isNotNull);
      expect(product.dimensions!.width, 15.14);
      expect(product.warrantyInformation, '1 week warranty');
      expect(product.shippingInformation, 'Ships in 3-5 business days');
      expect(product.availabilityStatus, 'In Stock');
      expect(product.returnPolicy, 'No return policy');
      expect(product.minimumOrderQuantity, 48);
      expect(product.reviews, hasLength(1));
      expect(product.reviews.first.reviewerName, 'Eleanor Collins');
      expect(product.meta, isNotNull);
      expect(product.meta!.barcode, '5784719087687');
      expect(
        product.meta!.qrCodeUrl,
        'https://cdn.dummyjson.com/public/qr-code.png',
      );
    });
  });
}
