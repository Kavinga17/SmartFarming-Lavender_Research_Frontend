import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:async';
import '../services/climate_api_service.dart';
import '../services/climate_data_service.dart';
import '../services/sensor_data_service.dart';

// Colors - defined at module level
const Color backgroundColor = Color(0xFFF8F9FA);
const Color primaryPurple = Color(0xFF8B5CF6);
const Color primaryGreen = Color(0xFF22C55E);
const Color primaryBlue = Color(0xFF3B82F6);
const Color textDark = Color(0xFF1F2937);
const Color textGrey = Color(0xFF6B7280);
const Color cardBackground = Colors.white;

class VentingModeScreen extends StatefulWidget {
  final int? initialFanLevel;
  final double? currentAirTemp;
  final double? currentHumidity;
  final double? currentSoilTemp;
  final double? targetTemp;
  final double? targetHumidity;
  final double? prevFanSpeed;
  final double? prevHumidifierMode;

  const VentingModeScreen({
    super.key,
    this.initialFanLevel,
    this.currentAirTemp,
    this.currentHumidity,
    this.currentSoilTemp,
    this.targetTemp,
    this.targetHumidity,
    this.prevFanSpeed,
    this.prevHumidifierMode,
  });

  @override
  State<VentingModeScreen> createState() => _VentingModeScreenState();
}

class _VentingModeScreenState extends State<VentingModeScreen> {
  // 0 = Off, 1 = Manual, 2 = Auto
  int _selectedMode = 2;
  bool _isManualFanOn = false;
  int _manualSpeed = 50; // 1-100 manual speed
  int _selectedMetric = 2;

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

