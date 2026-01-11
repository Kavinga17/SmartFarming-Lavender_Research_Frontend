import 'package:flutter/material.dart';

class IrrigationHistoryScreen extends StatefulWidget {
  @override
  _IrrigationHistoryScreenState createState() =>
      _IrrigationHistoryScreenState();
}

class _IrrigationHistoryScreenState extends State<IrrigationHistoryScreen> {
  String _selectedPeriod = '30 Days';
  final List<String> _periods = ['7 Days', '30 Days', '90 Days', '1 Year'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Irrigation History',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.download, color: Color(0xFF64748B)),
            onPressed: _exportData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with period selector
            _buildHeader(),

            // Performance Overview
            _buildPerformanceOverview(),

            // Timeline View
            _buildTimelineView(),

            // Water Usage Charts
            _buildUsageCharts(),

            // Activity Log
            _buildActivityLog(),

            // Insights
            _buildInsights(),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF0D9488).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, color: Color(0xFF0D9488), size: 18),
                SizedBox(width: 8),
                Text(
                  'ANALYTICS & HISTORY',
                  style: TextStyle(
                    color: Color(0xFF0D9488),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Irrigation Performance',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    icon: Icon(Icons.keyboard_arrow_down, size: 20),
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w500,
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedPeriod = newValue!;
                      });
                    },
                    items: _periods.map((String period) {
                      return DropdownMenuItem<String>(
                        value: period,
                        child: Text(period),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Track water usage, efficiency, and irrigation events',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceOverview() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PERFORMANCE OVERVIEW',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Last 30 Days',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildMetricCard(
                title: 'Overall Efficiency',
                value: '92%',
                change: '+5%',
                icon: Icons.trending_up,
                color: Color(0xFF10B981),
                iconBg: Color(0xFF10B981).withOpacity(0.1),
              ),
              _buildMetricCard(
                title: 'Water Saved',
                value: '125L',
                change: '💰 \$18',
                icon: Icons.savings,
                color: Color(0xFF3B82F6),
                iconBg: Color(0xFF3B82F6).withOpacity(0.1),
              ),
              _buildMetricCard(
                title: 'Plant Health',
                value: '87%',
                change: 'Optimal',
                icon: Icons.psychology,
                color: Color(0xFF8B5CF6),
                iconBg: Color(0xFF8B5CF6).withOpacity(0.1),
              ),
              _buildMetricCard(
                title: 'Schedule Adherence',
                value: '94%',
                change: 'Excellent',
                icon: Icons.schedule,
                color: Color(0xFFF59E0B),
                iconBg: Color(0xFFF59E0B).withOpacity(0.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String change,
    required IconData icon,
    required Color color,
    required Color iconBg,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        change,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineView() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WATERING TIMELINE - JUNE 2024',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          SizedBox(height: 16),

          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                .map(
                  (day) => Container(
                    width: 36,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 12),

          // Calendar weeks
          Column(
            children: [
              _buildCalendarWeek(startDay: 1, wateringDays: [3, 6]),
              SizedBox(height: 8),
              _buildCalendarWeek(startDay: 8, wateringDays: [10]),
              SizedBox(height: 8),
              _buildCalendarWeek(startDay: 15, wateringDays: [16, 19]),
              SizedBox(height: 8),
              _buildCalendarWeek(startDay: 22, wateringDays: [24, 29]),
            ],
          ),

          SizedBox(height: 16),
          Divider(color: Color(0xFFE2E8F0)),
          SizedBox(height: 12),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                color: Color(0xFF0D9488),
                text: 'Watering Day',
                icon: Icons.water_drop,
              ),
              SizedBox(width: 20),
              _buildLegendItem(
                color: Color(0xFFF59E0B),
                text: 'Smart Override',
                icon: Icons.adjust,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarWeek({
    required int startDay,
    required List<int> wateringDays,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final day = startDay + index;
        final isWateringDay = wateringDays.contains(day);
        final isOverrideDay = [3, 16].contains(day); // Example override days

        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isWateringDay ? Color(0xFF0D9488).withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isWateringDay ? Color(0xFF0D9488) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                day <= 30 ? day.toString() : '',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isWateringDay ? FontWeight.w700 : FontWeight.w500,
                  color: isWateringDay ? Color(0xFF0D9488) : Color(0xFF1E293B),
                ),
              ),
              if (isOverrideDay)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String text,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildUsageCharts() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildChartCard(
              title: 'WEEKLY WATER USAGE',
              data: [85, 70, 80, 85, 90, 75, 88],
              labels: ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7'],
              color: Color(0xFF3B82F6),
              maxValue: 100,
              unit: 'L',
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildChartCard(
              title: 'EFFICIENCY TREND',
              data: [92, 88, 90, 94, 96, 92, 95],
              labels: ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7'],
              color: Color(0xFF10B981),
              maxValue: 100,
              unit: '%',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required List<int> data,
    required List<String> labels,
    required Color color,
    required int maxValue,
    required String unit,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(data.length, (index) {
                final height = (data[index] / maxValue) * 100;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 16,
                      height: height,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      labels[index],
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${data[index]}$unit',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLog() {
    final activities = [
      {
        'type': 'watering',
        'title': 'Watering executed',
        'subtitle': 'Regular schedule',
        'value': '1250ml',
        'time': 'Today, 06:00',
      },
      {
        'type': 'override',
        'title': 'Smart override applied',
        'subtitle': 'Overwatering detected',
        'value': '-25%',
        'time': '2 days ago',
      },
      {
        'type': 'update',
        'title': 'Plan updated',
        'subtitle': 'Moisture level changed',
        'value': '+2 days',
        'time': '1 week ago',
      },
      {
        'type': 'create',
        'title': 'New plan created',
        'subtitle': 'Initial setup',
        'value': '5 plants',
        'time': '2 weeks ago',
      },
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT ACTIVITY LOG',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF0D9488),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          Column(
            children: activities.map((activity) {
              return Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: _buildActivityItem(
                  type: activity['type'] as String,
                  title: activity['title'] as String,
                  subtitle: activity['subtitle'] as String,
                  value: activity['value'] as String,
                  time: activity['time'] as String,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String type,
    required String title,
    required String subtitle,
    required String value,
    required String time,
  }) {
    Color color;
    IconData icon;

    switch (type) {
      case 'watering':
        color = Color(0xFF0D9488);
        icon = Icons.water_drop;
        break;
      case 'override':
        color = Color(0xFFF59E0B);
        icon = Icons.adjust;
        break;
      case 'update':
        color = Color(0xFF3B82F6);
        icon = Icons.edit;
        break;
      default:
        color = Color(0xFF10B981);
        icon = Icons.add_circle;
    }

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            SizedBox(height: 2),
            Text(
              time,
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsights() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.insights, color: Color(0xFF8B5CF6), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'INSIGHTS & RECOMMENDATIONS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          Column(
            children: [
              _buildInsightItem(
                icon: Icons.star,
                color: Color(0xFFF59E0B),
                title: 'Best watering time',
                description: '06:00-07:00 AM shows 25% better absorption',
              ),
              SizedBox(height: 12),
              _buildInsightItem(
                icon: Icons.lightbulb,
                color: Color(0xFF10B981),
                title: 'Weather-based adjustment',
                description: 'Reduce watering by 10% during cooler days',
              ),
              SizedBox(height: 12),
              _buildInsightItem(
                icon: Icons.trending_up,
                color: Color(0xFF3B82F6),
                title: 'Efficiency improvement',
                description: '15% more efficient than last month',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    // Hardcoded export function
    print('Exporting irrigation history data...');
    // In real app, this would generate CSV/PDF
  }

  @override
  void dispose() {
    super.dispose();
  }
}
