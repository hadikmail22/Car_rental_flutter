import 'chat_message.dart';

class ChatConversation {
  final int rentalId;
  final ChatCustomer customer;
  final ChatCar car;
  final String rentalStatus;
  final ChatMessage? lastMessage;
  final int messageCount;
  final int photoCount;
  final int unreadCount;

  const ChatConversation({
    required this.rentalId,
    required this.customer,
    required this.car,
    required this.rentalStatus,
    required this.lastMessage,
    required this.messageCount,
    required this.photoCount,
    required this.unreadCount,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> customerJson = json['customer'] is Map
        ? Map<String, dynamic>.from(json['customer'] as Map)
        : <String, dynamic>{};

    final Map<String, dynamic> carJson = json['car'] is Map
        ? Map<String, dynamic>.from(json['car'] as Map)
        : <String, dynamic>{};

    final Map<String, dynamic>? lastMessageJson = json['lastMessage'] is Map
        ? Map<String, dynamic>.from(json['lastMessage'] as Map)
        : null;

    return ChatConversation(
      rentalId: _toInt(json['rentalId']),
      customer: ChatCustomer.fromJson(customerJson),
      car: ChatCar.fromJson(carJson),
      rentalStatus: json['rentalStatus']?.toString() ?? '',
      lastMessage: lastMessageJson == null
          ? null
          : ChatMessage.fromJson(lastMessageJson),
      messageCount: _toInt(json['messageCount']),
      photoCount: _toInt(json['photoCount']),
      unreadCount: _toInt(json['unreadCount']),
    );
  }

  bool get hasUnreadMessages {
    return unreadCount > 0;
  }
}

class ChatConversationPage {
  final List<ChatConversation> items;
  final int total;

  const ChatConversationPage({required this.items, required this.total});

  factory ChatConversationPage.fromJson(Map<String, dynamic> json) {
    final List<dynamic> itemsJson = json['items'] is List
        ? json['items'] as List<dynamic>
        : <dynamic>[];

    return ChatConversationPage(
      items: itemsJson
          .whereType<Map>()
          .map(
            (Map item) =>
                ChatConversation.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      total: _toInt(json['total']),
    );
  }
}

class ChatCustomer {
  final int id;
  final String email;
  final String fullName;

  const ChatCustomer({
    required this.id,
    required this.email,
    required this.fullName,
  });

  factory ChatCustomer.fromJson(Map<String, dynamic> json) {
    return ChatCustomer(
      id: _toInt(json['id']),
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
    );
  }

  String get displayName {
    if (fullName.trim().isNotEmpty) {
      return fullName.trim();
    }

    if (email.trim().isNotEmpty) {
      return email.trim();
    }

    return 'Customer';
  }
}

class ChatCar {
  final int id;
  final String brand;
  final String model;
  final int year;

  const ChatCar({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
  });

  factory ChatCar.fromJson(Map<String, dynamic> json) {
    return ChatCar(
      id: _toInt(json['id']),
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      year: _toInt(json['year']),
    );
  }

  String get fullName {
    final String name = '$brand $model'.trim();

    if (year > 0 && name.isNotEmpty) {
      return '$name $year';
    }

    if (name.isNotEmpty) {
      return name;
    }

    return 'Rental car';
  }
}

int _toInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
