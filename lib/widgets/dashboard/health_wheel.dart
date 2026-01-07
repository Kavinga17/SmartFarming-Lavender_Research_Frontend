// lib/widgets/dashboard/health_wheel.dart
import 'package:flutter/material.dart';

class HealthWheel extends StatelessWidget {
  final double healthScore;
  final DateTime? lastUpdated;

  static const Color successColor = Color(0xFF2ECC71);
  static const Color warningColor = Color(0xFFFFA726);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color textColor = Color(0xFF2C3E50);
  static const Color lightTextColor = Color(0xFF95A5A6);

  const HealthWheel({super.key, required this.healthScore, this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    final isHealthy = healthScore >= 80;
    final color = isHealthy ? successColor : warningColor;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: healthScore / 100,
                  strokeWidth: 12,
                  backgroundColor: backgroundColor,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${healthScore.round()}%',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -1,
                    ),
                  ),
                  const Text(
                    'HEALTH',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: lightTextColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isHealthy ? Icons.check_circle : Icons.info,
                  color: color,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  isHealthy ? 'OPTIMAL' : 'NEEDS ATTENTION',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getHealthMessage(healthScore),
            style: TextStyle(color: lightTextColor, fontSize: 14),
          ),
          if (lastUpdated != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last updated: ${_formatTime(lastUpdated!)}',
              style: TextStyle(
                color: lightTextColor.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getHealthMessage(double score) {
    if (score >= 90) return 'Excellent health - all systems optimal';
    if (score >= 80) return 'Good health - minor improvements possible';
    if (score >= 60) return 'Needs attention - review recommendations';
    if (score >= 40) return 'Requires action - implement changes';
    return 'Critical - immediate action needed';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
