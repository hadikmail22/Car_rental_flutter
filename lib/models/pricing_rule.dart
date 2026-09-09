class PricingRule {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String adjustmentType;
  final double percentage;
  final String scope;
  final String? targetName;
  final int priority;
  final bool active;

  const PricingRule({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.adjustmentType,
    required this.percentage,
    required this.scope,
    this.targetName,
    required this.priority,
    required this.active,
  });

  PricingRule copyWith({bool? active}) {
    return PricingRule(
      id: id,
      name: name,
      startDate: startDate,
      endDate: endDate,
      adjustmentType: adjustmentType,
      percentage: percentage,
      scope: scope,
      targetName: targetName,
      priority: priority,
      active: active ?? this.active,
    );
  }
}
