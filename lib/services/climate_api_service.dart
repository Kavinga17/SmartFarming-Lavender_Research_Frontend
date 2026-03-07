import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

/// Service for communicating with the Greenhouse Climate Control API.
/// This handles fan speed predictions and humidifier mode predictions.
class ClimateApiService {
  // ── UPDATE THIS to your Flask server's IP address ──
  // e.g., 'http://192.168.1.100:5000'
  static String baseUrl = 'http://192.168.0.100:5000';

  /// Check if the climate control server is reachable and models are loaded.
  /// Returns true if the server is healthy and models are ready.
  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Support both old format {"models_loaded": true} and
        // unified format {"status": "healthy", "climate_control": {"models_loaded": true}}
        if (data['models_loaded'] == true) return true;
        if (data['status'] == 'healthy') return true;
        if (data['climate_control']?['models_loaded'] == true) return true;
        return false;
      }
      return false;
    } catch (e) {
      print('🔌 Climate API health check failed: $e');
      return false;
    }
  }

  /// Get API information from the root endpoint.
  static Future<Map<String, dynamic>?> getApiInfo() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Failed to get climate API info: $e');
      return null;
    }
  }

  /// Fetch the latest sensor readings from the backend.
  /// The backend stores values each time the ESP32 calls /predict.
  /// Returns a map with air_temp, humidity, soil_temp, or null if unavailable.
  static Future<Map<String, double>?> fetchSensors() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/sensors'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'air_temp': (data['air_temp'] as num?)?.toDouble() ?? 0.0,
          'humidity': (data['humidity'] as num?)?.toDouble() ?? 0.0,
          'soil_temp': (data['soil_temp'] as num?)?.toDouble() ?? 0.0,
        };
      }
      return null;
    } catch (e) {
      print('📡 Sensor fetch failed: $e');
      return null;
    }
  }

  /// Send sensor data and get AI-predicted fan speed & humidifier mode.
  ///
  /// Returns a [ClimatePrediction] on success, or null on failure.
  static Future<ClimatePrediction?> predict({
    required double airTemp,
    required double humidity,
    required double soilTemp,
    required double targetTemp,
    required double targetHumidity,
    required double prevFanSpeed,
    required double prevHumidifierMode,
  }) async {
    try {
      final body = {
        'air_temp': airTemp,
        'humidity': humidity,
        'soil_temp': soilTemp,
        'target_temp': targetTemp,
        'target_humidity': targetHumidity,
        'prev_fan_speed': prevFanSpeed,
        'prev_humidifier_mode': prevHumidifierMode,
      };

      print('🌡️ Sending prediction request: $body');

      final response = await http
          .post(
            Uri.parse('$baseUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Prediction: fan_speed=${data['fan_speed']}, humidifier_mode=${data['humidifier_mode']}');
        print('   Response keys: ${data.keys.toList()}');
        return ClimatePrediction.fromJson(
          data,
          inputAirTemp: airTemp,
          inputHumidity: humidity,
          inputSoilTemp: soilTemp,
        );
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        print('⚠️ Bad request: ${error['error']}');
        if (error['missing'] != null) {
          print('   Missing fields: ${error['missing']}');
        }
        return null;
      } else {
        print('❌ Server error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('💥 Prediction request failed: $e');
      return null;
    }
  }

  /// Convert humidifier mode integer to display label.
  static String humidifierModeLabel(int mode) {
    switch (mode) {
      case 0:
        return 'Off';
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      default:
        return 'Unknown';
    }
  }

  /// Convert fan speed (0-100) to a fan level (1-4) for the venting dial.
  static int fanSpeedToLevel(double fanSpeed) {
    if (fanSpeed <= 0) return 1;
    if (fanSpeed <= 25) return 1;
    if (fanSpeed <= 50) return 2;
    if (fanSpeed <= 75) return 3;
    return 4;
  }

  /// Convert fan level (1-4) back to approximate fan speed (0-100).
  static double fanLevelToSpeed(int level) {
    switch (level) {
      case 1:
        return 12.5;
      case 2:
        return 37.5;
      case 3:
        return 62.5;
      case 4:
        return 87.5;
      default:
        return 50.0;
    }
  }

  // ── Fan Control Endpoints ──

  /// Set the fan operating mode: "off", "manual", or "auto".
  static Future<Map<String, dynamic>?> setFanMode(String mode) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/fan/mode'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'mode': mode}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔧 Fan mode set to: $mode → $data');
        return data;
      } else {
        final error = jsonDecode(response.body);
        print('⚠️ Set fan mode failed: ${error['error']}');
        return null;
      }
    } catch (e) {
      print('💥 Set fan mode request failed: $e');
      return null;
    }
  }

  /// Set manual fan control: on/off and speed (1-100).
  /// Only works when fan mode is "manual".
  static Future<Map<String, dynamic>?> setFanManual({
    bool? on,
    int? speed,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (on != null) body['on'] = on;
      if (speed != null) body['speed'] = speed;

      final response = await http
          .post(
            Uri.parse('$baseUrl/fan/manual'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔧 Fan manual set: $body → $data');
        return data;
      } else {
        final error = jsonDecode(response.body);
        print('⚠️ Set fan manual failed: ${error['error']}');
        return null;
      }
    } catch (e) {
      print('💥 Set fan manual request failed: $e');
      return null;
    }
  }

  /// Get the current fan state: mode, manual_on, manual_speed.
  static Future<FanState?> getFanState() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/fan/state'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FanState.fromJson(data);
      }
      return null;
    } catch (e) {
      print('📡 Fan state fetch failed: $e');
      return null;
    }
  }

  /// Convert fan mode string to a display label.
  static String fanModeLabel(String mode) {
    switch (mode) {
      case 'off':
        return 'Off';
      case 'manual':
        return 'Manual';
      case 'auto':
        return 'Auto';
      default:
        return 'Unknown';
    }
  }

  // ── Humidifier Control Endpoints ──

  /// Set the humidifier operating mode: "off", "manual", or "auto".
  static Future<Map<String, dynamic>?> setHumidifierMode(String mode) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/humidifier/mode'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'mode': mode}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔧 Humidifier mode set to: $mode → $data');
        return data;
      } else {
        final error = jsonDecode(response.body);
        print('⚠️ Set humidifier mode failed: ${error['error']}');
        return null;
      }
    } catch (e) {
      print('💥 Set humidifier mode request failed: $e');
      return null;
    }
  }

  /// Set manual humidifier level (only effective when mode = "manual").
  /// level: 0=off, 1=low, 2=medium, 3=high
  static Future<Map<String, dynamic>?> setHumidifierManual({required int level}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/humidifier/manual'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'level': level}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔧 Humidifier manual level set: $level → $data');
        return data;
      } else {
        final error = jsonDecode(response.body);
        print('⚠️ Set humidifier manual failed: ${error['error']}');
        return null;
      }
    } catch (e) {
      print('💥 Set humidifier manual request failed: $e');
      return null;
    }
  }

  /// Get the current humidifier state: mode, manual_level.
  static Future<HumidifierState?> getHumidifierState() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/humidifier/state'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return HumidifierState.fromJson(data);
      }
      return null;
    } catch (e) {
      print('📡 Humidifier state fetch failed: $e');
      return null;
    }
  }
}

