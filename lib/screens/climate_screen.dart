import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'venting_mode_screen.dart';
import 'analytics_report_screen.dart';
import 'humidity_mode_screen.dart';
import 'activity_history_screen.dart';
import '../services/climate_api_service.dart';
import '../services/climate_data_service.dart';
import '../services/sensor_data_service.dart';

class ClimateScreen extends StatefulWidget {
  const ClimateScreen({super.key});

  @override
  State<ClimateScreen> createState() => _ClimateScreenState();
}

class _ClimateScreenState extends State<ClimateScreen> {
  int _selectedMode = 0; // 0 = Venting, 1 = Humidity

  // Colors
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryGreen = Color(0xFF22C55E);
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryOrange = Color(0xFFFF7A45);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color cardBackground = Colors.white;

  // ── Climate API State ──
  bool _isServerConnected = false;
  bool _isLoading = false;
  ClimatePrediction? _prediction;
  Timer? _refreshTimer;
  DateTime? _lastUpdated;

  // Current sensor readings (live from backend /sensors endpoint)
  double _airTemp = 0.0;
  double _humidity = 0.0;
  double _soilTemp = 0.0;
  bool _hasSensorData = false; // true once we receive sensor data
  StreamSubscription? _sensorSubscription;

  // Target values (user-configurable)
  double _targetTemp = 24.0;
  double _targetHumidity = 65.0;

  // Previous prediction values (fed back into next prediction)
  double _prevFanSpeed = 0.0;
  double _prevHumidifierMode = 0.0;

  // Recent activity log from API updates
  final List<_ActivityEntry> _recentActivities = [];

  // Chart data loaded from Firestore
  List<double> _chartHumidity = [];
  List<double> _chartVentilation = [];
  List<double> _chartTemperature = [];
  List<String> _chartLabels = [];

  // Firestore-based recent activities
  List<_ActivityEntry> _firestoreActivities = [];

  @override
  void initState() {
    super.initState();
    _initClimateApi();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _sensorSubscription?.cancel();
    SensorDataService.stopPolling();
    super.dispose();
  }

