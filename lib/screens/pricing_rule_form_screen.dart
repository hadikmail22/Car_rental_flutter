import 'package:flutter/material.dart';

import '../models/car.dart';
import '../models/car_catalog.dart';
import '../models/pricing_rule.dart';
import '../services/car_service.dart';
import '../services/pricing_rule_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class PricingRuleFormScreen extends StatefulWidget {
  final PricingRule? rule;

  const PricingRuleFormScreen({super.key, this.rule});

  @override
  State<PricingRuleFormScreen> createState() => _PricingRuleFormScreenState();
}

class _PricingRuleFormScreenState extends State<PricingRuleFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final PricingRuleService _service = PricingRuleService();
  final CarService _carService = CarService();

  late final TextEditingController _nameController;
  late final TextEditingController _percentageController;
  late final TextEditingController _priorityController;

  DateTime? _startDate;
  DateTime? _endDate;

  String _adjustmentType = 'DISCOUNT';
  String _scope = 'ALL';
  bool _active = true;

  int? _categoryId;
  int? _carId;

  List<CatalogItem> _categories = <CatalogItem>[];
  List<Car> _cars = <Car>[];

  bool _isLoadingOptions = true;
  String? _optionsError;
  bool _isSaving = false;

  bool get _isEditing => widget.rule != null;

  @override
  void initState() {
    super.initState();

    final PricingRule? rule = widget.rule;

    _nameController = TextEditingController(text: rule?.name ?? '');

    _percentageController = TextEditingController(
      text: rule?.percentage.toStringAsFixed(2) ?? '',
    );

    _priorityController = TextEditingController(
      text: (rule?.priority ?? 0).toString(),
    );

    _startDate = rule?.startDate.toLocal();
    _endDate = rule?.endDate.toLocal();
    _adjustmentType = rule?.adjustmentType ?? 'DISCOUNT';
    _scope = rule?.scope ?? 'ALL';
    _active = rule?.active ?? true;
    _categoryId = rule?.categoryId;
    _carId = rule?.carId;

    _loadOptions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _percentageController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  // Categories come from the catalogue, cars from the cars API,
  // so the Admin picks a real target instead of typing a name.
  Future<void> _loadOptions() async {
    try {
      final CarCatalog catalog = await _carService.getCatalog();
      final cars = await _carService.getCars(max: 100, offset: 0);

      if (!mounted) {
        return;
      }

      setState(() {
        _categories = catalog.categories;
        _cars = cars.items;
        _isLoadingOptions = false;
      });
    } on CarServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _optionsError = error.message;
        _isLoadingOptions = false;
      });
    }
  }

  void _retryOptions() {
    setState(() {
      _isLoadingOptions = true;
      _optionsError = null;
    });

    _loadOptions();
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Select date';
    }

    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  Future<void> _selectStartDate() async {
    final DateTime today = DateTime.now();

    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _startDate ?? today,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 5),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _startDate = selected;

      if (_endDate != null && _endDate!.isBefore(selected)) {
        _endDate = null;
      }
    });
  }

  Future<void> _selectEndDate() async {
    final DateTime today = DateTime.now();
    final DateTime firstDate = _startDate ?? DateTime(today.year - 1);
    final DateTime initialDate = _endDate ?? firstDate;

    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: DateTime(today.year + 5),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _endDate = selected;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  Future<void> _saveRule() async {
    final bool isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isSaving) {
      return;
    }

    if (_startDate == null || _endDate == null) {
      _showError('Please select the start and end dates.');
      return;
    }

    if (_scope == 'CATEGORY' && _categoryId == null) {
      _showError('Please select a category.');
      return;
    }

    if (_scope == 'CAR' && _carId == null) {
      _showError('Please select a car.');
      return;
    }

    final Map<String, dynamic> data = {
      'name': _nameController.text.trim(),
      'startDate': _formatDate(_startDate),
      'endDate': _formatDate(_endDate),
      'adjustmentType': _adjustmentType,
      'percentage': double.parse(_percentageController.text.trim()),
      'scope': _scope,
      'priority': int.parse(_priorityController.text.trim()),
      'active': _active,
      'categoryId': _scope == 'CATEGORY' ? _categoryId : null,
      'carId': _scope == 'CAR' ? _carId : null,
    };

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEditing) {
        await _service.updateRule(widget.rule!.id, data);
      } else {
        await _service.createRule(data);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Rule updated.' : 'Rule created.',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );

      Navigator.pop(context, true);
    } on PricingRuleException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showError(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Pricing Rule' : 'Add Pricing Rule',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingOptions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_optionsError != null) {
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
              Text(_optionsError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _retryOptions,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Rule Name',
              prefixIcon: Icon(Icons.label_outline),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name is required';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'Start Date',
                  value: _formatDate(_startDate),
                  onTap: _selectStartDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateField(
                  label: 'End Date',
                  value: _formatDate(_endDate),
                  onTap: _selectEndDate,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _adjustmentType,
            decoration: const InputDecoration(
              labelText: 'Adjustment Type',
              prefixIcon: Icon(Icons.swap_vert),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'DISCOUNT', child: Text('Discount')),
              DropdownMenuItem(value: 'INCREASE', child: Text('Increase')),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _adjustmentType = value;
              });
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _percentageController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Percentage',
              helperText: 'Between 0.01 and 100',
              prefixIcon: Icon(Icons.percent),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final double? percentage = double.tryParse(
                value?.trim() ?? '',
              );

              if (percentage == null) {
                return 'Enter a valid percentage';
              }

              if (percentage < 0.01 || percentage > 100) {
                return 'Percentage must be between 0.01 and 100';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _scope,
            decoration: const InputDecoration(
              labelText: 'Applies To',
              prefixIcon: Icon(Icons.my_location_outlined),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('All cars')),
              DropdownMenuItem(value: 'CATEGORY', child: Text('A category')),
              DropdownMenuItem(value: 'CAR', child: Text('One car')),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _scope = value;
                // The old target does not fit the new scope.
                _categoryId = null;
                _carId = null;
              });
            },
          ),

          if (_scope == 'CATEGORY') ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _categoryId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem<int>(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _categoryId = value;
                });
              },
            ),
          ],

          if (_scope == 'CAR') ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _carId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Car',
                prefixIcon: Icon(Icons.directions_car_outlined),
                border: OutlineInputBorder(),
              ),
              items: _cars.map((car) {
                return DropdownMenuItem<int>(
                  value: car.id,
                  child: Text(
                    '${car.brand} ${car.model} - ${car.plateNumber}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _carId = value;
                });
              },
            ),
          ],

          const SizedBox(height: 16),

          TextFormField(
            controller: _priorityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Priority',
              helperText: 'Higher priority wins when rules overlap',
              prefixIcon: Icon(Icons.low_priority_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final int? priority = int.tryParse(value?.trim() ?? '');

              if (priority == null || priority < 0) {
                return 'Enter a number, 0 or more';
              }

              return null;
            },
          ),

          const SizedBox(height: 8),

          SwitchListTile(
            value: _active,
            onChanged: (value) {
              setState(() {
                _active = value;
              });
            },
            title: const Text('Active'),
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 20),

          PrimaryButton(
            text: _isEditing ? 'Save Changes' : 'Create Rule',
            isLoading: _isSaving,
            onPressed: _saveRule,
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          value,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
