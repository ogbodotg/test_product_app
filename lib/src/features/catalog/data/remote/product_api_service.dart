import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/product.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
}

class ProductPageResponse {
  const ProductPageResponse({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  final List<Product> products;
  final int total;
  final int skip;
  final int limit;
}

class ProductApiService {
  ProductApiService(this._client);

  static const String _baseUrl = 'https://dummyjson.com';

  final http.Client _client;

  Future<ProductPageResponse> fetchProducts({
    required int limit,
    required int skip,
  }) {
    final uri = Uri.parse('$_baseUrl/products?limit=$limit&skip=$skip');
    return _fetchPage(uri);
  }

  Future<ProductPageResponse> searchProducts({
    required String query,
    required int limit,
    required int skip,
  }) {
    final encodedQuery = Uri.encodeQueryComponent(query);
    final uri = Uri.parse(
      '$_baseUrl/products/search?q=$encodedQuery&limit=$limit&skip=$skip',
    );
    return _fetchPage(uri);
  }

  Future<ProductPageResponse> fetchProductsByCategory({
    required String category,
    required int limit,
    required int skip,
  }) {
    final encodedCategory = Uri.encodeComponent(category);
    final uri = Uri.parse(
      '$_baseUrl/products/category/$encodedCategory?limit=$limit&skip=$skip',
    );
    return _fetchPage(uri);
  }

  Future<List<String>> fetchCategories() async {
    final uri = Uri.parse('$_baseUrl/products/categories');
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw ApiException(
        'Failed to fetch categories',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw ApiException('Invalid category payload');
    }

    final categories = <String>[];
    for (final item in decoded) {
      if (item is String && item.trim().isNotEmpty) {
        categories.add(item.trim());
        continue;
      }

      if (item is Map<String, dynamic>) {
        final slug = item['slug'];
        if (slug is String && slug.trim().isNotEmpty) {
          categories.add(slug.trim());
        }
      }
    }

    return categories.toSet().toList()..sort();
  }

  Future<Product> fetchProductById(int id) async {
    final uri = Uri.parse('$_baseUrl/products/$id');
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw ApiException(
        'Failed to fetch product detail for id=$id',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid detail payload for id=$id');
    }

    return Product.fromJson(decoded);
  }

  Future<ProductPageResponse> _fetchPage(Uri uri) async {
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw ApiException(
        'Request failed for $uri',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid page payload for $uri');
    }

    final productsJson = decoded['products'];
    final total = decoded['total'];
    final skip = decoded['skip'];
    final limit = decoded['limit'];

    if (productsJson is! List ||
        total is! num ||
        skip is! num ||
        limit is! num) {
      throw ApiException('Malformed page payload for $uri');
    }

    final products = productsJson
        .whereType<Map>()
        .map((item) => Product.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return ProductPageResponse(
      products: products,
      total: total.toInt(),
      skip: skip.toInt(),
      limit: limit.toInt(),
    );
  }
}
