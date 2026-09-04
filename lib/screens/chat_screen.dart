import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _markMessagesAsSeen();
  }

  void _markMessagesAsSeen() async {
    final messagesRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages');
    
    final unseens = await messagesRef
        .where('senderId', isEqualTo: widget.otherUserId)
        .where('isSeen', isEqualTo: false)
        .get();
        
    for (var doc in unseens.docs) {
      await doc.reference.update({'isSeen': true});
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final authProvider = Provider.of(context, listen: false);
    final message = Message(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: authProvider.currentUser!.uid,
      text: _messageController.text.trim(),
      timestamp: DateTime.now(),
    );
    
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(message.messageId)
        .set(message.toMap());
        
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .set({
          'lastMessage': message.text,
          'lastMessageTime': message.timestamp,
          'lastMessageSender': message.senderId,
        }, SetOptions(merge: true));
        
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              child: Text(widget.otherUserName[0].toUpperCase()),
            ),
            SizedBox(width: 10),
            Text(widget.otherUserName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                
                var messages = snapshot.data!.docs;
                
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = Message.fromMap(
                      messages[index].data() as Map
                    );
                    bool isMe = message.senderId == authProvider.currentUser!.uid;
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? Colors.green[300] : Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message.text, style: TextStyle(color: isMe ? Colors.white : Colors.black)),
            SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.black54),
                ),
                if (isMe) ...[
                  SizedBox(width: 4),
                  Icon(
                    message.isSeen ? Icons.done_all : Icons.done,
                    size: 12,
                    color: isMe ? Colors.white70 : Colors.black54,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          IconButton(icon: Icon(Icons.attach_file), onPressed: () {}),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(hintText: 'Digite uma mensagem...', border: InputBorder.none),
              maxLines: null,
            ),
          ),
          IconButton(icon: Icon(Icons.send, color: Colors.green), onPressed: _sendMessage),
        ],
      ),
    );
  }
}