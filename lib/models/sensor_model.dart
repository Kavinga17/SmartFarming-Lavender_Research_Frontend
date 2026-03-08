class SensorData {
  final double temperature; // Celsius
  final double humidity;    // Percent
  final double lightIntensity; // Lux
  final DateTime timestamp;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.lightIntensity,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: json['temperature']?.toDouble() ?? 0.0,
      humidity: json['humidity']?.toDouble() ?? 0.0,
      lightIntensity: json['lightIntensity']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'lightIntensity': lightIntensity,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}