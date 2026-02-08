import 'package:flutter/material.dart';
import 'dart:math';

// Colors - defined at module level
const Color backgroundColor = Color(0xFFF8F9FA);
const Color primaryPurple = Color(0xFF8B5CF6);
const Color primaryGreen = Color(0xFF22C55E);
const Color primaryBlue = Color(0xFF3B82F6);
const Color textDark = Color(0xFF1F2937);
const Color textGrey = Color(0xFF6B7280);
const Color cardBackground = Colors.white;

class HumidityModeScreen extends StatefulWidget {
  const HumidityModeScreen({super.key});

  @override
  State<HumidityModeScreen> createState() => _HumidityModeScreenState();
}

class _HumidityModeScreenState extends State<HumidityModeScreen> {
  int _selectedMode = 1; // 0 = Auto, 1 = Manual
  bool _isToggleOn = true;
  int _selectedMetric = 2; // 0 = Today, 1 = Last 7 days, 2 = Last month, 3 = Custom period
  int _selectedLevel = 2; // Selected humidity mode (1=Low, 2=Medium, 3=High)

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
                    // Mode Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildModeButtons(),
                    ),
                    const SizedBox(height: 24),
                    // Circular Dial
                    _buildCircularDial(),
                    const SizedBox(height: 20),
                    // Toggle Switch
                    _buildToggleSwitch(),
                    const SizedBox(height: 20),
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
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedMode = 0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                        colors: [Colors.white, Color(0xFFF5F5F5)],
                      ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _selectedMode == 0 ? Colors.transparent : Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _selectedMode == 0
                        ? primaryPurple.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: _selectedMode == 0
                        ? primaryPurple.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.08),
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
                    Icons.adjust,
                    color: _selectedMode == 0 ? Colors.white : textGrey,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Auto Mode',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _selectedMode == 0 ? Colors.white : textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedMode = 1),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                        colors: [Colors.white, Color(0xFFF5F5F5)],
                      ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _selectedMode == 1 ? Colors.transparent : Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _selectedMode == 1
                        ? primaryPurple.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: _selectedMode == 1
                        ? primaryPurple.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.08),
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
                    Icons.pan_tool,
                    color: _selectedMode == 1 ? Colors.white : textGrey,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Manual Mode',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _selectedMode == 1 ? Colors.white : textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircularDial() {
    return Center(
      child: Opacity(
        opacity: (_selectedMode == 0 || !_isToggleOn) ? 0.6 : 1.0,
        child: IgnorePointer(
          ignoring: _selectedMode == 0 || !_isToggleOn,
          child: GestureDetector(
        onTapDown: (_selectedMode == 0 || !_isToggleOn)
            ? null
            : (TapDownDetails details) {
          // Calculate which level was tapped
          final size = 240.0;
          final center = Offset(size / 2, size / 2);
          final tapPosition = details.localPosition;
          final dx = tapPosition.dx - center.dx;
          final dy = tapPosition.dy - center.dy;
          
          double angle = atan2(dy, dx);
          
          // Normalize angle to 0-2π
          if (angle < 0) angle += 2 * pi;
          
          // Convert to degrees for easier understanding
          final degrees = angle * 180 / pi;
          
          // Map tap to nearest of 3 mode angles: Low (bottom-left), Medium (top), High (bottom-right)
          double norm(double a) {
            while (a < 0) a += 2 * pi;
            while (a >= 2 * pi) a -= 2 * pi;
            return a;
          }

          double ang = norm(angle);
          final lowAngle = norm(-5 * pi / 6);     // 210° bottom-left
          final medAngle = norm(pi / 2);          // 90° top
          final highAngle = norm(-pi / 6);        // 330° bottom-right

          double dist(double a, double b) {
            var d = (a - b).abs();
            if (d > pi) d = 2 * pi - d;
            return d;
          }

          final distances = [dist(ang, lowAngle), dist(ang, medAngle), dist(ang, highAngle)];
          int level = 2;
          final minDist = distances.reduce((v, e) => e < v ? e : v);
          final idx = distances.indexOf(minDist);
          level = idx + 1; // 1=Low, 2=Medium, 3=High
          
          setState(() => _selectedLevel = level);
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 240,
              height: 240,
              child: CustomPaint(
                painter: CircularDialPainter(selectedLevel: _selectedLevel),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Level 0$_selectedLevel',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getSelectedLevelLabel(),
                  style: TextStyle(
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
    );
  }

  String _getSelectedLevelLabel() {
    switch (_selectedLevel) {
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      default:
        return 'Medium';
    }
  }

  Widget _buildToggleSwitch() {
    return Center(
      child: Opacity(
        opacity: _selectedMode == 0 ? 0.6 : 1.0,
        child: IgnorePointer(
          ignoring: _selectedMode == 0,
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
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
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
                color: _isToggleOn ? primaryPurple : textGrey,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _selectedMode == 0
                  ? null
                  : () => setState(() => _isToggleOn = !_isToggleOn),
              child: Container(
                width: 50,
                height: 28,
                decoration: BoxDecoration(
                  gradient: _isToggleOn
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFC084FC),
                            Color(0xFFA855F7),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.grey[300]!,
                            Colors.grey[400]!,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _isToggleOn
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
                      alignment: _isToggleOn ? Alignment.centerRight : Alignment.centerLeft,
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
          ],
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.air,
            iconColor: primaryBlue,
            value: 'Auto',
            label: 'Ventilation',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.thermostat_outlined,
            iconColor: const Color(0xFF10B981),
            value: '24°C',
            label: 'Inside',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.thermostat_outlined,
            iconColor: const Color(0xFF10B981),
            value: '28°C',
            label: 'Soil',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.science_outlined,
            iconColor: primaryPurple,
            value: '6.5',
            label: 'pH Level',
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
              return GestureDetector(
                onTap: () => setState(() => _selectedMetric = index),
                child: Container(
                  margin: EdgeInsets.only(right: index < metrics.length - 1 ? 8 : 0),
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
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildHumidityChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.water_drop, color: primaryBlue, size: 20),
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
        const Text(
          'Average : 63%',
          style: TextStyle(
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
                child: CustomPaint(
                  painter: HumidityChartPainter(),
                ),
              ),
              const SizedBox(height: 12),
              // X-axis labels
              SizedBox(
                height: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
                    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
                  ].map((month) {
                    return Text(
                      month,
                      style: const TextStyle(
                        fontSize: 10,
                        color: textGrey,
                      ),
                    );
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

    // Mode positions (in radians) for 3 modes spaced 120° apart
    final level1Angle = -5 * pi / 6;  // 210° - bottom left (Low)
    final level2Angle = pi / 2;       // 90°  - top (Medium)
    final level3Angle = -pi / 6;      // 330° - bottom right (High)

    final arcWidth = 20.0;

    // Draw each arc segment (each segment is 120 degrees)
    // Segment 1: Low to Medium (green if selected >= 1)
    _drawArcSegmentBetween(
      canvas, center, radius, arcWidth,
      level1Angle, level2Angle,
      selectedLevel >= 1,
    );

    // Segment 2: Medium to High (green if selected >= 2)
    _drawArcSegmentBetween(
      canvas, center, radius, arcWidth,
      level2Angle, level3Angle,
      selectedLevel >= 2,
    );

    // Segment 3: High back to Low (green if selected >= 3)
    _drawArcSegmentBetween(
      canvas, center, radius, arcWidth,
      level3Angle, level1Angle + 2 * pi,
      selectedLevel >= 3,
    );

    // Draw numbers (1, 2, 3, 4) and scale marks
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final numbers = ['1', '2', '3'];
    final angles = [level1Angle, level2Angle, level3Angle];

    for (int i = 0; i < numbers.length; i++) {
      // Draw scale marks
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

      // Draw numbers
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
      default:
        indicatorPos = Offset(center.dx + radius * cos(level2Angle), center.dy + radius * sin(level2Angle));
    }

    // Draw 3D ball shadow
    canvas.drawCircle(
      Offset(indicatorPos.dx, indicatorPos.dy + 2),
      12,
      Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..style = PaintingStyle.fill,
    );

    // Draw 3D ball - outer glow
    canvas.drawCircle(
      indicatorPos,
      14,
      Paint()
        ..color = const Color(0xFF10B981).withOpacity(0.25)
        ..style = PaintingStyle.fill,
    );

    // Draw 3D ball - main sphere
    canvas.drawCircle(
      indicatorPos,
      11,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF34D399),
            const Color(0xFF10B981),
          ],
        ).createShader(Rect.fromCircle(center: indicatorPos, radius: 11))
        ..style = PaintingStyle.fill,
    );

    // Draw 3D ball - highlight
    canvas.drawCircle(
      Offset(indicatorPos.dx - 4, indicatorPos.dy - 4),
      5,
      Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..style = PaintingStyle.fill,
    );

    // Draw 3D ball - inner shadow
    canvas.drawCircle(
      Offset(indicatorPos.dx + 3, indicatorPos.dy + 3),
      4,
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawArcSegmentBetween(Canvas canvas, Offset center, double radius, double strokeWidth, 
      double startAngle, double endAngle, bool isGreen) {
    final paint = Paint()
      ..color = isGreen ? const Color(0xFF10B981) : const Color(0xFFA855F7)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Calculate the sweep angle (always 90 degrees between levels)
    var sweepAngle = endAngle - startAngle;
    
    // Make sure sweep is positive
    if (sweepAngle < 0) {
      sweepAngle += 2 * pi;
    }
    
    // If sweep is more than pi, take the shorter arc
    if (sweepAngle > pi) {
      sweepAngle = sweepAngle - 2 * pi;
    }

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
  @override
  void paint(Canvas canvas, Size size) {
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

    // Sample data for humidity (matching the image)
    final data = [50, 40, 55, 75, 80, 70, 60, 65, 75, 70, 60, 75];

    // Draw filled area
    final path = Path();
    final chartWidth = size.width - 40;
    final chartHeight = size.height;

    // Start from bottom left
    path.moveTo(30, chartHeight);

    // Draw curve through data points
    for (int i = 0; i < data.length; i++) {
      final x = 30 + (i * chartWidth / (data.length - 1));
      final y = chartHeight - (data[i] * chartHeight / 100);
      
      if (i == 0) {
        path.lineTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Close the path
    path.lineTo(30 + chartWidth, chartHeight);
    path.close();

    // Fill with green gradient
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF10B981).withOpacity(0.3),
            const Color(0xFF10B981).withOpacity(0.05),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill,
    );

    // Draw line
    final linePath = Path();
    for (int i = 0; i < data.length; i++) {
      final x = 30 + (i * chartWidth / (data.length - 1));
      final y = chartHeight - (data[i] * chartHeight / 100);

      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = const Color(0xFF10B981)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    // Draw dot at a specific point (around SEP)
    final dotIndex = 8;
    final dotX = 30 + (dotIndex * chartWidth / (data.length - 1));
    final dotY = chartHeight - (data[dotIndex] * chartHeight / 100);

    canvas.drawCircle(
      Offset(dotX, dotY),
      5,
      Paint()
        ..color = const Color(0xFF10B981)
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
