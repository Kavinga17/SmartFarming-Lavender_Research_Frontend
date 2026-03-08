import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.4.1:3000'; // Your ESP32 IP

  // GET request
  static Future<dynamic> get(String endpoint) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('🔌 Connection test failed: $e');
      return false;
    }
  }

  /// Main plant analysis with enhanced cross-verification
  static Future<Map<String, dynamic>> analyzePlant({
    required XFile image,
    required Map<String, dynamic> sensorData,
  }) async {
    print('🎯 Starting plant analysis...');
    print('📊 Sensor data: $sensorData');
    print('📸 Image: ${image.name} (${(await image.length()) / 1024}KB)');

    try {
      final bytes = await image.readAsBytes();

      // Build multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/analysis'),
      );

      // Attach image
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: image.name,
      ));

      // Attach sensor data as JSON string
      request.fields['sensorData'] = jsonEncode(sensorData);

      print('🚀 Sending request to backend...');

      final streamedResponse = await request
          .send()
          .timeout(const Duration(seconds: 60));

      final responseBody = await streamedResponse.stream.bytesToString();

      print('📥 Response received: ${streamedResponse.statusCode}');

      if (streamedResponse.statusCode == 200) {
        try {
          final response = jsonDecode(responseBody);
          print('✅ Analysis successful');
          print(
            '📈 Health Score: ${response['dashboardSummary']?['healthScore']}%',
          );
          print(
            '🤝 Cross-verification: ${response['crossVerification']?['matchPercentage']}% match',
          );
          return response;
        } catch (e) {
          print('❌ JSON parse error: $e');
          print('Raw response: $responseBody');
          throw Exception('JSON parse error: $e');
        }
      } else {
        print('❌ Server error ${streamedResponse.statusCode}: $responseBody');
        throw Exception(
          'Server error ${streamedResponse.statusCode}: $responseBody',
        );
      }
    } catch (e) {
      print('💥 Unexpected error in analyzePlant: $e');
      rethrow;
    }
  }

  /// Get analysis history (if you implement this endpoint)
  static Future<List<Map<String, dynamic>>> getAnalysisHistory() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/analysis/history'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['history'] ?? []);
      }
      return null;
    } catch (e) {
      print('POST Error: $e');
      return null;
    }
  }

  // Upload image
  static Future<Map<String, dynamic>?> uploadImage(File image) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/analysis/summary'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Upload Error: $e');
      return null;
    }
  }

  // Your soil health methods here...
  static Future<Map<String, dynamic>> getLatestSensorData() async {
    // Implementation using http.get
    final data = await get('/sensors/latest');
    return {
      'moisture': (data?['moisture'] ?? 45).toDouble(),
      'temperature': (data?['temperature'] ?? 24).toDouble(),
    };
  }
}
