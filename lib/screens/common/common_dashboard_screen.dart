import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../climate/climate_main_screen.dart';
import 'common_login_screen.dart';
import 'common_profile_screen.dart';
import 'common_settings_screen.dart';
import 'common_activity_history_screen.dart';
import '../lighting/lighting_control_screen.dart';
import '../disease/disease_main_menu_screen.dart';
import '../soil/soil_health_dashboard_screen.dart';
import '../../services/climate_api_service.dart';
import '../../services/climate_data_service.dart';
import '../../services/soil_backend_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTabIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _profileImageUrl;

  // Recent activities from Firestore
  List<ActivityItem> _recentActivities = [];
  bool _isLoadingActivities = true;

  // Monitor tab data
  bool _isLoadingMonitor = true;
  ClimatePrediction? _latestClimate;
  double? _latestSoilMoisture;
  Map<String, dynamic>? _latestDiseaseScan;
  bool _climateConnected = false;
  bool _soilConnected = false;

  // Alerts tab data
  bool _isLoadingAlerts = true;
  List<Map<String, dynamic>> _alerts = [];

  // Home card dynamic data
  int _todayDiseaseScans = 0;
  int _totalDiseaseScans = 0;
  int _totalWateringEvents = 0;

  // Colors
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryOrange = Color(0xFFFF7A45);
  static const Color primaryGreen = Color(0xFF22C55E);
  static const Color primaryYellow = Color(0xFFFBBF24);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color cardBackground = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadRecentActivities();
    _loadMonitorData();
    _loadAlerts();
    _loadHomeCardStats();
  }

  Future<void> _loadRecentActivities() async {
    try {
      final uid = _auth.currentUser?.uid;
      final activities = <ActivityItem>[];

      // Load climate activities
      try {
        Query<Map<String, dynamic>> climateQuery = _firestore
            .collection('climate_readings')
            .orderBy('timestamp', descending: true)
            .limit(10);
        if (uid != null) {
          climateQuery = _firestore
              .collection('climate_readings')
              .where('user_id', isEqualTo: uid)
              .orderBy('timestamp', descending: true)
              .limit(10);
        }
        final climateSnap = await climateQuery.get();
        for (final doc in climateSnap.docs) {
          final d = doc.data();
          final ts = d['timestamp'];
          DateTime? time;
          if (ts is Timestamp) time = ts.toDate();
          if (time == null) continue;

          final airTemp = (d['air_temp'] as num?)?.toDouble() ?? 0.0;
          final humidity = (d['humidity'] as num?)?.toDouble() ?? 0.0;
          final soilTemp = (d['soil_temp'] as num?)?.toDouble() ?? 0.0;
          final fanSpeed = (d['effective_fan_speed'] as num?)?.toDouble() ??
              (d['fan_speed'] as num?)?.toDouble() ?? 0.0;
          final fanMode = d['fan_mode'] as String? ?? 'auto';
          final humLevel = (d['effective_humidifier_level'] as num?)?.toInt() ??
              (d['humidifier_mode'] as num?)?.toInt() ?? 0;
          final humLabels = ['Off', 'Low', 'Medium', 'High'];
          final humLabel = humLevel >= 0 && humLevel < humLabels.length
              ? humLabels[humLevel]
              : 'Off';

          activities.add(ActivityItem(
            icon: Icons.thermostat_outlined,
            iconBgColor: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFF59E0B),
            title: 'Temp: ${airTemp.toStringAsFixed(1)}°C | Humidity: ${humidity.toStringAsFixed(1)}%',
            subtitle: 'Fan: $fanMode ${fanSpeed.toStringAsFixed(0)}% · Humidifier: $humLabel · Soil: ${soilTemp.toStringAsFixed(1)}°C',
            time: time,
            source: 'climate',
            rawData: d,
          ));
        }
      } catch (e) {
        print('⚠️ Dashboard: Failed to load climate activities: $e');
      }

      // Load disease activities
      try {
        Query<Map<String, dynamic>> diseaseQuery = _firestore
            .collection('lavender_detections')
            .orderBy('timestamp', descending: true)
            .limit(10);
        if (uid != null) {
          diseaseQuery = _firestore
              .collection('lavender_detections')
              .where('user_id', isEqualTo: uid)
              .orderBy('timestamp', descending: true)
              .limit(10);
        }
        final diseaseSnap = await diseaseQuery.get();
        for (final doc in diseaseSnap.docs) {
          final d = doc.data();
          final ts = d['timestamp'] ?? d['date_time'];
          DateTime? time;
          if (ts is Timestamp) time = ts.toDate();
          if (time == null) continue;

          final status = d['overall_status'] as String? ?? 'Unknown';
          final diseaseCount = (d['disease_count'] as num?)?.toInt() ?? 0;
          final healthyCount = (d['healthy_count'] as num?)?.toInt() ?? 0;
          final totalCount = (d['detection_count'] as num?)?.toInt() ?? 0;
          final hasDisease = d['has_disease'] == true;

          activities.add(ActivityItem(
            icon: hasDisease ? Icons.warning_amber : Icons.check_circle_outline,
            iconBgColor: hasDisease ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
            iconColor: hasDisease ? const Color(0xFFEF4444) : primaryGreen,
            title: status,
            subtitle: 'Detections: $totalCount (Disease: $diseaseCount, Healthy: $healthyCount)',
            time: time,
            source: 'disease',
            rawData: d,
          ));
        }
      } catch (e) {
        print('⚠️ Dashboard: Failed to load disease activities: $e');
      }

      activities.sort((a, b) => b.time.compareTo(a.time));

      if (mounted) {
        setState(() {
          _recentActivities = activities;
          _isLoadingActivities = false;
        });
      }
    } catch (e) {
      print('⚠️ Dashboard: Failed to load activities: $e');
      if (mounted) setState(() => _isLoadingActivities = false);
    }
  }

  Future<void> _loadMonitorData() async {
    if (mounted) setState(() => _isLoadingMonitor = true);
    try {
      // Climate data
      try {
        final reading = await ClimateDataService.getLatestReading();
        _latestClimate = reading;
        _climateConnected = reading != null;
      } catch (e) {
        _climateConnected = false;
        print('⚠️ Monitor: Climate data load failed: $e');
      }

      // Soil moisture
      try {
        final moisture = await SoilBackendService.getMoisture();
        _latestSoilMoisture = moisture;
        _soilConnected = moisture != null;
      } catch (e) {
        _soilConnected = false;
        print('⚠️ Monitor: Soil data load failed: $e');
      }

      // Latest disease scan
      try {
        final uid = _auth.currentUser?.uid;
        Query<Map<String, dynamic>> q = _firestore
            .collection('lavender_detections')
            .orderBy('timestamp', descending: true)
            .limit(1);
        if (uid != null) {
          q = _firestore
              .collection('lavender_detections')
              .where('user_id', isEqualTo: uid)
              .orderBy('timestamp', descending: true)
              .limit(1);
        }
        final snap = await q.get();
        if (snap.docs.isNotEmpty) {
          _latestDiseaseScan = snap.docs.first.data();
        }
      } catch (e) {
        print('⚠️ Monitor: Disease data load failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoadingMonitor = false);
    }
  }

  Future<void> _loadHomeCardStats() async {
    try {
      final uid = _auth.currentUser?.uid;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      // Count today's disease scans
      try {
        Query<Map<String, dynamic>> q = _firestore
            .collection('lavender_detections')
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
            .orderBy('timestamp', descending: true);
        if (uid != null) {
          q = _firestore
              .collection('lavender_detections')
              .where('user_id', isEqualTo: uid)
              .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
              .orderBy('timestamp', descending: true);
        }
        final snap = await q.get();
        _todayDiseaseScans = snap.docs.length;
      } catch (e) {
        print('⚠️ HomeStats: today disease scans failed: $e');
      }

      // Count total disease scans
      try {
        Query<Map<String, dynamic>> q = _firestore
            .collection('lavender_detections')
            .orderBy('timestamp', descending: true);
        if (uid != null) {
          q = _firestore
              .collection('lavender_detections')
              .where('user_id', isEqualTo: uid)
              .orderBy('timestamp', descending: true);
        }
        final snap = await q.get();
        _totalDiseaseScans = snap.docs.length;
      } catch (e) {
        print('⚠️ HomeStats: total disease scans failed: $e');
      }

      // Count total watering events
      try {
        final wateringHistory = await SoilBackendService.getWateringHistory(limit: 100);
        _totalWateringEvents = wateringHistory.length;
      } catch (e) {
        print('⚠️ HomeStats: watering history failed: $e');
      }

      if (mounted) setState(() {});
    } catch (e) {
      print('⚠️ HomeStats load failed: $e');
    }
  }

  int _computeHealthScore() {
    int score = 0;
    int factors = 0;

    // Climate factor (40% weight): temp in 15-30°C range, humidity in 40-60%
    if (_latestClimate != null) {
      double tempScore = 100;
      final temp = _latestClimate!.airTemp;
      if (temp < 15) {
        tempScore = (temp / 15 * 100).clamp(0, 100);
      } else if (temp > 30) {
        tempScore = ((45 - temp) / 15 * 100).clamp(0, 100);
      }

      double humScore = 100;
      final hum = _latestClimate!.humidity;
      if (hum < 40) {
        humScore = (hum / 40 * 100).clamp(0, 100);
      } else if (hum > 60) {
        humScore = ((80 - hum) / 20 * 100).clamp(0, 100);
      }

      score += ((tempScore + humScore) / 2).round();
      factors++;
    }

    // Soil factor (30% weight): moisture in 30-50% range
    if (_latestSoilMoisture != null) {
      double soilScore = 100;
      final m = _latestSoilMoisture!;
      if (m < 30) {
        soilScore = (m / 30 * 100).clamp(0, 100);
      } else if (m > 50) {
        soilScore = ((70 - m) / 20 * 100).clamp(0, 100);
      }
      score += soilScore.round();
      factors++;
    }

    // Disease factor (30% weight): no disease = 100, has disease = 40
    if (_latestDiseaseScan != null) {
      final hasDisease = _latestDiseaseScan!['has_disease'] == true;
      score += hasDisease ? 40 : 100;
      factors++;
    }

    if (factors == 0) return 0;
    return (score / factors).round().clamp(0, 100);
  }

  Future<void> _loadAlerts() async {
    if (mounted) setState(() => _isLoadingAlerts = true);
    try {
      final alertsList = <Map<String, dynamic>>[];
      final uid = _auth.currentUser?.uid;

      // Disease alerts — scans where disease was found
      try {
        Query<Map<String, dynamic>> q = _firestore
            .collection('lavender_detections')
            .orderBy('timestamp', descending: true)
            .limit(20);
        if (uid != null) {
          q = _firestore
              .collection('lavender_detections')
              .where('user_id', isEqualTo: uid)
              .orderBy('timestamp', descending: true)
              .limit(20);
        }
        final snap = await q.get();
        for (final doc in snap.docs) {
          final d = doc.data();
          if (d['has_disease'] == true) {
            final ts = d['timestamp'] ?? d['date_time'];
            DateTime? time;
            if (ts is Timestamp) time = ts.toDate();
            alertsList.add({
              'type': 'disease',
              'severity': 'high',
              'title': 'Disease Detected',
              'subtitle': '${d['overall_status'] ?? 'Unknown'} — ${d['disease_count'] ?? 0} diseased plant(s)',
              'time': time ?? DateTime.now(),
              'icon': Icons.bug_report,
              'color': const Color(0xFFEF4444),
            });
          }
        }
      } catch (e) {
        print('⚠️ Alerts: Disease query failed: $e');
      }

      // Climate alerts — temperature or humidity out of range
      try {
        Query<Map<String, dynamic>> q = _firestore
            .collection('climate_readings')
            .orderBy('timestamp', descending: true)
            .limit(20);
        if (uid != null) {
          q = _firestore
              .collection('climate_readings')
              .where('user_id', isEqualTo: uid)
              .orderBy('timestamp', descending: true)
              .limit(20);
        }
        final snap = await q.get();
        for (final doc in snap.docs) {
          final d = doc.data();
          final airTemp = (d['air_temp'] as num?)?.toDouble() ?? 0;
          final humidity = (d['humidity'] as num?)?.toDouble() ?? 0;
          final ts = d['timestamp'];
          DateTime? time;
          if (ts is Timestamp) time = ts.toDate();

          // Lavender ideal: 15-30°C, 40-60% humidity
          if (airTemp > 35 || airTemp < 10) {
            alertsList.add({
              'type': 'climate',
              'severity': airTemp > 40 || airTemp < 5 ? 'high' : 'medium',
              'title': airTemp > 35 ? 'High Temperature Alert' : 'Low Temperature Alert',
              'subtitle': 'Temperature at ${airTemp.toStringAsFixed(1)}°C (ideal: 15-30°C)',
              'time': time ?? DateTime.now(),
              'icon': Icons.thermostat,
              'color': const Color(0xFFEF4444),
            });
          }
          if (humidity > 80 || humidity < 30) {
            alertsList.add({
              'type': 'climate',
              'severity': humidity > 90 || humidity < 20 ? 'high' : 'medium',
              'title': humidity > 80 ? 'High Humidity Alert' : 'Low Humidity Alert',
              'subtitle': 'Humidity at ${humidity.toStringAsFixed(1)}% (ideal: 40-60%)',
              'time': time ?? DateTime.now(),
              'icon': Icons.water_drop,
              'color': const Color(0xFF3B82F6),
            });
          }
        }
      } catch (e) {
        print('⚠️ Alerts: Climate query failed: $e');
      }

      // Soil alerts from analyses
      try {
        final analyses = await SoilBackendService.getAnalysisHistory(limit: 10);
        for (final a in analyses) {
          final diagnosis = a['diagnosis'] as Map<String, dynamic>?;
          if (diagnosis != null) {
            final overall = diagnosis['overall_health'] as String? ?? '';
            if (overall.toLowerCase().contains('poor') ||
                overall.toLowerCase().contains('critical') ||
                overall.toLowerCase().contains('warning') ||
                overall.toLowerCase().contains('low')) {
              final ts = a['createdAt'];
              DateTime? time;
              if (ts is String) time = DateTime.tryParse(ts);
              if (ts is Timestamp) time = ts.toDate();
              alertsList.add({
                'type': 'soil',
                'severity': overall.toLowerCase().contains('critical') ? 'high' : 'medium',
                'title': 'Soil Health Warning',
                'subtitle': overall,
                'time': time ?? DateTime.now(),
                'icon': Icons.eco,
                'color': const Color(0xFFF59E0B),
              });
            }
          }
        }
      } catch (e) {
        print('⚠️ Alerts: Soil analysis query failed: $e');
      }

      // Sort by time descending
      alertsList.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));

      if (mounted) {
        setState(() {
          _alerts = alertsList;
          _isLoadingAlerts = false;
        });
      }
    } catch (e) {
      print('⚠️ Alerts load failed: $e');
      if (mounted) setState(() => _isLoadingAlerts = false);
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && mounted) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _profileImageUrl = userData['profileImageUrl'];
          });
        }
      }
    } catch (e) {
      // Silently fail - profile image not critical
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Tab Navigation
            _buildTabNavigation(),
            // Main Content
            Expanded(
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentDateTime() {
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    return '${dateFormat.format(now)} | ${timeFormat.format(now)}';
  }

  String _getRelativeTime(int minutesAgo) {
    if (minutesAgo < 60) {
      return '$minutesAgo mins ago';
    } else {
      final hours = (minutesAgo / 60).floor();
      return '$hours hour${hours > 1 ? 's' : ''} ago';
    }
  }

  // =====================================================================
  //  TAB CONTENT SWITCHER
  // =====================================================================

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildMonitorTab();
      case 2:
        return _buildControlTab();
      case 3:
        return _buildAlertsTab();
      default:
        return _buildHomeTab();
    }
  }

  // =====================================================================
  //  HOME TAB  (original dashboard content)
  // =====================================================================

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          _loadUserProfile(),
          _loadRecentActivities(),
          _loadMonitorData(),
          _loadHomeCardStats(),
        ]);
      },
      color: primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHealthCard(),
            const SizedBox(height: 16),
            _buildFeatureCard(
              icon: Icons.bug_report_outlined,
              iconColor: primaryPurple,
              iconBgColor: primaryPurple.withOpacity(0.1),
              title: 'Disease Detection',
              subtitle: 'AI-powered plant health monitoring',
              badge: _todayDiseaseScans > 0
                  ? '$_todayDiseaseScans Scan${_todayDiseaseScans == 1 ? '' : 's'} Today'
                  : 'No Scans Today',
              badgeColor: primaryPurple,
              actionText: 'Tap to Scan',
              onTap: () {
                final uid = _auth.currentUser?.uid ?? '';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Home(userId: uid),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              icon: Icons.eco_outlined,
              iconColor: primaryOrange,
              iconBgColor: primaryOrange.withOpacity(0.1),
              title: 'Soil Health',
              subtitle: 'AI-powered soil health monitoring',
              badge: _latestSoilMoisture != null
                  ? 'Moisture: ${_latestSoilMoisture!.toStringAsFixed(0)}%'
                  : 'Moisture: --',
              badgeColor: primaryOrange,
              actionText: 'Run Diagnostic',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SoilHealthDashboard(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              icon: Icons.thermostat_outlined,
              iconColor: const Color(0xFFEF4444),
              iconBgColor: const Color(0xFFEF4444).withOpacity(0.1),
              title: 'Climate Control',
              subtitle: 'Temperature & humidity monitoring',
              badge: _latestClimate != null
                  ? 'Temp: ${_latestClimate!.airTemp.toStringAsFixed(1)}°C'
                  : 'Temp: --',
              badgeColor: primaryOrange,
              actionText: 'View Climate',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ClimateScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              icon: Icons.wb_sunny_outlined,
              iconColor: primaryYellow,
              iconBgColor: primaryYellow.withOpacity(0.1),
              title: 'Lighting System',
              subtitle: 'Smart light management',
              badge: 'Status: Auto',
              badgeColor: primaryYellow,
              actionText: 'Control Lights',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LightingControlScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildStatsRow(),
            const SizedBox(height: 20),
            _buildRecentActivity(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  //  MONITOR TAB — live sensor overview from all components
  // =====================================================================

  Widget _buildMonitorTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadMonitorData();
      },
      color: primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: _isLoadingMonitor
            ? const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section: Connection Status
                  _buildMonitorSectionHeader('System Status'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatusChip('Climate', _climateConnected),
                      const SizedBox(width: 8),
                      _buildStatusChip('Soil', _soilConnected),
                      const SizedBox(width: 8),
                      _buildStatusChip('Disease', _latestDiseaseScan != null),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Section: Climate Sensors
                  _buildMonitorSectionHeader('Climate Sensors'),
                  const SizedBox(height: 10),
                  if (_latestClimate != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildSensorCard(
                            icon: Icons.thermostat_outlined,
                            color: const Color(0xFFEF4444),
                            label: 'Air Temp',
                            value: '${_latestClimate!.airTemp.toStringAsFixed(1)}°C',
                            detail: _getClimateRangeLabel(_latestClimate!.airTemp, 15, 30, '°C'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSensorCard(
                            icon: Icons.water_drop_outlined,
                            color: const Color(0xFF3B82F6),
                            label: 'Humidity',
                            value: '${_latestClimate!.humidity.toStringAsFixed(1)}%',
                            detail: _getClimateRangeLabel(_latestClimate!.humidity, 40, 60, '%'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSensorCard(
                            icon: Icons.grass_outlined,
                            color: const Color(0xFF8B5CF6),
                            label: 'Soil Temp',
                            value: '${_latestClimate!.soilTemp.toStringAsFixed(1)}°C',
                            detail: _getClimateRangeLabel(_latestClimate!.soilTemp, 15, 25, '°C'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSensorCard(
                            icon: Icons.air_outlined,
                            color: primaryGreen,
                            label: 'Fan Speed',
                            value: '${_latestClimate!.effectiveFanSpeed.toStringAsFixed(0)}%',
                            detail: 'Mode: ${_latestClimate!.fanMode}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSensorCard(
                      icon: Icons.cloud_outlined,
                      color: const Color(0xFF06B6D4),
                      label: 'Humidifier',
                      value: _latestClimate!.humidifierLabel,
                      detail: 'Mode: ${_latestClimate!.humidifierControlMode}',
                    ),
                  ] else
                    _buildEmptyStateCard(
                      icon: Icons.thermostat_outlined,
                      message: 'No climate data available.\nCheck sensor connection.',
                    ),

                  const SizedBox(height: 20),

                  // Section: Soil Sensors
                  _buildMonitorSectionHeader('Soil Sensors'),
                  const SizedBox(height: 10),
                  if (_latestSoilMoisture != null) ...[
                    _buildSensorCard(
                      icon: Icons.opacity_outlined,
                      color: primaryOrange,
                      label: 'Soil Moisture',
                      value: '${_latestSoilMoisture!.toStringAsFixed(1)}%',
                      detail: _latestSoilMoisture! < 30
                          ? 'Below ideal (30-50%)'
                          : _latestSoilMoisture! > 50
                              ? 'Above ideal (30-50%)'
                              : 'Within ideal range',
                    ),
                  ] else
                    _buildEmptyStateCard(
                      icon: Icons.eco_outlined,
                      message: 'Soil sensor offline.\nCheck ESP32 connection.',
                    ),

                  const SizedBox(height: 20),

                  // Section: Disease Detection
                  _buildMonitorSectionHeader('Latest Disease Scan'),
                  const SizedBox(height: 10),
                  if (_latestDiseaseScan != null) ...[
                    _buildDiseaseMonitorCard(_latestDiseaseScan!),
                  ] else
                    _buildEmptyStateCard(
                      icon: Icons.bug_report_outlined,
                      message: 'No disease scans yet.\nTap Disease Detection to scan.',
                    ),

                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }

  String _getClimateRangeLabel(double value, double low, double high, String unit) {
    if (value < low) return 'Below ideal (${low.toInt()}-${high.toInt()}$unit)';
    if (value > high) return 'Above ideal (${low.toInt()}-${high.toInt()}$unit)';
    return 'Within ideal range';
  }

  Widget _buildMonitorSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),
    );
  }

  Widget _buildStatusChip(String label, bool connected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: connected
            ? primaryGreen.withOpacity(0.1)
            : const Color(0xFFEF4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: connected
              ? primaryGreen.withOpacity(0.3)
              : const Color(0xFFEF4444).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connected ? primaryGreen : const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: connected ? primaryGreen : const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    String? detail,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 11,
                      color: detail.contains('Below') || detail.contains('Above')
                          ? const Color(0xFFF59E0B)
                          : primaryGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard({
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: textGrey.withOpacity(0.4), size: 40),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseMonitorCard(Map<String, dynamic> scan) {
    final hasDisease = scan['has_disease'] == true;
    final status = scan['overall_status'] as String? ?? 'Unknown';
    final diseaseCount = (scan['disease_count'] as num?)?.toInt() ?? 0;
    final healthyCount = (scan['healthy_count'] as num?)?.toInt() ?? 0;
    final totalCount = (scan['detection_count'] as num?)?.toInt() ?? 0;
    final ts = scan['timestamp'] ?? scan['date_time'];
    DateTime? time;
    if (ts is Timestamp) time = ts.toDate();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasDisease
              ? const Color(0xFFEF4444).withOpacity(0.3)
              : primaryGreen.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: (hasDisease ? const Color(0xFFEF4444) : primaryGreen)
                .withOpacity(0.1),
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
                hasDisease ? Icons.warning_amber : Icons.check_circle_outline,
                color: hasDisease ? const Color(0xFFEF4444) : primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: hasDisease ? const Color(0xFFEF4444) : primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDiseaseStatPill('Total', totalCount, textDark),
              _buildDiseaseStatPill('Diseased', diseaseCount, const Color(0xFFEF4444)),
              _buildDiseaseStatPill('Healthy', healthyCount, primaryGreen),
            ],
          ),
          if (time != null) ...[
            const SizedBox(height: 8),
            Text(
              'Scanned: ${_formatActivityTimeAgo(time)}',
              style: const TextStyle(fontSize: 11, color: textGrey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiseaseStatPill(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: textGrey),
        ),
      ],
    );
  }

  // =====================================================================
  //  CONTROL TAB — quick actions for all components
  // =====================================================================

  Widget _buildControlTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadMonitorData();
      },
      color: primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Climate Control Section
            _buildMonitorSectionHeader('Climate Control'),
            const SizedBox(height: 10),
            _buildControlActionCard(
              icon: Icons.thermostat_outlined,
              color: const Color(0xFFEF4444),
              title: 'Climate System',
              subtitle: _latestClimate != null
                  ? 'Fan: ${_latestClimate!.fanMode} · Humidifier: ${_latestClimate!.humidifierControlMode}'
                  : 'Not connected',
              actionLabel: 'Open Climate Control',
              onAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ClimateScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            // Quick climate toggles
            if (_latestClimate != null)
              Row(
                children: [
                  Expanded(
                    child: _buildQuickToggle(
                      icon: Icons.air,
                      label: 'Fan Mode',
                      currentValue: _latestClimate!.fanMode,
                      color: const Color(0xFF3B82F6),
                      options: ['off', 'manual', 'auto'],
                      onChanged: (mode) async {
                        try {
                          await ClimateApiService.setFanMode(mode);
                          await _loadMonitorData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Fan mode set to $mode'),
                                backgroundColor: primaryGreen,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed: $e'),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickToggle(
                      icon: Icons.cloud,
                      label: 'Humidifier',
                      currentValue: _latestClimate!.humidifierControlMode,
                      color: const Color(0xFF06B6D4),
                      options: ['off', 'manual', 'auto'],
                      onChanged: (mode) async {
                        try {
                          await ClimateApiService.setHumidifierMode(mode);
                          await _loadMonitorData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Humidifier mode set to $mode'),
                                backgroundColor: primaryGreen,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed: $e'),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Soil & Irrigation Section
            _buildMonitorSectionHeader('Soil & Irrigation'),
            const SizedBox(height: 10),
            _buildControlActionCard(
              icon: Icons.eco_outlined,
              color: primaryOrange,
              title: 'Soil Health Dashboard',
              subtitle: 'Manage soil analysis & irrigation routines',
              actionLabel: 'Open Soil Dashboard',
              onAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SoilHealthDashboard()),
                );
              },
            ),

            const SizedBox(height: 24),

            // Disease Detection Section
            _buildMonitorSectionHeader('Disease Detection'),
            const SizedBox(height: 10),
            _buildControlActionCard(
              icon: Icons.bug_report_outlined,
              color: primaryPurple,
              title: 'Plant Scanner',
              subtitle: 'AI-powered disease detection & monitoring',
              actionLabel: 'Start Scanning',
              onAction: () {
                final uid = _auth.currentUser?.uid ?? '';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Home(userId: uid),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Lighting Section
            _buildMonitorSectionHeader('Lighting System'),
            const SizedBox(height: 10),
            _buildControlActionCard(
              icon: Icons.wb_sunny_outlined,
              color: primaryYellow,
              title: 'Smart Lighting',
              subtitle: 'Control greenhouse lighting zones',
              actionLabel: 'Control Lights',
              onAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LightingControlScreen()),
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildControlActionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        onTap: onAction,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.grey.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  actionLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickToggle({
    required IconData icon,
    required String label,
    required String currentValue,
    required Color color,
    required List<String> options,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
          const SizedBox(height: 8),
          ...options.map((opt) {
            final isActive = currentValue.toLowerCase() == opt.toLowerCase();
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: isActive ? null : () => onChanged(opt),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    decoration: BoxDecoration(
                      color: isActive ? color.withOpacity(0.15) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive ? color.withOpacity(0.4) : Colors.grey.shade200,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        opt[0].toUpperCase() + opt.substring(1),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive ? color : textGrey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // =====================================================================
  //  ALERTS TAB — warnings from all components
  // =====================================================================

  Widget _buildAlertsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadAlerts();
      },
      color: primaryGreen,
      child: _isLoadingAlerts
          ? const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          : _alerts.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      Icon(Icons.check_circle_outline, color: primaryGreen.withOpacity(0.5), size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'All Clear!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No alerts at this time.\nAll systems are operating normally.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: textGrey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _alerts.length + 1, // +1 for header
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Alerts summary header
                      final highCount = _alerts.where((a) => a['severity'] == 'high').length;
                      final mediumCount = _alerts.where((a) => a['severity'] == 'medium').length;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            _buildAlertCountBadge('$highCount High', const Color(0xFFEF4444)),
                            const SizedBox(width: 8),
                            _buildAlertCountBadge('$mediumCount Medium', const Color(0xFFF59E0B)),
                            const SizedBox(width: 8),
                            _buildAlertCountBadge('${_alerts.length} Total', textGrey),
                          ],
                        ),
                      );
                    }

                    final alert = _alerts[index - 1];
                    return _buildAlertCard(alert);
                  },
                ),
    );
  }

  Widget _buildAlertCountBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final color = alert['color'] as Color;
    final severity = alert['severity'] as String;
    final time = alert['time'] as DateTime;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: severity == 'high'
                ? color.withOpacity(0.4)
                : color.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(alert['icon'] as IconData, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert['title'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: severity == 'high'
                              ? const Color(0xFFEF4444).withOpacity(0.1)
                              : const Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          severity.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: severity == 'high'
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    alert['subtitle'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: textGrey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatActivityTimeAgo(time),
                    style: TextStyle(
                      fontSize: 11,
                      color: textGrey.withOpacity(0.7),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: textDark),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    color: primaryOrange,
                    onPressed: () {
                      // TODO: Navigate to notifications
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    color: textDark,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      ).then((_) => _loadUserProfile());
                    },
                  ),
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      splashColor: primaryOrange.withOpacity(0.2),
                      highlightColor: primaryOrange.withOpacity(0.1),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        ).then((_) => _loadUserProfile());
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryOrange, width: 2),
                        ),
                      child: ClipOval(
                        child: _profileImageUrl != null
                            ? Image.network(
                                _profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person_outline,
                                    color: primaryOrange,
                                    size: 20,
                                  );
                                },
                              )
                            : const Icon(
                                Icons.person_outline,
                                color: primaryOrange,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Lavender Farm System',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Smart Agriculture Management',
            style: TextStyle(
              fontSize: 14,
              color: textGrey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getCurrentDateTime(),
            style: TextStyle(
              fontSize: 12,
              color: textGrey.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigation() {
    final tabs = [
      {'icon': Icons.home_outlined, 'label': 'Home'},
      {'icon': Icons.monitor_heart_outlined, 'label': 'Monitor'},
      {'icon': Icons.tune_outlined, 'label': 'Control'},
      {'icon': Icons.notifications_outlined, 'label': 'Alerts'},
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: primaryGreen.withOpacity(0.1),
              highlightColor: primaryGreen.withOpacity(0.05),
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? primaryGreen : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tabs[index]['icon'] as IconData,
                      color: isSelected ? primaryGreen : textGrey,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tabs[index]['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? primaryGreen : textGrey,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHealthCard() {
    // Compute dynamic health score from available data
    final healthScore = _computeHealthScore();
    final healthLabel = healthScore >= 80 ? 'GOOD' : healthScore >= 50 ? 'FAIR' : 'POOR';
    final healthColor = healthScore >= 80 ? primaryGreen : healthScore >= 50 ? primaryYellow : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE8F5E9),
            const Color(0xFFF3E5F5).withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Lavender Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/lvd4.png',
              width: 80,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lavender\nPlant\nHealth',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Overall System Status',
                  style: TextStyle(
                    fontSize: 12,
                    color: textGrey.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          // Health Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$healthScore',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    TextSpan(
                      text: '%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textGrey.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Health Score',
                style: TextStyle(
                  fontSize: 12,
                  color: textGrey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: healthColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  healthLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFFAFAFA),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          // Subtitle
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: textGrey,
            ),
          ),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: badgeColor,
              ),
            ),
          ),
          // Action
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              splashColor: primaryOrange.withOpacity(0.15),
              highlightColor: primaryOrange.withOpacity(0.08),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primaryOrange,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward,
                      color: primaryOrange,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
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
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(
            child: _buildStatItem(
              icon: Icons.bolt,
              iconColor: primaryPurple,
              value: '$_totalDiseaseScans',
              label: 'Total Scans',
            ),
          ),
          Flexible(
            child: _buildStatItem(
              icon: Icons.water_drop_outlined,
              iconColor: Colors.blue,
              value: _latestSoilMoisture != null
                  ? '${_latestSoilMoisture!.toStringAsFixed(0)}%'
                  : '--',
              label: 'Moisture',
            ),
          ),
          Flexible(
            child: _buildStatItem(
              icon: Icons.thermostat_outlined,
              iconColor: primaryOrange,
              value: _latestClimate != null
                  ? '${_latestClimate!.airTemp.toStringAsFixed(1)}°'
                  : '--',
              label: 'Temp',
            ),
          ),
          Flexible(
            child: _buildStatItem(
              icon: Icons.opacity,
              iconColor: primaryYellow,
              value: _latestClimate != null
                  ? '${_latestClimate!.humidity.toStringAsFixed(0)}%'
                  : '--',
              label: 'Humidity',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    String? secondValue,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            if (secondValue != null) ...[
              const SizedBox(width: 2),
              Text(
                secondValue,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            color: textGrey,
          ),
        ),
      ],
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
                splashColor: primaryGreen.withOpacity(0.15),
                highlightColor: primaryGreen.withOpacity(0.08),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ActivityHistoryScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      const Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 13,
                          color: primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryGreen.withOpacity(0.3)),
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Activity Items
        if (_isLoadingActivities)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_recentActivities.isNotEmpty)
          ..._recentActivities.take(6).map((activity) => _buildActivityItem(
            icon: activity.icon,
            iconBgColor: activity.iconBgColor,
            iconColor: activity.iconColor,
            title: activity.title,
            subtitle: activity.subtitle,
            time: _formatActivityTimeAgo(activity.time),
            onTap: () => showActivityDetailSheet(
              context,
              icon: activity.icon,
              iconBgColor: activity.iconBgColor,
              iconColor: activity.iconColor,
              title: activity.title,
              subtitle: activity.subtitle,
              time: activity.time,
              source: activity.source,
              rawData: activity.rawData,
            ),
          ))
        else ...[  
          _buildActivityItem(
            icon: Icons.info_outline,
            iconBgColor: const Color(0xFFF3F4F6),
            iconColor: textGrey,
            title: 'No recent activities yet',
            time: 'Start using the app to see activity',
          ),
        ],
      ],
    );
  }

  String _formatActivityTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(time);
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String time,
    String subtitle = '',
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
                color: iconColor.withOpacity(0.12),
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
                  if (subtitle.isNotEmpty) ...[                  
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: textGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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

  Widget _buildDrawer() {
    final user = _auth.currentUser;
    final userName = user?.displayName ?? 'User';
    final userEmail = user?.email ?? '';

    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Drawer Header with user info
            Material(
              color: Colors.transparent,
              child: InkWell(
                splashColor: Colors.white.withOpacity(0.15),
                highlightColor: Colors.white.withOpacity(0.08),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  ).then((_) => _loadUserProfile());
                },
                child: Ink(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryPurple,
                        primaryPurple.withOpacity(0.8),
                      ],
                    ),
                  ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _profileImageUrl != null
                            ? Image.network(
                                _profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    color: primaryPurple,
                                    size: 40,
                                  );
                                },
                              )
                            : const Icon(
                                Icons.person,
                                color: primaryPurple,
                                size: 40,
                              ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_outlined,
                    title: 'Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_outline,
                    title: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      ).then((_) => _loadUserProfile());
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      ).then((_) => _loadUserProfile());
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to help screen
                    },
                  ),
                  const Divider(height: 1),
                  _buildDrawerItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    onTap: () {
                      Navigator.pop(context);
                      // Show about dialog
                    },
                  ),
                ],
              ),
            ),

            // Logout Button at bottom
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: _buildDrawerItem(
                icon: Icons.logout,
                title: 'Logout',
                iconColor: Colors.red[400]!,
                titleColor: Colors.red[600]!,
                onTap: () async {
                  Navigator.pop(context);
                  _showLogoutConfirmation();
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? textDark,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: titleColor ?? textDark,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      visualDensity: VisualDensity.compact,
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                await _handleLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    try {
      await _auth.signOut();
      if (!mounted) return;
      
      // Navigate to login screen and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}
