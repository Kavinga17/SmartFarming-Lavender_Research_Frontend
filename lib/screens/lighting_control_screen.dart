import 'dart:async';
import 'package:flutter/material.dart';
import '../models/lighting_model.dart';
import '../models/sensor_model.dart';
import '../services/api_service.dart';
import 'diagnostic_screen.dart';
import 'growth_stage_screen.dart';
import 'recommendation_screen.dart';
import 'sensor_chart_screen.dart';

class LightingControlScreen extends StatefulWidget {
  const LightingControlScreen({super.key});

  @override
  State<LightingControlScreen> createState() => _LightingControlScreenState();
}

class _LightingControlScreenState extends State<LightingControlScreen> {
  // Colors (same as ClimateScreen)
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryGreen = Color(0xFF22C55E);
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryOrange = Color(0xFFFF7A45);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color cardBackground = Colors.white;

  // Lighting state
  LightingState _lightingState = LightingState.initial();

  // Sensor data
  SensorData? _latestSensor;

  // Photoperiod settings
  bool _photoperiodEnabled = false;
  TimeOfDay _lightOn = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _lightOff = const TimeOfDay(hour: 22, minute: 0);

  // Oil yield prediction (dummy)
  double _predictedOilYield = 2.4;

  // Timer for auto-refresh
  Timer? _sensorTimer;

