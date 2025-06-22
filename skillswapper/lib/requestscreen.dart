import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestScreen extends StatelessWidget {
  final String currentUser;

  RequestScreen({required this.currentUser});

  Future<void> handleRequest(String sender, bool accepted) async {
    final status = accepted ? 'accepted' : 'rejected';

    final receiverRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser);

    final senderRef = FirebaseFirestore.instance
        .collection('users')
        .doc(sender);

    // Update status in the receiver's requests
    await receiverRef
        .collection('requests')
        .doc(sender)
        .update({'status': status});

    // Add to receiver's accepted/rejected collection (optional)
    await receiverRef
        .collection(status)
        .doc(sender)
        .set({
          'from': sender,
          'timestamp': FieldValue.serverTimestamp(),
        });

    // Update status in sender's sentRequests
    await senderRef
        .collection('sentRequests')
        .doc(currentUser)
        .update({'status': status});
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
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

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
                  subtitle: Text("Status: $status\n"
                      "${data['timestamp']?.toDate().toString() ?? ''}"),
                  trailing: status == 'pending'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.check, color: Colors.green),
                              tooltip: 'Accept',
                              onPressed: () => handleRequest(sender, true),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              tooltip: 'Reject',
                              onPressed: () => handleRequest(sender, false),
                            ),
                          ],
                        )
                      : Icon(
                          status == 'accepted'
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: status == 'accepted'
                              ? Colors.green
                              : Colors.red,
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
