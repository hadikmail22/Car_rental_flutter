class Rental {
  final int id;

  final int? customerId;
  final String customerEmail;

  final int? carId;
  final String carName;

  final DateTime startDate;
  final DateTime endDate;

  final double totalPrice;
  final double bookingDeposit;
  final bool depositPaid;
  final double securityDeposit;
  final double damageCost;

  final String status;

  const Rental({
    required this.id,
    this.customerId,
    required this.customerEmail,
    this.carId,
    required this.carName,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.bookingDeposit,
    required this.depositPaid,
    required this.securityDeposit,
    required this.damageCost,
    required this.status,
  });

  factory Rental.fromJson(
      Map<String, dynamic> json,
      ) {
    final Map<String, dynamic> customerJson =
    json['customer'] is Map
        ? Map<String, dynamic>.from(
      json['customer'] as Map,
    )
        : <String, dynamic>{};

    final Map<String, dynamic> carJson =
    json['car'] is Map
        ? Map<String, dynamic>.from(
      json['car'] as Map,
    )
        : <String, dynamic>{};

    final String brand =
        carJson['brand']?.toString() ?? '';

    final String model =
        carJson['model']?.toString() ?? '';

    return Rental(
      id: _toInt(json['id']),
      customerId: _toNullableInt(
        customerJson['id'],
      ),
      customerEmail:
      customerJson['username']?.toString() ?? '',
      carId: _toNullableInt(carJson['id']),
      carName: '$brand $model'.trim(),
      startDate: _toDateTime(json['startDate']),
      endDate: _toDateTime(json['endDate']),
      totalPrice: _toDouble(json['totalPrice']),
      bookingDeposit:
      _toDouble(json['bookingDeposit']),
      depositPaid: json['depositPaid'] == true,
      securityDeposit:
      _toDouble(json['securityDeposit']),
      damageCost: _toDouble(json['damageCost']),
      status: json['status']?.toString() ?? '',
    );
  }

  Rental copyWith({
    String? status,
    double? damageCost,
    bool? depositPaid,
  }) {
    return Rental(
      id: id,
      customerId: customerId,
      customerEmail: customerEmail,
      carId: carId,
      carName: carName,
      startDate: startDate,
      endDate: endDate,
      totalPrice: totalPrice,
      bookingDeposit: bookingDeposit,
      depositPaid:
      depositPaid ?? this.depositPaid,
      securityDeposit: securityDeposit,
      damageCost: damageCost ?? this.damageCost,
      status: status ?? this.status,
    );
  }
}

class RentalPage {
  final List<Rental> items;
  final RentalPagination pagination;

  const RentalPage({
    required this.items,
    required this.pagination,
  });

  factory RentalPage.fromJson(
      Map<String, dynamic> json,
      ) {
    final List<dynamic> itemsJson =
        json['items'] as List<dynamic>? ?? [];

    final Map<String, dynamic> paginationJson =
    json['pagination'] is Map
        ? Map<String, dynamic>.from(
      json['pagination'] as Map,
    )
        : <String, dynamic>{};

    return RentalPage(
      items: itemsJson
          .map(
            (item) => Rental.fromJson(
          Map<String, dynamic>.from(
            item as Map,
          ),
        ),
      )
          .toList(),
      pagination: RentalPagination.fromJson(
        paginationJson,
      ),
    );
  }
}

class RentalPagination {
  final int total;
  final int max;
  final int offset;

  const RentalPagination({
    required this.total,
    required this.max,
    required this.offset,
  });

  factory RentalPagination.fromJson(
      Map<String, dynamic> json,
      ) {
    return RentalPagination(
      total: _toInt(json['total']),
      max: _toInt(json['max'], fallback: 10),
      offset: _toInt(json['offset']),
    );
  }

  bool get hasMore => offset + max < total;

  int get nextOffset => offset + max;
}

int _toInt(
    dynamic value, {
      int fallback = 0,
    }) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ??
      fallback;
}

int? _toNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
    value?.toString() ?? '',
  ) ??
      0;
}

DateTime _toDateTime(dynamic value) {
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(
      value.toInt(),
    );
  }

  final DateTime? parsedDate =
  DateTime.tryParse(value?.toString() ?? '');

  if (parsedDate == null) {
    throw const FormatException(
      'Invalid rental date received from server.',
    );
  }

  return parsedDate;
}