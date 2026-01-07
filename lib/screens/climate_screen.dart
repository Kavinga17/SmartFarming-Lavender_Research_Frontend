import 'package:flutter/material.dart';
import 'venting_mode_screen.dart';

class ClimateScreen extends StatefulWidget {
  const ClimateScreen({super.key});

  @override
  State<ClimateScreen> createState() => _ClimateScreenState();
}

class _ClimateScreenState extends State<ClimateScreen> {
  int _selectedMode = 0; // 0 = Venting, 1 = Humidity

  // Colors
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryGreen = Color(0xFF22C55E);
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryOrange = Color(0xFFFF7A45);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color cardBackground = Colors.white;

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
                  children: [
                    // Climate Hero Section with readings
                    _buildClimateHeroSection(),
                    const SizedBox(height: 20),
                    // Status Cards Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildStatusCardsRow(),
                    ),
                    const SizedBox(height: 20),
                    // Mode Toggle Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildModeToggle(),
                    ),
                    const SizedBox(height: 24),
                    // Overview Section with Chart
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildOverviewSection(),
                    ),
                    const SizedBox(height: 20),
                    // View Analytics Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildAnalyticsButton(),
                    ),
                    const SizedBox(height: 24),
                    // Recent Activity
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildRecentActivity(),
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
            color: primaryOrange,
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

  Widget _buildClimateHeroSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9).withOpacity(0.5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              // Curved green background
              Positioned(
                top: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  child: CustomPaint(
                    size: const Size(200, 350),
                    painter: CurvedGreenPainter(),
                  ),
                ),
              ),
              // Lavender plant illustration (right side)
              Positioned(
                top: 20,
                right: 10,
            child: _buildLavenderPlant(),
          ),
          // Sensor readings - full width
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSensorReading(
                        icon: Icons.thermostat_outlined,
                        iconBgColor: const Color(0xFFDCFCE7),
                        iconColor: primaryGreen,
                        label: 'Green House Temperature',
                        value: '24°C',
                      ),
                      const SizedBox(height: 16),
                      _buildSensorReading(
                        icon: Icons.thermostat_outlined,
                        iconBgColor: const Color(0xFFDCFCE7),
                        iconColor: primaryGreen,
                        label: 'Soil Temperature',
                        value: '28°C',
                      ),
                      const SizedBox(height: 16),
                      _buildSensorReading(
                        icon: Icons.water_drop_outlined,
                        iconBgColor: const Color(0xFFE0F2FE),
                        iconColor: primaryBlue,
                        label: 'Humidity',
                        value: '30%',
                      ),
                      const SizedBox(height: 16),
                      _buildSensorReading(
                        icon: Icons.science_outlined,
                        iconBgColor: const Color(0xFFF3E5F5),
                        iconColor: primaryPurple,
                        label: 'pH Level',
                        value: '6.5',
                      ),
                      const SizedBox(height: 16),
                      _buildSensorReading(
                        icon: Icons.air,
                        iconBgColor: const Color(0xFFF3E5F5),
                        iconColor: primaryPurple,
                        label: 'Venting',
                        value: 'Automatic Mode',
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                // Spacer for lavender plant area
                const Expanded(
                  flex: 2,
                  child: SizedBox(),
                ),
              ],
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLavenderPlant() {
    return SizedBox(
      width: 200,
      height: 350,
      child: Image.asset(
        'assets/images/lavender.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon-based lavender if image not found
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Transform.rotate(
                    angle: -0.2,
                    child: _buildLavenderStalk(80),
                  ),
                  Transform.rotate(
                    angle: -0.1,
                    child: _buildLavenderStalk(100),
                  ),
                  _buildLavenderStalk(110),
                  Transform.rotate(
                    angle: 0.1,
                    child: _buildLavenderStalk(95),
                  ),
                  Transform.rotate(
                    angle: 0.25,
                    child: _buildLavenderStalk(85),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.rotate(
                    angle: -0.5,
                    child: Icon(Icons.eco, size: 30, color: Colors.green[600]),
                  ),
                  Icon(Icons.eco, size: 35, color: Colors.green[700]),
                  Transform.rotate(
                    angle: 0.5,
                    child: Icon(Icons.eco, size: 30, color: Colors.green[600]),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLavenderStalk(double height) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Flower buds
        for (int i = 0; i < 6; i++)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 1),
            child: Icon(
              Icons.water_drop,
              size: height / 10,
              color: Color.lerp(
                const Color(0xFF9C27B0),
                const Color(0xFF7B1FA2),
                i / 6,
              ),
            ),
          ),
        // Stem
        Container(
          width: 2,
          height: height * 0.35,
          decoration: BoxDecoration(
            color: Colors.green[600],
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  Widget _buildSensorReading({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: textGrey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCardsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            title: 'Fan',
            subtitle: 'Level 03',
            status: 'ON',
            icon: Icons.air,
            iconColor: primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            title: 'Temp Sensors',
            subtitle: 'Connected',
            status: '',
            icon: Icons.thermostat_outlined,
            iconColor: primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            title: 'Humidity sensor',
            subtitle: 'Level 03',
            status: 'ON',
            icon: Icons.water_drop_outlined,
            iconColor: primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String subtitle,
    required String status,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
            color: iconColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: textGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            status.isNotEmpty ? status : ' ',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VentingModeScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
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
                        colors: [
                          Colors.white,
                          Color(0xFFF5F5F5),
                        ],
                      ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _selectedMode == 0 ? Colors.transparent : Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _selectedMode == 0
                        ? primaryPurple.withOpacity(0.4)
                        : Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: _selectedMode == 0
                        ? primaryPurple.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
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
                    Icons.air,
                    color: _selectedMode == 0 ? Colors.white : textGrey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Venting Mode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _selectedMode == 0 ? Colors.white : textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
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
              padding: const EdgeInsets.symmetric(vertical: 14),
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
                        colors: [
                          Colors.white,
                          Color(0xFFF5F5F5),
                        ],
                      ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _selectedMode == 1 ? Colors.transparent : Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _selectedMode == 1
                        ? primaryPurple.withOpacity(0.4)
                        : Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: _selectedMode == 1
                        ? primaryPurple.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
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
                    Icons.water_drop_outlined,
                    color: _selectedMode == 1 ? Colors.white : textGrey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Humidity Mode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _selectedMode == 1 ? Colors.white : textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        const SizedBox(height: 12),
        // Legend
        Row(
          children: [
            _buildLegendItem(primaryBlue, 'Humidity'),
            const SizedBox(width: 20),
            _buildLegendItem(primaryPurple, 'Ventilation'),
            const SizedBox(width: 20),
            _buildLegendItem(primaryGreen, 'Temperature'),
          ],
        ),
        const SizedBox(height: 16),
        // Chart
        Container(
          height: 200,
          width: double.infinity,
          child: CustomPaint(
            painter: ChartPainter(),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF34D399),
            Color(0xFF22C55E),
            Color(0xFF16A34A),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: primaryGreen.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: const Text(
          'View Analytics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
            Row(
              children: [
                Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 13,
                    color: textGrey,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: textGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Activity Items
        _buildActivityItem(
          icon: Icons.download_outlined,
          iconBgColor: const Color(0xFFE0F2FE),
          iconColor: primaryBlue,
          title: 'Analytics report downloaded',
          time: '5 mins ago',
        ),
        _buildActivityItem(
          icon: Icons.water_drop_outlined,
          iconBgColor: const Color(0xFFE0F2FE),
          iconColor: primaryBlue,
          title: 'Humidity adjusted to level 2',
          time: '25 mins ago',
        ),
        _buildActivityItem(
          icon: Icons.air,
          iconBgColor: const Color(0xFFFCE7F3),
          iconColor: const Color(0xFFEC4899),
          title: 'Fan adjusted to level 3',
          time: '1 hour ago',
        ),
        _buildActivityItem(
          icon: Icons.thermostat_outlined,
          iconBgColor: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFF59E0B),
          title: 'Soil temperature increased',
          time: '2 hours ago',
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            color: iconColor.withOpacity(0.15),
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
                ),
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
    );
  }
}

class CurvedGreenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD5F5E3)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.3, 0);
    path.quadraticBezierTo(
      size.width * 0.1,
      size.height * 0.3,
      size.width * 0.2,
      size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.9,
      size.width,
      size.height * 0.8,
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final yLabels = ['0', '10', '20', '30', '40', '50', '60', '70', '80', '90', '100'];
    
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw Y axis labels
    for (int i = 0; i <= 10; i++) {
      textPainter.text = TextSpan(
        text: yLabels[i],
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF6B7280),
        ),
      );
      textPainter.layout();
      final y = size.height - 20 - (i * (size.height - 30) / 10);
      textPainter.paint(canvas, Offset(0, y - 5));
    }

    // Draw X axis labels
    final chartWidth = size.width - 30;
    for (int i = 0; i < months.length; i++) {
      textPainter.text = TextSpan(
        text: months[i],
        style: const TextStyle(
          fontSize: 9,
          color: Color(0xFF6B7280),
        ),
      );
      textPainter.layout();
      final x = 30 + (i * chartWidth / 11);
      textPainter.paint(canvas, Offset(x - 10, size.height - 15));
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 10; i++) {
      final y = size.height - 20 - (i * (size.height - 30) / 10);
      canvas.drawLine(Offset(30, y), Offset(size.width, y), gridPaint);
    }

    // Humidity line (blue) - higher values
    final humidityData = [85, 88, 75, 80, 78, 82, 72, 80, 75, 18, 20, 18];
    _drawLine(canvas, size, humidityData, const Color(0xFF3B82F6));

    // Ventilation line (purple) - mid values
    final ventilationData = [60, 55, 65, 58, 52, 55, 48, 55, 50, 15, 18, 16];
    _drawLine(canvas, size, ventilationData, const Color(0xFF8B5CF6));

    // Temperature line (green) - lower values
    final temperatureData = [18, 20, 22, 20, 18, 20, 22, 20, 18, 20, 22, 20];
    _drawLine(canvas, size, temperatureData, const Color(0xFF22C55E));

    // Draw a point marker on September (index 8) for humidity
    final markerPaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.fill;
    final chartHeight = size.height - 30;
    final sepX = 30 + (8 * chartWidth / 11);
    final sepY = size.height - 20 - (75 * chartHeight / 100);
    canvas.drawCircle(Offset(sepX, sepY), 5, markerPaint);
    canvas.drawCircle(
      Offset(sepX, sepY),
      3,
      Paint()..color = Colors.white,
    );
  }

  void _drawLine(Canvas canvas, Size size, List<int> data, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final chartWidth = size.width - 30;
    final chartHeight = size.height - 30;

    for (int i = 0; i < data.length; i++) {
      final x = 30 + (i * chartWidth / 11);
      final y = size.height - 20 - (data[i] * chartHeight / 100);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
