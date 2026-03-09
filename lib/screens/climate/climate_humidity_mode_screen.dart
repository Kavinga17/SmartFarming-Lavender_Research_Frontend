import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:math';
import 'dart:async';
import '../../services/climate_api_service.dart';
import '../../services/climate_data_service.dart';
import '../../services/climate_sensor_data_service.dart';

// Colors - defined at module level
const Color backgroundColor = Color(0xFFF8F9FA);
const Color primaryPurple = Color(0xFF8B5CF6);
const Color primaryGreen = Color(0xFF22C55E);
const Color primaryBlue = Color(0xFF3B82F6);
const Color textDark = Color(0xFF1F2937);
const Color textGrey = Color(0xFF6B7280);
const Color cardBackground = Colors.white;

class HumidityModeScreen extends StatefulWidget {
  final int? initialHumidifierMode;
  final String? initialHumidifierControlMode;
  final double? currentAirTemp;
  final double? currentHumidity;
  final double? currentSoilTemp;
  final double? targetTemp;
  final double? targetHumidity;
  final double? prevFanSpeed;
  final double? prevHumidifierMode;

  const HumidityModeScreen({
    super.key,
    this.initialHumidifierMode,
    this.initialHumidifierControlMode,
    this.currentAirTemp,
    this.currentHumidity,
    this.currentSoilTemp,
    this.targetTemp,
    this.targetHumidity,
    this.prevFanSpeed,
    this.prevHumidifierMode,
  });

  @override
  State<HumidityModeScreen> createState() => _HumidityModeScreenState();
}

class _HumidityModeScreenState extends State<HumidityModeScreen> {
  // 0 = Off, 1 = Manual, 2 = Auto  (same pattern as fan)
  int _selectedMode = 2;
  int _manualLevel = 2; // Manual level 0-3 (0=off, 1=low, 2=medium, 3=high)
  int _selectedMetric = 2; // 0 = Today, 1 = Last 7 days, 2 = Last month

  // ── Dynamic data from Climate API ──
  bool _isServerConnected = false;
  ClimatePrediction? _prediction;
  Timer? _autoRefreshTimer;
  StreamSubscription? _sensorSubscription;
  double _airTemp = 0.0;
  double _humidity = 0.0;
  double _soilTemp = 0.0;
  double _targetTemp = 24.0;
  double _targetHumidity = 65.0;
  double _prevFanSpeed = 0.0;
  double _prevHumidifierMode = 0.0;
  bool _isSendingCommand = false;

  // Dynamic humidity chart data from Firestore
  List<double> _humChartData = [];
  List<String> _humChartLabels = [];
  double _humAvg = 0.0;

  @override
  void initState() {
    super.initState();
    _airTemp = widget.currentAirTemp ?? 0.0;
    _humidity = widget.currentHumidity ?? 0.0;
    _soilTemp = widget.currentSoilTemp ?? 0.0;
    _targetTemp = widget.targetTemp ?? 24.0;
    _targetHumidity = widget.targetHumidity ?? 65.0;
    _prevFanSpeed = widget.prevFanSpeed ?? 0.0;
    _prevHumidifierMode = widget.prevHumidifierMode ?? 0.0;

    _initApi();
    _subscribeSensorData();
    _loadHumidityChartData();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _sensorSubscription?.cancel();
    super.dispose();
  }

  /// Load humidity chart data from Firestore based on selected period.
  Future<void> _loadHumidityChartData() async {
    try {
      String period;
      switch (_selectedMetric) {
        case 0:
          period = 'today';
          break;
        case 1:
          period = '7days';
          break;
        case 2:
        case 3:
        default:
          period = '30days';
          break;
      }
      final readings = await ClimateDataService.getReadingsForPeriod(period);
      if (readings.isEmpty || !mounted) return;
      final sampled = ClimateDataService.downsample(readings, 12);
      final data = sampled.map((r) => r.humidity).toList();
      final labels = sampled.map((r) {
        if (r.timestamp == null) return '';
        if (period == 'today') return DateFormat('HH:mm').format(r.timestamp!);
        return DateFormat('dd/MM').format(r.timestamp!);
      }).toList();
      final stats = ClimateDataService.computeStats(readings);
      if (mounted) {
        setState(() {
          _humChartData = data;
          _humChartLabels = labels;
          _humAvg = stats.avgHumidity;
        });
      }
    } catch (e) {
      print('\u26a0\ufe0f Failed to load humidity chart data: $e');
    }
  }

