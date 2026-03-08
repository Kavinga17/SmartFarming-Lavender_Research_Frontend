import 'package:flutter/material.dart';
import 'light_bar.dart';
import 'spectrum_chip.dart';

class StageCard extends StatelessWidget {
  final String name;
  final String duration;
  final int red;
  final int blue;
  final int white;
  final String description;
  final bool isCurrent;
  final VoidCallback? onSelect;

  const StageCard({
    Key? key,
    required this.name,
    required this.duration,
    required this.red,
    required this.blue,
    required this.white,
    required this.description,
    required this.isCurrent,
    this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCurrent
              ? [const Color(0xFF8B5CF6).withOpacity(0.1), Colors.white]
              : [Colors.white, const Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? const Color(0xFF8B5CF6) : Colors.grey.shade200,
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrent ? const Color(0xFF8B5CF6).withOpacity(0.2) : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                    const SizedBox(height: 4),
                    Text('Duration: $duration', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Current', style: TextStyle(fontSize: 12, color: Colors.white)),
                )
              else
                ElevatedButton(
                  onPressed: onSelect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Select'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: LightBar(label: 'Red', value: red, color: Colors.red)),
              const SizedBox(width: 4),
              Expanded(child: LightBar(label: 'Blue', value: blue, color: Colors.blue)),
              const SizedBox(width: 4),
              Expanded(child: LightBar(label: 'White', value: white, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}