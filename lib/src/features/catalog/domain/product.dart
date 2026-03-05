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
    this.tags = const [],
    this.sku,
    this.weight,
    this.dimensions,
    this.warrantyInformation,
    this.shippingInformation,
    this.availabilityStatus,
    this.returnPolicy,
    this.minimumOrderQuantity,
    this.reviews = const [],
    this.meta,
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

    final tags = (json['tags'] is List)
        ? (json['tags'] as List)
              .whereType<String>()
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .toList()
        : const <String>[];

    final reviews = <ProductReview>[];
    final reviewsRaw = json['reviews'];
    if (reviewsRaw is List) {
      for (final review in reviewsRaw) {
        if (review is Map<String, dynamic>) {
          reviews.add(ProductReview.fromJson(review));
        }
      }
    }

    final dimensionsRaw = json['dimensions'];
    ProductDimensions? dimensions;
    if (dimensionsRaw is Map<String, dynamic>) {
      dimensions = ProductDimensions.fromJson(dimensionsRaw);
    }

    final metaRaw = json['meta'];
    ProductMeta? meta;
    if (metaRaw is Map<String, dynamic>) {
      meta = ProductMeta.fromJson(metaRaw);
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
      tags: tags,
      sku: _toNonEmptyString(json['sku']),
      weight: _toDouble(json['weight']),
      dimensions: dimensions,
      warrantyInformation: _toNonEmptyString(json['warrantyInformation']),
      shippingInformation: _toNonEmptyString(json['shippingInformation']),
      availabilityStatus: _toNonEmptyString(json['availabilityStatus']),
      returnPolicy: _toNonEmptyString(json['returnPolicy']),
      minimumOrderQuantity: _toInt(json['minimumOrderQuantity']),
      reviews: reviews,
      meta: meta,
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

  final List<String> tags;
  final String? sku;
  final double? weight;
  final ProductDimensions? dimensions;
  final String? warrantyInformation;
  final String? shippingInformation;
  final String? availabilityStatus;
  final String? returnPolicy;
  final int? minimumOrderQuantity;
  final List<ProductReview> reviews;
  final ProductMeta? meta;

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
    List<String>? tags,
    Object? sku = _sentinel,
    Object? weight = _sentinel,
    Object? dimensions = _sentinel,
    Object? warrantyInformation = _sentinel,
    Object? shippingInformation = _sentinel,
    Object? availabilityStatus = _sentinel,
    Object? returnPolicy = _sentinel,
    Object? minimumOrderQuantity = _sentinel,
    List<ProductReview>? reviews,
    Object? meta = _sentinel,
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
      tags: tags ?? this.tags,
      sku: sku == _sentinel ? this.sku : sku as String?,
      weight: weight == _sentinel ? this.weight : weight as double?,
      dimensions: dimensions == _sentinel
          ? this.dimensions
          : dimensions as ProductDimensions?,
      warrantyInformation: warrantyInformation == _sentinel
          ? this.warrantyInformation
          : warrantyInformation as String?,
      shippingInformation: shippingInformation == _sentinel
          ? this.shippingInformation
          : shippingInformation as String?,
      availabilityStatus: availabilityStatus == _sentinel
          ? this.availabilityStatus
          : availabilityStatus as String?,
      returnPolicy: returnPolicy == _sentinel
          ? this.returnPolicy
          : returnPolicy as String?,
      minimumOrderQuantity: minimumOrderQuantity == _sentinel
          ? this.minimumOrderQuantity
          : minimumOrderQuantity as int?,
      reviews: reviews ?? this.reviews,
      meta: meta == _sentinel ? this.meta : meta as ProductMeta?,
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

  static DateTime? _toDateTime(Object? value) {
    final raw = _toNonEmptyString(value);
    if (raw == null) {
      return null;
    }

    return DateTime.tryParse(raw);
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

  static const Object _sentinel = Object();
}

class ProductDimensions {
  const ProductDimensions({this.width, this.height, this.depth});

  factory ProductDimensions.fromJson(Map<String, dynamic> json) {
    return ProductDimensions(
      width: Product._toDouble(json['width']),
      height: Product._toDouble(json['height']),
      depth: Product._toDouble(json['depth']),
    );
  }

  final double? width;
  final double? height;
  final double? depth;

  bool get hasAny => width != null || height != null || depth != null;

  Map<String, dynamic> toJson() {
    return {'width': width, 'height': height, 'depth': depth};
  }
}

class ProductReview {
  const ProductReview({
    required this.rating,
    required this.comment,
    required this.reviewerName,
    required this.reviewerEmail,
    this.date,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      rating: (Product._toInt(json['rating']) ?? 0).clamp(0, 5),
      comment: Product._toNonEmptyString(json['comment']) ?? 'No comment',
      reviewerName:
          Product._toNonEmptyString(json['reviewerName']) ?? 'Anonymous',
      reviewerEmail: Product._toNonEmptyString(json['reviewerEmail']) ?? '-',
      date: Product._toDateTime(json['date']),
    );
  }

  final int rating;
  final String comment;
  final String reviewerName;
  final String reviewerEmail;
  final DateTime? date;

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment,
      'reviewerName': reviewerName,
      'reviewerEmail': reviewerEmail,
      'date': date?.toIso8601String(),
    };
  }
}

class ProductMeta {
  const ProductMeta({
    this.createdAt,
    this.updatedAt,
    this.barcode,
    this.qrCodeUrl,
  });

  factory ProductMeta.fromJson(Map<String, dynamic> json) {
    return ProductMeta(
      createdAt: Product._toDateTime(json['createdAt']),
      updatedAt: Product._toDateTime(json['updatedAt']),
      barcode: Product._toNonEmptyString(json['barcode']),
      qrCodeUrl: Product._validatedUrl(
        Product._toNonEmptyString(json['qrCode']),
      ),
    );
  }

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? barcode;
  final String? qrCodeUrl;

  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'barcode': barcode,
      'qrCode': qrCodeUrl,
    };
  }
}