  /// Subscribe to live sensor readings from backend /sensors endpoint.
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
          });
        }
      },
      onError: (e) => print('\u26a0\ufe0f Sensor stream error: $e'),
    );
  }

  Future<void> _initApi() async {
    final connected = await ClimateApiService.checkHealth();
    if (mounted) {
      setState(() => _isServerConnected = connected);
      if (connected) {
        await _loadHumidifierState();
        await _fetchPrediction();
      }
    }
    // Auto-refresh in auto mode every 15 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (_selectedMode == 2 && _isServerConnected) {
        await _fetchPrediction();
      }
      _loadHumidityChartData();
    });
  }

  /// Load the current humidifier state from the backend.
  Future<void> _loadHumidifierState() async {
    final state = await ClimateApiService.getHumidifierState();
    if (state != null && mounted) {
      setState(() {
        switch (state.mode) {
          case 'off':
            _selectedMode = 0;
            break;
          case 'manual':
            _selectedMode = 1;
            break;
          case 'auto':
            _selectedMode = 2;
            break;
        }
        _manualLevel = state.manualLevel;
      });
    }
  }

  /// Set humidifier mode on the backend and update local state.
  Future<void> _setHumidifierMode(int mode) async {
    if (_isSendingCommand) return;
    setState(() => _isSendingCommand = true);

    final modeStr = mode == 0 ? 'off' : mode == 1 ? 'manual' : 'auto';
    final result = await ClimateApiService.setHumidifierMode(modeStr);

    if (mounted) {
      setState(() {
        _isSendingCommand = false;
        if (result != null) {
          _selectedMode = mode;
          if (mode == 2 && _isServerConnected) {
            _fetchPrediction();
          }
        }
      });
    }
  }

  /// Send manual humidifier level to the backend.
  Future<void> _sendManualLevel(int level) async {
    if (_selectedMode != 1) return;
    final result = await ClimateApiService.setHumidifierManual(level: level);
    if (result != null && mounted) {
      setState(() {
        _manualLevel = level;
      });
    }
  }

  Future<void> _fetchPrediction() async {
    final result = await ClimateApiService.predict(
      airTemp: _airTemp,
      humidity: _humidity,
      soilTemp: _soilTemp,
      targetTemp: _targetTemp,
      targetHumidity: _targetHumidity,
      prevFanSpeed: _prevFanSpeed,
      prevHumidifierMode: _prevHumidifierMode,
    );
    if (result != null && mounted) {
      setState(() {
        _prediction = result;
        _prevFanSpeed = result.fanSpeed;
        _prevHumidifierMode = result.humidifierMode.toDouble();
      });

      // Save to Firestore
      ClimateDataService.saveReading(
        prediction: result,
        targetTemp: _targetTemp,
        targetHumidity: _targetHumidity,
      );
    }
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Mode Buttons (Off / Manual / Auto)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildModeButtons(),
                    ),
                    const SizedBox(height: 24),
                    // Level Control (dial for manual, display for auto)
                    _buildLevelControl(),
                    const SizedBox(height: 20),
                    // Level selector buttons (manual mode only)
                    if (_selectedMode == 1) _buildLevelSelector(),
                    if (_selectedMode == 1) const SizedBox(height: 20),
                    // Metric Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildMetricCards(),
                    ),
                    const SizedBox(height: 24),
                    // Metrics Time Filter
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildMetricsSection(),
                    ),
                    const SizedBox(height: 20),
                    // Humidity Chart
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildHumidityChart(),
                    ),
                    const SizedBox(height: 24),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: textDark, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          Flexible(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Lavender ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  TextSpan(
                    text: 'AI',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: textDark,
                    ),
                  ),
                  TextSpan(
                    text: '\ud83c\udf3f',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Connection status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                const SizedBox(width: 4),
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
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 22),
            color: const Color(0xFFFF7A45),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            color: textDark,
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: const Icon(Icons.menu, size: 22),
            color: textDark,
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  // -- Mode Buttons (Off / Manual / Auto) ---------------------------------

  Widget _buildModeButtons() {
    return Column(
      children: [
        Row(
          children: [
            _buildModeButton(0, Icons.power_settings_new, 'Off'),
            const SizedBox(width: 8),
            _buildModeButton(1, Icons.pan_tool, 'Manual'),
            const SizedBox(width: 8),
            _buildModeButton(2, Icons.auto_awesome, 'Auto'),
          ],
        ),
        if (_isSendingCommand)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryPurple),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Sending command...',
                  style: TextStyle(
                    fontSize: 12,
                    color: textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildModeButton(int mode, IconData icon, String label) {
    final isSelected = _selectedMode == mode;
    return Expanded(
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: mode == 0
                          ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                          : mode == 1
                              ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                              : [const Color(0xFF9D6FFF), const Color(0xFF7C3AED)],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Color(0xFFF5F5F5)],
                    ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.grey.shade300,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? (mode == 0
                              ? const Color(0xFFEF4444)
                              : mode == 1
                                  ? const Color(0xFFF59E0B)
                                  : primaryPurple)
                          .withOpacity(0.3)
                      : Colors.grey.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : textGrey, size: 18),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                splashColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.1),
                onTap: _isSendingCommand ? null : () => _setHumidifierMode(mode),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Level Control (Circular Dial) --------------------------------------

  Widget _buildLevelControl() {
    // Determine what level/label to display
    int displayLevel;
    String modeLabel;

    switch (_selectedMode) {
      case 0: // Off
        displayLevel = 0;
        modeLabel = 'Humidifier is OFF';
        break;
      case 1: // Manual
        displayLevel = _manualLevel;
        modeLabel = 'Manual Level';
        break;
      case 2: // Auto
        displayLevel = _prediction?.effectiveHumidifierLevel ?? _prediction?.humidifierMode ?? 0;
        modeLabel = 'AI Controlled';
        break;
      default:
        displayLevel = 0;
        modeLabel = '';
    }

    final levelLabel = ClimateApiService.humidifierModeLabel(displayLevel);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFFAFAFA)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular dial
            Center(
              child: Opacity(
                opacity: _selectedMode == 0 ? 0.5 : 1.0,
                child: GestureDetector(
                  onTapDown: (_selectedMode == 1)
                      ? (TapDownDetails details) {
                          // Calculate which level was tapped based on angle
                          const size = 220.0;
                          final center = Offset(size / 2, size / 2);
                          final tapPosition = details.localPosition;
                          final dx = tapPosition.dx - center.dx;
                          final dy = tapPosition.dy - center.dy;

                          double angle = atan2(dy, dx);
                          if (angle < 0) angle += 2 * pi;

                          double norm(double a) {
                            while (a < 0) a += 2 * pi;
                            while (a >= 2 * pi) a -= 2 * pi;
                            return a;
                          }

                          double ang = norm(angle);
                          final lowAngle = norm(-5 * pi / 6);
                          final medAngle = norm(pi / 2);
                          final highAngle = norm(-pi / 6);

                          double dist(double a, double b) {
                            var d = (a - b).abs();
                            if (d > pi) d = 2 * pi - d;
                            return d;
                          }

                          final distances = [
                            dist(ang, lowAngle),
                            dist(ang, medAngle),
                            dist(ang, highAngle),
                          ];
                          final minDist = distances.reduce((v, e) => e < v ? e : v);
                          final idx = distances.indexOf(minDist);
                          final level = idx + 1; // 1=Low, 2=Medium, 3=High

                          setState(() => _manualLevel = level);
                          _sendManualLevel(level);
                        }
                      : null,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: CustomPaint(
                          painter: CircularDialPainter(selectedLevel: displayLevel),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.water_drop,
                            size: 32,
                            color: displayLevel > 0
                                ? const Color(0xFF3B82F6)
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayLevel > 0 ? 'Level 0$displayLevel' : 'OFF',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            levelLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              color: textGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              modeLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textGrey,
              ),
              textAlign: TextAlign.center,
            ),
            // Show AI prediction info in auto mode
            if (_selectedMode == 2 && _prediction != null) ...[
              const SizedBox(height: 8),
              Text(
                'AI prediction: ${_prediction!.humidifierAiLabel} (Level ${_prediction!.humidifierMode})',
                style: TextStyle(
                  fontSize: 12,
                  color: primaryPurple.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // -- Level Selector Buttons (Manual Mode) -------------------------------

  Widget _buildLevelSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildLevelButton(0, 'Off'),
          const SizedBox(width: 8),
          _buildLevelButton(1, 'Low'),
          const SizedBox(width: 8),
          _buildLevelButton(2, 'Medium'),
          const SizedBox(width: 8),
          _buildLevelButton(3, 'High'),
        ],
      ),
    );
  }

  Widget _buildLevelButton(int level, String label) {
    final isSelected = _manualLevel == level;
    return Expanded(
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: level == 0
                          ? [Colors.grey.shade400, Colors.grey.shade500]
                          : level == 1
                              ? [const Color(0xFF60A5FA), const Color(0xFF3B82F6)]
                              : level == 2
                                  ? [const Color(0xFF34D399), const Color(0xFF10B981)]
                                  : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Color(0xFFF5F5F5)],
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.grey.shade300,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? primaryBlue.withOpacity(0.25)
                      : Colors.grey.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : textDark,
              ),
            ),
          ),
        ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                splashColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.1),
                onTap: () {
                  setState(() => _manualLevel = level);
                  _sendManualLevel(level);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Metric Cards -------------------------------------------------------

  Widget _buildMetricCards() {
    // Determine current effective humidifier level for display
    int effectiveLevel;
    switch (_selectedMode) {
      case 0:
        effectiveLevel = 0;
        break;
      case 1:
        effectiveLevel = _manualLevel;
        break;
      case 2:
        effectiveLevel = _prediction?.effectiveHumidifierLevel ?? _prediction?.humidifierMode ?? 0;
        break;
      default:
        effectiveLevel = 0;
    }

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.water_drop_outlined,
            iconColor: primaryBlue,
            value: '${_humidity.toStringAsFixed(0)}%',
            label: 'Humidity',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.thermostat_outlined,
            iconColor: const Color(0xFF10B981),
            value: '${_airTemp.toStringAsFixed(1)}\u00b0C',
            label: 'Inside',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.thermostat_outlined,
            iconColor: const Color(0xFF10B981),
            value: '${_soilTemp.toStringAsFixed(1)}\u00b0C',
            label: 'Soil',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.water_drop,
            iconColor: primaryPurple,
            value: 'Lv$effectiveLevel',
            label: 'Humidifier',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(16),
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
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // -- Metrics Time Filter ------------------------------------------------

  Widget _buildMetricsSection() {
    final metrics = ['Today', 'Last 7 days', 'Last month', 'Custom period'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metrics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(metrics.length, (index) {
              final isSelected = _selectedMetric == index;
              return Padding(
                padding: EdgeInsets.only(right: index < metrics.length - 1 ? 8 : 0),
                child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  splashColor: primaryPurple.withOpacity(0.15),
                  highlightColor: primaryPurple.withOpacity(0.08),
                  onTap: () {
                    setState(() => _selectedMetric = index);
                    _loadHumidityChartData();
                  },
                  child: Ink(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFC084FC),
                              Color(0xFFA855F7),
                            ],
                          )
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Color(0xFFF5F5F5)],
                          ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : Colors.grey.shade300,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? primaryPurple.withOpacity(0.25)
                            : Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    metrics[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : textDark,
                    ),
                  ),
                ),
              ),
              ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // -- Humidity Chart -----------------------------------------------------

  Widget _buildHumidityChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.water_drop, color: primaryBlue, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Humidity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _humAvg > 0 ? 'Average : ${_humAvg.toStringAsFixed(0)}%' : 'Average : --',
          style: const TextStyle(
            fontSize: 13,
            color: textGrey,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFFAFAFA)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
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
          child: Column(
            children: [
              SizedBox(
                height: 180,
                width: double.infinity,
                child: _humChartData.isNotEmpty
                    ? CustomPaint(
                        painter: HumidityChartPainter(data: _humChartData),
                      )
                    : const Center(
                        child: Text('Loading chart data...', style: TextStyle(color: textGrey, fontSize: 13)),
                      ),
              ),
              const SizedBox(height: 12),
              // X-axis labels (dynamic)
              if (_humChartLabels.isNotEmpty)
                SizedBox(
                  height: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _humChartLabels.map((label) {
                      return Text(
                        label,
                        style: const TextStyle(fontSize: 10, color: textGrey),
                      );
                    }).toList(),
                  ),
                )
              else
                SizedBox(
                  height: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
                      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
                    ].map((month) {
                      return Text(month, style: const TextStyle(fontSize: 10, color: textGrey));
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// =========================================================================
//  PAINTERS
// =========================================================================

class CircularDialPainter extends CustomPainter {
  final int selectedLevel;

  CircularDialPainter({required this.selectedLevel});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 25;

    // Draw background circle (light gray)
    canvas.drawCircle(
      center,
      radius + 5,
      Paint()
        ..color = Colors.grey.withOpacity(0.08)
        ..style = PaintingStyle.fill,
    );

    // Draw outer circle stroke
    canvas.drawCircle(
      center,
      radius + 5,
      Paint()
        ..color = Colors.grey.withOpacity(0.1)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    // Mode positions (in radians) for 3 modes spaced 120deg apart
    final level1Angle = -5 * pi / 6; // 210deg - bottom left (Low)
    final level2Angle = pi / 2;      // 90deg  - top (Medium)
    final level3Angle = -pi / 6;     // 330deg - bottom right (High)

    final arcWidth = 20.0;

    // Draw each arc segment
    _drawArcSegmentBetween(
      canvas, center, radius, arcWidth,
      level1Angle, level2Angle,
      selectedLevel >= 1,
    );
    _drawArcSegmentBetween(
      canvas, center, radius, arcWidth,
      level2Angle, level3Angle,
      selectedLevel >= 2,
    );
    _drawArcSegmentBetween(
      canvas, center, radius, arcWidth,
      level3Angle, level1Angle + 2 * pi,
      selectedLevel >= 3,
    );

    // Draw numbers and scale marks
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final numbers = ['1', '2', '3'];
    final angles = [level1Angle, level2Angle, level3Angle];

    for (int i = 0; i < numbers.length; i++) {
      final markStartRadius = radius + 8;
      final markEndRadius = radius + 15;

      final markStartX = center.dx + markStartRadius * cos(angles[i]);
      final markStartY = center.dy + markStartRadius * sin(angles[i]);
      final markEndX = center.dx + markEndRadius * cos(angles[i]);
      final markEndY = center.dy + markEndRadius * sin(angles[i]);

      canvas.drawLine(
        Offset(markStartX, markStartY),
        Offset(markEndX, markEndY),
        Paint()
          ..color = textGrey
          ..strokeWidth = 1.5,
      );

      textPainter.text = TextSpan(
        text: numbers[i],
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textGrey,
        ),
      );
      textPainter.layout();

      final labelRadius = radius - 25;
      final x = center.dx + labelRadius * cos(angles[i]);
      final y = center.dy + labelRadius * sin(angles[i]);

      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // Draw 3D ball indicator at selected mode
    if (selectedLevel >= 1 && selectedLevel <= 3) {
      late Offset indicatorPos;
      switch (selectedLevel) {
        case 1:
          indicatorPos = Offset(center.dx + radius * cos(level1Angle), center.dy + radius * sin(level1Angle));
          break;
        case 2:
          indicatorPos = Offset(center.dx + radius * cos(level2Angle), center.dy + radius * sin(level2Angle));
          break;
        case 3:
          indicatorPos = Offset(center.dx + radius * cos(level3Angle), center.dy + radius * sin(level3Angle));
          break;
      }

      // Shadow
      canvas.drawCircle(
        Offset(indicatorPos.dx, indicatorPos.dy + 2),
        12,
        Paint()
          ..color = Colors.black.withOpacity(0.15)
          ..style = PaintingStyle.fill,
      );

      // Outer glow
      canvas.drawCircle(
        indicatorPos,
        14,
        Paint()
          ..color = const Color(0xFF3B82F6).withOpacity(0.25)
          ..style = PaintingStyle.fill,
      );

      // Main sphere
      canvas.drawCircle(
        indicatorPos,
        11,
        Paint()
          ..shader = const RadialGradient(
            colors: [
              Color(0xFF60A5FA),
              Color(0xFF3B82F6),
            ],
          ).createShader(Rect.fromCircle(center: indicatorPos, radius: 11))
          ..style = PaintingStyle.fill,
      );

      // Highlight
      canvas.drawCircle(
        Offset(indicatorPos.dx - 4, indicatorPos.dy - 4),
        5,
        Paint()
          ..color = Colors.white.withOpacity(0.6)
          ..style = PaintingStyle.fill,
      );

      // Inner shadow
      canvas.drawCircle(
        Offset(indicatorPos.dx + 3, indicatorPos.dy + 3),
        4,
        Paint()
          ..color = Colors.black.withOpacity(0.2)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawArcSegmentBetween(Canvas canvas, Offset center, double radius, double strokeWidth,
      double startAngle, double endAngle, bool isActive) {
    final paint = Paint()
      ..color = isActive ? const Color(0xFF3B82F6) : const Color(0xFFA855F7)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    var sweepAngle = endAngle - startAngle;
    if (sweepAngle < 0) sweepAngle += 2 * pi;
    if (sweepAngle > pi) sweepAngle = sweepAngle - 2 * pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CircularDialPainter oldDelegate) {
    return oldDelegate.selectedLevel != selectedLevel;
  }
}

class HumidityChartPainter extends CustomPainter {
  final List<double> data;

  HumidityChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Y-axis labels
    final yLabels = ['0', '20', '40', '60', '80', '100'];
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= 5; i++) {
      textPainter.text = TextSpan(
        text: yLabels[i],
        style: const TextStyle(
          fontSize: 9,
          color: Color(0xFF9CA3AF),
        ),
      );
      textPainter.layout();
      final y = size.height - (i * size.height / 5) - textPainter.height / 2;
      textPainter.paint(canvas, Offset(0, y));
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 5; i++) {
      final y = size.height - (i * size.height / 5);
      canvas.drawLine(
        Offset(30, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    final chartWidth = size.width - 40;
    final chartHeight = size.height;
    final step = data.length > 1 ? chartWidth / (data.length - 1) : chartWidth;

    // Draw filled area
    final fillPath = Path();
    fillPath.moveTo(30, chartHeight);
    for (int i = 0; i < data.length; i++) {
      final x = 30 + (i * step);
      final y = chartHeight - (data[i].clamp(0, 100) * chartHeight / 100);
      fillPath.lineTo(x, y);
    }
    fillPath.lineTo(30 + chartWidth, chartHeight);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.3),
            const Color(0xFF3B82F6).withOpacity(0.05),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill,
    );

    // Draw line
    final linePath = Path();
    for (int i = 0; i < data.length; i++) {
      final x = 30 + (i * step);
      final y = chartHeight - (data[i].clamp(0, 100) * chartHeight / 100);
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = const Color(0xFF3B82F6)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    // Draw dot at last data point
    if (data.isNotEmpty) {
      final lastIdx = data.length - 1;
      final dotX = 30 + (lastIdx * step);
      final dotY = chartHeight - (data[lastIdx].clamp(0, 100) * chartHeight / 100);

      canvas.drawCircle(
        Offset(dotX, dotY),
        5,
        Paint()
          ..color = const Color(0xFF3B82F6)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(dotX, dotY),
        3,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HumidityChartPainter oldDelegate) =>
      data != oldDelegate.data;
}