  Future<void> _initClimateApi() async {
    // 1) Subscribe to live sensor data from backend GET /sensors
    _subscribeSensorData();

    // 2) Load last saved prediction from Firestore (offline fallback for fan/humidifier)
    await _loadLastKnownPrediction();

    // 3) Debug Firestore state, then load overview chart data + recent activities
    await ClimateDataService.debugCheckCollection();
    _loadOverviewChartData();
    _loadFirestoreActivities();

    // 4) Check API server & run first prediction
    await _checkServerConnection();
    if (_isServerConnected) {
      await _fetchPrediction();
    }

    // Auto-refresh prediction every 15 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      await _checkServerConnection();
      if (_isServerConnected) {
        await _fetchPrediction();
      }
      _loadOverviewChartData();
      _loadFirestoreActivities();
    });
  }

  /// Subscribe to live sensor readings from backend /sensors endpoint.
  /// The ESP32 pushes sensor data to /predict, backend stores it,
  /// and we poll /sensors every 5 seconds to get the latest values.
  void _subscribeSensorData() {
    _sensorSubscription = SensorDataService.streamLatestReading(
      intervalSeconds: 5,
    ).listen(
      (reading) {
        if (reading != null && reading.hasData && mounted) {
          setState(() {
            _airTemp = reading.airTemp;
            _humidity = reading.humidity;
            _soilTemp = reading.soilTemp;
            _hasSensorData = true;
          });
          print('📡 Live sensor data: air=${reading.airTemp}°C, humidity=${reading.humidity}%, soil=${reading.soilTemp}°C');
        }
      },
      onError: (e) {
        print('⚠️ Sensor stream error: $e');
      },
    );
  }

  /// Load last saved prediction from Firestore (for fan/humidifier offline fallback).
  Future<void> _loadLastKnownPrediction() async {
    try {
      final lastReading = await ClimateDataService.getLatestReading();
      if (lastReading != null && mounted) {
        setState(() {
          _prediction = lastReading;
          _prevFanSpeed = lastReading.fanSpeed;
          _prevHumidifierMode = lastReading.humidifierMode.toDouble();
          // Only use saved sensor values if we don't have live data yet
          if (!_hasSensorData) {
            _airTemp = lastReading.airTemp;
            _humidity = lastReading.humidity;
            _soilTemp = lastReading.soilTemp;
            _hasSensorData = true;
          }
        });
      }
    } catch (e) {
      print('⚠️ Failed to load last known prediction: $e');
    }
  }

  Future<void> _checkServerConnection() async {
    final connected = await ClimateApiService.checkHealth();
    if (mounted) {
      setState(() => _isServerConnected = connected);
    }
  }

  Future<void> _fetchPrediction() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final result = await ClimateApiService.predict(
      airTemp: _airTemp,
      humidity: _humidity,
      soilTemp: _soilTemp,
      targetTemp: _targetTemp,
      targetHumidity: _targetHumidity,
      prevFanSpeed: _prevFanSpeed,
      prevHumidifierMode: _prevHumidifierMode,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _lastUpdated = DateTime.now();
        if (result != null) {
          // Track changes for activity log
          if (_prediction != null) {
            if (result.effectiveFanSpeed != _prediction!.effectiveFanSpeed) {
              _addActivity(
                Icons.air,
                const Color(0xFFFCE7F3),
                const Color(0xFFEC4899),
                'Fan speed: ${result.effectiveFanSpeed.toStringAsFixed(0)}% (${result.fanMode})',
              );
            }
            if (result.humidifierMode != _prediction!.humidifierMode) {
              _addActivity(
                Icons.water_drop_outlined,
                const Color(0xFFE0F2FE),
                primaryBlue,
                'Humidity set to ${result.humidifierLabel}',
              );
            }
          }
          _prediction = result;
          _prevFanSpeed = result.fanSpeed;
          _prevHumidifierMode = result.humidifierMode.toDouble();
          // Sensor readings come from Firestore stream, not from API response
        }
      });

      // Save to Firestore (outside setState, fire-and-forget)
      if (result != null) {
        ClimateDataService.saveReading(
          prediction: result,
          targetTemp: _targetTemp,
          targetHumidity: _targetHumidity,
        );
      }
    }
  }

  /// Load overview chart data from Firestore climate_readings.
  Future<void> _loadOverviewChartData() async {
    try {
      print('📈 _loadOverviewChartData: starting fetch...');
      final readings = await ClimateDataService.getReadingsForPeriod('7days');
      print('📈 Overview chart: got ${readings.length} readings');
      if (readings.isNotEmpty) {
        print('📈 First reading: airTemp=${readings.first.airTemp}, humidity=${readings.first.humidity}, ts=${readings.first.timestamp}');
        print('📈 Last reading: airTemp=${readings.last.airTemp}, humidity=${readings.last.humidity}, ts=${readings.last.timestamp}');
      }
      if (readings.isEmpty || !mounted) return;
      final sampled = ClimateDataService.downsample(readings, 12);
      final hum = sampled.map((r) => r.humidity).toList();
      final vent = sampled.map((r) => r.fanSpeed).toList();
      final temp = sampled.map((r) => r.airTemp).toList();
      final labels = sampled.map((r) {
        if (r.timestamp != null) {
          return DateFormat('dd/MM').format(r.timestamp!);
        }
        return '';
      }).toList();
      if (mounted) {
        setState(() {
          _chartHumidity = hum;
          _chartVentilation = vent;
          _chartTemperature = temp;
          _chartLabels = labels;
        });
      }
    } catch (e, stack) {
      print('⚠️ Failed to load overview chart data: $e');
      print('⚠️ Stack: $stack');
    }
  }

  /// Load recent activities from Firestore climate_readings.
  Future<void> _loadFirestoreActivities() async {
    try {
      final readings = await ClimateDataService.getReadingsForPeriod('today');
      if (!mounted) return;
      final recent = readings.reversed.take(10).toList();
      final activities = <_ActivityEntry>[];
      for (final r in recent) {
        final rawData = <String, dynamic>{
          'air_temp': r.airTemp,
          'humidity': r.humidity,
          'soil_temp': r.soilTemp,
          'fan_speed': r.fanSpeed,
          'effective_fan_speed': r.fanSpeed,
          'fan_mode': r.fanMode,
          'humidifier_mode': r.humidifierMode,
          'effective_humidifier_level': r.effectiveHumidifierLevel,
          'humidifier_control_mode': r.humidifierControlMode,
        };
        // Fan change entry
        activities.add(_ActivityEntry(
          icon: Icons.air,
          iconBgColor: const Color(0xFFFCE7F3),
          iconColor: const Color(0xFFEC4899),
          title: 'Fan ${r.fanMode} - ${r.fanSpeed.toStringAsFixed(0)}%',
          time: r.timestamp ?? DateTime.now(),
          rawData: rawData,
        ));
        // Temperature entry
        activities.add(_ActivityEntry(
          icon: Icons.thermostat_outlined,
          iconBgColor: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFF59E0B),
          title: 'Temp: ${r.airTemp.toStringAsFixed(1)}°C | Soil: ${r.soilTemp.toStringAsFixed(1)}°C',
          time: r.timestamp ?? DateTime.now(),
          rawData: rawData,
        ));
        // Humidity entry
        activities.add(_ActivityEntry(
          icon: Icons.water_drop_outlined,
          iconBgColor: const Color(0xFFE0F2FE),
          iconColor: const Color(0xFF3B82F6),
          title: 'Humidity: ${r.humidity.toStringAsFixed(1)}%',
          time: r.timestamp ?? DateTime.now(),
          rawData: rawData,
        ));
      }
      if (mounted) {
        setState(() {
          _firestoreActivities = activities;
        });
      }
    } catch (e) {
      print('⚠️ Failed to load Firestore activities: $e');
    }
  }

  void _addActivity(IconData icon, Color bgColor, Color iconColor, String title) {
    _recentActivities.insert(0, _ActivityEntry(
      icon: icon,
      iconBgColor: bgColor,
      iconColor: iconColor,
      title: title,
      time: DateTime.now(),
    ));
    // Keep only last 10 activities
    if (_recentActivities.length > 10) {
      _recentActivities.removeLast();
    }
  }

  String _getRelativeTime(int minutesAgo) {
    if (minutesAgo < 60) {
      return '$minutesAgo mins ago';
    } else {
      final hours = (minutesAgo / 60).floor();
      return '$hours hour${hours > 1 ? 's' : ''} ago';
    }
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Main Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchPrediction,
                color: primaryPurple,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Connection banner (shown when disconnected)
                      if (!_isServerConnected) _buildConnectionBanner(),
                      // Climate Hero Section with readings
                      _buildClimateHeroSection(),
                    const SizedBox(height: 20),
                    // Status Cards Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildStatusCardsRow(),
                    ),
                    const SizedBox(height: 20),
                    // Mode Toggle Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildModeToggle(),
                    ),
                    const SizedBox(height: 24),
                    // Overview Section with Chart
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildOverviewSection(),
                    ),
                    const SizedBox(height: 20),
                    // View Analytics Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildAnalyticsButton(),
                    ),
                    const SizedBox(height: 24),
                    // Recent Activity
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildRecentActivity(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryOrange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryOrange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, color: primaryOrange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Climate Server Offline',
                  style: TextStyle(
                    color: primaryOrange,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Text(
                  'Showing last known values',
                  style: TextStyle(fontSize: 11, color: textGrey),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              splashColor: primaryOrange.withOpacity(0.2),
              highlightColor: primaryOrange.withOpacity(0.1),
              onTap: _checkServerConnection,
              child: Ink(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.refresh, color: primaryOrange, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
          // Connection status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isServerConnected
                  ? primaryGreen.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _isServerConnected ? primaryGreen : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _isServerConnected ? 'Live' : 'Offline',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _isServerConnected ? primaryGreen : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
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
    );
  }

  Widget _buildClimateHeroSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
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
              // Lavender plant illustration (right side)
              Positioned(
                top: 20,
                right: 10,
            child: _buildLavenderPlant(),
          ),
          // Sensor readings - full width
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
                        label: 'Green House Temperature',
                        value: _hasSensorData
                            ? '${_airTemp.toStringAsFixed(1)}°C'
                            : 'Waiting...',
                      ),
                      const SizedBox(height: 16),
                      _buildSensorReading(
                        icon: Icons.thermostat_outlined,
                        iconBgColor: const Color(0xFFDCFCE7),
                        iconColor: primaryGreen,
                        label: 'Soil Temperature',
                        value: _hasSensorData
                            ? '${_soilTemp.toStringAsFixed(1)}°C'
                            : 'Waiting...',
                      ),
                      const SizedBox(height: 16),
                      _buildSensorReading(
                        icon: Icons.water_drop_outlined,
                        iconBgColor: const Color(0xFFE0F2FE),
                        iconColor: primaryBlue,
                        label: 'Humidity',
                        value: _hasSensorData
                            ? '${_humidity.toStringAsFixed(1)}%'
                            : 'Waiting...',
                      ),
                      const SizedBox(height: 16),
                      _buildSensorReading(
                        icon: Icons.science_outlined,
                        iconBgColor: const Color(0xFFF3E5F5),
                        iconColor: primaryPurple,
                        label: 'pH Level',
                        value: '6.5',
                      ),
                      const SizedBox(height: 16),
                      _buildSensorReading(
                        icon: Icons.air,
                        iconBgColor: const Color(0xFFF3E5F5),
                        iconColor: primaryPurple,
                        label: 'Fan Speed',
                        value: _prediction != null
                            ? '${_prediction!.effectiveFanSpeed.toStringAsFixed(1)}%'
                            : 'Waiting...',
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                // Spacer for lavender plant area
                const Expanded(
                  flex: 2,
                  child: SizedBox(),
                ),
              ],
            ),
          ),
            ],
          ),
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
                  Transform.rotate(
                    angle: -0.2,
                    child: _buildLavenderStalk(80),
                  ),
                  Transform.rotate(
                    angle: -0.1,
                    child: _buildLavenderStalk(100),
                  ),
                  _buildLavenderStalk(110),
                  Transform.rotate(
                    angle: 0.1,
                    child: _buildLavenderStalk(95),
                  ),
                  Transform.rotate(
                    angle: 0.25,
                    child: _buildLavenderStalk(85),
                  ),
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
        // Flower buds
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
        // Stem
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
      mainAxisSize: MainAxisSize.min,
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
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: textGrey,
                ),
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
    final fanMode = _prediction?.fanMode ?? 'auto';
    final effectiveSpeed = _prediction?.effectiveFanSpeed ?? 0;
    final fanOn = effectiveSpeed > 0;
    final humMode = _prediction?.effectiveHumidifierLevel ?? 0;
    final humOn = humMode > 0;

    // Fan subtitle based on mode
    String fanSubtitle;
    switch (fanMode) {
      case 'off':
        fanSubtitle = 'Mode: Off';
        break;
      case 'manual':
        fanSubtitle = fanOn ? 'Manual ${effectiveSpeed.toStringAsFixed(0)}%' : 'Manual (Off)';
        break;
      case 'auto':
        fanSubtitle = fanOn ? 'Auto ${effectiveSpeed.toStringAsFixed(0)}%' : 'Auto (Idle)';
        break;
      default:
        fanSubtitle = 'Waiting';
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            title: 'Fan',
            subtitle: fanSubtitle,
            status: fanOn ? 'ON' : 'OFF',
            icon: Icons.air,
            iconColor: fanOn ? primaryGreen : Colors.grey,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            title: 'Temp Sensors',
            subtitle: _isServerConnected ? 'Connected' : 'Offline',
            status: '',
            icon: Icons.thermostat_outlined,
            iconColor: _isServerConnected ? primaryGreen : Colors.grey,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            title: 'Humidifier',
            subtitle: _prediction != null
                ? _prediction!.humidifierLabel
                : 'Waiting',
            status: humOn ? 'ON' : 'OFF',
            icon: Icons.water_drop_outlined,
            iconColor: humOn ? primaryBlue : Colors.grey,
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
          colors: [
            Colors.white,
            Color(0xFFFAFAFA),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: textGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            status.isNotEmpty ? status : ' ',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              splashColor: Colors.white.withOpacity(0.2),
              highlightColor: Colors.white.withOpacity(0.1),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VentingModeScreen(
                    initialFanLevel: _prediction?.fanLevel,
                    currentAirTemp: _airTemp,
                    currentHumidity: _humidity,
                    currentSoilTemp: _soilTemp,
                    targetTemp: _targetTemp,
                    targetHumidity: _targetHumidity,
                    prevFanSpeed: _prevFanSpeed,
                    prevHumidifierMode: _prevHumidifierMode,
                  )),
                );
              },
              child: Ink(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: _selectedMode == 0
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF9D6FFF),
                            Color(0xFF7C3AED),
                          ],
                        )
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                          Colors.white,
                          Color(0xFFF5F5F5),
                        ],
                      ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _selectedMode == 0 ? Colors.transparent : Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _selectedMode == 0
                        ? primaryPurple.withOpacity(0.4)
                        : Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: _selectedMode == 0
                        ? primaryPurple.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.air,
                    color: _selectedMode == 0 ? Colors.white : textGrey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Venting Mode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _selectedMode == 0 ? Colors.white : textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              splashColor: Colors.white.withOpacity(0.2),
              highlightColor: Colors.white.withOpacity(0.1),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HumidityModeScreen(
                    initialHumidifierMode: _prediction?.humidifierMode,
                    initialHumidifierControlMode: _prediction?.humidifierControlMode,
                    currentAirTemp: _airTemp,
                    currentHumidity: _humidity,
                    currentSoilTemp: _soilTemp,
                    targetTemp: _targetTemp,
                    targetHumidity: _targetHumidity,
                    prevFanSpeed: _prevFanSpeed,
                    prevHumidifierMode: _prevHumidifierMode,
                  )),
                );
              },
              child: Ink(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: _selectedMode == 1
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF9D6FFF),
                            Color(0xFF7C3AED),
                          ],
                        )
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Color(0xFFF5F5F5),
                        ],
                      ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _selectedMode == 1 ? Colors.transparent : Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _selectedMode == 1
                        ? primaryPurple.withOpacity(0.4)
                        : Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: _selectedMode == 1
                        ? primaryPurple.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    color: _selectedMode == 1 ? Colors.white : textGrey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Humidity Mode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _selectedMode == 1 ? Colors.white : textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ],
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        const SizedBox(height: 12),
        // Legend
        Row(
          children: [
            _buildLegendItem(primaryBlue, 'Humidity'),
            const SizedBox(width: 20),
            _buildLegendItem(primaryPurple, 'Ventilation'),
            const SizedBox(width: 20),
            _buildLegendItem(primaryGreen, 'Temperature'),
          ],
        ),
        const SizedBox(height: 16),
        // Chart
        Container(
          height: 200,
          width: double.infinity,
          child: _chartHumidity.isNotEmpty
              ? CustomPaint(
                  painter: ChartPainter(
                    humidityData: _chartHumidity,
                    ventilationData: _chartVentilation,
                    temperatureData: _chartTemperature,
                    xLabels: _chartLabels,
                  ),
                )
              : const Center(
                  child: Text(
                    'Loading chart data...',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF34D399),
            Color(0xFF22C55E),
            Color(0xFF16A34A),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: primaryGreen.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AnalyticsReportScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: const Text(
          'View Analytics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                splashColor: primaryPurple.withOpacity(0.15),
                highlightColor: primaryPurple.withOpacity(0.08),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ActivityHistoryScreen(filter: 'climate'),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 13,
                          color: primaryPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryPurple.withOpacity(0.3)),
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: primaryPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Show Firestore activities first, then API-driven activities, then defaults
        if (_firestoreActivities.isNotEmpty)
          ..._firestoreActivities.take(6).map((activity) => _buildActivityItem(
            icon: activity.icon,
            iconBgColor: activity.iconBgColor,
            iconColor: activity.iconColor,
            title: activity.title,
            time: _formatTimeAgo(activity.time),
            onTap: () => showActivityDetailSheet(
              context,
              icon: activity.icon,
              iconBgColor: activity.iconBgColor,
              iconColor: activity.iconColor,
              title: activity.title,
              time: activity.time,
              source: 'climate',
              rawData: activity.rawData,
            ),
          ))
        else if (_recentActivities.isNotEmpty)
          ..._recentActivities.take(4).map((activity) => _buildActivityItem(
            icon: activity.icon,
            iconBgColor: activity.iconBgColor,
            iconColor: activity.iconColor,
            title: activity.title,
            time: _formatTimeAgo(activity.time),
            onTap: () => showActivityDetailSheet(
              context,
              icon: activity.icon,
              iconBgColor: activity.iconBgColor,
              iconColor: activity.iconColor,
              title: activity.title,
              time: activity.time,
              source: 'climate',
              rawData: activity.rawData,
            ),
          ))
        // Default items when no Firestore or API activities yet
        else ...[
          _buildActivityItem(
            icon: Icons.cloud_outlined,
            iconBgColor: const Color(0xFFE0F2FE),
            iconColor: primaryBlue,
            title: _isServerConnected
                ? 'Connected to climate server'
                : 'Waiting for server connection',
            time: _lastUpdated != null ? _formatTimeAgo(_lastUpdated!) : 'Now',
          ),
          if (_prediction != null)
            _buildActivityItem(
              icon: Icons.air,
              iconBgColor: const Color(0xFFFCE7F3),
              iconColor: const Color(0xFFEC4899),
              title: 'Fan speed: ${_prediction!.fanSpeed.toStringAsFixed(1)}%',
              time: _lastUpdated != null ? _formatTimeAgo(_lastUpdated!) : 'Now',
            ),
          if (_prediction != null)
            _buildActivityItem(
              icon: Icons.water_drop_outlined,
              iconBgColor: const Color(0xFFE0F2FE),
              iconColor: primaryBlue,
              title: 'Humidifier: ${_prediction!.humidifierLabel}',
              time: _lastUpdated != null ? _formatTimeAgo(_lastUpdated!) : 'Now',
            ),
          _buildActivityItem(
            icon: Icons.thermostat_outlined,
            iconBgColor: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFF59E0B),
            title: _hasSensorData
                ? 'Air temp: ${_airTemp.toStringAsFixed(1)}°C | Soil: ${_soilTemp.toStringAsFixed(1)}°C'
                : 'Waiting for sensor data...',
            time: _lastUpdated != null ? _formatTimeAgo(_lastUpdated!) : 'Now',
          ),
        ],
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String time,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: iconColor.withOpacity(0.1),
        highlightColor: iconColor.withOpacity(0.05),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xFFFCFCFC),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: textGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade300,
              size: 20,
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }
}

