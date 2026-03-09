import 'dart:async';
import 'climate_api_service.dart';

/// Service for fetching live sensor data from the Flask backend.
///
/// The ESP32 sends sensor readings to POST /predict. The backend stores
/// the latest values in memory. This service polls GET /sensors to
/// retrieve them for display in the mobile app.
class SensorDataService {
  static Timer? _pollTimer;
  static final StreamController<SensorReading?> _controller =
      StreamController<SensorReading?>.broadcast();

  /// Start polling the backend /sensors endpoint every [intervalSeconds].
  /// Returns a broadcast stream that emits [SensorReading] on each poll.
  static Stream<SensorReading?> streamLatestReading({
    int intervalSeconds = 5,
  }) {
    // If already polling, just return the existing stream
    if (_pollTimer != null && _pollTimer!.isActive) {
      return _controller.stream;
    }

    // Do an immediate fetch
    _fetchAndEmit();

    // Then poll at interval
    _pollTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => _fetchAndEmit(),
    );

    return _controller.stream;
  }

  /// Stop polling.
  static void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  static Future<void> _fetchAndEmit() async {
    final data = await ClimateApiService.fetchSensors();
    if (data != null) {
      _controller.add(SensorReading(
        airTemp: data['air_temp'] ?? 0.0,
        humidity: data['humidity'] ?? 0.0,
        soilTemp: data['soil_temp'] ?? 0.0,
        timestamp: DateTime.now(),
      ));
    }
  }

  /// One-shot fetch of the latest sensor reading.
  static Future<SensorReading?> getLatestReading() async {
    try {
      final data = await ClimateApiService.fetchSensors();
      if (data == null) return null;
      return SensorReading(
        airTemp: data['air_temp'] ?? 0.0,
        humidity: data['humidity'] ?? 0.0,
        soilTemp: data['soil_temp'] ?? 0.0,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('⚠️ Failed to fetch sensor reading: $e');
      return null;
    }
  }
}

/// A single sensor reading from the greenhouse.
class SensorReading {
  final double airTemp;
  final double humidity;
  final double soilTemp;
  final DateTime? timestamp;

  SensorReading({
    required this.airTemp,
    required this.humidity,
    required this.soilTemp,
    this.timestamp,
  });

  /// True if at least one reading is non-zero (i.e. we have real data).
  bool get hasData => airTemp != 0.0 || humidity != 0.0 || soilTemp != 0.0;
}
