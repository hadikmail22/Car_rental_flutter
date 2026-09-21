import 'package:flutter/material.dart';

import '../models/pricing_rule.dart';
import '../services/pricing_rule_service.dart';
import '../theme/app_theme.dart';
import 'pricing_rule_form_screen.dart';

class PricingRulesScreen extends StatefulWidget {
  const PricingRulesScreen({super.key});

  @override
  State<PricingRulesScreen> createState() => _PricingRulesScreenState();
}

class _PricingRulesScreenState extends State<PricingRulesScreen> {
  final PricingRuleService _service = PricingRuleService();

  List<PricingRule> _rules = <PricingRule>[];
  bool _isLoading = true;
  String? _errorMessage;
  int? _busyRuleId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRules();
    });
  }

  Future<void> _loadRules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<PricingRule> rules = await _service.getRules();

      if (!mounted) {
        return;
      }

      setState(() {
        _rules = rules;
        _isLoading = false;
      });
    } on PricingRuleException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? AppTheme.errorColor
            : AppTheme.successColor,
      ),
    );
  }

  Future<void> _openForm({PricingRule? rule}) async {
    final bool? saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PricingRuleFormScreen(rule: rule),
      ),
    );

    if (saved == true) {
      await _loadRules();
    }
  }

  Future<void> _toggleActive(PricingRule rule) async {
    setState(() {
      _busyRuleId = rule.id;
    });

    try {
      final PricingRule updated = await _service.toggleActive(rule.id);

      if (!mounted) {
        return;
      }

      setState(() {
        final int index = _rules.indexWhere((item) => item.id == updated.id);

        if (index != -1) {
          _rules[index] = updated;
        }

        _busyRuleId = null;
      });

      _showMessage(
        updated.active ? 'Rule activated.' : 'Rule deactivated.',
      );
    } on PricingRuleException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _busyRuleId = null;
      });

      _showMessage(error.message, isError: true);
    }
  }

  Future<void> _deleteRule(PricingRule rule) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete rule'),
          content: Text('Delete "${rule.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _busyRuleId = rule.id;
    });

    try {
      await _service.deleteRule(rule.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _rules.removeWhere((item) => item.id == rule.id);
        _busyRuleId = null;
      });

      _showMessage('Rule deleted.');
    } on PricingRuleException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _busyRuleId = null;
      });

      _showMessage(error.message, isError: true);
    }
  }

  String _formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pricing Rules',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _loadRules,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Rule'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
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
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadRules,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_rules.isEmpty) {
      return const Center(
        child: Text('No pricing rules yet.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRules,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: _rules.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildRuleCard(_rules[index]);
        },
      ),
    );
  }

  Widget _buildRuleCard(PricingRule rule) {
    final bool isBusy = _busyRuleId == rule.id;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rule.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: rule.isDiscount
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${rule.isDiscount ? '-' : '+'}'
                        '${rule.percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            _infoLine(Icons.my_location_outlined, rule.targetLabel),
            _infoLine(
              Icons.calendar_today_outlined,
              '${_formatDate(rule.startDate)}  →  '
                  '${_formatDate(rule.endDate)}',
            ),
            _infoLine(
              Icons.low_priority_outlined,
              'Priority: ${rule.priority}',
            ),

            const Divider(height: 24),

            Row(
              children: [
                if (isBusy)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Switch(
                    value: rule.active,
                    onChanged: (_) => _toggleActive(rule),
                  ),

                Text(rule.active ? 'Active' : 'Inactive'),

                const Spacer(),

                IconButton(
                  onPressed: isBusy ? null : () => _openForm(rule: rule),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                ),

                IconButton(
                  onPressed: isBusy ? null : () => _deleteRule(rule),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.errorColor,
                  ),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.mutedColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.mutedColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
