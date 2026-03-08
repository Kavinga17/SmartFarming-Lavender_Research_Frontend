enum HealthStatus { healthy, nutrientDeficient, diseased }

class DiagnosticReport {
  final String id;
  final DateTime timestamp;
  final HealthStatus status;
  final double confidence; // 0-1
  final String? imageUrl;
  final Map<String, double> sensorReadings; // e.g., {'temperature': 22.5}
  final List<String> recommendations;

  DiagnosticReport({
    required this.id,
    required this.timestamp,
    required this.status,
    required this.confidence,
    this.imageUrl,
    required this.sensorReadings,
    required this.recommendations,
  });

  factory DiagnosticReport.fromJson(Map<String, dynamic> json) {
    return DiagnosticReport(
      id: json['id'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      status: _statusFromString(json['status']),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      imageUrl: json['imageUrl'],
      sensorReadings: Map<String, double>.from(json['sensorReadings'] ?? {}),
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }

  static HealthStatus _statusFromString(String? s) {
    switch (s?.toLowerCase()) {
      case 'healthy':
        return HealthStatus.healthy;
      case 'nutrient_deficient':
        return HealthStatus.nutrientDeficient;
      case 'diseased':
        return HealthStatus.diseased;
      default:
        return HealthStatus.healthy;
    }
  }

  String get statusString {
    switch (status) {
      case HealthStatus.healthy:
        return 'Healthy';
      case HealthStatus.nutrientDeficient:
        return 'Nutrient Deficient';
      case HealthStatus.diseased:
        return 'Diseased';
    }
  }
}