class Car {
  final int id;
  final String brand;
  final int? brandId;
  final String model;
  final int? modelId;
  final int year;
  final String plateNumber;
  final double pricePerDay;
  final String status;
  final int? categoryId;
  final String? category;
  final String? imageUrl;

  // Today's offer, sent by the server. Null when there is none.
  final double? discountedPricePerDay;
  final String? offerName;
  final String? offerType;
  final double? offerPercentage;
  final String? offerEndDate;

  const Car({
    required this.id,
    required this.brand,
    this.brandId,
    required this.model,
    this.modelId,
    required this.year,
    required this.plateNumber,
    required this.pricePerDay,
    required this.status,
    this.categoryId,
    this.category,
    this.imageUrl,
    this.discountedPricePerDay,
    this.offerName,
    this.offerType,
    this.offerPercentage,
    this.offerEndDate,
  });

  // Falls back to the normal price when there is no offer today.
  double get effectivePricePerDay =>
      discountedPricePerDay ?? pricePerDay;

  String get fullName => '$brand $model';

  bool get isAvailable => status == 'AVAILABLE';

  bool get hasDiscount =>
      offerType == 'DISCOUNT' && effectivePricePerDay < pricePerDay;

  bool get hasSurcharge =>
      offerType == 'INCREASE' && effectivePricePerDay > pricePerDay;

  factory Car.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? categoryJson =
    json['category'] is Map
        ? Map<String, dynamic>.from(
      json['category'] as Map,
    )
        : null;

    final Map<String, dynamic>? offerJson = json['offer'] is Map
        ? Map<String, dynamic>.from(
      json['offer'] as Map,
    )
        : null;

    return Car(
      id: (json['id'] as num).toInt(),
      brand: json['brand']?.toString() ?? '',
      brandId: (json['brandId'] as num?)?.toInt(),
      model: json['model']?.toString() ?? '',
      modelId: (json['modelId'] as num?)?.toInt(),
      year: (json['year'] as num).toInt(),
      plateNumber:
      json['plateNumber']?.toString() ?? '',
      pricePerDay:
      (json['pricePerDay'] as num).toDouble(),
      status: json['status']?.toString() ?? '',
      categoryId:
      (categoryJson?['id'] as num?)?.toInt(),
      category: categoryJson?['name']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      discountedPricePerDay:
      (json['effectivePricePerDay'] as num?)?.toDouble(),
      offerName: offerJson?['name']?.toString(),
      offerType: offerJson?['adjustmentType']?.toString(),
      offerPercentage:
      (offerJson?['percentage'] as num?)?.toDouble(),
      offerEndDate: offerJson?['endDate']?.toString(),
    );
  }
}

class CarPage {
  final List<Car> items;
  final CarPagination pagination;

  const CarPage({
    required this.items,
    required this.pagination,
  });

  factory CarPage.fromJson(Map<String, dynamic> json) {
    final List<dynamic> itemsJson =
        json['items'] as List<dynamic>? ?? [];

    final Map<String, dynamic> paginationJson =
    json['pagination'] is Map
        ? Map<String, dynamic>.from(
      json['pagination'] as Map,
    )
        : <String, dynamic>{};

    return CarPage(
      items: itemsJson
          .map(
            (item) => Car.fromJson(
          Map<String, dynamic>.from(
            item as Map,
          ),
        ),
      )
          .toList(),
      pagination: CarPagination.fromJson(
        paginationJson,
      ),
    );
  }
}

class CarPagination {
  final int total;
  final int max;
  final int offset;

  const CarPagination({
    required this.total,
    required this.max,
    required this.offset,
  });

  factory CarPagination.fromJson(
      Map<String, dynamic> json,
      ) {
    return CarPagination(
      total: (json['total'] as num?)?.toInt() ?? 0,
      max: (json['max'] as num?)?.toInt() ?? 10,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
    );
  }

  bool get hasMore => offset + max < total;

  int get nextOffset => offset + max;
}