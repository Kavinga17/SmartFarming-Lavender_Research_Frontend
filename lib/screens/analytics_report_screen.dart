import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/climate_data_service.dart';

// Shared colors
const Color backgroundColor = Color(0xFFF8F9FA);
const Color textDark = Color(0xFF1F2937);
const Color textGrey = Color(0xFF6B7280);
const Color primaryGreen = Color(0xFF10B981);
const Color primaryBlue = Color(0xFF3B82F6);
const Color primaryPurple = Color(0xFF8B5CF6);

class AnalyticsReportScreen extends StatefulWidget {
  const AnalyticsReportScreen({super.key});

  @override
  State<AnalyticsReportScreen> createState() => _AnalyticsReportScreenState();
}

class _AnalyticsReportScreenState extends State<AnalyticsReportScreen> {
  final GlobalKey _reportKey = GlobalKey();
  int _selectedMetric = 2; // Last month as default

  // Dynamic chart data loaded from Firestore
  List<double> _tempData = [];
  List<double> _humData = [];
  List<double> _ventData = [];
  List<String> _chartLabels = [];
  ClimateStats _stats = ClimateStats.empty();
  bool _isLoading = true;
  int _totalReadings = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  /// Load chart data from Firestore for the selected time period.
  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
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
      if (!mounted) return;
      if (readings.isEmpty) {
        setState(() {
          _tempData = [];
          _humData = [];
          _ventData = [];
          _chartLabels = [];
          _stats = ClimateStats.empty();
          _totalReadings = 0;
          _isLoading = false;
        });
        return;
      }
      final sampled = ClimateDataService.downsample(readings, 12);
      final stats = ClimateDataService.computeStats(readings);
      final labels = sampled.map((r) {
        if (r.timestamp == null) return '';
        if (period == 'today') return DateFormat('HH:mm').format(r.timestamp!);
        return DateFormat('dd/MM').format(r.timestamp!);
      }).toList();

