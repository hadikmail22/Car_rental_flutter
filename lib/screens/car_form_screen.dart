import 'package:flutter/material.dart';
import '../models/car.dart';
import '../widgets/primary_button.dart';

class CarFormScreen extends StatefulWidget {
  final Car? car;

  const CarFormScreen({super.key, this.car});

  @override
  State<CarFormScreen> createState() => _CarFormScreenState();
}

class _CarFormScreenState extends State<CarFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _plateController;
  late final TextEditingController _priceController;
  late final TextEditingController _categoryController;

  String _status = 'AVAILABLE';

  bool get _isEditing => widget.car != null;

  @override
  void initState() {
    super.initState();

    final Car? car = widget.car;

    _brandController = TextEditingController(text: car?.brand ?? '');

    _modelController = TextEditingController(text: car?.model ?? '');

    _yearController = TextEditingController(text: car?.year.toString() ?? '');

    _plateController = TextEditingController(text: car?.plateNumber ?? '');

    _priceController = TextEditingController(
      text: car?.pricePerDay.toString() ?? '',
    );

    _categoryController = TextEditingController(text: car?.category ?? '');

    _status = car?.status ?? 'AVAILABLE';
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _saveCar() {
    final bool isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final Car savedCar = Car(
      id: widget.car?.id ?? DateTime.now().millisecondsSinceEpoch,
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      year: int.parse(_yearController.text.trim()),
      plateNumber: _plateController.text.trim().toUpperCase(),
      pricePerDay: double.parse(_priceController.text.trim()),
      status: _status,
      category: _categoryController.text.trim(),
      imageUrl: widget.car?.imageUrl,
    );

    Navigator.pop(context, savedCar);
  }

  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Update Car' : 'Add Car',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _brandController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Brand',
                prefixIcon: Icon(Icons.business_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                return _requiredValidator(value, 'Brand');
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _modelController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Model',
                prefixIcon: Icon(Icons.directions_car_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                return _requiredValidator(value, 'Model');
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Year',
                prefixIcon: Icon(Icons.calendar_today_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final int? year = int.tryParse(value?.trim() ?? '');

                if (year == null) {
                  return 'Enter a valid year';
                }

                if (year < 1900 || year > DateTime.now().year + 1) {
                  return 'Year is outside the allowed range';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _plateController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Plate Number',
                prefixIcon: Icon(Icons.pin_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                return _requiredValidator(value, 'Plate number');
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Price Per Day',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final double? price = double.tryParse(value?.trim() ?? '');

                if (price == null) {
                  return 'Enter a valid price';
                }

                if (price < 0) {
                  return 'Price cannot be negative';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _categoryController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                return _requiredValidator(value, 'Category');
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.info_outline),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'AVAILABLE', child: Text('Available')),
                DropdownMenuItem(value: 'RENTED', child: Text('Rented')),
                DropdownMenuItem(
                  value: 'MAINTENANCE',
                  child: Text('Maintenance'),
                ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _status = value;
                });
              },
            ),

            const SizedBox(height: 30),

            PrimaryButton(
              text: _isEditing ? 'Update Car' : 'Add Car',
              onPressed: _saveCar,
            ),
          ],
        ),
      ),
    );
  }
}
