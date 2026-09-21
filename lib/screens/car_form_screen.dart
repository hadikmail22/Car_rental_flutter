import 'package:flutter/material.dart';

import '../models/car.dart';
import '../models/car_catalog.dart';
import '../services/car_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class CarFormScreen extends StatefulWidget {
  // null = add a new car, a car = edit that car.
  final Car? car;

  const CarFormScreen({super.key, this.car});

  @override
  State<CarFormScreen> createState() => _CarFormScreenState();
}

class _CarFormScreenState extends State<CarFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final CarService _carService = CarService();

  late final TextEditingController _yearController;
  late final TextEditingController _plateController;
  late final TextEditingController _priceController;

  CarCatalog? _catalog;
  bool _isLoadingCatalog = true;
  String? _catalogError;

  int? _brandId;
  int? _modelId;
  int? _categoryId;
  String _status = 'AVAILABLE';
  bool _isSaving = false;

  bool get _isEditing => widget.car != null;

  @override
  void initState() {
    super.initState();

    final Car? car = widget.car;

    // In edit mode the form starts filled with the car's values.
    _yearController = TextEditingController(
      text: car?.year.toString() ?? '',
    );
    _plateController = TextEditingController(
      text: car?.plateNumber ?? '',
    );
    _priceController = TextEditingController(
      text: car?.pricePerDay.toStringAsFixed(2) ?? '',
    );

    _brandId = car?.brandId;
    _modelId = car?.modelId;
    _categoryId = car?.categoryId;
    _status = car?.status ?? 'AVAILABLE';

    _loadCatalog();
  }

  @override
  void dispose() {
    _yearController.dispose();
    _plateController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _retryCatalog() {
    setState(() {
      _isLoadingCatalog = true;
      _catalogError = null;
    });

    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final CarCatalog catalog = await _carService.getCatalog();

      if (!mounted) {
        return;
      }

      setState(() {
        _catalog = catalog;
        _isLoadingCatalog = false;
      });
    } on CarServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _catalogError = error.message;
        _isLoadingCatalog = false;
      });
    }
  }

  // The models list depends on the selected brand.
  List<CatalogItem> get _modelsForSelectedBrand {
    final CarCatalog? catalog = _catalog;

    if (catalog == null || _brandId == null) {
      return const <CatalogItem>[];
    }

    for (final CatalogBrand brand in catalog.brands) {
      if (brand.id == _brandId) {
        return brand.models;
      }
    }

    return const <CatalogItem>[];
  }

  Future<void> _saveCar() async {
    final bool isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final int year = int.parse(_yearController.text.trim());
      final double price = double.parse(_priceController.text.trim());

      if (_isEditing) {
        await _carService.updateCar(
          id: widget.car!.id,
          brandId: _brandId!,
          modelId: _modelId!,
          year: year,
          plateNumber: _plateController.text,
          pricePerDay: price,
          status: _status,
          categoryId: _categoryId,
        );
      } else {
        await _carService.createCar(
          brandId: _brandId!,
          modelId: _modelId!,
          year: year,
          plateNumber: _plateController.text,
          pricePerDay: price,
          status: _status,
          categoryId: _categoryId,
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Car updated successfully.'
                : 'Car added successfully.',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );

      Navigator.pop(context, true);
    } on CarServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
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
          _isEditing ? 'Edit Car' : 'Add Car',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingCatalog) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_catalogError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 12),
              Text(
                _catalogError!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _retryCatalog,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final CarCatalog catalog = _catalog!;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<int>(
            initialValue: _brandId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Brand',
              prefixIcon: Icon(Icons.business_outlined),
              border: OutlineInputBorder(),
            ),
            items: catalog.brands.map((brand) {
              return DropdownMenuItem<int>(
                value: brand.id,
                child: Text(brand.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _brandId = value;
                // A new brand means the old model is no longer valid.
                _modelId = null;
              });
            },
            validator: (value) {
              return value == null ? 'Brand is required' : null;
            },
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<int>(
            // The key changes with the brand, so the model
            // dropdown is rebuilt with the new list.
            key: ValueKey<int?>(_brandId),
            initialValue: _modelId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Model',
              helperText: _brandId == null ? 'Select a brand first' : null,
              prefixIcon: const Icon(Icons.directions_car_outlined),
              border: const OutlineInputBorder(),
            ),
            items: _modelsForSelectedBrand.map((model) {
              return DropdownMenuItem<int>(
                value: model.id,
                child: Text(model.name),
              );
            }).toList(),
            onChanged: _brandId == null
                ? null
                : (value) {
              setState(() {
                _modelId = value;
              });
            },
            validator: (value) {
              return value == null ? 'Model is required' : null;
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

          DropdownButtonFormField<int?>(
            initialValue: _categoryId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Category (optional)',
              prefixIcon: Icon(Icons.category_outlined),
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('No category'),
              ),
              ...catalog.categories.map((category) {
                return DropdownMenuItem<int?>(
                  value: category.id,
                  child: Text(category.name),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _categoryId = value;
              });
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
            items: [
              const DropdownMenuItem(
                value: 'AVAILABLE',
                child: Text('Available'),
              ),
              const DropdownMenuItem(
                value: 'MAINTENANCE',
                child: Text('Maintenance'),
              ),
              // Only shown when editing a car that is out on a rental,
              // so the current value is still valid in the list.
              if (_status == 'RENTED')
                const DropdownMenuItem(
                  value: 'RENTED',
                  child: Text('Rented'),
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
            text: _isEditing ? 'Save Changes' : 'Add Car',
            isLoading: _isSaving,
            onPressed: _saveCar,
          ),
        ],
      ),
    );
  }
}
