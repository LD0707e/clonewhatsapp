import 'package:flutter/material.dart';
import 'package:whatssap_clone/models/contact.dart';
import 'package:whatssap_clone/screens/chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final List<Contact> contacts = [
    Contact(
      id: '1',
      name: 'Orlando',
      avatar: '',
      lastMessage: 'Olá! Como posso te ajudar hoje?',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
      isOnline: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Conversas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: contacts.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma conversa',
                style: TextStyle(color: Color(0xFF888888)),
              ),
            )
          : ListView.separated(
              itemCount: contacts.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Color(0xFF222222), height: 1),
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return ListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(contact: contact),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF075E54),
                    child: Text(
                      contact.name.isNotEmpty
                          ? contact.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        contact.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    contact.lastMessage,
                    style: const TextStyle(color: Color(0xFF888888)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(contact.lastMessageTime),
                        style:
                            const TextStyle(color: Color(0xFF888888), fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      contact.isOnline
                          ? const CircleAvatar(
                              radius: 6,
                              backgroundColor: Color(0xFF075E54),
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE53935),
        onPressed: () {},
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else {
      final day = time.day.toString().padLeft(2, '0');
      final month = time.month.toString().padLeft(2, '0');
      return '$day/$month';
    }
  }
}
