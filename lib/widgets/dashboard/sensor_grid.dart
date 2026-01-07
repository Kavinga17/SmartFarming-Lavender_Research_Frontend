// lib/widgets/dashboard/sensor_grid.dart
import 'package:flutter/material.dart';

class SensorGrid extends StatelessWidget {
  final Map<String, dynamic> sensorData;
  final Function(String, double) onSensorValueChanged;

  static const Color primaryColor = Color(0xFF8A4FFF);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color textColor = Color(0xFF2C3E50);
  static const Color lightTextColor = Color(0xFF95A5A6);

  const SensorGrid({
    super.key,
    required this.sensorData,
    required this.onSensorValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sensors = [
      _buildSensorConfig(
        'Moisture',
        sensorData['moisture'],
        '%',
        Icons.water_drop,
        const Color(0xFF3498DB),
        0,
        100,
      ),
      _buildSensorConfig(
        'pH Level',
        sensorData['ph'],
        '',
        Icons.science,
        primaryColor,
        0,
        14,
      ),
      _buildSensorConfig(
        'EC',
        sensorData['ec'],
        '',
        Icons.bolt,
        const Color(0xFFF39C12),
        0,
        5,
      ),
      _buildSensorConfig(
        'Temp',
        sensorData['temperature'],
        '°C',
        Icons.thermostat,
        const Color(0xFFE74C3C),
        0,
        50,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sensor Readings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        ...sensors.map((sensor) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: sensor['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            sensor['icon'],
                            color: sensor['color'],
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          sensor['title'],
                          style: const TextStyle(
                            color: lightTextColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${sensor['value'].toStringAsFixed(sensor['title'] == 'pH Level' ? 1 : 0)}${sensor['unit']}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Stack(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final percentage =
                                  sensor['value'] / sensor['max'];
                              return Container(
                                width:
                                    constraints.maxWidth *
                                    percentage.clamp(0.0, 1.0),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      sensor['color'].withOpacity(0.8),
                                      sensor['color'],
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: sensor['value'],
                      min: sensor['min'],
                      max: sensor['max'],
                      activeColor: sensor['color'],
                      inactiveColor: Colors.transparent,
                      thumbColor: sensor['color'],
                      onChanged: (value) {
                        final key = _getSensorKey(sensor['title']);
                        onSensorValueChanged(key, value);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Map<String, dynamic> _buildSensorConfig(
    String title,
    double value,
    String unit,
    IconData icon,
    Color color,
    double min,
    double max,
  ) {
    return {
      'title': title,
      'value': value,
      'unit': unit,
      'icon': icon,
      'color': color,
      'min': min,
      'max': max,
    };
  }

  String _getSensorKey(String title) {
    switch (title) {
      case 'Moisture':
        return 'moisture';
      case 'pH Level':
        return 'ph';
      case 'EC':
        return 'ec';
      case 'Temp':
        return 'temperature';
      default:
        return title.toLowerCase();
    }
  }
}
