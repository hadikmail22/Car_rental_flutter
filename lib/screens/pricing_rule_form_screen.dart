import 'package:flutter/material.dart';
import '../models/pricing_rule.dart';
import '../widgets/primary_button.dart';

class PricingRuleFormScreen extends StatefulWidget {
  final PricingRule? rule;

  const PricingRuleFormScreen({super.key, this.rule});

  @override
  State<PricingRuleFormScreen> createState() => _PricingRuleFormScreenState();
}

class _PricingRuleFormScreenState extends State<PricingRuleFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _percentageController;
  late final TextEditingController _targetController;
  late final TextEditingController _priorityController;

  DateTime? _startDate;
  DateTime? _endDate;

  String _adjustmentType = 'DISCOUNT';
  String _scope = 'ALL';
  bool _active = true;

  bool get _isEditing => widget.rule != null;

  @override
  void initState() {
    super.initState();

    final PricingRule? rule = widget.rule;

    _nameController = TextEditingController(text: rule?.name ?? '');

    _percentageController = TextEditingController(
      text: rule?.percentage.toString() ?? '',
    );

    _targetController = TextEditingController(text: rule?.targetName ?? '');

    _priorityController = TextEditingController(
      text: rule?.priority.toString() ?? '0',
    );

    _startDate = rule?.startDate;
    _endDate = rule?.endDate;
    _adjustmentType = rule?.adjustmentType ?? 'DISCOUNT';
    _scope = rule?.scope ?? 'ALL';
    _active = rule?.active ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _percentageController.dispose();
    _targetController.dispose();
    _priorityController.dispose();
    super.dispose();
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

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? today,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 5),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _startDate = selectedDate;

      if (_endDate != null && _endDate!.isBefore(selectedDate)) {
        _endDate = null;
      }
    });
  }

  Future<void> _selectEndDate() async {
    final DateTime today = DateTime.now();
    final DateTime firstDate = _startDate ?? DateTime(today.year - 1);

    final DateTime initialDate = _endDate ?? _startDate ?? today;

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: DateTime(today.year + 5),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _endDate = selectedDate;
    });
  }

  void _saveRule() {
    final bool isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start date and end date are required'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date cannot be before start date'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final PricingRule savedRule = PricingRule(
      id: widget.rule?.id ?? DateTime.now().millisecondsSinceEpoch,
      name: _nameController.text.trim(),
      startDate: _startDate!,
      endDate: _endDate!,
      adjustmentType: _adjustmentType,
      percentage: double.parse(_percentageController.text.trim()),
      scope: _scope,
      targetName: _scope == 'ALL' ? null : _targetController.text.trim(),
      priority: int.parse(_priorityController.text.trim()),
      active: _active,
    );

    Navigator.pop(context, savedRule);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Update Pricing Rule' : 'Add Pricing Rule',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Rule Name',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final String name = value?.trim() ?? '';

                if (name.isEmpty) {
                  return 'Rule name is required';
                }

                if (name.length > 100) {
                  return 'Maximum length is 100 characters';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _adjustmentType,
              decoration: const InputDecoration(
                labelText: 'Adjustment Type',
                prefixIcon: Icon(Icons.price_change_outlined),
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
                prefixIcon: Icon(Icons.percent),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final double? percentage = double.tryParse(value?.trim() ?? '');

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
                labelText: 'Scope',
                prefixIcon: Icon(Icons.filter_alt_outlined),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('All Cars')),
                DropdownMenuItem(
                  value: 'CATEGORY',
                  child: Text('Specific Category'),
                ),
                DropdownMenuItem(value: 'CAR', child: Text('Specific Car')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _scope = value;

                  if (_scope == 'ALL') {
                    _targetController.clear();
                  }
                });
              },
            ),

            if (_scope != 'ALL') ...[
              const SizedBox(height: 16),

              TextFormField(
                controller: _targetController,
                decoration: InputDecoration(
                  labelText: _scope == 'CATEGORY'
                      ? 'Category Name'
                      : 'Car Name',
                  prefixIcon: Icon(
                    _scope == 'CATEGORY'
                        ? Icons.category_outlined
                        : Icons.directions_car_outlined,
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_scope != 'ALL' &&
                      (value == null || value.trim().isEmpty)) {
                    return _scope == 'CATEGORY'
                        ? 'Category is required'
                        : 'Car is required';
                  }

                  return null;
                },
              ),
            ],

            const SizedBox(height: 16),

            _DateSelector(
              label: 'Start Date',
              value: _formatDate(_startDate),
              onTap: _selectStartDate,
            ),

            const SizedBox(height: 16),

            _DateSelector(
              label: 'End Date',
              value: _formatDate(_endDate),
              onTap: _selectEndDate,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _priorityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Priority',
                prefixIcon: Icon(Icons.low_priority_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final int? priority = int.tryParse(value?.trim() ?? '');

                if (priority == null || priority < 0) {
                  return 'Priority must be zero or greater';
                }

                return null;
              },
            ),

            const SizedBox(height: 12),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              subtitle: const Text('Apply this pricing rule when applicable'),
              value: _active,
              onChanged: (value) {
                setState(() {
                  _active = value;
                });
              },
            ),

            const SizedBox(height: 24),

            PrimaryButton(
              text: _isEditing ? 'Update Rule' : 'Add Rule',
              onPressed: _saveRule,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateSelector({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          border: const OutlineInputBorder(),
        ),
        child: Text(value),
      ),
    );
  }
}
