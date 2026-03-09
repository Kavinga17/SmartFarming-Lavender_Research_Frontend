import 'package:flutter/material.dart';
import '../../services/soil_diagnostic_history.dart';

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
  // Color Palette — matches app-wide design system
  static const Color primaryColor = Color(0xFF8B5CF6);  // primaryPurple
  static const Color dangerColor = Color(0xFFEF4444);   // dangerRed
  static const Color warningColor = Color(0xFFFBBF24);  // warningAmber
  static const Color successColor = Color(0xFF22C55E);  // successGreen
  static const Color infoColor = Color(0xFF3B82F6);     // primaryBlue
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF1F2937);     // textDark
  static const Color lightTextColor = Color(0xFF6B7280); // textGrey

  // Helper to safely get data from API response
  dynamic _getFromResult(String key, [dynamic defaultValue]) {
    try {
      final parts = key.split('.');
      Map<String, dynamic> current = Map<String, dynamic>.from(
        widget.analysisResult,
      );

      for (final part in parts) {
        if (current.containsKey(part)) {
          final value = current[part];
          if (value is Map) {
            current = Map<String, dynamic>.from(value);
          } else {
            return value;
          }
        } else {
          return defaultValue;
        }
      }
      return current;
    } catch (e) {
      return defaultValue;
    }
  }

  // Get three class prediction
  Map<String, dynamic> get _threeClass {
    final result = _getFromResult('threeClass', {});
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    return {};
  }

  // Get yellow meter data
  Map<String, dynamic> get _yellowMeter {
    final result = _getFromResult('yellowMeter', {});
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    return {};
  }

  // Get moisture reading
  double? get _moisture {
    final moisture = _getFromResult('moisture');
    if (moisture is num) return moisture.toDouble();
    return widget.sensorData['moisture']?.toDouble();
  }

  // Get diagnosis
  String get _diagnosis {
    return _getFromResult('diagnosis')?.toString() ?? 'UNKNOWN';
  }

  // Get action
  String get _action {
    return _getFromResult('action')?.toString() ?? 'Monitor plant';
  }

  // Get warning
  String? get _warning {
    return _getFromResult('warning')?.toString();
  }

  // Check if plant is healthy
  bool get _isHealthy {
    final prediction = _threeClass['prediction']?.toString() ?? '';
    return prediction == 'healthy';
  }

  // Get moisture status
  String _getMoistureStatus(double? moisture) {
    if (moisture == null) return 'Unknown';
    if (moisture < 30) return 'Too Dry';
    if (moisture > 70) return 'Too Wet';
    return 'Optimal';
  }

  Color _getMoistureColor(double? moisture) {
    if (moisture == null) return lightTextColor;
    if (moisture < 30) return dangerColor;
    if (moisture > 70) return warningColor;
    return successColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emergency Banner
                    _buildEmergencyBanner(),
                    const SizedBox(height: 20),

                    // 3-Class Model Result
                    _buildThreeClassResult(),
                    const SizedBox(height: 20),

                    // Yellow Meter (if available)
                    if (_yellowMeter.isNotEmpty) ...[
                      _buildYellowMeter(),
                      const SizedBox(height: 20),
                    ],

                    // Moisture Reading
                    _buildMoistureCard(),
                    const SizedBox(height: 20),

                    // Diagnosis & Action
                    _buildDiagnosisCard(),
                    const SizedBox(height: 20),

                    // Warning if any
                    if (_warning != null) ...[
                      _buildWarningCard(),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Lavender ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                TextSpan(
                  text: 'AI',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                  ),
                ),
                TextSpan(
                  text: ' 🌿',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Page context badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.science, size: 14, color: primaryColor),
                const SizedBox(width: 4),
                Text(
                  'Diagnostic',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyBanner() {
    final prediction = _threeClass['prediction']?.toString() ?? 'unknown';
    final confidence = (_threeClass['confidence'] as num?)?.toDouble() ?? 0.0;

    Color bannerColor;
    IconData icon;
    String title;

    if (prediction == 'healthy') {
      bannerColor = successColor;
      icon = Icons.check_circle;
      title = 'Plant is Healthy';
    } else if (prediction == 'nutrient_deficient') {
      bannerColor = warningColor;
      icon = Icons.warning;
      title = 'Nutrient Deficiency Detected';
    } else {
      bannerColor = dangerColor;
      icon = Icons.error;
      title = 'Disease Detected';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bannerColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
                title,
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
            'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeClassResult() {
    final prediction = _threeClass['prediction']?.toString() ?? 'Unknown';
    final confidence = (_threeClass['confidence'] as num?)?.toDouble() ?? 0.0;
    final probabilities = _threeClass['probabilities'] is Map
        ? Map<String, dynamic>.from(_threeClass['probabilities'] as Map)
        : {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Visual Analysis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  prediction.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: prediction == 'healthy'
                        ? successColor
                        : prediction == 'nutrient_deficient'
                        ? warningColor
                        : dangerColor,
                  ),
                ),
                Text(
                  '${(confidence * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ],
            ),
            if (probabilities.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Class Probabilities:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...probabilities.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          e.key.replaceAll('_', ' '),
                          style: const TextStyle(color: lightTextColor),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: (e.value as num?)?.toDouble() ?? 0,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: e.key == 'healthy'
                                      ? successColor
                                      : e.key == 'nutrient_deficient'
                                      ? warningColor
                                      : dangerColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${((e.value as num?)?.toDouble() ?? 0 * 100).toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
    );
  }

  Widget _buildYellowMeter() {
    final yellowness = (_yellowMeter['yellowness'] as num?)?.toDouble() ?? 0.0;
    final severity = _yellowMeter['severity']?.toString() ?? 'mild';

    Color severityColor;
    switch (severity) {
      case 'severe':
        severityColor = dangerColor;
        break;
      case 'moderate':
        severityColor = warningColor;
        break;
      default:
        severityColor = infoColor;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: warningColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yellow Meter',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Yellowness Level',
                  style: TextStyle(color: lightTextColor),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    severity.toUpperCase(),
                    style: TextStyle(
                      color: severityColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: yellowness / 100,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [successColor, warningColor, dangerColor],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${yellowness.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildMoistureCard() {
    final moisture = _moisture;
    final moistureColor = _getMoistureColor(moisture);
    final moistureStatus = _getMoistureStatus(moisture);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: moistureColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop, color: moistureColor, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Soil Moisture',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    moisture != null ? '${moisture.toStringAsFixed(1)}%' : '--',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: moistureColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: moistureColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      moistureStatus,
                      style: TextStyle(
                        color: moistureColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildDiagnosisCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Diagnosis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _diagnosis.contains('LOCKOUT')
                    ? dangerColor.withOpacity(0.1)
                    : _diagnosis.contains('DEFICIENCY')
                    ? warningColor.withOpacity(0.1)
                    : infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _diagnosis.contains('LOCKOUT')
                      ? dangerColor
                      : _diagnosis.contains('DEFICIENCY')
                      ? warningColor
                      : infoColor,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _diagnosis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _diagnosis.contains('LOCKOUT')
                          ? dangerColor
                          : _diagnosis.contains('DEFICIENCY')
                          ? warningColor
                          : infoColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _action,
                    style: const TextStyle(fontSize: 14, color: textColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: warningColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: warningColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _warning!,
              style: const TextStyle(color: textColor, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
