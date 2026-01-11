// lib/services/irrigation/irrigation_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class IrrigationService {
  final String baseUrl = 'http://localhost:5000'; // Your backend URL
  String? _token;

  IrrigationService();

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Get current irrigation status
  Future<IrrigationStatus> getStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/irrigation/status'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return IrrigationStatus.fromJson(json.decode(response.body));
      } else {
        // Return default if no schedule exists
        return IrrigationStatus(
          hasSchedule: false,
          message: 'No irrigation schedule found',
        );
      }
    } catch (e) {
      print('Error getting irrigation status: $e');
      return IrrigationStatus(
        hasSchedule: false,
        message: 'Failed to load irrigation status',
      );
    }
  }

  // Setup initial irrigation with moisture input
  Future<IrrigationResult> setupIrrigationWithMoisture({
    required int plantCount,
    required double currentMoisture,
    bool startAutomated = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/irrigation/setup'),
        headers: _getHeaders(),
        body: json.encode({
          'plantCount': plantCount,
          'currentMoisture': currentMoisture,
          'startAutomated': startAutomated,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return IrrigationResult.fromJson(data);
      } else {
        throw Exception('Failed to setup irrigation');
      }
    } catch (e) {
      print('Error setting up irrigation: $e');
      rethrow;
    }
  }

  // Start automated irrigation routine
  Future<IrrigationResult> startAutomatedRoutine() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/irrigation/start'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return IrrigationResult.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to start automated routine');
      }
    } catch (e) {
      print('Error starting automated routine: $e');
      rethrow;
    }
  }

  // Water now (manual override)
  Future<IrrigationResult> waterNow() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/irrigation/water-now'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return IrrigationResult.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to execute watering');
      }
    } catch (e) {
      print('Error watering now: $e');
      rethrow;
    }
  }

  // Submit diagnostic moisture reading
  Future<DiagnosticResult> submitMoistureReading(double moistureLevel) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/irrigation/diagnostic'),
        headers: _getHeaders(),
        body: json.encode({
          'moistureLevel': moistureLevel,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return DiagnosticResult.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to submit moisture reading');
      }
    } catch (e) {
      print('Error submitting moisture reading: $e');
      rethrow;
    }
  }

  // Get suggested watering routine based on plant count and moisture
  Future<WateringRoutine> getSuggestedRoutine({
    required int plantCount,
    required double moistureLevel,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/irrigation/suggest-routine'),
        headers: _getHeaders(),
        body: json.encode({
          'plantCount': plantCount,
          'moistureLevel': moistureLevel,
        }),
      );

      if (response.statusCode == 200) {
        return WateringRoutine.fromJson(json.decode(response.body));
      } else {
        // Return mock suggestion if backend not ready
        return _getMockRoutine(plantCount, moistureLevel);
      }
    } catch (e) {
      print('Error getting suggested routine: $e');
      return _getMockRoutine(plantCount, moistureLevel);
    }
  }
}

// Model classes
class IrrigationStatus {
  final bool hasSchedule;
  final String message;
  final IrrigationSchedule? schedule;

  IrrigationStatus({
    required this.hasSchedule,
    required this.message,
    this.schedule,
  });

  factory IrrigationStatus.fromJson(Map<String, dynamic> json) {
    return IrrigationStatus(
      hasSchedule: json['hasSchedule'] ?? false,
      message: json['message'] ?? '',
      schedule: json['schedule'] != null
          ? IrrigationSchedule.fromJson(json['schedule'])
          : null,
    );
  }
}

class IrrigationSchedule {
  final String id;
  final int plantCount;
  final double waterAmount;
  final int intervalDays;
  final DateTime nextWatering;
  final bool isAutomated;
  final String status;

  IrrigationSchedule({
    required this.id,
    required this.plantCount,
    required this.waterAmount,
    required this.intervalDays,
    required this.nextWatering,
    required this.isAutomated,
    required this.status,
  });

  factory IrrigationSchedule.fromJson(Map<String, dynamic> json) {
    return IrrigationSchedule(
      id: json['_id'] ?? '',
      plantCount: json['plantCount'] ?? 0,
      waterAmount: (json['waterAmount'] ?? 0).toDouble(),
      intervalDays: json['intervalDays'] ?? 3,
      nextWatering: DateTime.parse(
        json['nextWatering'] ?? DateTime.now().toIso8601String(),
      ),
      isAutomated: json['isAutomated'] ?? false,
      status: json['status'] ?? 'inactive',
    );
  }
}

class IrrigationResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  IrrigationResult({required this.success, required this.message, this.data});

  factory IrrigationResult.fromJson(Map<String, dynamic> json) {
    return IrrigationResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json,
    );
  }
}

class DiagnosticResult {
  final String id;
  final String condition;
  final String recommendation;
  final Map<String, dynamic> adjustments;
  final DateTime timestamp;

  DiagnosticResult({
    required this.id,
    required this.condition,
    required this.recommendation,
    required this.adjustments,
    required this.timestamp,
  });

  factory DiagnosticResult.fromJson(Map<String, dynamic> json) {
    return DiagnosticResult(
      id: json['_id'] ?? '',
      condition: json['condition'] ?? 'optimal',
      recommendation: json['recommendation'] ?? '',
      adjustments: Map<String, dynamic>.from(json['adjustments'] ?? {}),
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class WateringRoutine {
  final double waterAmount;
  final int intervalDays;
  final int durationMinutes;
  final String suggestion;
  final Map<String, dynamic> calculations;

  WateringRoutine({
    required this.waterAmount,
    required this.intervalDays,
    required this.durationMinutes,
    required this.suggestion,
    required this.calculations,
  });

  factory WateringRoutine.fromJson(Map<String, dynamic> json) {
    return WateringRoutine(
      waterAmount: (json['waterAmount'] ?? 0).toDouble(),
      intervalDays: json['intervalDays'] ?? 3,
      durationMinutes: json['durationMinutes'] ?? 5,
      suggestion: json['suggestion'] ?? '',
      calculations: Map<String, dynamic>.from(json['calculations'] ?? {}),
    );
  }
}

// Helper method for mock data
WateringRoutine _getMockRoutine(int plantCount, double moistureLevel) {
  // Calculate based on lavender requirements
  double baseWaterPerPlant = 500; // mL per week
  double adjustmentFactor = 1.0;

  if (moistureLevel < 30) {
    adjustmentFactor = 1.4; // Increase for dry soil
  } else if (moistureLevel > 70) {
    adjustmentFactor = 0.6; // Decrease for wet soil
  }

  final weeklyWater = baseWaterPerPlant * plantCount * adjustmentFactor;
  final perCycleWater = (weeklyWater / (7 / 3)).round(); // 3-day intervals

  return WateringRoutine(
    waterAmount: perCycleWater.toDouble(),
    intervalDays: moistureLevel < 30 ? 2 : 3,
    durationMinutes: 5,
    suggestion: moistureLevel < 30
        ? 'Soil is dry. Increase watering frequency.'
        : moistureLevel > 70
        ? 'Soil is wet. Reduce watering amount.'
        : 'Soil moisture is optimal for lavender.',
    calculations: {
      'plantCount': plantCount,
      'moistureLevel': moistureLevel,
      'baseWaterPerPlant': baseWaterPerPlant,
      'adjustmentFactor': adjustmentFactor,
      'weeklyTotal': weeklyWater,
    },
  );
}
