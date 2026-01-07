// lib/services/diagnostic_history.dart
import 'package:shared_preferences/shared_preferences.dart';

class DiagnosticHistory {
  static double _currentHealth = 87.0;
  static Map<String, dynamic>? _lastResult;
  static Map<String, dynamic>? _lastDashboardSummary;
  static DateTime? _lastUpdateTime;

  static double get currentHealth => _currentHealth;
  static Map<String, dynamic>? get lastResult => _lastResult;
  static Map<String, dynamic>? get lastDashboardSummary =>
      _lastDashboardSummary;
  static DateTime? get lastUpdateTime => _lastUpdateTime;

  static Future<void> saveResult(Map<String, dynamic> result) async {
    _lastResult = result;
    _lastUpdateTime = DateTime.now();

    // Update health score from dashboard summary
    if (result['dashboardSummary']?['healthScore'] != null) {
      _currentHealth = result['dashboardSummary']['healthScore'].toDouble();
    }

    // Save dashboard summary for quick tips
    _lastDashboardSummary = result['dashboardSummary'];

    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('currentHealth', _currentHealth);
    await prefs.setString('lastUpdateTime', _lastUpdateTime!.toIso8601String());

    // Save result as JSON string
    await prefs.setString('lastResult', _mapToJsonString(result));
    await prefs.setString(
      'lastDashboardSummary',
      _mapToJsonString(_lastDashboardSummary ?? {}),
    );
  }

  static Future<Map<String, dynamic>?> getLastResult() async {
    if (_lastResult != null) return _lastResult;

    final prefs = await SharedPreferences.getInstance();
    final health = prefs.getDouble('currentHealth');
    final timeString = prefs.getString('lastUpdateTime');
    final resultString = prefs.getString('lastResult');
    final summaryString = prefs.getString('lastDashboardSummary');

    if (health != null) {
      _currentHealth = health;
    }

    if (timeString != null) {
      _lastUpdateTime = DateTime.parse(timeString);
    }

    if (resultString != null) {
      _lastResult = _jsonStringToMap(resultString);
    }

    if (summaryString != null) {
      _lastDashboardSummary = _jsonStringToMap(summaryString);
    }

    return _lastResult;
  }

  static String _mapToJsonString(Map<String, dynamic> map) {
    // Simple serialization for demo - in production use proper JSON encoding
    return map.toString();
  }

  static Map<String, dynamic> _jsonStringToMap(String jsonString) {
    // Simple deserialization for demo - in production use proper JSON decoding
    try {
      // This is a simplified version - you should use proper JSON parsing
      return {'raw': jsonString};
    } catch (e) {
      return {};
    }
  }

  static Future<void> clearHistory() async {
    _currentHealth = 87.0;
    _lastResult = null;
    _lastDashboardSummary = null;
    _lastUpdateTime = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentHealth');
    await prefs.remove('lastUpdateTime');
    await prefs.remove('lastResult');
    await prefs.remove('lastDashboardSummary');
  }
}
