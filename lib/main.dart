import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'features/irrigation/irrigation_dashboard.dart';
import 'features/irrigation/irrigation_setup.dart';
import 'screens/irrigation_history_screen.dart';

void main() {
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
      home: DashboardScreen(),
      routes: {
        '/irrigation': (context) => const IrrigationDashboard(),
        // '/irrigation/setup': (context) => const IrrigationSetupPage(), // Commented out as shown
        '/irrigation-history': (context) =>
            IrrigationHistoryScreen(), // FIXED THIS LINE
      },
    );
  }
}
