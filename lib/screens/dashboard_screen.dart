// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/diagnostic_history.dart';
import '../widgets/dashboard/health_wheel.dart';
import '../widgets/dashboard/quick_actions_row.dart';
import '../widgets/dashboard/sensor_grid.dart';
import '../widgets/dashboard/plant_analysis_card.dart';
import '../widgets/dashboard/analysis_button.dart';
import '../widgets/dashboard/quick_tips_card.dart';
import '../widgets/shared/connection_status.dart';
import '../widgets/shared/gradient_app_bar.dart';
import './diagnostic_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Modern Color Palette
  static const Color primaryColor = Color(0xFF8A4FFF);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF2C3E50);
  static const Color lightTextColor = Color(0xFF95A5A6);

  bool _backendConnected = false;
  bool _checkingConnection = false;
  bool _isAnalyzing = false;
  XFile? _selectedImage;
  double _soilHealth = DiagnosticHistory.currentHealth;
  final Map<String, dynamic> _sensorData = {
    'moisture': 45.0,
    'ph': 6.8,
    'ec': 2.5,
    'temperature': 24.0,
    'nitrogen': 65.0,
    'phosphorus': 42.0,
    'potassium': 58.0,
  };
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkBackendConnection();
    _loadLastDiagnosticData();
  }

  Future<void> _loadLastDiagnosticData() async {
    final lastResult = await DiagnosticHistory.getLastResult();
    if (lastResult != null && mounted) {
      setState(() {
        _soilHealth = DiagnosticHistory.currentHealth;
        // Update sensor data from last result if available
        final sensorReadings = lastResult['sensorReadings']?['raw'];
        if (sensorReadings is Map) {
          _sensorData.addAll(Map<String, dynamic>.from(sensorReadings));
        }
      });
    }
  }

  Future<void> _checkBackendConnection() async {
    if (_checkingConnection) return;

    setState(() {
      _checkingConnection = true;
    });

    final connected = await ApiService.testConnection();

    setState(() {
      _backendConnected = connected;
      _checkingConnection = false;
    });

    if (!connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cannot connect to backend'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _analyzePlant() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an image first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Call your API service
      final result = await ApiService.analyzePlant(
        image: _selectedImage!,
        sensorData: _sensorData,
      );

      // Save to diagnostic history
      await DiagnosticHistory.saveResult(result);

      // Update local state with new health score
      if (result['dashboardSummary']?['healthScore'] != null) {
        setState(() {
          _soilHealth = result['dashboardSummary']['healthScore'].toDouble();
        });
      }

      // Navigate to Diagnostic Screen
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DiagnosticScreen(analysisResult: result, sensorData: _sensorData),
        ),
      ).then((_) {
        // Refresh dashboard when returning from diagnostic
        _loadLastDiagnosticData();
      });
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Analysis Failed'),
            ],
          ),
          content: Text('Error: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  void _updateSensorData(String key, double value) {
    setState(() {
      _sensorData[key] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          GradientAppBar(
            title: 'Lavender AI',
            icon: Icons.spa,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Health Wheel
                HealthWheel(
                  healthScore: _soilHealth,
                  lastUpdated: DiagnosticHistory.lastUpdateTime,
                ),
                const SizedBox(height: 24),

                // Quick Actions
                const QuickActionsRow(),
                const SizedBox(height: 32),

                // Sensor Readings
                SensorGrid(
                  sensorData: _sensorData,
                  onSensorValueChanged: _updateSensorData,
                ),
                const SizedBox(height: 32),

                // Plant Analysis Card
                PlantAnalysisCard(
                  selectedImage: _selectedImage,
                  onPickImage: _pickImage,
                  onTakePhoto: _takePhoto,
                ),
                const SizedBox(height: 24),

                // Quick Tips from last diagnostic
                QuickTipsCard(
                  dashboardSummary: DiagnosticHistory.lastDashboardSummary,
                ),
                const SizedBox(height: 32),

                // Analysis Button
                AnalysisButton(
                  isAnalyzing: _isAnalyzing,
                  selectedImage: _selectedImage,
                  onAnalyze: _analyzePlant,
                ),
                const SizedBox(height: 24),

                // Connection Status
                if (!_backendConnected)
                  ConnectionStatus(
                    isConnected: _backendConnected,
                    isChecking: _checkingConnection,
                    onRetry: _checkBackendConnection,
                  ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
