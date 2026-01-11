// lib/widgets/shared/connection_status.dart
import 'package:flutter/material.dart';

class ConnectionStatus extends StatelessWidget {
  final bool isConnected;
  final bool isChecking;
  final VoidCallback onRetry;

  static const Color accentColor = Color(0xFFFFA726);

  const ConnectionStatus({
    super.key,
    required this.isConnected,
    required this.isChecking,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isConnected) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor),
      ),
      child: Row(
        children: [
          Icon(
            isChecking ? Icons.wifi_find : Icons.wifi_off,
            color: accentColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isChecking
                  ? 'Checking backend connection...'
                  : 'Backend disconnected - using mock data',
              style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 13),
            ),
          ),
          if (!isChecking)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
