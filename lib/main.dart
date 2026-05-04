import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/common/common_login_screen.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      Zone.current.handleUncaughtError(
        details.exception,
        details.stack ?? StackTrace.current,
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      Zone.current.handleUncaughtError(error, stack);
      return true;
    };

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      runApp(const LavenderAIApp());
    } catch (e, st) {
      runApp(StartupErrorApp(message: e.toString()));
      Zone.current.handleUncaughtError(e, st);
    }
  }, (error, stack) {
    debugPrint('Uncaught startup error: $error');
    debugPrintStack(stackTrace: stack);
  });
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 54),
                const SizedBox(height: 16),
                const Text(
                  'App could not start correctly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
