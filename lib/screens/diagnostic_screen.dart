import 'package:flutter/material.dart';
import '../services/diagnostic_history.dart';

class DiagnosticScreen extends StatefulWidget {
  final Map<String, dynamic> analysisResult;
  final Map<String, dynamic> sensorData;

  const DiagnosticScreen({
    super.key,
    required this.analysisResult,
    required this.sensorData,
  });

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  // Color Palette matching your screenshots
  static const Color primaryColor = Color(0xFF8A4FFF); // Lavender Purple
  static const Color dangerColor = Color(0xFFE74C3C); // Red
  static const Color warningColor = Color(0xFFFFA726); // Amber
  static const Color successColor = Color(0xFF2ECC71); // Green
  static const Color infoColor = Color(0xFF3498DB); // Blue
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF2C3E50);
  static const Color lightTextColor = Color(0xFF95A5A6);

  // Helper to safely get data from API response
  dynamic _getFromResult(String key, [dynamic defaultValue]) {
    try {
      // Navigate through nested structure
      final parts = key.split('.');
      dynamic current = widget.analysisResult;

      for (final part in parts) {
        if (current is Map && current.containsKey(part)) {
          current = current[part];
        } else {
          return defaultValue;
        }
      }
      return current;
    } catch (e) {
      return defaultValue;
    }
  }

  // Get dashboard summary data
  Map<String, dynamic> get _dashboardSummary {
    return _getFromResult('dashboardSummary', {});
  }

  // Get cross-verification data
  Map<String, dynamic> get _crossVerification {
    return _getFromResult('crossVerification', {});
  }

  // Get intelligent diagnosis
  Map<String, dynamic> get _intelligentDiagnosis {
    return _getFromResult('intelligentDiagnosis', {});
  }

  // Get visual assessment
  Map<String, dynamic> get _visualAssessment {
    return _getFromResult('visualAssessment', {});
  }

  // Get sensor readings
  Map<String, dynamic> get _sensorReadings {
    return _getFromResult('sensorReadings', {});
  }

  // Get recommendations
  List<dynamic> get _recommendations {
    final recs = _getFromResult('recommendations.priorityOrder', []);
    if (recs is List) return recs;
    return [];
  }

  // Parse issues from backend response
  List<Map<String, dynamic>> get _parsedIssues {
    final issues = <Map<String, dynamic>>[];

    // Check cross-verification conflicts
    final conflicts = _crossVerification['conflicts'] ?? [];
    if (conflicts is List) {
      for (final conflict in conflicts) {
        if (conflict is Map) {
          issues.add({
            'title': 'DATA CONFLICT',
            'severity': 'MEDIUM',
            'description':
                conflict['message'] ??
                'Conflicting data between CNN and sensors',
            'detectedBy': 'Cross-verification',
          });
        }
      }
    }

    // Check sensor issues
    final sensorIssues = _sensorReadings['assessment']?['issues'] ?? [];
    if (sensorIssues is List) {
      for (final issue in sensorIssues) {
        if (issue is Map) {
          final sensor = issue['sensor']?.toString() ?? 'Unknown';
          final value = issue['value']?.toString() ?? 'N/A';
          final optimalRange = issue['optimalRange']?.toString() ?? 'N/A';

          issues.add({
            'title': '${sensor.toUpperCase()} ISSUE',
            'severity': issue['severity'] == 'high' ? 'HIGH' : 'MEDIUM',
            'currentValue': '$value${issue['unit'] ?? ''}',
            'optimalRange': optimalRange,
            'detectedBy': 'Sensor',
          });
        }
      }
    }

    // Check emergency level
    final emergencyLevel =
        _intelligentDiagnosis['emergencyLevel']?['level'] ?? 'low';
    if (emergencyLevel == 'high' && issues.isEmpty) {
      issues.add({
        'title': 'HIGH PRIORITY ALERT',
        'severity': 'HIGH',
        'description': 'Immediate action required based on analysis',
        'detectedBy': 'Intelligent Diagnosis',
      });
    }

    return issues;
  }

  // Get action plan from recommendations
  List<Map<String, dynamic>> get _actionPlan {
    final plan = <Map<String, dynamic>>[];
    final recommendations = _recommendations;

    for (var i = 0; i < recommendations.length; i++) {
      final rec = recommendations[i];
      if (rec is Map<String, dynamic>) {
        // Be more specific
        final iconString = rec['icon']?.toString() ?? '🌱';

        plan.add({
          'priority': i + 1,
          'title': rec['action']?.toString() ?? 'Unknown Action',
          'description': rec['reason']?.toString() ?? '',
          'severity': _getRecommendationSeverity(rec),
          'icon': iconString,
        });
      } else {
        // Handle non-Map items if needed
        print('⚠️ Non-Map recommendation at index $i: $rec');
      }
    }

    // If no recommendations, show healthy maintenance
    if (plan.isEmpty) {
      final isHealthy =
          _intelligentDiagnosis['verdict']?.toString().contains('HEALTHY') ??
          false;
      plan.add({
        'priority': 1,
        'title': isHealthy
            ? 'Continue current care routine'
            : 'Monitor plant closely',
        'description': isHealthy
            ? 'Plant is healthy - maintain current practices'
            : 'No specific actions required at this time',
        'severity': 'LOW',
        'icon': '✅',
      });
    }

    return plan;
  }

  String _getRecommendationSeverity(Map<String, dynamic> recommendation) {
    final emergencyLevel =
        _intelligentDiagnosis['emergencyLevel']?['level'] ?? 'low';
    if (emergencyLevel == 'high') return 'HIGH';

    final priority = (recommendation['priority'] as num?)?.toInt() ?? 1;
    if (priority <= 2) return 'MEDIUM';
    return 'LOW';
  }

  // Get health trend data
  Map<String, dynamic> get _healthTrend {
    final currentHealth = _dashboardSummary['healthScore'] ?? 0.0;
    final previousHealth = DiagnosticHistory.currentHealth;

    return {
      'current': currentHealth,
      'previous': previousHealth,
      'target': 80.0,
      'trend': currentHealth >= previousHealth ? 'up' : 'down',
    };
  }

  // Get summary text
  String get _summary {
    final verdict = _intelligentDiagnosis['verdict']?.toString() ?? 'UNKNOWN';
    final message = _intelligentDiagnosis['message']?.toString() ?? '';

    if (verdict.contains('HEALTHY')) {
      return 'Your lavender plant appears healthy. All systems are within optimal ranges. Continue with your current care routine.';
    } else {
      final cnnPrediction =
          _visualAssessment['cnnPrediction']?.toString() ?? 'issues';
      return 'Your lavender shows signs of ${cnnPrediction.toLowerCase().replaceAll('_', ' ')}. '
          '$message '
          'Immediate action is recommended to prevent further issues and encourage healthy growth.';
    }
  }

  // Check if plant is healthy
  bool get _isHealthy {
    final verdict = _intelligentDiagnosis['verdict']?.toString() ?? '';
    return verdict.contains('HEALTHY') && _parsedIssues.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Diagnostic Report',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareReport,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Banner
            _buildEmergencyBanner(),
            const SizedBox(height: 20),

            // Visual Assessment
            _buildVisualAssessment(),
            const SizedBox(height: 20),

            // Sensor Cross-Verification
            _buildSensorCrossVerification(),
            const SizedBox(height: 20),

            // Issues Detected
            if (_parsedIssues.isNotEmpty) ...[
              _buildIssuesDetected(),
              const SizedBox(height: 20),
            ],

            // Action Plan
            _buildActionPlan(),
            const SizedBox(height: 20),

            // Health Trend
            _buildHealthTrend(),
            const SizedBox(height: 20),

            // Summary
            _buildSummary(),
            const SizedBox(height: 20),

            // Mark Actions Button
            _buildActionButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyBanner() {
    final emergencyLevel =
        _intelligentDiagnosis['emergencyLevel']?['level'] ?? 'low';
    final message =
        _intelligentDiagnosis['emergencyLevel']?['message'] ??
        'MONITOR REGULARLY';

    Color bannerColor;
    IconData icon;

    switch (emergencyLevel) {
      case 'high':
        bannerColor = dangerColor;
        icon = Icons.warning_amber_rounded;
        break;
      case 'medium':
        bannerColor = warningColor;
        icon = Icons.info;
        break;
      default:
        bannerColor = _isHealthy ? successColor : infoColor;
        icon = _isHealthy ? Icons.check_circle : Icons.info;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: bannerColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                _isHealthy ? 'Plant is Healthy' : 'Action Required',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${emergencyLevel.toUpperCase()} PRIORITY',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualAssessment() {
    final prediction =
        _visualAssessment['cnnPrediction']?.toString() ?? 'Unknown';
    final confidence =
        double.tryParse(
          (_visualAssessment['confidencePercentage']?.toString() ??
              (_visualAssessment['confidence']?.toString() ?? '0.0')),
        ) ??
        0.0;
    final message =
        _visualAssessment['message']?.toString() ?? 'Visual analysis complete';

    // Determine color based on prediction
    Color diagnosisColor;
    if (prediction.toLowerCase().contains('over') ||
        prediction.toLowerCase().contains('under')) {
      diagnosisColor = warningColor;
    } else if (prediction.toLowerCase().contains('healthy')) {
      diagnosisColor = successColor;
    } else if (prediction.toLowerCase().contains('deficient') ||
        prediction.toLowerCase().contains('disease')) {
      diagnosisColor = dangerColor;
    } else {
      diagnosisColor = infoColor;
    }

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Visual Assessment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: diagnosisColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: diagnosisColor),
                  ),
                  child: Text(
                    prediction.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: diagnosisColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'CNN Diagnosis',
                      style: TextStyle(color: lightTextColor, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${confidence.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'AI Confidence Score',
                      style: TextStyle(color: lightTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '"$message"',
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCrossVerification() {
    final matchPercentage =
        (_crossVerification['matchPercentage'] as num?)?.toDouble() ?? 0.0;
    final confidence = _crossVerification['confidence']?.toString() ?? 'medium';
    final sensorCorrelation = _crossVerification['sensorCorrelation'] ?? {};
    final sensorReadings = _sensorReadings['raw'] ?? widget.sensorData;

    Color matchColor;
    String matchText;

    if (matchPercentage >= 80) {
      matchColor = successColor;
      matchText = 'CONFIRMED MATCH';
    } else if (matchPercentage >= 60) {
      matchColor = warningColor;
      matchText = 'PARTIAL MATCH';
    } else {
      matchColor = dangerColor;
      matchText = 'CONFLICTING DATA';
    }

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Sensor Cross-Verification',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Match banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: matchColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: matchColor),
              ),
              child: Center(
                child: Text(
                  matchText,
                  style: TextStyle(
                    color: matchColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // NPK Values
            const Center(
              child: Text(
                'N    P    K',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  letterSpacing: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${_getNPKValue('nitrogen')}    '
                '${_getNPKValue('phosphorus')}    '
                '${_getNPKValue('potassium')}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: 12,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'ppm    ppm    ppm',
                style: TextStyle(
                  color: lightTextColor,
                  fontSize: 12,
                  letterSpacing: 8,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Match percentage
            Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Sensors agree with visual\n',
                      style: TextStyle(color: lightTextColor, fontSize: 14),
                    ),
                    TextSpan(
                      text: '${matchPercentage.toStringAsFixed(1)}% Match',
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: '\n(${confidence.toUpperCase()} confidence)',
                      style: TextStyle(color: lightTextColor, fontSize: 12),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            const Divider(),
            const SizedBox(height: 16),

            // Moisture, pH, EC with status indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSensorReading(
                  'Moisture',
                  '${_getSensorValue('moisture').toStringAsFixed(1)}%',
                  _getMoistureStatus(_getSensorValue('moisture')),
                  _getMoistureStatusColor(_getSensorValue('moisture')),
                ),
                _buildSensorReading(
                  'pH',
                  _getSensorValue('ph').toStringAsFixed(1),
                  _getPHStatus(_getSensorValue('ph')),
                  _getPHStatusColor(_getSensorValue('ph')),
                ),
                _buildSensorReading(
                  'EC',
                  _getSensorValue('ec').toStringAsFixed(1),
                  _getECStatus(_getSensorValue('ec')),
                  _getECStatusColor(_getSensorValue('ec')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getNPKValue(String nutrient) {
    final npk = _sensorReadings['calculatedNPK'] ?? widget.sensorData;
    final value =
        (npk[nutrient] as num?)?.toDouble() ??
        (widget.sensorData[nutrient] as num?)?.toDouble() ??
        0.0;
    return value.toStringAsFixed(1);
  }

  double _getSensorValue(String key) {
    final sensorReadings = _sensorReadings['raw'] ?? widget.sensorData;
    final value = sensorReadings[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Helper methods for sensor status
  String _getMoistureStatus(double moisture) {
    if (moisture < 30) return 'Low';
    if (moisture > 50) return 'High';
    return 'Optimal';
  }

  Color _getMoistureStatusColor(double moisture) {
    if (moisture < 30) return warningColor;
    if (moisture > 50) return dangerColor;
    return successColor;
  }

  String _getPHStatus(double ph) {
    if (ph < 6.0) return 'Acidic';
    if (ph > 7.5) return 'Alkaline';
    return 'Optimal';
  }

  Color _getPHStatusColor(double ph) {
    if (ph < 6.0 || ph > 7.5) return warningColor;
    return successColor;
  }

  String _getECStatus(double ec) {
    if (ec < 1.0) return 'Low';
    if (ec > 4.0) return 'High';
    return 'Optimal';
  }

  Color _getECStatusColor(double ec) {
    if (ec < 1.0 || ec > 4.0) return warningColor;
    return successColor;
  }

  Widget _buildSensorReading(
    String label,
    String value,
    String status,
    Color statusColor,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: lightTextColor, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIssuesDetected() {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Intelligent Analysis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Final Diagnosis',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),

            ..._parsedIssues.map((issue) {
              Color severityColor;
              switch (issue['severity']) {
                case 'HIGH':
                  severityColor = dangerColor;
                  break;
                case 'MEDIUM':
                  severityColor = warningColor;
                  break;
                default:
                  severityColor = infoColor;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      issue['severity'] == 'HIGH' ? Icons.warning : Icons.info,
                      color: severityColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            issue['title'] ?? 'Unknown Issue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: severityColor,
                            ),
                          ),
                          if (issue['severity'] != null)
                            Text(
                              'Severity: ${issue['severity']}',
                              style: TextStyle(
                                color: lightTextColor,
                                fontSize: 12,
                              ),
                            ),
                          if (issue['currentValue'] != null)
                            Text(
                              'Current: ${issue['currentValue']}',
                              style: const TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (issue['optimalRange'] != null)
                            Text(
                              'Optimal: ${issue['optimalRange']}',
                              style: const TextStyle(
                                color: lightTextColor,
                                fontSize: 12,
                              ),
                            ),
                          if (issue['detectedBy'] != null)
                            Text(
                              'Detected by: ${issue['detectedBy']}',
                              style: const TextStyle(
                                color: lightTextColor,
                                fontSize: 11,
                              ),
                            ),
                          if (issue['description'] != null)
                            Text(
                              issue['description'],
                              style: TextStyle(
                                color: textColor.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 16),
            const Text(
              'AI Reasoning',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _intelligentDiagnosis['reasoning']?.toString() ??
                  'Analysis complete based on visual and sensor data correlation.',
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPlan() {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Action Plan - Priority Order',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),

            ..._actionPlan.map((action) {
              Color severityColor;
              switch (action['severity']) {
                case 'HIGH':
                  severityColor = dangerColor;
                  break;
                case 'MEDIUM':
                  severityColor = warningColor;
                  break;
                default:
                  severityColor = infoColor;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: severityColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${action['priority']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action['title'] ?? 'Unknown Action',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            action['description'] ?? '',
                            style: TextStyle(
                              color: textColor.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: severityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              action['severity'] ?? 'LOW',
                              style: TextStyle(
                                color: severityColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthTrend() {
    final trend = _healthTrend;
    final isImproving = trend['trend'] == 'up';

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Health Trend',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${trend['previous'].toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Previous Health',
                        style: TextStyle(color: lightTextColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isImproving
                        ? successColor.withOpacity(0.1)
                        : warningColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isImproving ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isImproving ? successColor : warningColor,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${trend['current'].toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: isImproving ? successColor : warningColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Current Health',
                        style: TextStyle(color: lightTextColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Divider(),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Target:',
                      style: TextStyle(color: lightTextColor, fontSize: 12),
                    ),
                    Text(
                      '>${trend['target']}%',
                      style: const TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isImproving ? 'Improving' : 'Needs attention',
                      style: TextStyle(
                        color: isImproving ? successColor : warningColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(trend['current'] - trend['previous']).toStringAsFixed(1)}% ${isImproving ? 'better' : 'worse'}',
                      style: TextStyle(color: lightTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final insights = _dashboardSummary['insights'] ?? {};
    final reminders = _dashboardSummary['reminders'] ?? [];

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _summary,
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            _buildChecklistItem(
              Icons.check_circle,
              insights['whatsWorking']?.toString() ?? 'Plant structure intact',
              successColor,
            ),
            _buildChecklistItem(
              Icons.remove_red_eye,
              insights['watchFor']?.toString() ?? 'Normal growth patterns',
              warningColor,
            ),
            if (reminders.isNotEmpty)
              _buildChecklistItem(
                Icons.notifications_active,
                reminders.first['title']?.toString() ?? 'Next checkup',
                primaryColor,
              ),
            _buildChecklistItem(
              Icons.flag,
              insights['goal']?.toString() ?? 'Maintain plant health',
              _isHealthy ? successColor : primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(color: textColor, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _markActionsComplete();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _isHealthy ? successColor : primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Text(
          _isHealthy ? 'PLANT IS HEALTHY' : 'MARK ACTIONS AS COMPLETE',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  void _markActionsComplete() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isHealthy
              ? 'Plant is healthy - no actions needed'
              : 'Actions marked as complete',
        ),
        backgroundColor: _isHealthy ? successColor : primaryColor,
      ),
    );
  }

  void _shareReport() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
        backgroundColor: primaryColor,
      ),
    );
  }
}