  @override
  void initState() {
    super.initState();
    _fetchSensorData();
    _sensorTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchSensorData());
  }

  @override
  void dispose() {
    _sensorTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSensorData() async {
    final data = await ApiService.fetchSensorData();
    if (data != null) {
      setState(() {
        _latestSensor = data;
      });
    }
  }

  Future<void> _updateLighting() async {
    await ApiService.updateLighting(_lightingState);
  }

  Future<void> _updatePhotoperiod() async {
    await ApiService.updatePhotoperiod(_photoperiodEnabled, _lightOn, _lightOff);
  }

  void _setStage(GrowthStage stage) {
    int red, blue, white;
    switch (stage) {
      case GrowthStage.germination:
        red = 50; blue = 100; white = 30;
        break;
      case GrowthStage.seedling:
        red = 80; blue = 120; white = 50;
        break;
      case GrowthStage.vegetative:
        red = 150; blue = 100; white = 70;
        break;
      case GrowthStage.flowering:
        red = 200; blue = 80; white = 60;
        break;
      case GrowthStage.oilMaturation:
        red = 220; blue = 60; white = 100;
        break;
    }
    setState(() {
      _lightingState = LightingState(
        red: red,
        blue: blue,
        white: white,
        stage: stage,
        isScheduleEnabled: _photoperiodEnabled,
        scheduleStart: _photoperiodEnabled
            ? DateTime(2024, 1, 1, _lightOn.hour, _lightOn.minute)
            : null,
        scheduleEnd: _photoperiodEnabled
            ? DateTime(2024, 1, 1, _lightOff.hour, _lightOff.minute)
            : null,
      );
    });
    _updateLighting();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section with Plant Illustration and Sensor Readings
              _buildHeroSection(),
              const SizedBox(height: 20),

              // Status Cards Row
              _buildStatusCardsRow(),
              const SizedBox(height: 20),

              // RGB Control Card
              _buildRGBControlCard(),
              const SizedBox(height: 20),

              // Growth Stage Card
              _buildGrowthStageCard(),
              const SizedBox(height: 20),

              // Photoperiod Card
              _buildPhotoperiodCard(),
              const SizedBox(height: 20),

              // Oil Yield Prediction Card
              _buildOilYieldCard(),
              const SizedBox(height: 20),

              // Health Check and Recommendations Buttons
              _buildActionButtons(),
              const SizedBox(height: 24),

              // Recent Activity
              _buildRecentActivity(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: textDark, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Lavender ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const TextSpan(
                    text: 'AI',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: textDark,
                    ),
                  ),
                  const TextSpan(
                    text: '🌿',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              color: primaryOrange,
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              color: textDark,
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.menu),
              color: textDark,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9).withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            // Curved green background
            Positioned(
              top: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: CustomPaint(
                  size: const Size(200, 350),
                  painter: CurvedGreenPainter(),
                ),
              ),
            ),
            // Lavender plant illustration
            Positioned(
              top: 20,
              right: 10,
              child: _buildLavenderPlant(),
            ),
            // Sensor readings
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSensorReading(
                          icon: Icons.thermostat_outlined,
                          iconBgColor: const Color(0xFFDCFCE7),
                          iconColor: primaryGreen,
                          label: 'Air Temperature',
                          value: _latestSensor != null
                              ? '${_latestSensor!.temperature.toStringAsFixed(1)}°C'
                              : '--°C',
                        ),
                        const SizedBox(height: 16),
                        _buildSensorReading(
                          icon: Icons.water_drop_outlined,
                          iconBgColor: const Color(0xFFE0F2FE),
                          iconColor: primaryBlue,
                          label: 'Humidity',
                          value: _latestSensor != null
                              ? '${_latestSensor!.humidity.toStringAsFixed(0)}%'
                              : '--%',
                        ),
                        const SizedBox(height: 16),
                        _buildSensorReading(
                          icon: Icons.wb_sunny_outlined,
                          iconBgColor: const Color(0xFFFEF3C7),
                          iconColor: primaryOrange,
                          label: 'Light Intensity',
                          value: _latestSensor != null
                              ? '${_latestSensor!.lightIntensity.toStringAsFixed(0)} lux'
                              : '-- lux',
                        ),
                        const SizedBox(height: 16),
                        _buildSensorReading(
                          icon: Icons.science_outlined,
                          iconBgColor: const Color(0xFFF3E5F5),
                          iconColor: primaryPurple,
                          label: 'Soil pH',
                          value: '6.5', // dummy
                        ),
                      ],
                    ),
                  ),
                  const Expanded(flex: 2, child: SizedBox()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLavenderPlant() {
    return SizedBox(
      width: 200,
      height: 350,
      child: Image.asset(
        'assets/images/lavender.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon-based lavender if image not found
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Transform.rotate(angle: -0.2, child: _buildLavenderStalk(80)),
                  Transform.rotate(angle: -0.1, child: _buildLavenderStalk(100)),
                  _buildLavenderStalk(110),
                  Transform.rotate(angle: 0.1, child: _buildLavenderStalk(95)),
                  Transform.rotate(angle: 0.25, child: _buildLavenderStalk(85)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.rotate(
                    angle: -0.5,
                    child: Icon(Icons.eco, size: 30, color: Colors.green[600]),
                  ),
                  Icon(Icons.eco, size: 35, color: Colors.green[700]),
                  Transform.rotate(
                    angle: 0.5,
                    child: Icon(Icons.eco, size: 30, color: Colors.green[600]),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLavenderStalk(double height) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 6; i++)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 1),
            child: Icon(
              Icons.water_drop,
              size: height / 10,
              color: Color.lerp(
                const Color(0xFF9C27B0),
                const Color(0xFF7B1FA2),
                i / 6,
              ),
            ),
          ),
        Container(
          width: 2,
          height: height * 0.35,
          decoration: BoxDecoration(
            color: Colors.green[600],
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  Widget _buildSensorReading({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: textGrey),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCardsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            title: 'Red LED',
            subtitle: '${_lightingState.red}/255',
            status: _lightingState.red > 0 ? 'ON' : 'OFF',
            icon: Icons.lightbulb,
            iconColor: Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            title: 'Blue LED',
            subtitle: '${_lightingState.blue}/255',
            status: _lightingState.blue > 0 ? 'ON' : 'OFF',
            icon: Icons.lightbulb,
            iconColor: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            title: 'White LED',
            subtitle: '${_lightingState.white}/255',
            status: _lightingState.white > 0 ? 'ON' : 'OFF',
            icon: Icons.lightbulb,
            iconColor: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String subtitle,
    required String status,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: textGrey)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textDark)),
          const SizedBox(height: 2),
          Text(status.isNotEmpty ? status : ' ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textDark)),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildRGBControlCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('RGB Spectrum Control', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 16),
            _buildSliderTile('Red', _lightingState.red, Colors.red, (val) {
              setState(() => _lightingState = _lightingState.copyWith(red: val.round()));
              _updateLighting();
            }),
            _buildSliderTile('Blue', _lightingState.blue, Colors.blue, (val) {
              setState(() => _lightingState = _lightingState.copyWith(blue: val.round()));
              _updateLighting();
            }),
            _buildSliderTile('White', _lightingState.white, Colors.grey, (val) {
              setState(() => _lightingState = _lightingState.copyWith(white: val.round()));
              _updateLighting();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderTile(String label, int value, Color color, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('$value', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 0,
          max: 255,
          divisions: 255,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildGrowthStageCard() {
    String stageName;
    switch (_lightingState.stage) {
      case GrowthStage.germination: stageName = 'Germination'; break;
      case GrowthStage.seedling: stageName = 'Seedling'; break;
      case GrowthStage.vegetative: stageName = 'Vegetative'; break;
      case GrowthStage.flowering: stageName = 'Flowering'; break;
      case GrowthStage.oilMaturation: stageName = 'Oil Maturation'; break;
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Growth Stage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Stage', style: const TextStyle(fontSize: 12, color: textGrey)),
                    Text(stageName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryGreen)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GrowthStageScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Change'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoperiodCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: primaryGreen, size: 20),
                const SizedBox(width: 8),
                const Text('Photoperiod Scheduling', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Enable Schedule'),
              value: _photoperiodEnabled,
              onChanged: (val) {
                setState(() => _photoperiodEnabled = val);
                _updatePhotoperiod();
              },
              activeColor: primaryGreen,
              contentPadding: EdgeInsets.zero,
            ),
            if (_photoperiodEnabled) ...[
              ListTile(
                title: const Text('Light On', style: TextStyle(fontSize: 14)),
                subtitle: Text(_lightOn.format(context)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () async {
                    final picked = await showTimePicker(context: context, initialTime: _lightOn);
                    if (picked != null) {
                      setState(() => _lightOn = picked);
                      _updatePhotoperiod();
                    }
                  },
                ),
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                title: const Text('Light Off', style: TextStyle(fontSize: 14)),
                subtitle: Text(_lightOff.format(context)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () async {
                    final picked = await showTimePicker(context: context, initialTime: _lightOff);
                    if (picked != null) {
                      setState(() => _lightOff = picked);
                      _updatePhotoperiod();
                    }
                  },
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOilYieldCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: Colors.amber[800]),
                const SizedBox(width: 8),
                const Text('Oil Yield Prediction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estimated per plant:'),
                Text(
                  '$_predictedOilYield ml',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _predictedOilYield / 5.0,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 4),
            const Text('Based on current spectrum and growth stage.', style: TextStyle(fontSize: 12, color: textGrey)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Provide default mock data since we're just viewing the dashboard
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DiagnosticScreen(
                    analysisResult: {
                      'dashboardSummary': {'healthScore': 85.0},
                      'intelligentDiagnosis': {
                        'emergencyLevel': {'level': 'low', 'message': 'MONITOR REGULARLY'},
                        'verdict': 'PLANT IS HEALTHY',
                      },
                      'visualAssessment': {
                        'cnnPrediction': 'healthy',
                        'confidence': 0.85,
                        'message': 'Plant appears healthy',
                      },
                      'crossVerification': {
                        'matchPercentage': 92.5,
                        'confidence': 'high',
                      },
                      'sensorReadings': {
                        'raw': _latestSensor?.toJson() ?? {},
                      },
                      'recommendations': {'priorityOrder': []},
                    },
                    sensorData: _latestSensor?.toJson() ?? {},
                  ),
                ),
              );
            },
            icon: const Icon(Icons.health_and_safety),
            label: const Text('Health Check'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecommendationScreen()),
              );
            },
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('Tips'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SensorChartScreen()),
              );
            },
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('Charts'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
            Row(
              children: [
                Text('View All', style: TextStyle(fontSize: 13, color: textGrey)),
                const SizedBox(width: 4),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
                  child: const Icon(Icons.arrow_forward, size: 14, color: textGrey),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          icon: Icons.lightbulb,
          iconBgColor: const Color(0xFFFCE7F3),
          iconColor: const Color(0xFFEC4899),
          title: 'Spectrum changed to Vegetative',
          time: '10 mins ago',
        ),
        _buildActivityItem(
          icon: Icons.schedule,
          iconBgColor: const Color(0xFFE0F2FE),
          iconColor: primaryBlue,
          title: 'Photoperiod updated',
          time: '25 mins ago',
        ),
        _buildActivityItem(
          icon: Icons.analytics,
          iconBgColor: const Color(0xFFDCFCE7),
          iconColor: primaryGreen,
          title: 'Oil yield prediction updated',
          time: '1 hour ago',
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFCFCFC)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textDark)),
                const SizedBox(height: 2),
                Text(time, style: const TextStyle(fontSize: 12, color: textGrey)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 20),
        ],
      ),
    );
  }
}

// Reusable painter from ClimateScreen
class CurvedGreenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD5F5E3)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.3, 0);
    path.quadraticBezierTo(
      size.width * 0.1,
      size.height * 0.3,
      size.width * 0.2,
      size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.9,
      size.width,
      size.height * 0.8,
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}