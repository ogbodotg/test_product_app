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
  });
}
