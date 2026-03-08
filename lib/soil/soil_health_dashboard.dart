// lib/screens/soil_health_dashboard.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/soil_backend_service.dart';
import 'irrigation_setup_screen.dart';
import 'diagnostic_screen.dart';
import 'soil_history_screen.dart';

class SoilHealthDashboard extends StatefulWidget {
  final double? initialMoisture;

  const SoilHealthDashboard({super.key, this.initialMoisture});

  @override
  State<SoilHealthDashboard> createState() => _SoilHealthDashboardState();
}

class _SoilHealthDashboardState extends State<SoilHealthDashboard> {
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryOrange = Color(0xFFFF7A45);
  static const Color successGreen = Color(0xFF22C55E);
  static const Color warningAmber = Color(0xFFFBBF24);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);

  double _currentMoisture = 45;
  double _temperature = 24;
  bool _isLoading = false;
  bool _hasIrrigationRoutine = false;
  Map<String, dynamic>? _lastAnalysis;
  Map<String, dynamic>? _currentRoutine; // Added this variable

  @override
  void initState() {
    super.initState();
    _currentMoisture = widget.initialMoisture ?? 45;
    _loadData();
  }

  Future<void> _loadData() async {
    await _fetchSensorData();
    await _checkIrrigationRoutine();
    await _fetchLatestAnalysis();
    _currentRoutine =
        await SoilBackendService.getCurrentRoutine(); // Added this line
    setState(() {}); // Refresh UI
  }

  Future<void> _fetchSensorData() async {
    setState(() => _isLoading = true);
    try {
      final moisture = await SoilBackendService.getMoisture();
      if (moisture != null) {
        setState(() {
          _currentMoisture = moisture;
          _isLoading = false;
        });
      } else {
        // No sensor reading available
        setState(() {
          _currentMoisture = -1; // Use -1 to indicate no reading
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching sensor data: $e');
      setState(() {
        _currentMoisture = -1;
        _isLoading = false;
      });
    }
  }

  Future<void> _checkIrrigationRoutine() async {
    try {
      final routine = await SoilBackendService.getCurrentRoutine();
      setState(() => _hasIrrigationRoutine = routine != null);
    } catch (e) {
      print('❌ Error checking routine: $e');
    }
  }

  Future<void> _fetchLatestAnalysis() async {
    try {
      final history = await SoilBackendService.getAnalysisHistory(limit: 1);
      if (history.isNotEmpty) {
        setState(() {
          _lastAnalysis = history.first;
        });
      }
    } catch (e) {
      print('❌ Error fetching latest analysis: $e');
    }
  }

  Color _getMoistureColor(double moisture) {
    if (moisture < 30) return dangerRed;
    if (moisture > 70) return warningAmber;
    return successGreen;
  }

  String _getMoistureStatus(double moisture) {
    if (moisture < 30) return 'Too Dry';
    if (moisture > 70) return 'Too Wet';
    return 'Optimal';
  }

  String _formatDate(String timestamp) {
    if (timestamp.isEmpty) return 'Not scheduled';
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: primaryPurple),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _runDiagnostic(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: primaryPurple),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _runDiagnostic(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _runDiagnostic(ImageSource source) async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(source: source);

      if (image == null) return;

      setState(() => _isLoading = true);

      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(color: primaryPurple),
          );
        },
      );

      final result = await SoilBackendService.analyzeImage(image);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (result != null) {
        setState(() {
          _lastAnalysis = result;
          _isLoading = false;
        });

        // Navigate to diagnostic screen
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiagnosticScreen(
              analysisResult: result,
              sensorData: {'moisture': _currentMoisture},
            ),
          ),
        ).then((_) => _fetchLatestAnalysis()); // Refresh after returning
      } else {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analysis failed. Please try again.'),
            backgroundColor: dangerRed,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog if open
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: dangerRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Soil Health', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: primaryPurple,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Connection Status Indicator
              FutureBuilder<bool>(
                future: SoilBackendService.testConnection(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data == true) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: successGreen),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: successGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Connected to backend',
                            style: TextStyle(color: successGreen, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: warningAmber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: warningAmber),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning, color: warningAmber, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Offline - using cached data',
                          style: TextStyle(color: warningAmber, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),

              _buildMoistureCard(),
              const SizedBox(height: 16),

              // Active routine summary (if exists)
              if (_currentRoutine != null) ...[
                _buildActiveRoutineSummary(),
                const SizedBox(height: 16),
              ],

              _buildActionCards(),
              if (_lastAnalysis != null) ...[
                const SizedBox(height: 16),
                _buildRecentAnalysis(),
              ],
              const SizedBox(height: 16),
              _buildHistoryButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoistureCard() {
    // Handle no sensor reading
    if (_currentMoisture == -1) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.sensors_off, color: warningAmber, size: 32),
                const SizedBox(width: 12),
                const Text(
                  'Soil Moisture',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'No Sensor Reading',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: textGrey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: warningAmber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Check Sensor Connection',
                style: TextStyle(
                  color: warningAmber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final moistureColor = _getMoistureColor(_currentMoisture);
    final moistureStatus = _getMoistureStatus(_currentMoisture);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.water_drop, color: moistureColor, size: 32),
              const SizedBox(width: 12),
              const Text(
                'Soil Moisture',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _isLoading ? '--' : '${_currentMoisture.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: moistureColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    );
  }

  Widget _buildActiveRoutineSummary() {
    final schedule = _currentRoutine?['schedule'] ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryPurple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryPurple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.settings_input_component, color: primaryPurple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active Routine',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Next: ${_formatDate(schedule['nextWatering'] ?? '')}',
                  style: TextStyle(color: textGrey, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SoilHistoryScreen(),
                ),
              );
            },
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards() {
    return Column(
      children: [
        _buildActionCard(
          icon: Icons.settings_input_component,
          title: 'Irrigation Routine',
          subtitle: _hasIrrigationRoutine
              ? 'Active - Tap to view schedule'
              : 'Set up automated watering',
          color: primaryOrange,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const IrrigationSetupScreen(),
              ),
            );
            if (result == true) {
              _checkIrrigationRoutine();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Routine saved successfully!'),
                  backgroundColor: successGreen,
                ),
              );
            }
          },
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.analytics,
          title: 'Run Diagnostic',
          subtitle: 'Analyze plant health with AI',
          color: successGreen,
          onTap: _showImageSourceDialog,
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: textGrey, fontSize: 13),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildRecentAnalysis() {
    final threeClass = _lastAnalysis?['threeClass'] ?? {};
    final prediction = threeClass['prediction'] ?? 'unknown';
    final confidence = threeClass['confidence'] ?? 0.0;

    Color statusColor;
    String statusText;

    if (prediction == 'healthy') {
      statusColor = successGreen;
      statusText = 'Healthy';
    } else if (prediction == 'nutrient_deficient') {
      statusColor = warningAmber;
      statusText = 'Deficient';
    } else {
      statusColor = dangerRed;
      statusText = 'Diseased';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Latest Analysis',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_lastAnalysis?['yellowMeter'] != null) ...[
            const Text(
              'Yellowness Level',
              style: TextStyle(color: textGrey, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor:
                      (_lastAnalysis?['yellowMeter']['yellowness'] ?? 0) / 100,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [successGreen, warningAmber, dangerRed],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_lastAnalysis?['yellowMeter']['yellowness']?.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(color: textGrey, fontSize: 13),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DiagnosticScreen(
                        analysisResult: _lastAnalysis!,
                        sensorData: {'moisture': _currentMoisture},
                      ),
                    ),
                  ).then((_) => _fetchLatestAnalysis());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('View Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SoilHistoryScreen()),
          );
        },
        icon: const Icon(Icons.history, color: Colors.white),
        label: const Text('View Full History'),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }
}
