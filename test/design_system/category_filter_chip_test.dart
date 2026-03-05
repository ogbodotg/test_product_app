import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ogbodo_product_app/src/design_system/components/category_filter_chip.dart';

void main() {
  testWidgets('renders category label and selected state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryFilterChip(
            label: 'Smartphones',
            selected: true,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Smartphones'), findsOneWidget);
    final chip = tester.widget<FilterChip>(find.byType(FilterChip));
    expect(chip.selected, isTrue);
  });
}
