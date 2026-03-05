import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/catalog/presentation/screens/catalog_shell_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/products',
    routes: [
      GoRoute(path: '/', redirect: (_, state) => '/products'),
      GoRoute(
        path: '/products',
        pageBuilder: (context, state) {
          return const MaterialPage(
            child: CatalogShellScreen(selectedProductId: null),
          );
        },
        routes: [
          GoRoute(
            path: ':id',
            pageBuilder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');

              if (id == null) {
                return const MaterialPage(
                  child: _RouteErrorView(message: 'Invalid product id'),
                );
              }

              return MaterialPage(
                child: CatalogShellScreen(selectedProductId: id),
              );
            },
          ),
        ],
      ),
    ],
  );
});

class _RouteErrorView extends StatelessWidget {
  const _RouteErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route Error')),
      body: Center(child: Text(message)),
    );
  }
}
