class CatalogItem {
  final int id;
  final String name;

  const CatalogItem({
    required this.id,
    required this.name,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
    );
  }
}

class CatalogBrand {
  final int id;
  final String name;
  final List<CatalogItem> models;

  const CatalogBrand({
    required this.id,
    required this.name,
    required this.models,
  });

  factory CatalogBrand.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawModels = json['models'] is List
        ? json['models'] as List<dynamic>
        : <dynamic>[];

    return CatalogBrand(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      models: rawModels
          .whereType<Map>()
          .map((item) => CatalogItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class CarCatalog {
  final List<CatalogBrand> brands;
  final List<CatalogItem> categories;

  const CarCatalog({
    required this.brands,
    required this.categories,
  });

  factory CarCatalog.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawBrands = json['brands'] is List
        ? json['brands'] as List<dynamic>
        : <dynamic>[];

    final List<dynamic> rawCategories = json['categories'] is List
        ? json['categories'] as List<dynamic>
        : <dynamic>[];

    return CarCatalog(
      brands: rawBrands
          .whereType<Map>()
          .map((item) => CatalogBrand.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      categories: rawCategories
          .whereType<Map>()
          .map((item) => CatalogItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}
