class Message {
  String messageId;
  String senderId;
  String text;
  DateTime timestamp;
  bool isSeen;
  String? imageUrl;

  Message({
    required this.messageId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isSeen = false,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'isSeen': isSeen,
      'imageUrl': imageUrl,
    };
  }

  factory Message.fromMap(Map map) {
    return Message(
      messageId: map['messageId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as DateTime?) ?? DateTime.now(),
      isSeen: map['isSeen'] ?? false,
      imageUrl: map['imageUrl'],
    );
  }
}