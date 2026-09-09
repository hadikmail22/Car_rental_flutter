import 'package:flutter/material.dart';
import '../models/pricing_rule.dart';
import '../theme/app_theme.dart';
import 'pricing_rule_form_screen.dart';

class PricingRulesScreen extends StatefulWidget {
  const PricingRulesScreen({super.key});

  @override
  State<PricingRulesScreen> createState() => _PricingRulesScreenState();
}

class _PricingRulesScreenState extends State<PricingRulesScreen> {
  final List<PricingRule> _rules = [
    PricingRule(
      id: 1,
      name: 'Summer Discount',
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 8, 31),
      adjustmentType: 'DISCOUNT',
      percentage: 10,
      scope: 'ALL',
      priority: 5,
      active: true,
    ),
    PricingRule(
      id: 2,
      name: 'SUV Weekend Increase',
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 12, 31),
      adjustmentType: 'INCREASE',
      percentage: 15,
      scope: 'CATEGORY',
      targetName: 'SUV',
      priority: 10,
      active: true,
    ),
    PricingRule(
      id: 3,
      name: 'Camry Special Offer',
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 10, 15),
      adjustmentType: 'DISCOUNT',
      percentage: 8,
      scope: 'CAR',
      targetName: 'Toyota Camry',
      priority: 7,
      active: false,
    ),
  ];

  String _formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');

    final String day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  Future<void> _addRule() async {
    final PricingRule? newRule = await Navigator.push<PricingRule>(
      context,
      MaterialPageRoute(builder: (context) => const PricingRuleFormScreen()),
    );

    if (newRule == null) {
      return;
    }

    setState(() {
      _rules.insert(0, newRule);
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pricing rule added successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _editRule(int index) async {
    final PricingRule? updatedRule = await Navigator.push<PricingRule>(
      context,
      MaterialPageRoute(
        builder: (context) => PricingRuleFormScreen(rule: _rules[index]),
      ),
    );

    if (updatedRule == null) {
      return;
    }

    setState(() {
      _rules[index] = updatedRule;
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pricing rule updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _toggleRule(int index, bool value) {
    setState(() {
      _rules[index] = _rules[index].copyWith(active: value);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'Pricing rule activated' : 'Pricing rule deactivated',
        ),
      ),
    );
  }

  Color _adjustmentColor(String type) {
    if (type == 'DISCOUNT') {
      return Colors.green;
    }

    return Colors.red;
  }

  String _scopeText(PricingRule rule) {
    if (rule.scope == 'ALL') {
      return 'All cars';
    }

    if (rule.scope == 'CATEGORY') {
      return 'Category: ${rule.targetName}';
    }

    return 'Car: ${rule.targetName}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pricing Rules',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _rules.length,
        separatorBuilder: (context, index) {
          return const SizedBox(height: 14);
        },
        itemBuilder: (context, index) {
          final PricingRule rule = _rules[index];

          final Color adjustmentColor = _adjustmentColor(rule.adjustmentType);

          final String adjustmentSign = rule.adjustmentType == 'DISCOUNT'
              ? '-'
              : '+';

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: adjustmentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        rule.adjustmentType == 'DISCOUNT'
                            ? Icons.discount_outlined
                            : Icons.trending_up,
                        color: adjustmentColor,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rule.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _scopeText(rule),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () {
                        _editRule(index);
                      },
                      icon: const Icon(Icons.edit_outlined),
                    ),

                    Switch(
                      value: rule.active,
                      onChanged: (value) {
                        _toggleRule(index, value);
                      },
                    ),
                  ],
                ),

                const Divider(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$adjustmentSign'
                      '${rule.percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: adjustmentColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Priority ${rule.priority}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(
                      Icons.date_range_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),

                    const SizedBox(width: 7),

                    Expanded(
                      child: Text(
                        '${_formatDate(rule.startDate)}'
                        ' → '
                        '${_formatDate(rule.endDate)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  rule.active ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    color: rule.active ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRule,
        backgroundColor: AppTheme.primaryYellow,
        foregroundColor: AppTheme.darkColor,
        icon: const Icon(Icons.add),
        label: const Text('Add Rule'),
      ),
    );
  }
}
