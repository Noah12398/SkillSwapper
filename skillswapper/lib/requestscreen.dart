import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class RequestScreen extends StatelessWidget {
  final String currentUser;

  RequestScreen({required this.currentUser});

  Future<void> handleRequest(
    BuildContext context,
    String sender,
    bool accepted,
  ) async {
    final status = accepted ? 'accepted' : 'rejected';

    final receiverRef =
        FirebaseFirestore.instance.collection('users').doc(currentUser);
    final senderRef =
        FirebaseFirestore.instance.collection('users').doc(sender);

    // 1. Update status in requests/sentRequests
    await receiverRef.collection('requests').doc(sender).update({
      'status': status,
    });
    await senderRef.collection('sentRequests').doc(currentUser).update({
      'status': status,
    });

    // 2. Store in accepted/rejected
    await receiverRef.collection(status).doc(sender).set({
      'from': sender,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 3. If accepted, store in connections and navigate to chat
    if (accepted) {
      await receiverRef.collection('connections').doc(sender).set({
        'name': sender,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await senderRef.collection('connections').doc(currentUser).set({
        'name': currentUser,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            currentUser: currentUser,
            peerUser: sender,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Requests for $currentUser")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser)
            .collection('requests')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return Center(child: Text("No requests yet"));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final data = requests[index].data() as Map<String, dynamic>;
              final sender = data['from'];
              final status = data['status'] ?? 'pending';

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text("Request from $sender"),
                  subtitle: Text(
                    "Status: $status\n"
                    "${data['timestamp']?.toDate().toString() ?? ''}",
                  ),
                  trailing: status == 'pending'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.check, color: Colors.green),
                              tooltip: 'Accept',
                              onPressed: () =>
                                  handleRequest(context, sender, true),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              tooltip: 'Reject',
                              onPressed: () =>
                                  handleRequest(context, sender, false),
                            ),
                          ],
                        )
                      : status == 'accepted'
                          ? IconButton(
                              icon: Icon(Icons.chat, color: Colors.blue),
                              tooltip: 'Chat',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      currentUser: currentUser,
                                      peerUser: sender,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Icon(Icons.cancel, color: Colors.red),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
