import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../data/local/app_database.dart';
import '../../data/product_repository.dart';
import '../../data/remote/product_api_service.dart';
import '../../domain/product.dart';
import '../controllers/product_list_controller.dart';
import '../controllers/product_list_state.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final productApiServiceProvider = Provider<ProductApiService>((ref) {
  final client = ref.watch(httpClientProvider);
  return ProductApiService(client);
});

final productRepositoryProvider = Provider<IProductRepository>((ref) {
  final apiService = ref.watch(productApiServiceProvider);
  final database = ref.watch(appDatabaseProvider);
  return ProductRepository(apiService, database);
});

final productListControllerProvider =
    StateNotifierProvider<ProductListController, ProductListState>((ref) {
      final repository = ref.watch(productRepositoryProvider);
      return ProductListController(repository);
    });

final productDetailProvider = FutureProvider.family<Product, int>((
  ref,
  productId,
) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.fetchProductById(productId);
});
