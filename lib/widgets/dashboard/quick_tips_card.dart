// lib/widgets/dashboard/quick_tips_card.dart
import 'package:flutter/material.dart';

class QuickTipsCard extends StatelessWidget {
  final Map<String, dynamic>? dashboardSummary;

  static const Color warningColor = Color(0xFFFFA726);
  static const Color successColor = Color(0xFF2ECC71);
  static const Color textColor = Color(0xFF2C3E50);
  static const Color lightTextColor = Color(0xFF95A5A6);

  const QuickTipsCard({super.key, this.dashboardSummary});

  @override
  Widget build(BuildContext context) {
    final tips = _generateTips();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [warningColor.withOpacity(0.8), warningColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Quick Tips',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...tips.map((tip) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      tip['icon'],
                      color: tip['isGood'] ? successColor : lightTextColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tip['text'],
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _generateTips() {
    // Use dashboard summary if available, otherwise default tips
    if (dashboardSummary != null) {
      final insights = dashboardSummary!['insights'] ?? {};
      final reminders = dashboardSummary!['reminders'] ?? [];
      final sensorStatus = dashboardSummary!['sensorStatus'] ?? {};

      final tips = <Map<String, dynamic>>[];

      // Add insights
      if (insights['whatsWorking'] != null) {
        tips.add({
          'text': '${insights['whatsWorking']}',
          'icon': Icons.check_circle,
          'isGood': true,
        });
      }

      if (insights['needsAttention'] != null &&
          insights['needsAttention'] != 'None - all systems optimal') {
        tips.add({
          'text': '${insights['needsAttention']}',
          'icon': Icons.info,
          'isGood': false,
        });
      }

      // Add reminders
      if (reminders.isNotEmpty) {
        final nextReminder = reminders.first;
        tips.add({
          'text': nextReminder['title'] ?? 'Check reminders',
          'icon': Icons.access_time,
          'isGood': false,
        });
      }

      // Add sensor status tips
      if (sensorStatus['moisture'] == 'low') {
        tips.add({
          'text': 'Water soon - moisture low',
          'icon': Icons.water_drop,
          'isGood': false,
        });
      }

      if (tips.length < 3) {
        // Add default tips if we don't have enough
        tips.addAll([
          {'text': 'Water in 12h', 'icon': Icons.access_time, 'isGood': false},
          {
            'text': 'Next analysis in 7 days',
            'icon': Icons.calendar_today,
            'isGood': false,
          },
        ]);
      }

      return tips.take(4).toList();
    }

    // Default tips when no dashboard summary
    return [
      {'text': 'Water in 12h', 'icon': Icons.access_time, 'isGood': false},
      {'text': 'pH optimal', 'icon': Icons.check_circle, 'isGood': true},
      {
        'text': 'Nitrogen levels good',
        'icon': Icons.check_circle,
        'isGood': true,
      },
      {'text': 'EC slightly high', 'icon': Icons.info, 'isGood': false},
    ];
  }
}
