import 'chat_conversation.dart';
import 'chat_message.dart';

class ChatThread {
  final ChatRental rental;
  final List<ChatMessage> messages;

  const ChatThread({required this.rental, required this.messages});

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rentalJson = json['rental'] is Map
        ? Map<String, dynamic>.from(json['rental'] as Map)
        : <String, dynamic>{};

    final List<dynamic> messagesJson = json['messages'] is List
        ? json['messages'] as List<dynamic>
        : <dynamic>[];

    return ChatThread(
      rental: ChatRental.fromJson(rentalJson),
      messages: messagesJson
          .whereType<Map>()
          .map(
            (Map message) =>
                ChatMessage.fromJson(Map<String, dynamic>.from(message)),
          )
          .toList(),
    );
  }
}

class ChatRental {
  final int id;
  final String status;
  final ChatCustomer customer;
  final ChatCar car;

  const ChatRental({
    required this.id,
    required this.status,
    required this.customer,
    required this.car,
  });

  factory ChatRental.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> customerJson = json['customer'] is Map
        ? Map<String, dynamic>.from(json['customer'] as Map)
        : <String, dynamic>{};

    final Map<String, dynamic> carJson = json['car'] is Map
        ? Map<String, dynamic>.from(json['car'] as Map)
        : <String, dynamic>{};

    return ChatRental(
      id: _toInt(json['id']),
      status: json['status']?.toString() ?? '',
      customer: ChatCustomer.fromJson(customerJson),
      car: ChatCar.fromJson(carJson),
    );
  }

  bool get canArchive {
    return status == 'COMPLETED' || status == 'CANCELLED';
  }
}

int _toInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
