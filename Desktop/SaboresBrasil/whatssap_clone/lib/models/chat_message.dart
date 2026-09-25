enum MessageType { sent, received }

class ChatMessage {
  final String text;
  final MessageType type;
  final DateTime time;

  ChatMessage({
    required this.text,
    required this.type,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}
