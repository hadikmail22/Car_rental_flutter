class PricingRule {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String adjustmentType;
  final double percentage;
  final String scope;
  final int priority;
  final bool active;

  final int? categoryId;
  final String? categoryName;
  final int? carId;
  final String? carLabel;

  const PricingRule({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.adjustmentType,
    required this.percentage,
    required this.scope,
    required this.priority,
    required this.active,
    this.categoryId,
    this.categoryName,
    this.carId,
    this.carLabel,
  });

  // The rule applies to all cars, to a category, or to one car.
  String get targetLabel {
    switch (scope) {
      case 'CATEGORY':
        return categoryName ?? 'Category';
      case 'CAR':
        return carLabel ?? 'Car';
      default:
        return 'All cars';
    }
  }

  bool get isDiscount => adjustmentType == 'DISCOUNT';

  factory PricingRule.fromJson(Map<String, dynamic> json) {
    return PricingRule(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      startDate: _toDateTime(json['startDate']),
      endDate: _toDateTime(json['endDate']),
      adjustmentType: json['adjustmentType']?.toString() ?? 'DISCOUNT',
      percentage: _toDouble(json['percentage']),
      scope: json['scope']?.toString() ?? 'ALL',
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      active: json['active'] == true,
      categoryId: (json['categoryId'] as num?)?.toInt(),
      categoryName: json['categoryName']?.toString(),
      carId: (json['carId'] as num?)?.toInt(),
      carLabel: json['carLabel']?.toString(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        value.toInt(),
        isUtc: true,
      );
    }

    final DateTime? parsed = DateTime.tryParse(value?.toString() ?? '');

    if (parsed == null) {
      throw const FormatException('Invalid date in pricing rule');
    }

    return parsed.isUtc ? parsed : parsed.toUtc();
  }
}