      setState(() {
        _tempData = sampled.map((r) => r.airTemp).toList();
        _humData = sampled.map((r) => r.humidity).toList();
        _ventData = sampled.map((r) => r.fanSpeed).toList();
        _chartLabels = labels;
        _stats = stats;
        _totalReadings = readings.length;
        _isLoading = false;
      });
    } catch (e) {
      print('Failed to load analytics data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadPdf() async {
    try {
      final boundary = _reportKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final doc = pw.Document();
      final pw.ImageProvider captured = pw.MemoryImage(pngBytes);
      doc.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(12),
          build: (pw.Context ctx) => pw.Center(child: pw.Image(captured)),
        ),
      );

      await Printing.sharePdf(bytes: await doc.save(), filename: 'analytics_report.pdf');
    } catch (e) {
      // Ignore for now
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
            Expanded(
              child: SingleChildScrollView(
                child: RepaintBoundary(
                  key: _reportKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummary(),
                        const SizedBox(height: 16),
                        _buildMetricsFilter(),
                        const SizedBox(height: 16),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_totalReadings == 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.analytics_outlined, size: 48, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No data available for this period',
                                    style: TextStyle(color: textGrey, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          _buildTemperatureSection(),
                          const SizedBox(height: 16),
                          _buildHumiditySection(),
                          const SizedBox(height: 16),
                          _buildVentilationSection(),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: textDark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Analytics Report',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            color: textDark,
            onPressed: () async {
              await _downloadPdf();
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            color: textDark,
            onPressed: () async {
              await _downloadPdf();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final periodName = ['Today', 'Last 7 days', 'Last month', 'Custom'][_selectedMetric];
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Green House 01',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textDark),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SummaryColumn(items: {
                  'Plant': 'Lavender',
                  'Period': periodName,
                  'Readings': '$_totalReadings',
                  'Current AI mode': 'Active / Auto',
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryColumn(items: _totalReadings > 0
                    ? {
                        'Avg Temp': '${_stats.avgTemp.toStringAsFixed(1)}\u00B0C',
                        'Avg Humidity': '${_stats.avgHumidity.toStringAsFixed(1)}%',
                        'Avg Fan': '${_stats.avgFanSpeed.toStringAsFixed(1)}%',
                        'Temp Range': '${_stats.minTemp.toStringAsFixed(1)} - ${_stats.maxTemp.toStringAsFixed(1)}\u00B0C',
                      }
                    : {'': ''}),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsFilter() {
    final filters = ['Today', 'Last 7 days', 'Last month', 'Custom period'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (i) {
        final selected = _selectedMetric == i;
        return Padding(
          padding: EdgeInsets.only(right: i < filters.length - 1 ? 8 : 0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              splashColor: primaryPurple.withOpacity(0.15),
              highlightColor: primaryPurple.withOpacity(0.08),
              onTap: () {
                setState(() => _selectedMetric = i);
                _loadAnalyticsData();
              },
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFC084FC), Color(0xFFA855F7)],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Color(0xFFF5F5F5)],
                      ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: selected ? Colors.transparent : Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: selected ? primaryPurple.withOpacity(0.25) : Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                filters[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : textDark,
                ),
              ),
            ),
          ),
          ),
        );
      }),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, Color color, String title, String avg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Average : $avg',
          style: const TextStyle(fontSize: 13, color: textGrey),
        ),
      ],
    );
  }

  Widget _buildTemperatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          Icons.thermostat_outlined,
          primaryGreen,
          'Temperature',
          '${_stats.avgTemp.toStringAsFixed(1)}\u00B0C',
        ),
        const SizedBox(height: 8),
        Container(
          height: 160,
          width: double.infinity,
          decoration: _chartDecoration(),
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _TemperaturePainter(data: _tempData),
                ),
              ),
              if (_chartLabels.isNotEmpty) _buildXAxisLabels(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHumiditySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          Icons.water_drop,
          primaryBlue,
          'Humidity',
          '${_stats.avgHumidity.toStringAsFixed(1)}%',
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          width: double.infinity,
          decoration: _chartDecoration(),
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _HumidityPainter(data: _humData),
                ),
              ),
              if (_chartLabels.isNotEmpty) _buildXAxisLabels(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVentilationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          Icons.air,
          primaryBlue,
          'Ventilation',
          '${_stats.avgFanSpeed.toStringAsFixed(1)}%',
        ),
        const SizedBox(height: 8),
        Container(
          height: 160,
          width: double.infinity,
          decoration: _chartDecoration(),
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _VentilationPainter(data: _ventData),
                ),
              ),
              if (_chartLabels.isNotEmpty) _buildXAxisLabels(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildXAxisLabels() {
    return SizedBox(
      height: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _chartLabels.map((l) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(l, style: const TextStyle(fontSize: 8, color: textGrey)),
        )).toList(),
      ),
    );
  }

  BoxDecoration _chartDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Color(0xFFFAFAFA)],
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
      ],
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  final Map<String, String> items;
  const _SummaryColumn({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.entries.map((e) {
        if (e.key.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Text(
                e.key,
                style: const TextStyle(fontSize: 12, color: textGrey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  e.value,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textDark),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Painters
mixin _GridPainterBase {
  void drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = Colors.grey.withOpacity(0.2)..strokeWidth = 0.5;
    for (int i = 0; i <= 5; i++) {
      final y = size.height - (i * size.height / 5);
      canvas.drawLine(Offset(30, y), Offset(size.width, y), gridPaint);
    }
  }
}

class _TemperaturePainter extends CustomPainter with _GridPainterBase {
  final List<double> data;
  _TemperaturePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    drawGrid(canvas, size);
    if (data.isEmpty) return;
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final yMax = maxVal > 35 ? maxVal + 5 : 40.0;
    final path = Path();
    final chartWidth = size.width - 40;
    final chartHeight = size.height - 10;
    final step = data.length > 1 ? chartWidth / (data.length - 1) : chartWidth;
    for (int i = 0; i < data.length; i++) {
      final x = 30 + (i * step);
      final y = chartHeight - (data[i].clamp(0, yMax) * chartHeight / yMax);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, Paint()..color = primaryGreen..strokeWidth = 2..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant _TemperaturePainter oldDelegate) => data != oldDelegate.data;
}

class _HumidityPainter extends CustomPainter with _GridPainterBase {
  final List<double> data;
  _HumidityPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    drawGrid(canvas, size);
    if (data.isEmpty) return;
    final area = Path();
    final line = Path();
    final chartWidth = size.width - 40;
    final chartHeight = size.height - 10;
    final step = data.length > 1 ? chartWidth / (data.length - 1) : chartWidth;

    area.moveTo(30, chartHeight);
    for (int i = 0; i < data.length; i++) {
      final x = 30 + (i * step);
      final y = chartHeight - (data[i].clamp(0, 100) * chartHeight / 100);
      if (i == 0) {
        line.moveTo(x, y);
      } else {
        line.lineTo(x, y);
      }
      area.lineTo(x, y);
    }
    area.lineTo(30 + (data.length - 1) * step, chartHeight);
    area.close();

    canvas.drawPath(
      area,
      Paint()
        ..color = const Color(0xFF10B981).withOpacity(0.18)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(line, Paint()..color = const Color(0xFF10B981)..strokeWidth = 2.5..style = PaintingStyle.stroke);

    // Last point marker
    if (data.isNotEmpty) {
      final lastIdx = data.length - 1;
      final lx = 30 + (lastIdx * step);
      final ly = chartHeight - (data[lastIdx].clamp(0, 100) * chartHeight / 100);
      canvas.drawCircle(Offset(lx, ly), 5, Paint()..color = const Color(0xFF10B981));
      canvas.drawCircle(Offset(lx, ly), 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _HumidityPainter oldDelegate) => data != oldDelegate.data;
}

class _VentilationPainter extends CustomPainter with _GridPainterBase {
  final List<double> data;
  _VentilationPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    drawGrid(canvas, size);
    if (data.isEmpty) return;
    final path = Path();
    final chartWidth = size.width - 40;
    final chartHeight = size.height - 10;
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
    canvas.drawPath(path, Paint()..color = primaryBlue..strokeWidth = 2..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant _VentilationPainter oldDelegate) => data != oldDelegate.data;
}
