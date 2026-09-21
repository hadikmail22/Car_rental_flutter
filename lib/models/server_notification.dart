class ServerNotification {
  final int? rentalId;
  final String title;
  final String message;
  final String severity;
  final String dateLabel;
  final int unreadMessages;

  const ServerNotification({
    required this.rentalId,
    required this.title,
    required this.message,
    required this.severity,
    required this.dateLabel,
    required this.unreadMessages,
  });

  bool get isUrgent => severity == 'danger' || severity == 'warning';

  factory ServerNotification.fromJson(Map<String, dynamic> json) {
    return ServerNotification(
      rentalId: (json['rentalId'] as num?)?.toInt(),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'info',
      dateLabel: json['dateLabel']?.toString() ?? '',
      unreadMessages: (json['unreadMessages'] as num?)?.toInt() ?? 0,
    );
  }
}
