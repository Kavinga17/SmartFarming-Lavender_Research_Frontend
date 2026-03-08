import 'package:flutter/material.dart';

class LightBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const LightBar({Key? key, required this.label, required this.value, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10)),
        const SizedBox(height: 2),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(color: color.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value / 255,
            child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          ),
        ),
        const SizedBox(height: 2),
        Text('$value', style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}