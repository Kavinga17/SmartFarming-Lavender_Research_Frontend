import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
      // Ignore for now; could show a snackbar
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
                        _buildTemperatureSection(),
                        const SizedBox(height: 16),
                        _buildHumiditySection(),
                        const SizedBox(height: 16),
                        _buildVentilationSection(),
                        const SizedBox(height: 8),
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
            children: const [
              Expanded(
                child: _SummaryColumn(items: {
                  'Plant': 'Lavender',
                  'Amount': '200 plants',
                  'Age': '2 month',
                  'Stage': 'Fruiting',
                  'Current AI mode': 'Active / Auto',
                }),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _SummaryColumn(items: {
                  '': '',
                }),
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
          child: GestureDetector(
            onTap: () => setState(() => _selectedMetric = i),
            child: Container(
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
        _buildSectionHeader(Icons.thermostat_outlined, primaryGreen, 'Temperature', '24°C'),
        const SizedBox(height: 8),
        Container(
          height: 160,
          width: double.infinity,
          decoration: _chartDecoration(),
          child: CustomPaint(painter: _TemperaturePainter()),
        ),
      ],
    );
  }

  Widget _buildHumiditySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.water_drop, primaryBlue, 'Humidity', '63%'),
        const SizedBox(height: 8),
        Container(
          height: 200,
          width: double.infinity,
          decoration: _chartDecoration(),
          child: CustomPaint(painter: _HumidityPainter()),
        ),
      ],
    );
  }

  Widget _buildVentilationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.air, primaryBlue, 'Ventilation', '50%'),
        const SizedBox(height: 8),
        Container(
          height: 160,
          width: double.infinity,
          decoration: _chartDecoration(),
          child: CustomPaint(painter: _VentilationPainter()),
        ),
      ],
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
  @override
  void paint(Canvas canvas, Size size) {
    drawGrid(canvas, size);
    final data = [10, 12, 15, 20, 23, 22, 21, 20, 18, 11, 18, 19];
    final path = Path();
    final chartWidth = size.width - 40;
    final chartHeight = size.height - 20;
    for (int i = 0; i < data.length; i++) {
      final x = 30 + (i * chartWidth / (data.length - 1));
      final y = chartHeight - (data[i] * chartHeight / 40);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, Paint()..color = primaryGreen..strokeWidth = 2..style = PaintingStyle.stroke);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HumidityPainter extends CustomPainter with _GridPainterBase {
  @override
  void paint(Canvas canvas, Size size) {
    drawGrid(canvas, size);
    final data = [65, 45, 55, 75, 80, 72, 68, 60, 75, 70, 55, 80];
    final area = Path();
    final line = Path();
    final chartWidth = size.width - 40;
    final chartHeight = size.height - 20;

    area.moveTo(30, chartHeight);
    for (int i = 0; i < data.length; i++) {
      final x = 30 + (i * chartWidth / (data.length - 1));
      final y = chartHeight - (data[i] * chartHeight / 100);
      if (i == 0) {
        line.moveTo(x, y);
      } else {
        line.lineTo(x, y);
      }
      area.lineTo(x, y);
    }
    area.lineTo(30 + chartWidth, chartHeight);
    area.close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF10B981), Color(0xFF10B981)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..color = const Color(0xFF10B981).withOpacity(0.18)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(line, Paint()..color = const Color(0xFF10B981)..strokeWidth = 2.5..style = PaintingStyle.stroke);

    // vertical line near SEP
    final sepIndex = 8;
    final sepX = 30 + (sepIndex * chartWidth / (data.length - 1));
    canvas.drawLine(Offset(sepX, 0), Offset(sepX, chartHeight), Paint()..color = Colors.grey.withOpacity(0.4)..strokeWidth = 1);

    // dot
    final sepY = chartHeight - (data[sepIndex] * chartHeight / 100);
    canvas.drawCircle(Offset(sepX, sepY), 5, Paint()..color = const Color(0xFF10B981));
    canvas.drawCircle(Offset(sepX, sepY), 3, Paint()..color = Colors.white);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VentilationPainter extends CustomPainter with _GridPainterBase {
  @override
  void paint(Canvas canvas, Size size) {
    drawGrid(canvas, size);
    final data = [20, 25, 22, 80, 50, 45, 38, 32, 35, 40, 70, 85];
    final path = Path();
    final chartWidth = size.width - 40;
    final chartHeight = size.height - 20;
    for (int i = 0; i < data.length; i++) {
      final x = 30 + (i * chartWidth / (data.length - 1));
      final y = chartHeight - (data[i] * chartHeight / 100);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, Paint()..color = primaryBlue..strokeWidth = 2..style = PaintingStyle.stroke);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
