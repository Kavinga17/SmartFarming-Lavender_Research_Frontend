import 'dart:convert';
import 'package:http/http.dart' as http;

class LightingService {

  static Future<void> updateLighting(int red, int blue, int white) async {

    final url = Uri.parse("http://YOUR_BACKEND_IP:5000/lighting");

    await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "red": red,
        "blue": blue,
        "white": white
      }),
    );
  }
}
