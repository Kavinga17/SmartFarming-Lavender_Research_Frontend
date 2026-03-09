// lib/services/soil_backend_service.dart
//
// Unified soil service:
// - ML analysis via Flask API  (POST /soil/analyze on the unified server)
// - Sensor data from Flask /sensors  (air humidity as moisture reference)
// - Firestore for analyses, routines, watering history
// - Decision engine & irrigation logic in Dart

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SoilBackendService {
  // ── Flask API Server Configuration ──
  // UPDATE this to the IP of the machine running app.py (port 5000)
  static String serverIp = '192.168.0.200';
  static int serverPort = 5000;
  static String get _serverUrl => 'http://$serverIp:$serverPort';

  static const int _timeout = 10; // seconds for normal calls
  static const int _analysisTimeout = 30; // seconds for ML analysis

  // ── Firestore references ──
  static final _firestore = FirebaseFirestore.instance;
  static final _analysesCol = _firestore.collection('analyses');
  static final _routinesCol = _firestore.collection('irrigation_routines');
  static final _wateringCol = _firestore.collection('watering_history');

  // ── Firebase Storage ──
  static final _storage = FirebaseStorage.instance;

  // =====================================================================
  //  CONNECTION / HEALTH
  // =====================================================================

  /// Check if the Flask server is running and the soil ML models are loaded.
  static Future<bool> testConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$_serverUrl/health'))
          .timeout(Duration(seconds: _timeout));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final soilStatus = data['soil_detection'] ?? {};
        return soilStatus['expert_model_loaded'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // =====================================================================
  //  MOISTURE  (from Flask /sensors — ambient humidity as reference)
  // =====================================================================

  /// Read ambient humidity from the Flask server's climate sensors.
  /// The unified server exposes GET /sensors → {air_temp, humidity, soil_temp}.
  /// Returns the humidity value (0-100) or null if the server is unreachable.
  static Future<double?> getMoisture() async {
    try {
      final response = await http
          .get(Uri.parse('$_serverUrl/sensors'))
          .timeout(Duration(seconds: _timeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final h = data['humidity'];
        return (h is num) ? h.toDouble() : null;
      }
      return null;
    } catch (e) {
      print('⚠️ Sensor data unavailable: $e');
      return null;
    }
  }

  // =====================================================================
  //  IMAGE ANALYSIS  (Flask /soil/analyze + Decision Engine + Firestore)
  // =====================================================================

  /// Analyse a plant image using the Flask ML server.
  ///
  /// Flow:
  /// 1. Read image and encode as base64
  /// 2. POST to Flask /soil/analyze → get threeClass + yellowMeter predictions
  /// 3. Upload image to Firebase Storage (record-keeping)
  /// 4. Read current moisture from ESP32
  /// 5. Run local decision engine with ML results + sensor data
  /// 6. Save complete analysis to Firestore
  /// 7. Return full result map for the UI
  static Future<Map<String, dynamic>?> analyzeImage(XFile image) async {
    try {
      // 1 — Read image and encode as base64
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // 2 — POST to Flask /soil/analyze
      final apiResponse = await http
          .post(
            Uri.parse('$_serverUrl/soil/analyze'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'image_base64': base64Image}),
          )
          .timeout(Duration(seconds: _analysisTimeout));

      if (apiResponse.statusCode != 200) {
        print('❌ Flask /soil/analyze error: ${apiResponse.statusCode}');
        print('   Body: ${apiResponse.body}');
        return null;
      }

      final mlResult = jsonDecode(apiResponse.body) as Map<String, dynamic>;
      if (mlResult['success'] != true) {
        print('❌ Flask analysis failed: ${mlResult['error']}');
        return null;
      }

      // 3 — Upload image to Firebase Storage for record-keeping
      String? imageUrl;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      try {
        final ref = _storage.ref().child('soil_analyses/$fileName');
        await ref.putData(bytes);
        imageUrl = await ref.getDownloadURL();
      } catch (e) {
        print('⚠️ Firebase Storage upload failed (continuing): $e');
      }

      // 4 — Read moisture from ESP32
      double? moisture;
      try {
        moisture = await getMoisture();
      } catch (_) {}

      // 5 — Extract ML predictions
      final threeClass =
          (mlResult['threeClass'] as Map<String, dynamic>?) ?? {};
      final yellowMeter = mlResult['yellowMeter'] as Map<String, dynamic>?;

      final expertPrediction =
          threeClass['prediction']?.toString() ?? 'unknown';
      final yellowness =
          (yellowMeter?['yellowness'] as num?)?.toDouble() ?? 0.0;

      // 6 — Run local decision engine
      // Estimate days since last water from watering history
      int daysSinceLastWater = 7; // default
      try {
        final waterHistory = await getWateringHistory(limit: 1);
        if (waterHistory.isNotEmpty) {
          final lastTs = waterHistory.first['timestamp'];
          if (lastTs is String) {
            final lastDate = DateTime.tryParse(lastTs);
            if (lastDate != null) {
              daysSinceLastWater =
                  DateTime.now().difference(lastDate).inDays;
            }
          }
        }
      } catch (_) {}

      final decision = diagnose(
        expertPrediction,
        yellowness,
        moisture ?? 50.0,
        daysSinceLastWater,
      );

      // 7 — Build full result
      final timestamp = DateTime.now().toUtc().toIso8601String();
      final result = <String, dynamic>{
        'success': true,
        'timestamp': timestamp,
        'image': fileName,
        'imageUrl': imageUrl,
        'moisture': moisture,
        'threeClass': threeClass,
        'yellowMeter': yellowMeter,
        ...decision,
      };

      // 8 — If diagnosis requires terminating irrigation, do it
      if (decision['terminateRoutine'] == true) {
        try {
          await terminateRoutine(
            reason: 'Auto-terminated: ${decision['diagnosis']}',
          );
        } catch (_) {}
      }

      // 9 — Save to Firestore
      try {
        final docRef = await _analysesCol.add({
          ...result,
          'createdAt': FieldValue.serverTimestamp(),
        });
        result['id'] = docRef.id;
      } catch (e) {
        print('⚠️ Firestore save failed (returning result anyway): $e');
      }

      return result;
    } catch (e) {
      print('❌ analyzeImage error: $e');
      return null;
    }
  }

  // =====================================================================
  //  ANALYSIS HISTORY  (Firestore)
  // =====================================================================

  static Future<List<Map<String, dynamic>>> getAnalysisHistory({
    int limit = 10,
  }) async {
    try {
      final snap = await _analysesCol
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snap.docs.map((doc) {
        final data = doc.data();
        // Convert Timestamps to ISO strings for the UI
        _convertTimestamps(data);
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      print('❌ getAnalysisHistory error: $e');
      return [];
    }
  }

  // =====================================================================
  //  WATERING HISTORY  (Firestore)
  // =====================================================================

  static Future<List<Map<String, dynamic>>> getWateringHistory({
    int limit = 10,
  }) async {
    try {
      final snap = await _wateringCol
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snap.docs.map((doc) {
        final data = doc.data();
        _convertTimestamps(data);
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      print('❌ getWateringHistory error: $e');
      return [];
    }
  }

  // =====================================================================
  //  IRRIGATION ROUTINE  (Firestore — single active routine)
  // =====================================================================

  /// Get the currently active irrigation routine, or null.
  static Future<Map<String, dynamic>?> getCurrentRoutine() async {
    try {
      final snap = await _routinesCol.limit(1).get();
      if (snap.docs.isEmpty) return null;

      final doc = snap.docs.first;
      final data = doc.data();
      _convertTimestamps(data);
      return {'id': doc.id, ...data};
    } catch (e) {
      print('❌ getCurrentRoutine error: $e');
      return null;
    }
  }

  /// Save a new irrigation routine.
  ///
  /// Returns `{success: true, ...}` on success.
  /// Returns `{error: 'Active routine exists', existingRoutine: {...}}` if one
  /// already exists.
  static Future<Map<String, dynamic>?> saveRoutine(
    Map<String, dynamic> routineData,
  ) async {
    try {
      // Check for existing routine
      final existing = await _routinesCol.limit(1).get();
      if (existing.docs.isNotEmpty) {
        final doc = existing.docs.first;
        final data = doc.data();
        _convertTimestamps(data);
        return {
          'error': 'Active routine exists',
          'message':
              'Please terminate the current routine before setting a new one',
          'existingRoutine': {'id': doc.id, ...data},
        };
      }

      // Calculate schedule using ported irrigation logic
      final schedule = _calculateSchedule(
        routineData['plantCount'] ?? 1,
        routineData['soilType'] ?? 'Loamy',
        (routineData['area'] ?? 0).toDouble(),
      );

      final toSave = {
        ...routineData,
        'schedule': schedule,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _routinesCol.add(toSave);

      // Record creation event
      await _wateringCol.add({
        'type': 'routine_created',
        'routineId': docRef.id,
        'details': routineData,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'routineId': docRef.id, 'schedule': schedule};
    } catch (e) {
      print('❌ saveRoutine error: $e');
      return null;
    }
  }

  /// Terminate the active irrigation routine.
  static Future<Map<String, dynamic>?> terminateRoutine({
    String? reason,
  }) async {
    try {
      final snap = await _routinesCol.limit(1).get();
      if (snap.docs.isEmpty) {
        return {'error': 'No active routine to terminate'};
      }

      final doc = snap.docs.first;
      final routineData = doc.data();

      // Record termination event
      await _wateringCol.add({
        'type': 'routine_terminated',
        'routineId': doc.id,
        'details': routineData,
        'reason': reason ?? 'User terminated',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Delete the routine document
      await doc.reference.delete();

      return {'success': true, 'message': 'Routine terminated successfully'};
    } catch (e) {
      print('❌ terminateRoutine error: $e');
      return null;
    }
  }

  // =====================================================================
  //  IRRIGATION LOGIC  (ported from irrigationLogic.js)
  // =====================================================================

  /// Calculate an irrigation schedule based on plant count, soil type & area.
  static Map<String, dynamic> _calculateSchedule(
    int plantCount,
    String soilType,
    double area,
  ) {
    // Base litres per plant for lavender
    double baseWaterPerPlant;
    switch (soilType.toLowerCase()) {
      case 'sandy':
        baseWaterPerPlant = 2.0;
        break;
      case 'clay':
        baseWaterPerPlant = 1.0;
        break;
      case 'loamy':
      default:
        baseWaterPerPlant = 1.5;
    }

    final totalWater = baseWaterPerPlant * plantCount;
    final frequencyDays = soilType.toLowerCase() == 'clay' ? 10 : 7;

    final nextDate = DateTime.now().add(Duration(days: frequencyDays));

    return {
      'waterPerPlant': baseWaterPerPlant,
      'totalWater': (totalWater * 10).round() / 10,
      'frequencyDays': frequencyDays,
      'nextWatering': nextDate.toUtc().toIso8601String(),
      'durationMinutes': (totalWater / 10 * 60).ceil(),
      'targetMoistureMin': 30,
      'targetMoistureMax': 50,
      'scientificNote':
          'Lavender prefers drier soil. Water only when soil is dry to touch.',
    };
  }

  // =====================================================================
  //  DECISION ENGINE  (ported from decisionEngine.js)
  // =====================================================================

  /// Diagnose plant status given model prediction, yellowness, moisture &
  /// days since last watering.
  static Map<String, dynamic> diagnose(
    String expertPrediction,
    double yellowness,
    double moisture,
    int daysSinceLastWater,
  ) {
    // Healthy
    if (expertPrediction == 'healthy') {
      return {
        'diagnosis': 'HEALTHY',
        'action': 'Continue normal care',
        'severity': 'low',
        'requiresAction': false,
        'terminateRoutine': false,
      };
    }

    // Diseased
    if (expertPrediction == 'diseased') {
      return {
        'diagnosis': 'DISEASE_DETECTED',
        'action': 'Pause routine and inspect plant',
        'severity': 'high',
        'requiresAction': true,
        'terminateRoutine': true,
        'userPrompt':
            'Disease detected. Please inspect manually and decide next steps.',
      };
    }

    // Nutrient deficient — check yellowness + moisture
    if (expertPrediction == 'nutrient_deficient') {
      if (yellowness > 60 && moisture > 70) {
        return {
          'diagnosis': 'NITROGEN_LOCKOUT',
          'action':
              'STOP WATERING immediately. Let soil dry for 3-5 days.',
          'severity': 'high',
          'requiresAction': true,
          'terminateRoutine': true,
          'recommendation':
              'Soil too wet, roots cannot absorb nitrogen',
        };
      }

      if (yellowness > 50 && moisture < 30) {
        return {
          'diagnosis': 'UNDERWATERING',
          'action': 'Increase watering frequency. Soil too dry.',
          'severity': 'high',
          'requiresAction': true,
          'terminateRoutine': false,
          'recommendation': 'Plant stressed from lack of water',
        };
      }

      if (yellowness > 50 && moisture >= 30 && moisture <= 70) {
        return {
          'diagnosis': 'NITROGEN_DEFICIENCY',
          'action': 'Add nitrogen fertilizer to next watering.',
          'severity': 'medium',
          'requiresAction': true,
          'terminateRoutine': false,
          'recommendation': 'Normal moisture but plant is yellow',
        };
      }

      if (yellowness > 30 && yellowness <= 50) {
        return {
          'diagnosis': 'MILD_CHLOROSIS',
          'action': 'Monitor closely. Check again in 3 days.',
          'severity': 'low',
          'requiresAction': false,
          'terminateRoutine': false,
          'recommendation': 'Early signs of stress',
        };
      }
    }

    // Fallback
    return {
      'diagnosis': 'UNKNOWN_ISSUE',
      'action': 'Manual inspection required',
      'severity': 'medium',
      'requiresAction': true,
      'terminateRoutine': true,
      'userPrompt':
          'Unable to determine issue. Please inspect plant manually.',
    };
  }

  // =====================================================================
  //  HELPERS
  // =====================================================================

  /// Recursively convert Firestore [Timestamp] values to ISO-8601 strings
  /// so the UI can safely use them.
  static void _convertTimestamps(Map<String, dynamic> data) {
    for (final key in data.keys.toList()) {
      final value = data[key];
      if (value is Timestamp) {
        data[key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        _convertTimestamps(value);
      }
    }
  }
}
