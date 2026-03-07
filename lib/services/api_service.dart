import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.4.1:3000'; // Your ESP32 IP

  // GET request
  static Future<dynamic> get(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('GET Error: $e');
      return null;
    }
  }

  // POST request
  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
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
      final url = Uri.parse('$baseUrl/analyze');
      var request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        return json.decode(responseData);
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
