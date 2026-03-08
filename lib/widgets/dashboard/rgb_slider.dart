import 'package:flutter/material.dart';

class RGBSlider extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final ValueChanged<double> onChanged;

  const RGBSlider({
    Key? key,
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('$value', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 0,
          max: 255,
          divisions: 255,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }
}