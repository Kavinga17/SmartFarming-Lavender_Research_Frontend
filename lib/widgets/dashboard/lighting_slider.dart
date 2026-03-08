import 'package:flutter/material.dart';

class LightingSlider extends StatelessWidget {
  final String label;
  final double value;
  final Function(double) onChanged;

  const LightingSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label),
        Slider(
          min: 0,
          max: 255,
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}