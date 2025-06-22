import 'package:flutter/material.dart';
import 'package:skillswapper/match.dart';
import 'package:skillswapper/welcome_screen.dart';
import 'combinedrequestsscreen.dart';

class DashboardScreen extends StatelessWidget {
  final String currentUser;

  DashboardScreen({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $currentUser'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => WelcomeScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.search),
              label: Text('Find Matches'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MatchScreen(name: currentUser),
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.swap_horiz),
              label: Text('View My Requests'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CombinedRequestsScreen(currentUser: currentUser),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
