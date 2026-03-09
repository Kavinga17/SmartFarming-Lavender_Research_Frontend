// lib/screens/soil_history_screen.dart
import 'package:flutter/material.dart';
import '../services/soil_backend_service.dart';
import 'diagnostic_screen.dart';
import 'soil_notification_popup.dart';

class SoilHistoryScreen extends StatefulWidget {
  const SoilHistoryScreen({super.key});

  @override
  State<SoilHistoryScreen> createState() => _SoilHistoryScreenState();
}

class _SoilHistoryScreenState extends State<SoilHistoryScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryOrange = Color(0xFFFF7A45);
  static const Color successGreen = Color(0xFF22C55E);
  static const Color warningAmber = Color(0xFFFBBF24);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color infoColor = Color(0xFF3498DB);

  late TabController _tabController;
  List<Map<String, dynamic>> _diagnosticHistory = [];
  List<Map<String, dynamic>> _wateringHistory = [];
  Map<String, dynamic>? _currentRoutine;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllHistory() async {
    setState(() => _isLoading = true);
    try {
      final diagnostic = await SoilBackendService.getAnalysisHistory(limit: 50);
      final watering = await SoilBackendService.getWateringHistory(limit: 50);
      final routine = await SoilBackendService.getCurrentRoutine();

      setState(() {
        _diagnosticHistory = diagnostic;
        _wateringHistory = watering;
        _currentRoutine = routine;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading history: $e');
      setState(() => _isLoading = false);
    }
  }

  // Format date to Indian Standard Time (IST = UTC+5:30)
  String _formatIST(String timestamp) {
    if (timestamp.isEmpty) return 'Unknown date';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      // Add 5 hours 30 minutes for IST
      final istDate = date.add(const Duration(hours: 5, minutes: 30));
      return '${istDate.day}/${istDate.month}/${istDate.year} at ${istDate.hour}:${istDate.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp.substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            // Custom tab bar matching app style
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: primaryPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: textGrey,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                dividerHeight: 0,
                tabs: const [
                  Tab(text: 'Diagnostics', icon: Icon(Icons.science, size: 18)),
                  Tab(text: 'Irrigation', icon: Icon(Icons.water_drop, size: 18)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: primaryPurple))
                  : TabBarView(
                      controller: _tabController,
                      children: [_buildDiagnosticTab(), _buildIrrigationTab()],
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
              color: primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 14, color: primaryPurple),
                const SizedBox(width: 4),
                Text(
                  'History',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: primaryPurple,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh),
            color: textDark,
            onPressed: _loadAllHistory,
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticTab() {
    if (_diagnosticHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off,
              size: 64,
              color: textGrey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No diagnostic history yet',
              style: TextStyle(color: textGrey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Run a diagnostic to see results here',
              style: TextStyle(color: textGrey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _diagnosticHistory.length,
      itemBuilder: (context, index) {
        final item = _diagnosticHistory[index];
        return _buildDiagnosticCard(item);
      },
    );
  }

  Widget _buildDiagnosticCard(Map<String, dynamic> item) {
    final threeClass = item['threeClass'] ?? {};
    final prediction = threeClass['prediction'] ?? 'unknown';
    final confidence = (threeClass['confidence'] as num?)?.toDouble() ?? 0.0;
    final yellowMeter = item['yellowMeter'];
    final diagnosis = item['diagnosis'] ?? 'No diagnosis';
    final timestamp = item['timestamp'] ?? '';

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (prediction == 'healthy') {
      statusColor = successGreen;
      statusText = 'Healthy';
      statusIcon = Icons.check_circle;
    } else if (prediction == 'nutrient_deficient') {
      statusColor = warningAmber;
      statusText = 'Deficient';
      statusIcon = Icons.warning;
    } else {
      statusColor = dangerRed;
      statusText = 'Diseased';
      statusIcon = Icons.error;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.15),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DiagnosticScreen(analysisResult: item, sensorData: {}),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatIST(timestamp),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
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
                Text(
                  diagnosis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.analytics, size: 16, color: textGrey),
                    const SizedBox(width: 4),
                    Text(
                      '${(confidence * 100).toStringAsFixed(1)}% confidence',
                      style: TextStyle(color: textGrey, fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                    if (item['moisture'] != null) ...[
                      Icon(Icons.water_drop, size: 16, color: textGrey),
                      const SizedBox(width: 4),
                      Text(
                        '${item['moisture']}% moisture',
                        style: TextStyle(color: textGrey, fontSize: 13),
                      ),
                    ],
                  ],
                ),
                if (yellowMeter != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.grass, color: warningAmber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Yellowness Level',
                                style: TextStyle(fontSize: 12, color: textGrey),
                              ),
                              const SizedBox(height: 4),
                              Stack(
                                children: [
                                  Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: backgroundColor,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor:
                                        (yellowMeter['yellowness'] ?? 0) / 100,
                                    child: Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            successGreen,
                                            warningAmber,
                                            dangerRed,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${(yellowMeter['yellowness'] as num?)?.toStringAsFixed(1) ?? '0'}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIrrigationTab() {
    return Column(
      children: [
        if (_currentRoutine != null) _buildCurrentRoutineCard(),
        Expanded(
          child: _wateringHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.water_drop_outlined,
                        size: 64,
                        color: textGrey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No watering history yet',
                        style: TextStyle(color: textGrey, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Water manually or set up a routine',
                        style: TextStyle(color: textGrey, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _wateringHistory.length,
                  itemBuilder: (context, index) {
                    final item = _wateringHistory[index];
                    return _buildHistoryEventCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCurrentRoutineCard() {
    if (_currentRoutine == null) return const SizedBox.shrink();

    final schedule = _currentRoutine?['schedule'] ?? {};
    final plantCount = _currentRoutine?['plantCount'];
    final soilType = _currentRoutine?['soilType'];

    // Only show if we have real data
    if (plantCount == null || soilType == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryPurple.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.15),
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
          // Header with icon and terminate button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.settings_input_component,
                      color: primaryPurple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Active Routine',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                ],
              ),
              // Terminate button
              ElevatedButton.icon(
                onPressed: _showTerminateDialog,
                icon: const Icon(Icons.stop_circle, size: 16),
                label: const Text('Terminate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: dangerRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(100, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Routine details
          _buildHistoryDetailRow('Plants', plantCount.toString()),
          _buildHistoryDetailRow('Soil Type', soilType),
          _buildHistoryDetailRow(
            'Water per Plant',
            '${schedule['waterPerPlant']?.toStringAsFixed(1) ?? '?'} L',
          ),
          _buildHistoryDetailRow(
            'Frequency',
            'Every ${schedule['frequencyDays'] ?? '?'} days',
          ),
          _buildHistoryDetailRow(
            'Duration',
            '${schedule['durationMinutes'] ?? '?'} minutes',
          ),
          _buildHistoryDetailRow(
            'Target Moisture',
            '${schedule['targetMoistureMin'] ?? '?'} - ${schedule['targetMoistureMax'] ?? '?'}%',
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Next watering
          Row(
            children: [
              Icon(Icons.notifications_active, color: primaryPurple, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Next: ${_formatIST(schedule['nextWatering'] ?? '')}',
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTerminateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminate Routine'),
        content: const Text(
          'Are you sure you want to terminate the current irrigation routine?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading
              if (!mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(color: primaryPurple),
                ),
              );

              final result = await SoilBackendService.terminateRoutine(
                reason: 'User terminated from history screen',
              );

              if (!mounted) return;
              Navigator.pop(context); // Close loading

              if (result != null && result['success'] == true) {
                if (!mounted) return;
                showSoilNotification(
                  context,
                  diagnosis: 'ROUTINE_TERMINATED',
                  action: 'Irrigation routine has been terminated.',
                  routineTerminated: true,
                  recommendation: result['reason']?.toString() ??
                      'User terminated from history screen',
                );
                _loadAllHistory(); // Refresh
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Failed to terminate routine'),
                    backgroundColor: dangerRed,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Terminate'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineDetailRow2(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: textGrey, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: textDark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryEventCard(Map<String, dynamic> item) {
    final type = item['type'] ?? 'unknown';
    final timestamp = item['timestamp'] ?? item['createdAt'] ?? '';
    final reason = item['reason'];
    final details = item['details'] ?? item;
    final changes = item['changes'];

    // Determine card style based on type
    Color cardColor;
    IconData icon;
    String title;

    switch (type) {
      case 'routine_created':
        cardColor = successGreen;
        icon = Icons.play_circle;
        title = 'Routine Created';
        break;
      case 'routine_terminated':
        cardColor = dangerRed;
        icon = Icons.stop_circle;
        title = reason?.toLowerCase().contains('lockout') == true
            ? 'Auto-terminated (Lockout)'
            : 'Routine Terminated';
        break;
      case 'routine_updated':
        cardColor = warningAmber;
        icon = Icons.update;
        title = 'Routine Updated';
        break;
      case 'automatic':
        cardColor = primaryPurple;
        icon = Icons.auto_awesome;
        title = 'Automatic Watering';
        break;
      case 'manual':
        cardColor = primaryOrange;
        icon = Icons.touch_app;
        title = 'Manual Watering';
        break;
      case 'watering_skipped':
        cardColor = warningAmber;
        icon = Icons.skip_next;
        title = 'Watering Skipped';
        break;
      case 'override':
        cardColor = infoColor;
        icon = Icons.settings_overscan;
        title = 'User Override';
        break;
      default:
        cardColor = textGrey;
        icon = Icons.info;
        title = type.replaceAll('_', ' ').toUpperCase();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFCFCFC)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.15),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: cardColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: cardColor,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatIST(timestamp),
                        style: TextStyle(color: textGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Show details based on type
            if (type == 'routine_created' && details != null) ...[
              const SizedBox(height: 16),
              _buildHistoryDetailRow(
                'Plants',
                '${details['plantCount'] ?? 'N/A'}',
              ),
              _buildHistoryDetailRow('Soil Type', details['soilType'] ?? 'N/A'),
              _buildHistoryDetailRow(
                'Water per Plant',
                '${details['schedule']?['waterPerPlant'] ?? '?'} L',
              ),
              _buildHistoryDetailRow(
                'Frequency',
                'Every ${details['schedule']?['frequencyDays'] ?? '?'} days',
              ),
              _buildHistoryDetailRow(
                'Duration',
                '${details['schedule']?['durationMinutes'] ?? '?'} minutes',
              ),
              _buildHistoryDetailRow(
                'Target Moisture',
                '${details['schedule']?['targetMoistureMin'] ?? '?'} - ${details['schedule']?['targetMoistureMax'] ?? '?'}%',
              ),
            ],

            if (type == 'routine_updated' && changes != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: warningAmber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: warningAmber),
                ),
                child: const Text(
                  'Routine settings were updated',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],

            if (type == 'routine_terminated' && reason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: dangerRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: dangerRed),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: dangerRed, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reason,
                        style: TextStyle(color: dangerRed, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if ((type == 'automatic' || type == 'manual') &&
                item['duration'] != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (item['duration'] != null)
                    _buildHistoryChip(
                      icon: Icons.timer,
                      label: '${item['duration']} min',
                    ),
                  if (item['waterAmount'] != null)
                    _buildHistoryChip(
                      icon: Icons.water_drop,
                      label: item['waterAmount'],
                    ),
                  if (item['moistureBefore'] != null)
                    _buildHistoryChip(
                      icon: Icons.arrow_downward,
                      label:
                          '${item['moistureBefore']}% → ${item['moistureAfter'] ?? '?'}%',
                    ),
                ],
              ),
            ],

            if (type == 'watering_skipped' && item['reason'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: warningAmber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: warningAmber),
                ),
                child: Text(
                  'Skipped: ${item['reason']}',
                  style: TextStyle(color: warningAmber, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: textGrey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: textDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryChip({
    required IconData icon,
    required String label,
    Color backgroundColor = const Color(0xFFF3F4F6),
    Color textColor = const Color(0xFF4B5563),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildRoutineDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
