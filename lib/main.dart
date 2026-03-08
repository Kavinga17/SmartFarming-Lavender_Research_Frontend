import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const LavenderAIApp());
}

class LavenderAIApp extends StatelessWidget {
  const LavenderAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '🌿 Lavender AI',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
