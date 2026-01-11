// lib/widgets/shared/gradient_app_bar.dart
import 'package:flutter/material.dart';

class GradientAppBar extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget>? actions;
  final bool showBackArrow;

  static const Color backgroundColor = Color.fromARGB(255, 248, 217, 249);
  const GradientAppBar({
    super.key,
    required this.title,
    this.icon,
    this.actions,
    this.showBackArrow = false, // Default to false
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 70,
      floating: false,
      pinned: true,
      collapsedHeight: 70,
      backgroundColor: backgroundColor,
      elevation: 2,
      leading: showBackArrow
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.black54,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          children: [
            if (icon != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color.fromARGB(255, 31, 27, 27),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon!, size: 20, color: Colors.grey[700]),
              ),
            if (icon != null) const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18, // Smaller, cleaner
                fontWeight: FontWeight.w500, // Medium weight, not bold
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 16, bottom: 10),
        background: Container(
          color: backgroundColor, // Solid light gray
        ),
      ),
      actions: actions,
    );
  }
}
