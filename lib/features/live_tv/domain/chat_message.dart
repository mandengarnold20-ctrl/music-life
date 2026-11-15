/// Message du chat en direct (table `chat_messages`).
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.body,
    required this.createdAt,
    this.isHidden = false,
  });

  final int id;
  final String userId;
  final String authorName;
  final String body;
  final DateTime createdAt;
  final bool isHidden;

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
        id: (m['id'] as num).toInt(),
        userId: m['user_id'] as String,
        authorName: (m['author_name'] as String?) ?? 'Anonyme',
        body: m['body'] as String,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
        isHidden: m['is_hidden'] as bool? ?? false,
      );
}
