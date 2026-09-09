class Car {
  final int id;
  final String brand;
  final String model;
  final int year;
  final String plateNumber;
  final double pricePerDay;
  final String status;
  final String? category;
  final String? imageUrl;

  const Car({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.plateNumber,
    required this.pricePerDay,
    required this.status,
    this.category,
    this.imageUrl,
  });

  String get fullName => '$brand $model';

  bool get isAvailable => status == 'AVAILABLE';

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'],
      brand: json['brand'],
      model: json['model'],
      year: json['year'],
      plateNumber: json['plateNumber'],
      pricePerDay: (json['pricePerDay'] as num).toDouble(),
      status: json['status'],
      category: json['category']?['name'],
      imageUrl: json['imageUrl'],
    );
  }
}
