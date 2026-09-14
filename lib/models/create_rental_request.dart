class CreateRentalRequest {
  final int carId;
  final DateTime startDate;
  final DateTime endDate;
  final int? customerId;

  const CreateRentalRequest({
    required this.carId,
    required this.startDate,
    required this.endDate,
    this.customerId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'carId': carId,
      'startDate': _formatDate(startDate),
      'endDate': _formatDate(endDate),
    };

    if (customerId != null) {
      json['customerId'] = customerId;
    }

    return json;
  }

  String _formatDate(DateTime date) {
    final String month =
    date.month.toString().padLeft(2, '0');

    final String day =
    date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}