/// Internal model for tracking recent activity entries.
class _ActivityEntry {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final DateTime time;
  final Map<String, dynamic> rawData;

  _ActivityEntry({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.time,
    this.rawData = const {},
  });
}

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

class ChartPainter extends CustomPainter {
  final List<double> humidityData;
  final List<double> ventilationData;
  final List<double> temperatureData;
  final List<String> xLabels;

  ChartPainter({
    required this.humidityData,
    required this.ventilationData,
    required this.temperatureData,
    required this.xLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final yLabels = ['0', '10', '20', '30', '40', '50', '60', '70', '80', '90', '100'];
    final dataLen = humidityData.length;
    if (dataLen == 0) return;

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    // Draw Y axis labels
    for (int i = 0; i <= 10; i++) {
      textPainter.text = TextSpan(
        text: yLabels[i],
        style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
      );
      textPainter.layout();
      final y = size.height - 20 - (i * (size.height - 30) / 10);
      textPainter.paint(canvas, Offset(0, y - 5));
    }

    // Draw X axis labels
    final chartWidth = size.width - 30;
    final step = dataLen > 1 ? chartWidth / (dataLen - 1) : chartWidth;
    for (int i = 0; i < xLabels.length; i++) {
      textPainter.text = TextSpan(
        text: xLabels[i],
        style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280)),
      );
      textPainter.layout();
      final x = 30 + (i * step);
      textPainter.paint(canvas, Offset(x - 10, size.height - 15));
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 10; i++) {
      final y = size.height - 20 - (i * (size.height - 30) / 10);
      canvas.drawLine(Offset(30, y), Offset(size.width, y), gridPaint);
    }

