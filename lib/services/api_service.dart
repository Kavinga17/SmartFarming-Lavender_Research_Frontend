import 'dart:convert';
import 'dart:async';
import 'dart:html' as html;
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000';

  /// Test backend connection
  static Future<bool> testConnection() async {
    try {
      final response = await html.HttpRequest.request(
        '$baseUrl/health',
        method: 'GET',
      );
      return response.status == 200;
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
      // Create FormData
      final formData = html.FormData();

      // Read file as blob
      final bytes = await image.readAsBytes();
      final blob = html.Blob([bytes], 'image/jpeg');

      // Append file
      formData.appendBlob('image', blob, image.name);

      // Append sensor data with proper encoding
      formData.append('sensorData', jsonEncode(sensorData));

      // Create and configure request
      final request = html.HttpRequest();
      request.open('POST', '$baseUrl/api/analysis');
      request.timeout = 60000; // 60 second timeout

      final completer = Completer<Map<String, dynamic>>();

      request.onLoad.listen((event) {
        print('📥 Response received: ${request.status}');

        if (request.status == 200) {
          try {
            final response = jsonDecode(request.responseText!);
            print('✅ Analysis successful');
            print(
              '📈 Health Score: ${response['dashboardSummary']?['healthScore']}%',
            );
            print(
              '🤝 Cross-verification: ${response['crossVerification']?['matchPercentage']}% match',
            );

            completer.complete(response);
          } catch (e) {
            print('❌ JSON parse error: $e');
            print('Raw response: ${request.responseText}');
            completer.completeError(Exception('JSON parse error: $e'));
          }
        } else {
          print('❌ Server error ${request.status}: ${request.responseText}');
          completer.completeError(
            Exception(
              'Server error ${request.status}: ${request.responseText}',
            ),
          );
        }
      });

      request.onError.listen((event) {
        print('❌ Network error during analysis');
        completer.completeError(Exception('Network error during analysis'));
      });

      // Show timeout warning
      Timer(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          print('⏰ Analysis taking longer than expected...');
        }
      });

      // Send request
      print('🚀 Sending request to backend...');
      request.send(formData);

      return await completer.future;
    } catch (e) {
      print('💥 Unexpected error in analyzePlant: $e');
      rethrow;
    }
  }

  /// Get analysis history (if you implement this endpoint)
  static Future<List<Map<String, dynamic>>> getAnalysisHistory() async {
    try {
      final response = await html.HttpRequest.request(
        '$baseUrl/api/analysis/history',
        method: 'GET',
      );

      if (response.status == 200) {
        final data = jsonDecode(response.responseText!);
        return List<Map<String, dynamic>>.from(data['history'] ?? []);
      }
      return [];
    } catch (e) {
      print('❌ Failed to get history: $e');
      return [];
    }
  }

  /// Get quick analysis summary for dashboard
  static Future<Map<String, dynamic>> getQuickSummary() async {
    try {
      final response = await html.HttpRequest.request(
        '$baseUrl/api/analysis/summary',
        method: 'GET',
      );

      if (response.status == 200) {
        return jsonDecode(response.responseText!);
      }
      return {'status': 'no_data', 'message': 'No analysis data available'};
    } catch (e) {
      print('❌ Failed to get summary: $e');
      return {'status': 'error', 'message': 'Failed to load summary'};
    }
  }
}

/// Helper class to parse the enhanced backend response
class AnalysisResponseParser {
  /// Parse health score from response
  static double parseHealthScore(Map<String, dynamic> response) {
    try {
      // Try to get from dashboardSummary first
      if (response['dashboardSummary']?['healthScore'] != null) {
        return (response['dashboardSummary']['healthScore'] as num).toDouble();
      }

      // Fallback to legacy field
      if (response['finalDiagnosis']?['healthScore'] != null) {
        return (response['finalDiagnosis']['healthScore'] as num).toDouble();
      }

      // Calculate from emergency level if no score provided
      final emergencyLevel =
          response['intelligentDiagnosis']?['emergencyLevel']?['level'] ??
          'low';
      switch (emergencyLevel) {
        case 'high':
          return 40.0;
        case 'medium':
          return 65.0;
        default:
          return 85.0;
      }
    } catch (e) {
      print('⚠️ Failed to parse health score: $e');
      return 87.0; // Default value
    }
  }

  /// Parse cross-verification match percentage
  static double parseMatchPercentage(Map<String, dynamic> response) {
    try {
      if (response['crossVerification']?['matchPercentage'] != null) {
        return (response['crossVerification']['matchPercentage'] as num)
            .toDouble();
      }

      // Calculate from sensor assessment if crossVerification not available
      final sensorIssues =
          response['sensorReadings']?['assessment']?['issues'] ?? [];
      final totalSensors = 7; // moisture, ph, ec, temp, N, P, K
      final issueCount = sensorIssues.length;

      return ((totalSensors - issueCount) / totalSensors * 100).clamp(
        0.0,
        100.0,
      );
    } catch (e) {
      print('⚠️ Failed to parse match percentage: $e');
      return 85.0;
    }
  }

