import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SensorChartScreen extends StatelessWidget {
  const SensorChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sensor Analytics"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Temperature (Last 24 Hours)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      spots: [
                        FlSpot(0, 22),
                        FlSpot(1, 23),
                        FlSpot(2, 24),
                        FlSpot(3, 23),
                        FlSpot(4, 25),
                        FlSpot(5, 24),
                        FlSpot(6, 26),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}