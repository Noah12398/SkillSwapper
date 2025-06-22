import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String currentUser;
  final String peerUser;

  ChatScreen({required this.currentUser, required this.peerUser});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String conversationId;

  @override
  void initState() {
    super.initState();
    // Generate conversation ID by sorting users
    final participants = [widget.currentUser, widget.peerUser]..sort();
    conversationId = participants.join('_');
  }

  void sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final message = {
      'from': widget.currentUser,
      'to': widget.peerUser,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'conversationId': conversationId,
    };

    print("Sending: $message");
    await FirebaseFirestore.instance.collection('messages').add(message);
    _controller.clear();

    Future.delayed(Duration(milliseconds: 300), () {
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
    return Scaffold(
      appBar: AppBar(title: Text("Chat with ${widget.peerUser}")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('conversationId', isEqualTo: conversationId)
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  print("Loading messages...");
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print("Error: ${snapshot.error}");
                  return Center(child: Text('Error loading messages'));
                }

                final messages = snapshot.data?.docs ?? [];
                print("Loaded ${messages.length} messages");

                if (messages.isEmpty) {
                  return Center(child: Text('No messages yet'));
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data =
                        messages[index].data() as Map<String, dynamic>;

                    final isMe = data['from'] == widget.currentUser;
                    final text = data['text'] ?? '';
                    final timestamp = data['timestamp'];

                    // Skip rendering if timestamp is null
                    if (timestamp == null) return SizedBox();

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.indigo[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          text,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.indigo),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