  // Dynamic ventilation chart data
  List<double> _ventChartData = [];
  List<String> _ventChartLabels = [];
  double _ventAvg = 0.0;

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
    _loadVentilationChartData();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _sensorSubscription?.cancel();
    super.dispose();
  }

  /// Load ventilation chart data from Firestore based on selected period.
  Future<void> _loadVentilationChartData() async {
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
      final data = sampled.map((r) => r.fanSpeed).toList();
      final labels = sampled.map((r) {
        if (r.timestamp == null) return '';
        if (period == 'today') return DateFormat('HH:mm').format(r.timestamp!);
        return DateFormat('dd/MM').format(r.timestamp!);
      }).toList();
      final stats = ClimateDataService.computeStats(readings);
      if (mounted) {
        setState(() {
          _ventChartData = data;
          _ventChartLabels = labels;
          _ventAvg = stats.avgFanSpeed;
        });
      }
    } catch (e) {
      print('⚠️ Failed to load ventilation chart data: $e');
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
      onError: (e) => print('⚠️ Sensor stream error: $e'),
    );
  }

  Future<void> _initApi() async {
    final connected = await ClimateApiService.checkHealth();
    if (mounted) {
      setState(() => _isServerConnected = connected);
      if (connected) {
        await _loadFanState();
        await _fetchPrediction();
      }
    }
    // Auto-refresh in auto mode every 15 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (_selectedMode == 2 && _isServerConnected) {
        await _fetchPrediction();
      }
    });
  }

  /// Load the current fan state from the backend.
  Future<void> _loadFanState() async {
    final state = await ClimateApiService.getFanState();
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
        _isManualFanOn = state.manualOn;
        _manualSpeed = state.manualSpeed > 0 ? state.manualSpeed : 50;
      });
    }
  }

  /// Set fan mode on the backend and update local state.
  Future<void> _setFanMode(int mode) async {
    if (_isSendingCommand) return;
    setState(() => _isSendingCommand = true);

    final modeStr = mode == 0 ? 'off' : mode == 1 ? 'manual' : 'auto';
    final result = await ClimateApiService.setFanMode(modeStr);

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

  /// Send manual fan on/off and speed to the backend.
  Future<void> _sendManualControl({bool? on, int? speed}) async {
    if (_selectedMode != 1) return;
    final result = await ClimateApiService.setFanManual(on: on, speed: speed);
    if (result != null && mounted) {
      setState(() {
        if (on != null) _isManualFanOn = on;
        if (speed != null) _manualSpeed = speed;
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
                    // Speed Control (slider for manual, display for auto)
                    _buildSpeedControl(),
                    const SizedBox(height: 20),
                    // Toggle Switch (manual mode only)
                    if (_selectedMode == 1) _buildToggleSwitch(),
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
                    // Ventilation Chart
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildVentilationChart(),
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
            color: const Color(0xFFFF7A45),
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : textDark,
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
                onTap: _isSendingCommand ? null : () => _setFanMode(mode),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedControl() {
    // Determine what speed to display
    double displaySpeed;
    String modeLabel;
    bool isInteractive;

    switch (_selectedMode) {
      case 0: // Off
        displaySpeed = 0;
        modeLabel = 'Fan is OFF';
        isInteractive = false;
        break;
      case 1: // Manual
        displaySpeed = _isManualFanOn ? _manualSpeed.toDouble() : 0;
        modeLabel = _isManualFanOn ? 'Manual Speed' : 'Fan is OFF (toggle ON to control)';
        isInteractive = _isManualFanOn;
        break;
      case 2: // Auto
        displaySpeed = _prediction?.effectiveFanSpeed ?? _prediction?.fanSpeed ?? 0;
        modeLabel = 'AI Controlled';
        isInteractive = false;
        break;
      default:
        displaySpeed = 0;
        modeLabel = '';
        isInteractive = false;
    }

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
              color: primaryPurple.withOpacity(0.1),
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
            // Speed display circle
            Center(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: displaySpeed > 0
                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                        : [Colors.grey.shade300, Colors.grey.shade400],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: displaySpeed > 0
                          ? const Color(0xFF10B981).withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${displaySpeed.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Speed',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
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
            // Show slider in manual mode when fan is on
            if (_selectedMode == 1 && _isManualFanOn) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('1', style: TextStyle(fontSize: 12, color: textGrey)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: const Color(0xFF10B981),
                        inactiveTrackColor: Colors.grey.shade200,
                        thumbColor: const Color(0xFF10B981),
                        overlayColor: const Color(0xFF10B981).withOpacity(0.2),
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                      ),
                      child: Slider(
                        value: _manualSpeed.toDouble(),
                        min: 1,
                        max: 100,
                        divisions: 99,
                        label: '$_manualSpeed',
                        onChanged: (value) {
                          setState(() => _manualSpeed = value.round());
                        },
                        onChangeEnd: (value) {
                          _sendManualControl(speed: value.round());
                        },
                      ),
                    ),
                  ),
                  const Text('100', style: TextStyle(fontSize: 12, color: textGrey)),
                ],
              ),
            ],
            // Show AI prediction info in auto mode
            if (_selectedMode == 2 && _prediction != null) ...[
              const SizedBox(height: 12),
              Text(
                'AI prediction: ${_prediction!.fanSpeed.toStringAsFixed(1)}%',
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

  Widget _buildToggleSwitch() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF5F5F5)],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ON',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _isManualFanOn ? primaryPurple : textGrey,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                final newState = !_isManualFanOn;
                setState(() => _isManualFanOn = newState);
                _sendManualControl(on: newState, speed: newState ? _manualSpeed : null);
              },
              child: Container(
                width: 50,
                height: 28,
                decoration: BoxDecoration(
                  gradient: _isManualFanOn
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFC084FC), Color(0xFFA855F7)],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.grey[300]!, Colors.grey[400]!],
                        ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _isManualFanOn
                          ? primaryPurple.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      alignment: _isManualFanOn
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        margin: const EdgeInsets.all(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'OFF',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: !_isManualFanOn ? primaryPurple : textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCards() {
    // Determine current effective speed for display
    double effectiveSpeed;
    switch (_selectedMode) {
      case 0:
        effectiveSpeed = 0;
        break;
      case 1:
        effectiveSpeed = _isManualFanOn ? _manualSpeed.toDouble() : 0;
        break;
      case 2:
        effectiveSpeed = _prediction?.effectiveFanSpeed ?? _prediction?.fanSpeed ?? 0;
        break;
      default:
        effectiveSpeed = 0;
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
            value: '${_airTemp.toStringAsFixed(1)}°C',
            label: 'Inside',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.thermostat_outlined,
            iconColor: const Color(0xFF10B981),
            value: '${_soilTemp.toStringAsFixed(1)}°C',
            label: 'Soil',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.speed_outlined,
            iconColor: primaryPurple,
            value: '${effectiveSpeed.toStringAsFixed(0)}%',
            label: 'Fan Speed',
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
                    _loadVentilationChartData();
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

  Widget _buildVentilationChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.air, color: primaryBlue, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Ventilation',
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
          _ventAvg > 0 ? 'Average : ${_ventAvg.toStringAsFixed(0)}%' : 'Average : --',
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
              Container(
                height: 180,
                width: double.infinity,
                child: _ventChartData.isNotEmpty
                    ? CustomPaint(
                        painter: VentilationChartPainter(data: _ventChartData),
                      )
                    : const Center(
                        child: Text('Loading chart data...', style: TextStyle(color: textGrey, fontSize: 13)),
                      ),
              ),
              const SizedBox(height: 12),
              // X-axis labels (dynamic)
              if (_ventChartLabels.isNotEmpty)
                SizedBox(
                  height: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _ventChartLabels.map((label) {
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

class VentilationChartPainter extends CustomPainter {
  final List<double> data;

  VentilationChartPainter({required this.data});

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

    // Draw line chart
    final linePaint = Paint()
      ..color = primaryBlue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final chartWidth = size.width - 40;
    final chartHeight = size.height;
    final step = data.length > 1 ? chartWidth / (data.length - 1) : chartWidth;

    for (int i = 0; i < data.length; i++) {
      final x = 30 + (i * step);
      final y = chartHeight - (data[i].clamp(0, 100) * chartHeight / 100);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant VentilationChartPainter oldDelegate) =>
      data != oldDelegate.data;
}
