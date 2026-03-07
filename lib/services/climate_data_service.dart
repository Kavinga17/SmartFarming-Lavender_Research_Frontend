import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'climate_api_service.dart';

/// Firestore service for persisting climate control data.
///
/// Collection structure:
///   climate_readings/{docId}
///     ├─ air_temp        (double)  – Greenhouse air temperature °C
///     ├─ humidity         (double)  – Relative humidity %
///     ├─ soil_temp        (double)  – Soil temperature °C
///     ├─ fan_speed        (double)  – AI-predicted fan speed 0-100
///     ├─ fan_level        (int)     – Derived fan level 1-4
///     ├─ humidifier_mode  (int)     – AI-predicted mode 0-3
///     ├─ effective_humidifier_level (int) – Actual level sent to Arduino
///     ├─ humidifier_control_mode (String) – off / manual / auto
///     ├─ humidifier_label (String)  – Off / Low / Medium / High
///     ├─ target_temp      (double)  – User target temperature
///     ├─ target_humidity  (double)  – User target humidity
///     ├─ user_id          (String)  – Firebase Auth UID
///     ├─ timestamp        (Timestamp)
///     └─ source           (String)  – 'api_prediction'
class ClimateDataService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collection = 'climate_readings';

  // ─── Write ────────────────────────────────────────────────────────────────

  /// Save a climate prediction + sensor snapshot to Firestore.
  static Future<void> saveReading({
    required ClimatePrediction prediction,
    required double targetTemp,
    required double targetHumidity,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      print('💾 SAVE: uid=$uid, airTemp=${prediction.airTemp}, humidity=${prediction.humidity}, fanSpeed=${prediction.fanSpeed}');
      final doc = prediction.toMap()
        ..addAll({
          'target_temp': targetTemp,
          'target_humidity': targetHumidity,
          'user_id': uid ?? 'anonymous',
          'timestamp': FieldValue.serverTimestamp(),
          'source': 'api_prediction',
        });
      print('💾 SAVE: document keys = ${doc.keys.toList()}');
      final docRef = await _db.collection(_collection).add(doc);
      print('💾 SAVE SUCCESS: docId=${docRef.id}, collection=$_collection');
    } catch (e, stack) {
      print('⚠️ Failed to save climate reading: $e');
      print('⚠️ Save stack: $stack');
    }
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  /// Get the latest climate reading from Firestore (for offline fallback).
  static Future<ClimatePrediction?> getLatestReading() async {
    try {
      final uid = _auth.currentUser?.uid;
      Query<Map<String, dynamic>> query = _db
          .collection(_collection)
          .orderBy('timestamp', descending: true)
          .limit(1);

      if (uid != null) {
        query = _db
            .collection(_collection)
            .where('user_id', isEqualTo: uid)
            .orderBy('timestamp', descending: true)
            .limit(1);
      }

      final snap = await query.get();
      if (snap.docs.isEmpty) return null;

      final data = snap.docs.first.data();
      return ClimatePrediction(
        fanSpeed: (data['fan_speed'] as num?)?.toDouble() ?? 0.0,
        effectiveFanSpeed: (data['effective_fan_speed'] as num?)?.toDouble() ?? (data['fan_speed'] as num?)?.toDouble() ?? 0.0,
        fanMode: data['fan_mode'] as String? ?? 'auto',
        humidifierMode: (data['humidifier_mode'] as num?)?.toInt() ?? 0,
        effectiveHumidifierLevel: (data['effective_humidifier_level'] as num?)?.toInt() ?? (data['humidifier_mode'] as num?)?.toInt() ?? 0,
        humidifierControlMode: data['humidifier_control_mode'] as String? ?? 'auto',
        airTemp: (data['air_temp'] as num?)?.toDouble() ?? 0.0,
        humidity: (data['humidity'] as num?)?.toDouble() ?? 0.0,
        soilTemp: (data['soil_temp'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      print('⚠️ Failed to load latest climate reading: $e');
      return null;
    }
  }

  /// Stream the latest N climate readings (for charts / history).
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamReadings({
    int limit = 50,
  }) {
    final uid = _auth.currentUser?.uid;
    Query<Map<String, dynamic>> query = _db
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (uid != null) {
      query = _db
          .collection(_collection)
          .where('user_id', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .limit(limit);
    }

    return query.snapshots();
  }

  /// Get climate readings within a date range.
  static Future<List<Map<String, dynamic>>> getReadingsByDateRange({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      Query<Map<String, dynamic>> query = _db
          .collection(_collection)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(to))
          .orderBy('timestamp', descending: true);

      if (uid != null) {
        query = _db
            .collection(_collection)
            .where('user_id', isEqualTo: uid)
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
            .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(to))
            .orderBy('timestamp', descending: true);
      }

      final snap = await query.get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      print('⚠️ Failed to load climate readings by date: $e');
      return [];
    }
  }

  // ─── Cleanup ──────────────────────────────────────────────────────────────

  /// Keep only the most recent [keep] documents per user (call periodically).
  static Future<void> pruneOldReadings({int keep = 500}) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final snap = await _db
          .collection(_collection)
          .where('user_id', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .get();

      if (snap.docs.length <= keep) return;

      final batch = _db.batch();
      for (int i = keep; i < snap.docs.length; i++) {
        batch.delete(snap.docs[i].reference);
      }
      await batch.commit();
      print('🗑️ Pruned ${snap.docs.length - keep} old climate readings');
    } catch (e) {
      print('⚠️ Failed to prune old readings: $e');
    }
  }

  // ─── Aggregation helpers ──────────────────────────────────────────────────

  /// Quick diagnostic: check if ANY documents exist in the collection.
  /// Uses the simplest possible query (no filters, no orderBy).
  static Future<void> debugCheckCollection() async {
    try {
      final uid = _auth.currentUser?.uid;
      print('🔍 DEBUG: uid=$uid, collection=$_collection');

      // 1) Count ALL docs in collection (no filter at all)
      final allSnap = await _db.collection(_collection).limit(5).get();
      print('🔍 DEBUG: total docs in collection (up to 5) = ${allSnap.docs.length}');
      for (final doc in allSnap.docs) {
        final d = doc.data();
        print('🔍 DEBUG: doc ${doc.id} => user_id=${d['user_id']}, timestamp=${d['timestamp']}, air_temp=${d['air_temp']}');
      }

      // 2) Count docs for this user_id (no orderBy — safest)
      if (uid != null) {
        final userSnap = await _db
            .collection(_collection)
            .where('user_id', isEqualTo: uid)
            .limit(5)
            .get();
        print('🔍 DEBUG: docs for uid=$uid (up to 5) = ${userSnap.docs.length}');
      }
    } catch (e) {
      print('🔍 DEBUG ERROR: $e');
    }
  }

  /// Fetch the most recent [limit] climate readings.
  /// First tries user_id + orderBy (needs composite index).
  /// Falls back to user_id only (no orderBy) if index is missing.
  /// Falls back to all docs (no filter) as last resort.
  static Future<List<Map<String, dynamic>>> getRecentReadings({
    int limit = 200,
  }) async {
    final uid = _auth.currentUser?.uid;
    print('📊 getRecentReadings: uid=$uid, limit=$limit');

    // ── Attempt 1: user_id + orderBy timestamp (composite index) ──
    try {
      Query<Map<String, dynamic>> query;
      if (uid != null) {
        query = _db
            .collection(_collection)
            .where('user_id', isEqualTo: uid)
            .orderBy('timestamp', descending: true)
            .limit(limit);
      } else {
        query = _db
            .collection(_collection)
            .orderBy('timestamp', descending: true)
            .limit(limit);
      }
      final snap = await query.get();
      print('📊 getRecentReadings (indexed): fetched ${snap.docs.length} docs');
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) => d.data()).toList();
      }
    } catch (e) {
      print('⚠️ getRecentReadings indexed query failed: $e');
      print('   → Falling back to non-indexed query...');
    }

    // ── Attempt 2: user_id only, no orderBy (no composite index needed) ──
    try {
      Query<Map<String, dynamic>> query;
      if (uid != null) {
        query = _db
            .collection(_collection)
            .where('user_id', isEqualTo: uid)
            .limit(limit);
      } else {
        query = _db.collection(_collection).limit(limit);
      }
      final snap = await query.get();
      print('📊 getRecentReadings (no-orderBy): fetched ${snap.docs.length} docs');
      if (snap.docs.isNotEmpty) {
        // Sort client-side
        final list = snap.docs.map((d) => d.data()).toList();
        list.sort((a, b) {
          final tA = a['timestamp'];
          final tB = b['timestamp'];
          if (tA == null && tB == null) return 0;
          if (tA == null) return 1;
          if (tB == null) return -1;
          return (tB as Timestamp).compareTo(tA as Timestamp);
        });
        return list;
      }
    } catch (e) {
      print('⚠️ getRecentReadings user-only query failed: $e');
    }

    // ── Attempt 3: no filter at all (last resort) ──
    try {
      final snap = await _db.collection(_collection).limit(limit).get();
      print('📊 getRecentReadings (all docs fallback): fetched ${snap.docs.length} docs');
      final list = snap.docs.map((d) => d.data()).toList();
      list.sort((a, b) {
        final tA = a['timestamp'];
        final tB = b['timestamp'];
        if (tA == null && tB == null) return 0;
        if (tA == null) return 1;
        if (tB == null) return -1;
        return (tB as Timestamp).compareTo(tA as Timestamp);
      });
      return list;
    } catch (e) {
      print('⚠️ getRecentReadings all-docs fallback failed: $e');
      return [];
    }
  }

  /// Get recent climate readings as parsed [ClimateReading] objects.
  /// [period]: 'today', '7days', '30days', or defaults to 30 days.
  /// Uses getRecentReadings + client-side date filtering to avoid
  /// needing a Firestore composite index on timestamp range.
  static Future<List<ClimateReading>> getReadingsForPeriod(String period) async {
    DateTime from;
    final now = DateTime.now();
    switch (period) {
      case 'today':
        from = DateTime(now.year, now.month, now.day);
        break;
      case '7days':
        from = now.subtract(const Duration(days: 7));
        break;
      case '30days':
      default:
        from = now.subtract(const Duration(days: 30));
        break;
    }
    // Use the simple query (no range filter) then filter client-side
    final rawList = await getRecentReadings(limit: 500);
    print('📊 getReadingsForPeriod($period): raw=${rawList.length}');
    final readings = rawList
        .map((d) => ClimateReading.fromMap(d))
        .where((r) {
          if (r.timestamp == null) return false;
          return r.timestamp!.isAfter(from) && r.timestamp!.isBefore(now.add(const Duration(minutes: 1)));
        })
        .toList()
      ..sort((a, b) => a.timestamp!.compareTo(b.timestamp!));
    print('📊 getReadingsForPeriod($period): after filter=${readings.length}');
    return readings;
  }

  /// Compute summary statistics for a list of readings.
  static ClimateStats computeStats(List<ClimateReading> readings) {
    if (readings.isEmpty) return ClimateStats.empty();
    double sumTemp = 0, sumHum = 0, sumSoil = 0, sumFan = 0;
    double minTemp = double.infinity, maxTemp = double.negativeInfinity;
    double minHum = double.infinity, maxHum = double.negativeInfinity;
    double minFan = double.infinity, maxFan = double.negativeInfinity;
    for (final r in readings) {
      sumTemp += r.airTemp;
      sumHum += r.humidity;
      sumSoil += r.soilTemp;
      sumFan += r.fanSpeed;
      if (r.airTemp < minTemp) minTemp = r.airTemp;
      if (r.airTemp > maxTemp) maxTemp = r.airTemp;
      if (r.humidity < minHum) minHum = r.humidity;
      if (r.humidity > maxHum) maxHum = r.humidity;
      if (r.fanSpeed < minFan) minFan = r.fanSpeed;
      if (r.fanSpeed > maxFan) maxFan = r.fanSpeed;
    }
    final n = readings.length;
    return ClimateStats(
      avgTemp: sumTemp / n,
      avgHumidity: sumHum / n,
      avgSoilTemp: sumSoil / n,
      avgFanSpeed: sumFan / n,
      minTemp: minTemp,
      maxTemp: maxTemp,
      minHumidity: minHum,
      maxHumidity: maxHum,
      minFanSpeed: minFan,
      maxFanSpeed: maxFan,
      totalReadings: n,
    );
  }

  /// Downsample readings into [buckets] evenly spaced averages (for charts).
  static List<ClimateReading> downsample(List<ClimateReading> readings, int buckets) {
    if (readings.isEmpty) return [];
    if (readings.length <= buckets) return readings;
    final result = <ClimateReading>[];
    final bucketSize = readings.length / buckets;
    for (int i = 0; i < buckets; i++) {
      final start = (i * bucketSize).floor();
      final end = ((i + 1) * bucketSize).floor().clamp(start + 1, readings.length);
      final slice = readings.sublist(start, end);
      final avgTemp = slice.map((r) => r.airTemp).reduce((a, b) => a + b) / slice.length;
      final avgHum = slice.map((r) => r.humidity).reduce((a, b) => a + b) / slice.length;
      final avgSoil = slice.map((r) => r.soilTemp).reduce((a, b) => a + b) / slice.length;
      final avgFan = slice.map((r) => r.fanSpeed).reduce((a, b) => a + b) / slice.length;
      result.add(ClimateReading(
        airTemp: avgTemp,
        humidity: avgHum,
        soilTemp: avgSoil,
        fanSpeed: avgFan,
        fanMode: slice.last.fanMode,
        humidifierMode: slice.last.humidifierMode,
        effectiveHumidifierLevel: slice.last.effectiveHumidifierLevel,
        humidifierControlMode: slice.last.humidifierControlMode,
        timestamp: slice[slice.length ~/ 2].timestamp,
      ));
    }
    return result;
  }
}