  /// Parse dashboard insights for quick tips
  static Map<String, dynamic> parseDashboardInsights(
    Map<String, dynamic> response,
  ) {
    try {
      return {
        'healthScore': parseHealthScore(response),
        'matchPercentage': parseMatchPercentage(response),
        'emergencyLevel':
            response['intelligentDiagnosis']?['emergencyLevel']?['level'] ??
            'low',
        'verdict': response['intelligentDiagnosis']?['verdict'] ?? 'UNKNOWN',
        'recommendations': response['recommendations']?['priorityOrder'] ?? [],
        'sensorStatus': _parseSensorStatus(response),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('⚠️ Failed to parse dashboard insights: $e');
      return {
        'healthScore': 87.0,
        'matchPercentage': 85.0,
        'emergencyLevel': 'low',
        'verdict': 'Analysis complete',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Parse sensor status from response
  static Map<String, String> _parseSensorStatus(Map<String, dynamic> response) {
    final status = <String, String>{};

    try {
      final sensorData = response['sensorReadings']?['raw'] ?? {};
      final issues = response['sensorReadings']?['assessment']?['issues'] ?? [];

      // Check each sensor
      for (final sensor in [
        'moisture',
        'ph',
        'ec',
        'temperature',
        'nitrogen',
        'phosphorus',
        'potassium',
      ]) {
        final value = sensorData[sensor];
        if (value != null) {
          // Check if this sensor has issues
          final hasIssue = issues.any((issue) => issue['sensor'] == sensor);
          status[sensor] = hasIssue ? 'needs_attention' : 'optimal';
        } else {
          status[sensor] = 'no_data';
        }
      }
    } catch (e) {
      print('⚠️ Failed to parse sensor status: $e');
    }

    return status;
  }
}

/// Mock service for testing when backend is unavailable
class MockApiService {
  static Future<Map<String, dynamic>> analyzePlant({
    required XFile image,
    required Map<String, dynamic> sensorData,
  }) async {
    print('🎭 Using mock analysis service');

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Generate mock response based on sensor data
    final isHealthy =
        sensorData['moisture'] >= 30 &&
        sensorData['moisture'] <= 50 &&
        sensorData['ph'] >= 6.0 &&
        sensorData['ph'] <= 7.5;

    final healthScore = isHealthy
        ? (85.0 + (sensorData['moisture'] - 40).abs() * 0.5)
        : (40.0 + (sensorData['moisture'] - 40).abs() * 0.8);

    return {
      'success': true,
      'mode': 'mock',
      'timestamp': DateTime.now().toIso8601String(),
      'image': image.name,

      'visualAssessment': {
        'cnnPrediction': isHealthy ? 'healthy' : 'nutrient_deficient',
        'confidence': isHealthy ? 0.85 : 0.72,
        'confidencePercentage': isHealthy ? '85.0' : '72.0',
        'message': isHealthy
            ? 'Plant appears healthy'
            : 'Possible nutrient deficiency detected',
      },

      'intelligentDiagnosis': {
        'emergencyLevel': {
          'level': isHealthy ? 'low' : 'medium',
          'color': isHealthy ? 'green' : 'orange',
          'message': isHealthy ? 'MONITOR REGULARLY' : 'ATTENTION NEEDED',
        },
        'verdict': isHealthy
            ? 'PLANT IS HEALTHY'
            : 'NUTRIENT DEFICIENCY SUSPECTED',
        'confidence': isHealthy ? 'high' : 'medium',
        'message': isHealthy
            ? 'Visual and sensor analysis indicate healthy plant'
            : 'Possible nutrient issues detected',
        'requiresImmediateAction': !isHealthy,
      },

      'crossVerification': {
        'matchPercentage': isHealthy ? 92.5 : 67.3,
        'confidence': isHealthy ? 'very_high' : 'medium',
        'overallStatus': isHealthy ? 'confirmed' : 'partial',
        'agreements': isHealthy
            ? ['watering_optimal_confirmed', 'overall_health_correlated']
            : ['nutrient_deficiency_suspected'],
        'conflicts': isHealthy ? [] : ['cnn_sensor_partial_match'],
      },

      'dashboardSummary': {
        'healthScore': healthScore.clamp(0.0, 100.0),
        'emergencyLevel': isHealthy ? 'low' : 'medium',
        'status': isHealthy ? 'optimal' : 'needs_attention',
        'trend': 'stable',
        'lastUpdated': DateTime.now().toIso8601String(),
        'insights': {
          'whatsWorking': isHealthy
              ? 'All systems optimal'
              : 'Plant structure intact',
          'needsAttention': isHealthy
              ? 'None - all systems optimal'
              : 'Nutrient levels, Watering schedule',
          'watchFor': isHealthy
              ? 'Normal growth patterns'
              : 'Leaf color changes, New growth patterns',
          'goal': isHealthy
              ? 'Maintain current health'
              : 'Restore optimal conditions',
        },
        'reminders': [
          {
            'id': 'next_analysis',
            'title': 'Next analysis in 7 days',
            'description': 'Schedule next diagnostic check',
            'priority': 'low',
            'icon': '📅',
          },
        ],
        'sensorStatus': {
          'moisture':
              sensorData['moisture'] >= 30 && sensorData['moisture'] <= 50
              ? 'optimal'
              : 'needs_attention',
          'ph': sensorData['ph'] >= 6.0 && sensorData['ph'] <= 7.5
              ? 'optimal'
              : 'needs_attention',
          'temperature': 'optimal',
          'nutrients': 'balanced',
        },
      },

      'recommendations': {
        'emergencyLevel': isHealthy ? 'low' : 'medium',
        'priorityOrder': isHealthy
            ? []
            : [
                {
                  'step': 1,
                  'action': 'APPLY BALANCED FERTILIZER',
                  'reason': 'Nutrient levels below optimal',
                  'priority': 1,
                  'icon': '🌱',
                },
              ],
        'totalSteps': isHealthy ? 0 : 1,
      },

      'finalDiagnosis': {
        'health': isHealthy ? 'healthy' : 'nutrient_deficient',
        'confidence': isHealthy ? 0.85 : 0.72,
        'message': isHealthy
            ? 'Plant is healthy'
            : 'Nutrient adjustment recommended',
        'healthScore': healthScore.clamp(0.0, 100.0),
      },
    };
  }
}