    // Draw lines
    _drawLine(canvas, size, humidityData, const Color(0xFF3B82F6));
    _drawLine(canvas, size, ventilationData, const Color(0xFF8B5CF6));
    _drawLine(canvas, size, temperatureData, const Color(0xFF22C55E));

    // Draw last-point marker for humidity
    if (humidityData.isNotEmpty) {
      final lastIdx = humidityData.length - 1;
      final markerX = 30 + (lastIdx * step);
      final chartHeight = size.height - 30;
      final markerY = size.height - 20 - (humidityData[lastIdx].clamp(0, 100) * chartHeight / 100);
      canvas.drawCircle(Offset(markerX, markerY), 5, Paint()..color = const Color(0xFF3B82F6));
      canvas.drawCircle(Offset(markerX, markerY), 3, Paint()..color = Colors.white);
    }
  }

  void _drawLine(Canvas canvas, Size size, List<double> data, Color color) {
    if (data.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final chartWidth = size.width - 30;
    final chartHeight = size.height - 30;
    final step = data.length > 1 ? chartWidth / (data.length - 1) : chartWidth;

    for (int i = 0; i < data.length; i++) {
      final x = 30 + (i * step);
      final y = size.height - 20 - (data[i].clamp(0, 100) * chartHeight / 100);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) =>
      humidityData != oldDelegate.humidityData ||
      ventilationData != oldDelegate.ventilationData ||
      temperatureData != oldDelegate.temperatureData;
}