/// A single parsed climate reading with timestamp.
class ClimateReading {
  final double airTemp;
  final double humidity;
  final double soilTemp;
  final double fanSpeed;
  final String fanMode;
  final int humidifierMode;
  final int effectiveHumidifierLevel;
  final String humidifierControlMode;
  final DateTime? timestamp;

  ClimateReading({
    required this.airTemp,
    required this.humidity,
    required this.soilTemp,
    required this.fanSpeed,
    this.fanMode = 'auto',
    this.humidifierMode = 0,
    this.effectiveHumidifierLevel = 0,
    this.humidifierControlMode = 'auto',
    this.timestamp,
  });

  factory ClimateReading.fromMap(Map<String, dynamic> d) {
    DateTime? ts;
    final rawTs = d['timestamp'];
    if (rawTs is Timestamp) {
      ts = rawTs.toDate();
    } else if (rawTs is DateTime) {
      ts = rawTs;
    } else if (rawTs != null) {
      print('⚠️ ClimateReading.fromMap: unexpected timestamp type: ${rawTs.runtimeType} = $rawTs');
    }
    final aiHum = (d['humidifier_mode'] as num?)?.toInt() ?? 0;
    return ClimateReading(
      airTemp: (d['air_temp'] as num?)?.toDouble() ?? 0.0,
      humidity: (d['humidity'] as num?)?.toDouble() ?? 0.0,
      soilTemp: (d['soil_temp'] as num?)?.toDouble() ?? 0.0,
      fanSpeed: (d['effective_fan_speed'] as num?)?.toDouble() ??
          (d['fan_speed'] as num?)?.toDouble() ?? 0.0,
      fanMode: d['fan_mode'] as String? ?? 'auto',
      humidifierMode: aiHum,
      effectiveHumidifierLevel: (d['effective_humidifier_level'] as num?)?.toInt() ?? aiHum,
      humidifierControlMode: d['humidifier_control_mode'] as String? ?? 'auto',
      timestamp: ts,
    );
  }
}

/// Aggregated statistics for a set of climate readings.
class ClimateStats {
  final double avgTemp;
  final double avgHumidity;
  final double avgSoilTemp;
  final double avgFanSpeed;
  final double minTemp, maxTemp;
  final double minHumidity, maxHumidity;
  final double minFanSpeed, maxFanSpeed;
  final int totalReadings;

  ClimateStats({
    required this.avgTemp,
    required this.avgHumidity,
    required this.avgSoilTemp,
    required this.avgFanSpeed,
    required this.minTemp,
    required this.maxTemp,
    required this.minHumidity,
    required this.maxHumidity,
    required this.minFanSpeed,
    required this.maxFanSpeed,
    required this.totalReadings,
  });

  factory ClimateStats.empty() => ClimateStats(
    avgTemp: 0, avgHumidity: 0, avgSoilTemp: 0, avgFanSpeed: 0,
    minTemp: 0, maxTemp: 0, minHumidity: 0, maxHumidity: 0,
    minFanSpeed: 0, maxFanSpeed: 0, totalReadings: 0,
  );
}
