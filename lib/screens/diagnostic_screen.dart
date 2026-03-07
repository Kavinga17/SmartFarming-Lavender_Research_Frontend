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
  // Color Palette
  static const Color primaryColor = Color(0xFF8A4FFF); // Lavender Purple
  static const Color dangerColor = Color(0xFFE74C3C); // Red
  static const Color warningColor = Color(0xFFFFA726); // Amber
  static const Color successColor = Color(0xFF2ECC71); // Green
  static const Color infoColor = Color(0xFF3498DB); // Blue
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF2C3E50);
  static const Color lightTextColor = Color(0xFF95A5A6);

  // Safe getter for Map values
  Map<String, dynamic> _safeGetMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

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
      print('Error parsing key $key: $e');
      return defaultValue;
    }
  }

  // ==================== BACKEND DATA GETTERS ====================

  // Get threeClass data
  Map<String, dynamic> get _threeClass {
    return _safeGetMap(_getFromResult('threeClass', {}));
  }

  String get _prediction {
    return _threeClass['prediction']?.toString() ?? 'Unknown';
  }

  double get _confidence {
    final conf = _threeClass['confidence'];
    return conf is num ? conf.toDouble() : 0.0;
  }

  Map<String, dynamic> get _probabilities {
    return _safeGetMap(_threeClass['probabilities']);
  }

  // Get yellow meter data (if exists)
  Map<String, dynamic> get _yellowMeter {
    return _safeGetMap(_getFromResult('yellowMeter', {}));
  }

  double get _yellowness {
    final y = _yellowMeter['yellowness'];
    return y is num ? y.toDouble() : 0.0;
  }

  String? get _diagnosis {
    return _getFromResult('diagnosis')?.toString();
  }

  String get _action {
    return _getFromResult('action')?.toString() ?? '';
  }

  String get _message {
    return _getFromResult('message')?.toString() ?? '';
  }

  String? get _warning {
    return _getFromResult('warning')?.toString();
  }

  bool get _needsDiseaseDetection {
    return _getFromResult('needsDiseaseDetection') ?? false;
  }

  // Moisture from sensor data
  double? get _moisture {
    final m = _getFromResult('moisture');
    if (m is num) return m.toDouble();
    return widget.sensorData['moisture']?.toDouble();
  }

  // Check if plant is healthy
  bool get _isHealthy {
    return _prediction == 'healthy' && _diagnosis == null;
  }

  // Get status color based on prediction
  Color get _statusColor {
    if (_prediction == 'healthy') return successColor;
    if (_prediction == 'nutrient_deficient') return warningColor;
    if (_prediction == 'diseased') return dangerColor;
    return infoColor;
  }

  String get _statusText {
    if (_prediction == 'healthy') return 'HEALTHY';
    if (_prediction == 'nutrient_deficient') return 'DEFICIENT';
    if (_prediction == 'diseased') return 'DISEASED';
    return 'UNKNOWN';
  }

  String _getMoistureStatus(double? moisture) {
    if (moisture == null) return 'Unknown';
    if (moisture < 30) return 'Low';
    if (moisture > 70) return 'High';
    return 'Optimal';
  }

  Color _getMoistureColor(double? moisture) {
    if (moisture == null) return lightTextColor;
    if (moisture < 30) return warningColor;
    if (moisture > 70) return dangerColor;
    return successColor;
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
            _buildHeaderBanner(),
            const SizedBox(height: 20),
            _buildThreeClassResult(),
            const SizedBox(height: 20),
            if (_yellowness > 0) _buildYellowMeter(),
            if (_yellowness > 0) const SizedBox(height: 20),
            _buildMoistureCard(),
            const SizedBox(height: 20),
            if (_diagnosis != null) _buildDiagnosisCard(),
            if (_diagnosis != null) const SizedBox(height: 20),
            if (_warning != null) _buildWarningCard(),
            if (_warning != null) const SizedBox(height: 20),
            _buildActionButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_statusColor, _statusColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withOpacity(0.3),
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
              Icon(
                _isHealthy ? Icons.check_circle : Icons.warning,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isHealthy ? 'Plant is Healthy' : 'Issue Detected',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _message.isNotEmpty ? _message : _statusText,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(_confidence * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThreeClassResult() {
    final probabilities = _probabilities;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                  _statusText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _statusColor,
                  ),
                ),
                Text(
                  '${(_confidence * 100).toStringAsFixed(1)}%',
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
      ),
    );
  }

  Widget _buildYellowMeter() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                    color: _yellowness > 60
                        ? dangerColor.withOpacity(0.1)
                        : _yellowness > 30
                        ? warningColor.withOpacity(0.1)
                        : successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _yellowness > 60
                        ? 'SEVERE'
                        : _yellowness > 30
                        ? 'MODERATE'
                        : 'MILD',
                    style: TextStyle(
                      color: _yellowness > 60
                          ? dangerColor
                          : _yellowness > 30
                          ? warningColor
                          : successColor,
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
                  widthFactor: _yellowness / 100,
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
              '${_yellowness.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoistureCard() {
    final moisture = _moisture;
    final moistureColor = _getMoistureColor(moisture);
    final moistureStatus = _getMoistureStatus(moisture);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
      ),
    );
  }

  Widget _buildDiagnosisCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                color: _diagnosis?.contains('LOCKOUT') == true
                    ? dangerColor.withOpacity(0.1)
                    : _diagnosis?.contains('DEFICIENCY') == true
                    ? warningColor.withOpacity(0.1)
                    : infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _diagnosis?.contains('LOCKOUT') == true
                      ? dangerColor
                      : _diagnosis?.contains('DEFICIENCY') == true
                      ? warningColor
                      : infoColor,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _diagnosis ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _diagnosis?.contains('LOCKOUT') == true
                          ? dangerColor
                          : _diagnosis?.contains('DEFICIENCY') == true
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
      ),
    );
  }

  Widget _buildWarningCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _markActionsComplete,
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
        backgroundColor: primaryColor,
      ),
    );
  }
}
