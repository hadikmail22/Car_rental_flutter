class CreateRentalResponse {
  final int id;
  final String message;
  final double totalPrice;
  final String status;

  const CreateRentalResponse({
    required this.id,
    required this.message,
    required this.totalPrice,
    required this.status,
  });

  factory CreateRentalResponse.fromJson(
      Map<String, dynamic> json,
      ) {
    return CreateRentalResponse(
      id: _toInt(json['id']),
      message: json['message']?.toString() ?? '',
      totalPrice: _toDouble(json['totalPrice']),
      status: json['status']?.toString() ?? '',
    );
  }
}

int _toInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
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