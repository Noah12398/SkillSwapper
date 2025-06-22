import 'package:flutter/material.dart';
import 'package:skillswapper/requestscreen.dart';
import 'package:skillswapper/sendrequest.dart';


class CombinedRequestsScreen extends StatelessWidget {
  final String currentUser;

  CombinedRequestsScreen({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Your Requests'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Received'),
              Tab(text: 'Sent'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RequestScreen(currentUser: currentUser),
            SentRequestsScreen(currentUser: currentUser),
          ],
        ),
      ),
    );
  }
}
