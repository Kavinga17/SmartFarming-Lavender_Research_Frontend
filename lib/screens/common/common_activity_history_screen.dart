import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// Unified model for a single activity entry from any Firestore collection.
class ActivityItem {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final DateTime time;
  final String source; // 'climate' or 'disease'
  final Map<String, dynamic> rawData;

  ActivityItem({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    this.subtitle = '',
    required this.time,
    required this.source,
    this.rawData = const {},
  });
}

/// Full-screen page showing all recent activities from Firestore.
class ActivityHistoryScreen extends StatefulWidget {
  /// Optional filter: 'all', 'climate', 'disease'
  final String filter;
  const ActivityHistoryScreen({super.key, this.filter = 'all'});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<ActivityItem> _allActivities = [];
  List<ActivityItem> _climateActivities = [];
  List<ActivityItem> _diseaseActivities = [];

  // Colors matching the app theme
  static const Color primaryGreen = Color(0xFF22C55E);
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.filter == 'climate'
        ? 1
        : widget.filter == 'disease'
            ? 2
            : 0;
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIndex);
    _loadActivities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final climate = await _loadClimateActivities(uid);
    final disease = await _loadDiseaseActivities(uid);

    final all = [...climate, ...disease]
      ..sort((a, b) => b.time.compareTo(a.time));

    if (mounted) {
      setState(() {
        _climateActivities = climate;
        _diseaseActivities = disease;
        _allActivities = all;
        _isLoading = false;
      });
    }
  }

  Future<List<ActivityItem>> _loadClimateActivities(String? uid) async {
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [];

    // Attempt 1: user_id + orderBy (requires composite index)
    if (uid != null) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('climate_readings')
            .where('user_id', isEqualTo: uid)
            .orderBy('timestamp', descending: true)
            .limit(50)
            .get();
        docs = snap.docs;
      } catch (e) {
        print('⚠️ Climate indexed query failed: $e');
      }
    }

    // Attempt 2: orderBy only (no user filter)
    if (docs.isEmpty) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('climate_readings')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .get();
        docs = snap.docs;
      } catch (e) {
        print('⚠️ Climate orderBy query failed: $e');
      }
    }

    // Attempt 3: no filter at all
    if (docs.isEmpty) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('climate_readings')
            .limit(50)
            .get();
        docs = snap.docs;
      } catch (e) {
        print('⚠️ Climate fallback query failed: $e');
        return [];
      }
    }

    final items = <ActivityItem>[];
    for (final doc in docs) {
      final d = doc.data();
      final ts = _parseTimestamp(d['timestamp']);
      if (ts == null) continue;

      final fanSpeed = (d['effective_fan_speed'] as num?)?.toDouble() ??
          (d['fan_speed'] as num?)?.toDouble() ?? 0.0;
      final fanMode = d['fan_mode'] as String? ?? 'auto';
      final airTemp = (d['air_temp'] as num?)?.toDouble() ?? 0.0;
      final humidity = (d['humidity'] as num?)?.toDouble() ?? 0.0;
      final soilTemp = (d['soil_temp'] as num?)?.toDouble() ?? 0.0;
      final humLevel = (d['effective_humidifier_level'] as num?)?.toInt() ??
          (d['humidifier_mode'] as num?)?.toInt() ?? 0;
      final humLabels = ['Off', 'Low', 'Medium', 'High'];
      final humLabel = humLevel >= 0 && humLevel < humLabels.length
          ? humLabels[humLevel]
          : 'Off';

      items.add(ActivityItem(
        icon: Icons.thermostat_outlined,
        iconBgColor: const Color(0xFFFEF3C7),
        iconColor: const Color(0xFFF59E0B),
        title: 'Temp: ${airTemp.toStringAsFixed(1)}°C | Humidity: ${humidity.toStringAsFixed(1)}%',
        subtitle: 'Fan: $fanMode ${fanSpeed.toStringAsFixed(0)}% · Humidifier: $humLabel · Soil: ${soilTemp.toStringAsFixed(1)}°C',
        time: ts,
        source: 'climate',
        rawData: d,
      ));
    }

    // Sort client-side if we used the no-orderBy fallback
    items.sort((a, b) => b.time.compareTo(a.time));
    return items;
  }

  Future<List<ActivityItem>> _loadDiseaseActivities(String? uid) async {
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [];

    // Attempt 1: user_id + orderBy (requires composite index)
    if (uid != null) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('lavender_detections')
            .where('user_id', isEqualTo: uid)
            .orderBy('timestamp', descending: true)
            .limit(50)
            .get();
        docs = snap.docs;
      } catch (e) {
        print('⚠️ Disease indexed query failed: $e');
      }
    }

    // Attempt 2: orderBy only (no user filter)
    if (docs.isEmpty) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('lavender_detections')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .get();
        docs = snap.docs;
      } catch (e) {
        print('⚠️ Disease orderBy query failed: $e');
      }
    }

    // Attempt 3: no filter at all
    if (docs.isEmpty) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('lavender_detections')
            .limit(50)
            .get();
        docs = snap.docs;
      } catch (e) {
        print('⚠️ Disease fallback query failed: $e');
        return [];
      }
    }

    final items = <ActivityItem>[];
    for (final doc in docs) {
      final d = doc.data();
      final ts = _parseTimestamp(d['timestamp'] ?? d['date_time']);
      if (ts == null) continue;

      final status = d['overall_status'] as String? ?? 'Unknown';
      final diseaseCount = (d['disease_count'] as num?)?.toInt() ?? 0;
      final healthyCount = (d['healthy_count'] as num?)?.toInt() ?? 0;
      final totalCount = (d['detection_count'] as num?)?.toInt() ?? 0;
      final hasDisease = d['has_disease'] == true;

      items.add(ActivityItem(
        icon: hasDisease ? Icons.warning_amber : Icons.check_circle_outline,
        iconBgColor: hasDisease ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
        iconColor: hasDisease ? const Color(0xFFEF4444) : primaryGreen,
        title: status,
        subtitle: 'Detections: $totalCount (Disease: $diseaseCount, Healthy: $healthyCount)',
        time: ts,
        source: 'disease',
        rawData: d,
      ));
    }

    items.sort((a, b) => b.time.compareTo(a.time));
    return items;
  }

  DateTime? _parseTimestamp(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(time);
  }

  void _showActivityDetail(ActivityItem activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ActivityDetailSheet(activity: activity),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Activity History',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryPurple,
          unselectedLabelColor: textGrey,
          indicatorColor: primaryPurple,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: 'All (${_allActivities.length})'),
            Tab(text: 'Climate (${_climateActivities.length})'),
            Tab(text: 'Disease (${_diseaseActivities.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActivityList(_allActivities),
                _buildActivityList(_climateActivities),
                _buildActivityList(_diseaseActivities),
              ],
            ),
    );
  }

  Widget _buildActivityList(List<ActivityItem> activities) {
    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No activities yet',
              style: TextStyle(fontSize: 16, color: textGrey),
            ),
          ],
        ),
      );
    }

    // Group activities by date
    final grouped = <String, List<ActivityItem>>{};
    for (final a in activities) {
      final key = DateFormat('EEEE, MMM d, yyyy').format(a.time);
      grouped.putIfAbsent(key, () => []).add(a);
    }

    return RefreshIndicator(
      onRefresh: _loadActivities,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: grouped.length,
        itemBuilder: (ctx, groupIndex) {
          final dateKey = grouped.keys.elementAt(groupIndex);
          final items = grouped[dateKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (groupIndex > 0) const SizedBox(height: 16),
              // Date header
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  dateKey,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textGrey,
                  ),
                ),
              ),
              // Activity items for this date
              ...items.map((activity) => _buildActivityTile(activity)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActivityTile(ActivityItem activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        splashColor: activity.iconColor.withOpacity(0.1),
        highlightColor: activity.iconColor.withOpacity(0.05),
        onTap: () => _showActivityDetail(activity),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: activity.iconColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
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
                color: activity.iconBgColor,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(activity.icon, color: activity.iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
                  if (activity.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      activity.subtitle,
                      style: TextStyle(fontSize: 11, color: textGrey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    _formatTimeAgo(activity.time),
                    style: TextStyle(fontSize: 11, color: textGrey.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
            // Source badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: activity.source == 'climate'
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                activity.source == 'climate' ? '🌡️' : '🌿',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 20),
          ],
        ),
      ),
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity Detail Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityDetailSheet extends StatelessWidget {
  final ActivityItem activity;
  const _ActivityDetailSheet({required this.activity});

  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: activity.iconBgColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(activity.icon, color: activity.iconColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: activity.source == 'climate'
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            activity.source == 'climate'
                                ? '🌡️ Climate Control'
                                : '🌿 Disease Detection',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Timestamp
              Row(
                children: [
                  Icon(Icons.access_time, size: 15, color: textGrey),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('EEEE, MMM d, yyyy • h:mm a').format(activity.time),
                    style: TextStyle(fontSize: 13, color: textGrey),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              // Detail fields
              if (activity.source == 'climate') _buildClimateDetails(),
              if (activity.source == 'disease') _buildDiseaseDetails(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClimateDetails() {
    final d = activity.rawData;
    final airTemp = (d['air_temp'] as num?)?.toDouble() ?? 0.0;
    final humidity = (d['humidity'] as num?)?.toDouble() ?? 0.0;
    final soilTemp = (d['soil_temp'] as num?)?.toDouble() ?? 0.0;
    final fanSpeed = (d['effective_fan_speed'] as num?)?.toDouble() ??
        (d['fan_speed'] as num?)?.toDouble() ?? 0.0;
    final fanMode = d['fan_mode'] as String? ?? 'auto';
    final humLevel = (d['effective_humidifier_level'] as num?)?.toInt() ??
        (d['humidifier_mode'] as num?)?.toInt() ?? 0;
    final humMode = d['humidifier_control_mode'] as String? ?? 'auto';
    final targetTemp = (d['target_temp'] as num?)?.toDouble();
    final targetHum = (d['target_humidity'] as num?)?.toDouble();
    final humLabels = ['Off', 'Low', 'Medium', 'High'];
    final humLabel = humLevel >= 0 && humLevel < humLabels.length
        ? humLabels[humLevel]
        : 'Off';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sensor Readings',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
        ),
        const SizedBox(height: 12),
        _detailRow(Icons.thermostat_outlined, 'Air Temperature', '${airTemp.toStringAsFixed(1)}°C',
            const Color(0xFFEF4444)),
        _detailRow(Icons.water_drop_outlined, 'Humidity', '${humidity.toStringAsFixed(1)}%',
            const Color(0xFF3B82F6)),
        _detailRow(Icons.grass, 'Soil Temperature', '${soilTemp.toStringAsFixed(1)}°C',
            const Color(0xFF8B5CF6)),
        if (targetTemp != null)
          _detailRow(Icons.track_changes, 'Target Temperature', '${targetTemp.toStringAsFixed(1)}°C',
              Colors.orange),
        if (targetHum != null)
          _detailRow(Icons.track_changes, 'Target Humidity', '${targetHum.toStringAsFixed(1)}%',
              Colors.cyan),
        const SizedBox(height: 16),
        const Text(
          'Control Status',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
        ),
        const SizedBox(height: 12),
        _detailRow(Icons.air, 'Fan Speed', '${fanSpeed.toStringAsFixed(0)}%',
            const Color(0xFFEC4899)),
        _detailRow(Icons.settings, 'Fan Mode', _capitalize(fanMode),
            const Color(0xFF8B5CF6)),
        _detailRow(Icons.water, 'Humidifier Level', humLabel,
            const Color(0xFF3B82F6)),
        _detailRow(Icons.settings, 'Humidifier Mode', _capitalize(humMode),
            const Color(0xFF8B5CF6)),
      ],
    );
  }

  Widget _buildDiseaseDetails() {
    final d = activity.rawData;
    final status = d['overall_status'] as String? ?? 'Unknown';
    final diseaseCount = (d['disease_count'] as num?)?.toInt() ?? 0;
    final healthyCount = (d['healthy_count'] as num?)?.toInt() ?? 0;
    final totalCount = (d['detection_count'] as num?)?.toInt() ?? 0;
    final hasDisease = d['has_disease'] == true;
    final detections = d['detections'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: hasDisease
                ? const Color(0xFFFEE2E2)
                : const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasDisease
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFF86EFAC),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasDisease ? Icons.warning_amber : Icons.check_circle,
                color: hasDisease ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                status,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: hasDisease ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Detection Summary',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
        ),
        const SizedBox(height: 12),
        _detailRow(Icons.search, 'Total Detections', '$totalCount',
            const Color(0xFF8B5CF6)),
        _detailRow(Icons.warning, 'Diseased', '$diseaseCount',
            const Color(0xFFEF4444)),
        _detailRow(Icons.check_circle_outline, 'Healthy', '$healthyCount',
            const Color(0xFF22C55E)),
        if (detections.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Individual Detections',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
          ),
          const SizedBox(height: 10),
          ...detections.map((det) {
            final className = det['class_name'] as String? ?? 'Unknown';
            final confidence = (det['confidence'] as num?)?.toDouble() ?? 0.0;
            final isDiseased = className == 'Lavender_Disease';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDiseased ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDiseased ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isDiseased ? Icons.warning : Icons.check,
                    color: isDiseased ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      className,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                  ),
                  Text(
                    '${(confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 12, color: textGrey),
                  ),
                ],
              ),
            );
          }),
        ],
        // Annotated image
        if (d['annotated_image_base64'] != null &&
            (d['annotated_image_base64'] as String).isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Annotated Image',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              Uri.parse('data:image/jpeg;base64,${d['annotated_image_base64']}')
                  .data!
                  .contentAsBytes(),
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: textGrey),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

/// Helper to show activity detail bottom sheet from anywhere.
void showActivityDetailSheet(BuildContext context, {
  required IconData icon,
  required Color iconBgColor,
  required Color iconColor,
  required String title,
  String subtitle = '',
  required DateTime time,
  required String source,
  Map<String, dynamic> rawData = const {},
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ActivityDetailSheet(
      activity: ActivityItem(
        icon: icon,
        iconBgColor: iconBgColor,
        iconColor: iconColor,
        title: title,
        subtitle: subtitle,
        time: time,
        source: source,
        rawData: rawData,
      ),
    ),
  );
}
