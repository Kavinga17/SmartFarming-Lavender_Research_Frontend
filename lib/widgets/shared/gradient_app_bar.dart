// lib/widgets/shared/gradient_app_bar.dart
import 'package:flutter/material.dart';

class GradientAppBar extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget>? actions;

  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8A4FFF), Color(0xFF6C3CE6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  const GradientAppBar({
    super.key,
    required this.title,
    required this.icon,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        background: Container(
          decoration: BoxDecoration(gradient: primaryGradient),
        ),
      ),
      actions: actions,
    );
  }
}
