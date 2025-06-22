import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillswapper/match.dart';
import 'package:skillswapper/requestscreen.dart';
import 'package:skillswapper/sendrequest.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nameController = TextEditingController();
  List<String> allSkills = ['Flutter', 'Python', 'JavaScript', 'UI/UX'];
  List<String> teaches = [];
  List<String> wants = [];

  void saveProfile() async {
    final name = _nameController.text;
    if (name.isEmpty || teaches.isEmpty || wants.isEmpty) return;

    await FirebaseFirestore.instance.collection('users').doc(name).set({
      'name': name,
      'teaches': teaches,
      'wants': wants,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SkillSwap')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Your name'),
            ),
            SizedBox(height: 20),
            Text('I can teach:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...allSkills.map((skill) => CheckboxListTile(
                  title: Text(skill),
                  value: teaches.contains(skill),
                  onChanged: (val) {
                    setState(() {
                      val! ? teaches.add(skill) : teaches.remove(skill);
                    });
                  },
                )),
            Divider(),
            Text('I want to learn:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...allSkills.map((skill) => CheckboxListTile(
                  title: Text(skill),
                  value: wants.contains(skill),
                  onChanged: (val) {
                    setState(() {
                      val! ? wants.add(skill) : wants.remove(skill);
                    });
                  },
                )),
            ElevatedButton(
              onPressed: saveProfile,
              child: Text('Save Profile'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MatchScreen(name: _nameController.text)),
              ),
              child: Text('Find Matches'),
            ),
            ElevatedButton(
  onPressed: () {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your name first')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestScreen(currentUser: name),
      ),
    );
  },
  child: Text('View Requests'),
),
ElevatedButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => SentRequestsScreen(currentUser: _nameController.text)),
  ),
  child: Text('View Sent Requests'),
),

          ],
          
        ),
      ),
    );
  }
}
