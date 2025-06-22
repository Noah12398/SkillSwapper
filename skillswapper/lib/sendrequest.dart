import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class SentRequestsScreen extends StatelessWidget {
  final String currentUser;

  SentRequestsScreen({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sent Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser)
            .collection('sentRequests')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return Center(child: Text("You haven't sent any requests."));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final data = requests[index].data() as Map<String, dynamic>;
              final receiverUid = data['to']; // always UID
              final receiverName = data['toName'] ?? receiverUid;
              final status = data['status'] ?? 'pending';
              final timestamp = data['timestamp']?.toDate().toString() ?? '';

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text("To: $receiverName"),
                  subtitle: Text("Status: $status\nSent at: $timestamp"),
                  trailing: status == 'accepted'
                      ? IconButton(
                          icon: Icon(Icons.chat, color: Colors.blue),
                          tooltip: "Chat",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  currentUser: currentUser,
                                  peerUser: receiverUid,
                                ),
                              ),
                            );
                          },
                        )
                      : Icon(
                          status == 'rejected'
                              ? Icons.cancel
                              : Icons.hourglass_top,
                          color: status == 'rejected'
                              ? Colors.red
                              : Colors.orange,
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
