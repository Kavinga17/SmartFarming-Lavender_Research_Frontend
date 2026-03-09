import 'package:flutter/material.dart';

class RecommendationScreen extends StatelessWidget {
  const RecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lighting Recommendations"),
      ),
      body: const Center(
        child: Text(
          "AI Lighting Recommendations will appear here",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
