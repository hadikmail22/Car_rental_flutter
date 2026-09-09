class Rental {
  final int id;
  final String customerEmail;
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
    required this.customerEmail,
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

  Rental copyWith({String? status, double? damageCost, bool? depositPaid}) {
    return Rental(
      id: id,
      customerEmail: customerEmail,
      carName: carName,
      startDate: startDate,
      endDate: endDate,
      totalPrice: totalPrice,
      bookingDeposit: bookingDeposit,
      depositPaid: depositPaid ?? this.depositPaid,
      securityDeposit: securityDeposit,
      damageCost: damageCost ?? this.damageCost,
      status: status ?? this.status,
    );
  }
}
