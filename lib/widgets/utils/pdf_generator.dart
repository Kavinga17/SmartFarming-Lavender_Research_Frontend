import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/report_model.dart';
import '../models/sensor_model.dart';
import '../models/lighting_model.dart';

class PdfGenerator {
  /// Generates a PDF report from given data and returns the bytes
  static Future<Uint8List> generateReport({
    required DiagnosticReport? diagnostic,
    required SensorData? sensorData,
    required LightingState? lightingState,
    required List<String> recommendations,
  }) async {
    final pdf = pw.Document();

    // Load a custom font (optional – defaults to Helvetica)
    final fontData = await rootBundle.load("assets/fonts/OpenSans-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header with logo and title
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Lavender AI',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                    pw.Text(
                      'Smart Farming System',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Container(
                  width: 60,
                  height: 60,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green100,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      '🌿',
                      style: pw.TextStyle(fontSize: 30),
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.green300),

            // Report title and date
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Plant Health & Environment Report',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated on ${_formatDate(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Diagnostic summary
            if (diagnostic != null) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '🌱 Plant Health Diagnosis',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Container(
                          width: 12,
                          height: 12,
                          decoration: pw.BoxDecoration(
                            color: _statusColor(diagnostic.status),
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          diagnostic.statusString,
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Confidence: ${(diagnostic.confidence * 100).toStringAsFixed(1)}%',
                      style: pw.TextStyle(fontSize: 12),
                    ),
                    if (diagnostic.imageUrl != null) ...[
                      pw.SizedBox(height: 8),
                      pw.Text('Image captured at analysis.', style: pw.TextStyle(fontSize: 10)),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
            ],

            // Sensor readings table
            pw.Text(
              '📊 Live Sensor Data',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _tableHeader('Parameter'),
                      _tableHeader('Value'),
                      _tableHeader('Status'),
                    ],
                  ),
                  _sensorRow('Temperature', sensorData?.temperature, '°C', _tempStatus(sensorData?.temperature)),
                  _sensorRow('Humidity', sensorData?.humidity, '%', _humidityStatus(sensorData?.humidity)),
                  _sensorRow('Light Intensity', sensorData?.lightIntensity, 'lux', _lightStatus(sensorData?.lightIntensity)),
                  _sensorRow('Soil pH', 6.5, '', 'Optimal'), // dummy
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Lighting settings
            if (lightingState != null) ...[
              pw.Text(
                '💡 Lighting Configuration',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  _buildLightChip('Red', lightingState.red, PdfColors.red600),
                  pw.SizedBox(width: 8),
                  _buildLightChip('Blue', lightingState.blue, PdfColors.blue600),
                  pw.SizedBox(width: 8),
                  _buildLightChip('White', lightingState.white, PdfColors.grey600),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Growth Stage: ${_stageName(lightingState.stage)}',
                style: pw.TextStyle(fontSize: 12),
              ),
              if (lightingState.isScheduleEnabled)
                pw.Text(
                  'Photoperiod: ${_formatTime(lightingState.scheduleStart)} - ${_formatTime(lightingState.scheduleEnd)}',
                  style: pw.TextStyle(fontSize: 12),
                ),
              pw.SizedBox(height: 20),
            ],

            // Recommendations
            pw.Text(
              '✅ Actionable Recommendations',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: recommendations.map((rec) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Expanded(child: pw.Text(rec, style: pw.TextStyle(fontSize: 11))),
                    ],
                  ),
                );
              }).toList(),
            ),
            pw.SizedBox(height: 30),

            // Footer
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),
            pw.Text(
              'Generated by Lavender AI - Smart Farming System',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              textAlign: pw.TextAlign.center,
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Saves the PDF to device storage or shares it
  static Future<void> saveAndShare({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: fileName,
    );
  }

  /// Helper to format date
  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  static String _stageName(GrowthStage stage) {
    switch (stage) {
      case GrowthStage.germination: return 'Germination';
      case GrowthStage.seedling: return 'Seedling';
      case GrowthStage.vegetative: return 'Vegetative';
      case GrowthStage.flowering: return 'Flowering';
      case GrowthStage.oilMaturation: return 'Oil Maturation';
    }
  }

  static PdfColor _statusColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy: return PdfColors.green600;
      case HealthStatus.nutrientDeficient: return PdfColors.orange600;
      case HealthStatus.diseased: return PdfColors.red600;
    }
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.TableRow _sensorRow(String param, double? value, String unit, String status) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(param),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value != null ? '${value.toStringAsFixed(1)}$unit' : '--'),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(status),
        ),
      ],
    );
  }

  static pw.Widget _buildLightChip(String label, int value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
        border: pw.Border.all(color: color),
      ),
      child: pw.Text('$label: $value', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    );
  }

  static String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Dummy status functions (replace with real logic)
  static String _tempStatus(double? temp) {
    if (temp == null) return 'Unknown';
    if (temp > 28) return 'High';
    if (temp < 18) return 'Low';
    return 'Optimal';
  }

  static String _humidityStatus(double? hum) {
    if (hum == null) return 'Unknown';
    if (hum > 70) return 'High';
    if (hum < 40) return 'Low';
    return 'Optimal';
  }

  static String _lightStatus(double? light) {
    if (light == null) return 'Unknown';
    if (light > 2000) return 'High';
    if (light < 500) return 'Low';
    return 'Optimal';
  }
}