import 'package:flutter/material.dart';

import '../../../../design_system/components/states_view.dart';
import 'product_detail_screen.dart';
import 'product_list_screen.dart';

class CatalogShellScreen extends StatelessWidget {
  const CatalogShellScreen({required this.selectedProductId, super.key});

  final int? selectedProductId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 768;

        if (!isWide) {
          if (selectedProductId != null) {
            return ProductDetailScreen(
              productId: selectedProductId!,
              embedded: false,
            );
          }

          return const ProductListScreen(
            embedded: false,
            selectedProductId: null,
            useWideNavigation: false,
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                SizedBox(
                  width: constraints.maxWidth.clamp(350, 400).toDouble(),
                  child: ProductListScreen(
                    embedded: true,
                    selectedProductId: selectedProductId,
                    useWideNavigation: true,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: selectedProductId == null
                      ? const StatusView(
                          icon: Icons.touch_app_outlined,
                          title: 'Select a product',
                          message:
                              'Pick any product from the list to view details.',
                        )
                      : ProductDetailScreen(
                          productId: selectedProductId!,
                          embedded: true,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
