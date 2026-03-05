import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ogbodo_product_app/src/design_system/components/product_card.dart';
import 'package:ogbodo_product_app/src/features/catalog/domain/product.dart';

void main() {
  testWidgets('shows fallback price label when price is missing', (
    tester,
  ) async {
    final product = Product(
      id: 10,
      title: 'Sample Product',
      description: 'Sample description',
      price: null,
      discountPercentage: 0,
      rating: 4.2,
      stock: 0,
      brand: 'Unknown brand',
      category: 'misc',
      thumbnailUrl: null,
      images: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductCard(product: product, onTap: () {}),
        ),
      ),
    );

    expect(find.text('Sample Product'), findsOneWidget);
    expect(find.text('Price unavailable'), findsOneWidget);
    expect(find.text('Out of stock'), findsOneWidget);
  });
}
