class ChatMessageModel {
  final String id;
  final String conversationId;
  final String sender; // 'user' | 'agency'
  final String text;
  final bool isRead;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? attachmentType;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.text,
    required this.isRead,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentType,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        id: json['id'],
        conversationId: json['conversation_id'],
        sender: json['sender'],
        text: json['text'],
        isRead: json['is_read'] ?? false,
        attachmentUrl: json['attachment_url'],
        attachmentName: json['attachment_name'],
        attachmentType: json['attachment_type'],
        createdAt: DateTime.parse(json['created_at']),
      );

  bool get isFromAgency => sender == 'agency';
  bool get hasAttachment => attachmentUrl != null;
}

class ConversationModel {
  final String id;
  final String userId;
  final String agencyId;
  final String agencyName;
  final DateTime createdAt;
  final ChatMessageModel? lastMessage;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.userId,
    required this.agencyId,
    required this.agencyName,
    required this.createdAt,
    this.lastMessage,
    required this.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      ConversationModel(
        id: json['id'],
        userId: json['user_id'],
        agencyId: json['agency_id'],
        agencyName: json['agency_name'],
        createdAt: DateTime.parse(json['created_at']),
        lastMessage: json['last_message'] != null
            ? ChatMessageModel.fromJson(json['last_message'])
            : null,
        unreadCount: json['unread_count'] ?? 0,
      );
}
