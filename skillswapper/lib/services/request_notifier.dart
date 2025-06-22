import 'package:flutter/material.dart';

class RequestNotifier extends ChangeNotifier {
  final Map<String, List<String>> _requests = {};

  void addRequest(String userId) {
    if (!_requests.containsKey(userId)) {
      _requests[userId] = [];
    }
    notifyListeners();
  }

  List<String> getRequestsForUser(String userId) {
    return _requests[userId] ?? [];
  }
}
