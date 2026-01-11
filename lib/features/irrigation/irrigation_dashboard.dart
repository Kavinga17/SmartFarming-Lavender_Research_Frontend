// lib/features/irrigation/irrigation_dashboard.dart
import 'package:flutter/material.dart';
import '../../services/irrigation/irrigation_service.dart';
import './irrigation_setup.dart';

class IrrigationDashboard extends StatefulWidget {
  const IrrigationDashboard({super.key});

  @override
  State<IrrigationDashboard> createState() => _IrrigationDashboardState();
}

class _IrrigationDashboardState extends State<IrrigationDashboard> {
  late final IrrigationService _service = IrrigationService();
  bool _isRefreshing = false;

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Irrigation System'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshData,
          ),
        ],
      ),
      body: _isRefreshing
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<IrrigationStatus>(
              future: _service.getStatus(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError || !snapshot.data!.hasSchedule) {
                  return const SetupIrrigationWidget();
                }

                final status = snapshot.data!;
                return _buildDashboard(status);
              },
            ),
    );
  }

  Widget _buildDashboard(IrrigationStatus status) {
    final schedule = status.schedule;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Status Card
          if (schedule != null) _buildStatusCard(schedule),

          const SizedBox(height: 20),

          // Quick Actions
          _buildQuickActionsCard(),

          const SizedBox(height: 20),

          // System Configuration
          _buildConfigurationCard(),

          const SizedBox(height: 20),

          // Moisture Check Section
          _buildMoistureCheckSection(),
        ],
      ),
    );
  }

  Widget _buildStatusCard(IrrigationSchedule schedule) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Schedule',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                Chip(
                  label: Text(
                    schedule.status.toUpperCase(),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: _getStatusColor(schedule.status),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Plants', '${schedule.plantCount} lavender plants'),
            _buildInfoRow('Water amount', '${schedule.waterAmount.round()} mL'),
            _buildInfoRow('Interval', 'Every ${schedule.intervalDays} days'),
            _buildInfoRow('Next watering', _formatDate(schedule.nextWatering)),
            _buildInfoRow(
              'Automation',
              schedule.isAutomated ? 'Active' : 'Manual',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Water Now Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final result = await _service.waterNow();
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(result.message)));
                    _refreshData();
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                icon: const Icon(Icons.water_drop, size: 24),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'WATER NOW',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Edit Schedule Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IrrigationSetupPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('EDIT SCHEDULE'),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Configuration',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.smart_toy),
              title: const Text('Smart Automation'),
              subtitle: const Text('Adjusts watering based on soil moisture'),
              trailing: Switch(
                value: true, // You'll need to get this from your service
                onChanged: (value) {
                  // Toggle automation
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              subtitle: const Text('Get alerts before watering'),
              trailing: Switch(value: true, onChanged: (value) {}),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('View History'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to history
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoistureCheckSection() {
    double currentMoisture = 50.0; // This should come from your service

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Soil Moisture Check',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // Moisture Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getMoistureColor(currentMoisture),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${currentMoisture.round()}%',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _getMoistureStatus(currentMoisture),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.thermostat, size: 40, color: Colors.white),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Update Moisture Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showMoistureInputDialog();
                },
                icon: const Icon(Icons.edit),
                label: const Text('UPDATE MOISTURE READING'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Update the moisture reading if you\'ve manually checked the soil',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'paused':
        return Colors.orange;
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Color _getMoistureColor(double moisture) {
    if (moisture < 30) return Colors.orange;
    if (moisture > 70) return Colors.blue;
    return Colors.green;
  }

  String _getMoistureStatus(double moisture) {
    if (moisture < 30) return 'Dry - Needs water';
    if (moisture > 70) return 'Wet - Reduce watering';
    return 'Optimal - Good for lavender';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showMoistureInputDialog() {
    double moistureValue = 50.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Update Soil Moisture'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Current moisture level:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // Moisture value display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getMoistureColor(moistureValue),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${moistureValue.round()}%',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _getMoistureStatus(moistureValue),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Slider
                Slider(
                  value: moistureValue,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '${moistureValue.round()}%',
                  onChanged: (value) {
                    setState(() => moistureValue = value);
                  },
                ),

                const SizedBox(height: 10),

                // Moisture guide
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Dry', style: TextStyle(fontSize: 12)),
                    Text('Optimal', style: TextStyle(fontSize: 12)),
                    Text('Wet', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _service.submitMoistureReading(moistureValue);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Moisture reading updated')),
                    );
                    Navigator.pop(context);
                    _refreshData();
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Setup widget for first-time users
class SetupIrrigationWidget extends StatelessWidget {
  const SetupIrrigationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.water_drop, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Smart Irrigation System',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'Setup automated watering based on your lavender plants and soil moisture',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const IrrigationSetupPage(),
                  ),
                );
              },
              icon: const Icon(Icons.settings),
              label: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Text('SETUP IRRIGATION SYSTEM'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
