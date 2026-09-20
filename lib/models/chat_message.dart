class ChatMessage {
  final int id;
  final int rentalId;
  final String body;
  final String messageType;
  final DateTime createdAt;
  final bool mine;
  final ChatSender sender;
  final List<ChatAttachment> attachments;

  const ChatMessage({
    required this.id,
    required this.rentalId,
    required this.body,
    required this.messageType,
    required this.createdAt,
    required this.mine,
    required this.sender,
    required this.attachments,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> senderJson = json['sender'] is Map
        ? Map<String, dynamic>.from(json['sender'] as Map)
        : <String, dynamic>{};

    final List<dynamic> attachmentsJson = json['attachments'] is List
        ? json['attachments'] as List<dynamic>
        : <dynamic>[];

    return ChatMessage(
      id: _toInt(json['id']),
      rentalId: _toInt(json['rentalId']),
      body: json['body']?.toString() ?? '',
      messageType: json['messageType']?.toString() ?? 'CHAT',
      createdAt: _toDateTime(json['createdAt']),
      mine: json['mine'] == true,
      sender: ChatSender.fromJson(senderJson),
      attachments: attachmentsJson
          .whereType<Map>()
          .map(
            (Map attachment) =>
                ChatAttachment.fromJson(Map<String, dynamic>.from(attachment)),
          )
          .toList(),
    );
  }

  bool get hasText {
    return body.trim().isNotEmpty;
  }

  bool get hasAttachments {
    return attachments.isNotEmpty;
  }

  bool get isPickupInspection {
    return messageType == 'PICKUP_INSPECTION';
  }

  bool get isReturnInspection {
    return messageType == 'RETURN_INSPECTION';
  }
}

class ChatSender {
  final int id;
  final String email;
  final String fullName;
  final bool admin;

  const ChatSender({
    required this.id,
    required this.email,
    required this.fullName,
    required this.admin,
  });

  factory ChatSender.fromJson(Map<String, dynamic> json) {
    return ChatSender(
      id: _toInt(json['id']),
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      admin: json['admin'] == true,
    );
  }

  String get displayName {
    if (fullName.trim().isNotEmpty) {
      return fullName.trim();
    }

    if (email.trim().isNotEmpty) {
      return email.trim();
    }

    return admin ? 'Car Rental Admin' : 'Customer';
  }
}

class ChatAttachment {
  final int id;
  final String fileName;
  final String contentType;
  final String url;

  const ChatAttachment({
    required this.id,
    required this.fileName,
    required this.contentType,
    required this.url,
  });

  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    return ChatAttachment(
      id: _toInt(json['id']),
      fileName: json['fileName']?.toString() ?? 'rental-photo',
      contentType: json['contentType']?.toString() ?? 'image/jpeg',
      url: json['url']?.toString() ?? '',
    );
  }
}

int _toInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime _toDateTime(dynamic value) {
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }

  final DateTime? parsedDate = DateTime.tryParse(value?.toString() ?? '');

  return parsedDate ?? DateTime.now();
}
