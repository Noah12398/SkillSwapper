import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:skillswapper/services/request_notifier.dart';
import 'package:skillswapper/welcome_screen.dart';
import 'firebase_options.dart'; // generated file from `flutterfire configure`

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Required for Firebase Web
      await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // <-- This line is key!
  );

  } else {
    await Firebase.initializeApp();
  }

runApp(
    ChangeNotifierProvider(
      create: (_) => RequestNotifier(),
      child: SkillSwapApp(),
    ),
  );}

class SkillSwapApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      
      title: 'SkillSwap',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: WelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
