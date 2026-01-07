// lib/widgets/dashboard/quick_actions_row.dart
import 'package:flutter/material.dart';

class QuickActionsRow extends StatelessWidget {
  static const Color primaryColor = Color(0xFF8A4FFF);
  static const Color secondaryColor = Color(0xFF27AE60);
  static const Color accentColor = Color(0xFFFFA726);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF2C3E50);

  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        'icon': Icons.qr_code_scanner,
        'label': 'Scan Now',
        'color': primaryColor,
        'onTap': () {
          // Handle scan action
        },
      },
      {
        'icon': Icons.history,
        'label': 'History',
        'color': secondaryColor,
        'onTap': () {
          // Handle history action
        },
      },
      {
        'icon': Icons.science,
        'label': 'NPK',
        'color': accentColor,
        'onTap': () {
          // Handle NPK action
        },
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: actions.map((action) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Material(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: action['onTap'] as VoidCallback,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (action['color'] as Color).withOpacity(
                                0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              action['icon'] as IconData,
                              color: action['color'] as Color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            action['label'] as String,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
