import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class IrrigationService {
  static const String _routineKey = 'irrigation_routine';
  static const String _historyKey = 'irrigation_history';

  // Save irrigation routine - using mock data for now
  static Future<bool> saveRoutine(Map<String, dynamic> routineData) async {
    try {
      print('💧 Mock: Saving irrigation routine');

      // Mock response
      final mockResponse = {
        'id': 'routine_123',
        'status': 'active',
        'created': DateTime.now().toIso8601String(),
        'schedule': routineData,
      };

      // Save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_routineKey, json.encode(mockResponse));

      return true;
    } catch (e) {
      print('Error saving routine: $e');
      return false;
    }
  }

  // Check if routine exists
  static Future<bool> hasRoutine() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_routineKey);
    } catch (e) {
      return false;
    }
  }

  // Get current routine - using mock data
  static Future<Map<String, dynamic>?> getCurrentRoutine() async {
    try {
      // Try local storage first
      final prefs = await SharedPreferences.getInstance();
      final String? routineString = prefs.getString(_routineKey);
      if (routineString != null) {
        return json.decode(routineString);
      }

      // Return mock data if nothing in local storage
      print('💧 Mock: Returning default routine');
      return {
        'id': 'routine_default',
        'status': 'active',
        'schedule': {
          'waterPerPlant': 1.5,
          'frequencyDays': 3,
          'nextWatering': 'Tomorrow at 8:00 AM',
          'targetMoistureMin': 40,
          'targetMoistureMax': 60,
        },
      };
    } catch (e) {
      return null;
    }
  }

  // Update routine - using mock
  static Future<bool> updateRoutine(Map<String, dynamic> routineData) async {
    try {
      print('💧 Mock: Updating routine');
      // Just save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_routineKey, json.encode(routineData));
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete routine
  static Future<void> deleteRoutine() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_routineKey);
    print('💧 Mock: Routine deleted');
    // Skip API call: await ApiService.delete('/irrigation/delete');
  }

  // Record watering event - using mock
  static Future<void> recordWatering() async {
    try {
      final now = DateTime.now();
      print('💧 Mock: Recording watering at $now');

      // Skip API call
      // await ApiService.post('/irrigation/water', {
      //   'timestamp': now.toIso8601String(),
      // });

      // Update local history
      final prefs = await SharedPreferences.getInstance();
      final String? historyString = prefs.getString(_historyKey);
      List<dynamic> history = [];

      if (historyString != null) {
        history = json.decode(historyString);
      }

      history.add({'timestamp': now.toIso8601String(), 'type': 'manual'});

      // Keep only last 30 days
      if (history.length > 30) {
        history = history.sublist(history.length - 30);
      }

      await prefs.setString(_historyKey, json.encode(history));
    } catch (e) {
      print('Error recording watering: $e');
    }
  }

  // Get watering history - using mock
  static Future<List<dynamic>> getWateringHistory() async {
    try {
      // Try local storage first
      final prefs = await SharedPreferences.getInstance();
      final String? historyString = prefs.getString(_historyKey);
      if (historyString != null) {
        return json.decode(historyString);
      }

      // Return mock history
      print('💧 Mock: Returning mock history');
      return [
        {
          'timestamp': DateTime.now()
              .subtract(const Duration(days: 2))
              .toIso8601String(),
          'type': 'manual',
        },
        {
          'timestamp': DateTime.now()
              .subtract(const Duration(days: 5))
              .toIso8601String(),
          'type': 'automatic',
        },
        {
          'timestamp': DateTime.now()
              .subtract(const Duration(days: 8))
              .toIso8601String(),
          'type': 'manual',
        },
      ];
    } catch (e) {
      return [];
    }
  }

  // Get next scheduled watering - using mock
  static Future<Map<String, dynamic>?> getNextWatering() async {
    try {
      print('💧 Mock: Returning next watering');
      return {
        'nextWatering': 'Tomorrow at 8:00 AM',
        'estimatedDuration': '15 minutes',
        'waterAmount': '2.5L',
      };
    } catch (e) {
      return null;
    }
  }

  // Manual override - using mock
  static Future<bool> manualOverride(String action) async {
    try {
      print('💧 Mock: Manual override - $action');
      return true;
    } catch (e) {
      return false;
    }
  }

  // Days since last water - using mock
  static Future<int> daysSinceLastWater() async {
    try {
      // Return mock data - 2 days since last watering
      return 2;
    } catch (e) {
      return 999;
    }
  }
}