/// Represents the current fan control state from GET /fan/state.
class FanState {
  final String mode;       // "off", "manual", "auto"
  final bool manualOn;     // Whether fan is on in manual mode
  final int manualSpeed;   // Speed 0-100 in manual mode

  FanState({
    required this.mode,
    required this.manualOn,
    required this.manualSpeed,
  });

  factory FanState.fromJson(Map<String, dynamic> json) {
    return FanState(
      mode: json['mode'] as String? ?? 'auto',
      manualOn: json['manual_on'] as bool? ?? false,
      manualSpeed: (json['manual_speed'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Represents the current humidifier control state from GET /humidifier/state.
class HumidifierState {
  final String mode;       // "off", "manual", "auto"
  final int manualLevel;   // 0=off, 1=low, 2=medium, 3=high

  HumidifierState({
    required this.mode,
    required this.manualLevel,
  });

  factory HumidifierState.fromJson(Map<String, dynamic> json) {
    return HumidifierState(
      mode: json['mode'] as String? ?? 'auto',
      manualLevel: (json['manual_level'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Model for the prediction response from POST /predict.
/// The API returns sensor readings alongside the AI prediction.
class ClimatePrediction {
  final double fanSpeed;              // AI predicted fan speed 0-100
  final double effectiveFanSpeed;     // Actual fan speed sent to Arduino (respects mode)
  final String fanMode;               // Current fan mode: "off", "manual", "auto"
  final int humidifierMode;           // AI predicted mode 0-3 (Off/Low/Medium/High)
  final int effectiveHumidifierLevel; // Actual humidifier level sent to Arduino (respects mode)
  final String humidifierControlMode; // Current humidifier mode: "off", "manual", "auto"
  final double airTemp;               // Current greenhouse air temperature (°C)
  final double humidity;              // Current humidity (%)
  final double soilTemp;              // Current soil temperature (°C)

  ClimatePrediction({
    required this.fanSpeed,
    required this.effectiveFanSpeed,
    required this.fanMode,
    required this.humidifierMode,
    required this.effectiveHumidifierLevel,
    required this.humidifierControlMode,
    required this.airTemp,
    required this.humidity,
    required this.soilTemp,
  });

  /// Parse from API response JSON.
  /// [inputAirTemp], [inputHumidity], [inputSoilTemp] are the values we SENT
  /// to the API — used as fallback when the backend does not echo them back.
  factory ClimatePrediction.fromJson(
    Map<String, dynamic> json, {
    double inputAirTemp = 0.0,
    double inputHumidity = 0.0,
    double inputSoilTemp = 0.0,
  }) {
    final aiSpeed = (json['fan_speed'] as num).toDouble();
    final aiHumMode = (json['humidifier_mode'] as num).toInt();
    return ClimatePrediction(
      fanSpeed: aiSpeed,
      effectiveFanSpeed: (json['effective_fan_speed'] as num?)?.toDouble() ?? aiSpeed,
      fanMode: json['fan_mode'] as String? ?? 'auto',
      humidifierMode: aiHumMode,
      effectiveHumidifierLevel: (json['effective_humidifier_level'] as num?)?.toInt() ?? aiHumMode,
      humidifierControlMode: json['humidifier_control_mode'] as String? ?? 'auto',
      airTemp: (json['air_temp'] as num?)?.toDouble() ?? inputAirTemp,
      humidity: (json['humidity'] as num?)?.toDouble() ?? inputHumidity,
      soilTemp: (json['soil_temp'] as num?)?.toDouble() ?? inputSoilTemp,
    );
  }

  /// Convert to a Map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'fan_speed': fanSpeed,
      'effective_fan_speed': effectiveFanSpeed,
      'fan_mode': fanMode,
      'fan_level': fanLevel,
      'humidifier_mode': humidifierMode,
      'effective_humidifier_level': effectiveHumidifierLevel,
      'humidifier_control_mode': humidifierControlMode,
      'humidifier_label': humidifierLabel,
      'air_temp': airTemp,
      'humidity': humidity,
      'soil_temp': soilTemp,
    };
  }

  /// Fan level 1-4 derived from fan speed.
  int get fanLevel => ClimateApiService.fanSpeedToLevel(fanSpeed);

  /// Humidifier effective label (Off/Low/Medium/High) based on the actual level sent to Arduino.
  String get humidifierLabel =>
      ClimateApiService.humidifierModeLabel(effectiveHumidifierLevel);

  /// Humidifier AI prediction label.
  String get humidifierAiLabel =>
      ClimateApiService.humidifierModeLabel(humidifierMode);
}
