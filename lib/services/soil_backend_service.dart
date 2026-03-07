// lib/services/soil_backend_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class SoilBackendService {
  // PC's IP address
  static const String baseUrl = 'http://10.118.213.120:3000';

  // ==================== SENSOR ENDPOINTS ====================

  static Future<double?> getMoisture() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sensor/moisture'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['moisture']?.toDouble();
      }
      return null;
    } catch (e) {
      print('❌ Error getting moisture: $e');
      return null;
    }
  }

  // ==================== DEVICE STATUS ====================

  static Future<Map<String, dynamic>?> getDeviceStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/irrigation/device/status'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Error getting device status: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getNextWatering() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/irrigation/next'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Error getting next watering: $e');
      return null;
    }
  }

  // ==================== ANALYSIS ENDPOINTS ====================

  static Future<Map<String, dynamic>?> analyzeImage(XFile image) async {
    try {
      final uri = Uri.parse('$baseUrl/api/analyze');
      var request = http.MultipartRequest('POST', uri);

      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = Map<String, dynamic>.from(
          json.decode(responseData),
        );
        return result;
      } else {
        print('❌ Analysis failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error in analyzeImage: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getAnalysisHistory({
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/history/analyses?limit=$limit'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> history = data['history'] ?? [];

        return history
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Error getting analysis history: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getTrends({int days = 30}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/history/trends?days=$days'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      print('❌ Error getting trends: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getSummary() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/history/summary'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      print('❌ Error getting summary: $e');
      return null;
    }
  }

  // ==================== IRRIGATION ROUTINE ENDPOINTS ====================

  static Future<Map<String, dynamic>?> saveRoutine(
    Map<String, dynamic> routineData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/irrigation/setup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(routineData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 400) {
        // Active routine exists
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Error saving routine: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> terminateRoutine({
    String? reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/irrigation/terminate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'reason': reason ?? 'User terminated'}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Error terminating routine: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getCurrentRoutine() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/irrigation/current'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      print('❌ Error getting routine: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateRoutine(
    Map<String, dynamic> routineData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/irrigation/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(routineData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Error updating routine: $e');
      return null;
    }
  }

  static Future<bool> deleteRoutine() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/irrigation/delete'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error deleting routine: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getRoutineHistory({
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/irrigation/history/routines?limit=$limit'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> history = data['history'] ?? [];
        return history.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error getting routine history: $e');
      return [];
    }
  }

  // ==================== WATERING CONTROL ====================

  static Future<Map<String, dynamic>?> checkWatering() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/irrigation/check'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      print('❌ Error checking watering: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> manualWater({int duration = 5}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/irrigation/water'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'duration': duration}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Error manual water: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> manualOverride({
    required String action,
    bool ignoreAnalysis = false,
    int duration = 5,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/irrigation/manual-override'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': action,
          'ignoreAnalysis': ignoreAnalysis,
          'duration': duration,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 400) {
        // Lockout detected
        return json.decode(response.body);
      } else if (response.statusCode == 503) {
        // Device offline
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Error in manual override: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> overrideIrrigation(String action) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/irrigation/override'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'action': action}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Error overriding irrigation: $e');
      return null;
    }
  }

  // ==================== WATERING HISTORY & STATS ====================

  static Future<List<Map<String, dynamic>>> getWateringHistory({
    int limit = 30,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/irrigation/history?limit=$limit'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> history = data['history'] ?? [];
        return history
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Error getting watering history: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getWateringStats({int days = 30}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/irrigation/stats?days=$days'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Error getting watering stats: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getWateringEventById(
    String eventId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/irrigation/history/$eventId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Error getting watering event: $e');
      return null;
    }
  }

  // ==================== UTILITY METHODS ====================

  static Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Backend connection failed: $e');
      return false;
    }
  }

  static String getBaseUrl() {
    return baseUrl;
  }
}
