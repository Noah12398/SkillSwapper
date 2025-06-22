import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchScreen extends StatelessWidget {
  final String name;

  MatchScreen({required this.name});

  Future<List<Map<String, dynamic>>> findMatches() async {
    final currentUser = await FirebaseFirestore.instance.collection('users').doc(name).get();
    final userTeaches = List<String>.from(currentUser['teaches']);
    final userWants = List<String>.from(currentUser['wants']);

    final allUsers = await FirebaseFirestore.instance.collection('users').get();

    List<Map<String, dynamic>> matches = [];

    for (var doc in allUsers.docs) {
      if (doc.id == name) continue;

      final teaches = List<String>.from(doc['teaches']);
      final wants = List<String>.from(doc['wants']);

      final mutualTeaches = userWants.where((want) => teaches.contains(want)).toList();
      final mutualWants = userTeaches.where((teach) => wants.contains(teach)).toList();

      if (mutualTeaches.isNotEmpty && mutualWants.isNotEmpty) {
        final userData = doc.data();
        userData['mutualTeaches'] = mutualTeaches;
        userData['mutualWants'] = mutualWants;
        matches.add(userData);
      }
    }

    return matches;
  }

  void _showUserDetails(BuildContext context, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(user['name'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Teaches: ${user['teaches'].join(', ')}"),
            Text("Wants: ${user['wants'].join(', ')}"),
            SizedBox(height: 12),
            ElevatedButton.icon(
              icon: Icon(Icons.person_add_alt_1),
              label: Text("Send Request"),
              onPressed: () {
                // Placeholder: send connection request
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Request sent to ${user['name']}"),
                ));
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Matches')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: findMatches(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final matches = snapshot.data!;
          if (matches.isEmpty) return Center(child: Text('No matches found'));

          return ListView(
            children: matches.map((user) {
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(user['name']),
                  subtitle: Text(
                    "They can teach: ${user['mutualTeaches'].join(', ')}\n"
                    "They want to learn: ${user['mutualWants'].join(', ')}"
                  ),
                  trailing: Icon(Icons.swap_horiz),
                  onTap: () => _showUserDetails(context, user),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
