import '../../../core/logging/app_logger.dart';

class Product {
  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.brand,
    required this.category,
    required this.thumbnailUrl,
    required this.images,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final id = _toInt(json['id']) ?? -1;
    final title = _toNonEmptyString(json['title']) ?? 'Untitled product';
    final description =
        _toNonEmptyString(json['description']) ?? 'No description available.';
    final brand = _toNonEmptyString(json['brand']) ?? 'Unknown brand';
    final category = _toNonEmptyString(json['category']) ?? 'Uncategorized';
    final stock = (_toInt(json['stock']) ?? 0).clamp(0, 1 << 31);

    final rawPrice = _toDouble(json['price']);
    double? price;
    if (rawPrice == null || rawPrice <= 0) {
      AppLogger.error(
        'Invalid price for product id=$id; value=${json['price']}',
      );
      price = null;
    } else {
      price = rawPrice;
    }

    final discount = (_toDouble(json['discountPercentage']) ?? 0)
        .clamp(0, 100)
        .toDouble();
    final rating = (_toDouble(json['rating']) ?? 0).clamp(0, 5).toDouble();

    final imageCandidates = <String>[];
    final images = json['images'];
    if (images is List) {
      for (final candidate in images) {
        if (candidate is String) {
          final validated = _validatedUrl(candidate);
          if (validated != null) {
            imageCandidates.add(validated);
          }
        }
      }
    }

    final thumbnail = _validatedUrl(_toNonEmptyString(json['thumbnail']));
    if (thumbnail == null) {
      AppLogger.warning('Missing or invalid thumbnail for product id=$id');
    }

    final primaryImage =
        thumbnail ??
        (imageCandidates.isNotEmpty ? imageCandidates.first : null);

    return Product(
      id: id,
      title: title,
      description: description,
      price: price,
      discountPercentage: discount,
      rating: rating,
      stock: stock,
      brand: brand,
      category: category,
      thumbnailUrl: primaryImage,
      images: imageCandidates,
    );
  }

  final int id;
  final String title;
  final String description;
  final double? price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String brand;
  final String category;
  final String? thumbnailUrl;
  final List<String> images;

  bool get hasDiscount => discountPercentage > 0 && price != null;

  double? get discountedPrice {
    if (price == null) {
      return null;
    }

    return price! * (1 - (discountPercentage / 100));
  }

  bool get inStock => stock > 0;

  Product copyWith({
    int? id,
    String? title,
    String? description,
    double? price,
    double? discountPercentage,
    double? rating,
    int? stock,
    String? brand,
    String? category,
    String? thumbnailUrl,
    List<String>? images,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      rating: rating ?? this.rating,
      stock: stock ?? this.stock,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      images: images ?? this.images,
    );
  }

  static int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  static double? _toDouble(Object? value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  static String? _toNonEmptyString(Object? value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _validatedUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(value);
    if (uri == null) {
      return null;
    }

    if ((uri.scheme != 'https' && uri.scheme != 'http') || uri.host.isEmpty) {
      return null;
    }

    return value;
  }
}
