import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String uid;

  ProfileSetupScreen({required this.uid});

  @override
  _ProfileSetupScreenState createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final List<String> allSkills = ['Flutter', 'Python', 'JavaScript', 'UI/UX'];
  List<String> teaches = [];
  List<String> wants = [];

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  void saveProfile() async {
    if (!_formKey.currentState!.validate() || teaches.isEmpty || wants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and select skills')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
      'uid': widget.uid,
      'name': _nameController.text.trim(),
      'teaches': teaches,
      'wants': wants,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile saved!')),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => DashboardScreen(currentUser: widget.uid)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Set Up Your Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Center(
              child: Image.asset(
                'assets/images/SkillswapperLogo.png',
                height: 100,
              ),
            ),
            SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Your Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Enter your name' : null,
                  ),
                  SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('I can teach:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('I want to learn:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  ...allSkills.map((skill) => CheckboxListTile(
                        title: Text(skill),
                        value: wants.contains(skill),
                        onChanged: (val) {
                          setState(() {
                            val! ? wants.add(skill) : wants.remove(skill);
                          });
                        },
                      )),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: saveProfile,
                    child: Text('Save Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      minimumSize: Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
