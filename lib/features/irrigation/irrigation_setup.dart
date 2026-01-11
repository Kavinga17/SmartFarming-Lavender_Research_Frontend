// lib/features/irrigation/irrigation_setup.dart
import 'package:flutter/material.dart';
import '../../services/irrigation/irrigation_service.dart';

class IrrigationSetupPage extends StatefulWidget {
  const IrrigationSetupPage({super.key});

  @override
  State<IrrigationSetupPage> createState() => _IrrigationSetupPageState();
}

class _IrrigationSetupPageState extends State<IrrigationSetupPage> {
  int _plantCount = 1;
  double _moistureLevel = 50.0; // Default moisture level (0-100%)
  bool _startAutomated = true;
  late final IrrigationService _service = IrrigationService();

  // For showing suggested routine
  bool _showSuggestion = false;
  WateringRoutine? _suggestedRoutine;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Irrigation System'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step 1: Plant Count
            _buildPlantCountSection(),

            const SizedBox(height: 30),

            // Step 2: Moisture Input
            _buildMoistureInputSection(),

            const SizedBox(height: 30),

            // Step 3: Get Suggested Routine
            if (!_showSuggestion) _buildGetRoutineButton(),

            // Step 4: Show Suggested Routine
            if (_showSuggestion && _suggestedRoutine != null)
              _buildRoutineSuggestionSection(),

            const SizedBox(height: 40),

            // Step 5: Start System
            if (_showSuggestion && _suggestedRoutine != null)
              _buildStartSystemButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantCountSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 1: Plant Count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'How many lavender plants are in your system?',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (_plantCount > 1) {
                      setState(() => _plantCount--);
                    }
                  },
                ),
                Container(
                  width: 100,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_plantCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() => _plantCount++);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '≈ ${_calculateBaseWater(_plantCount)} mL per watering cycle',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.blue, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoistureInputSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 2: Current Soil Moisture',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Drag the slider to match your current soil moisture level',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Moisture value display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getMoistureColor(_moistureLevel),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '${_moistureLevel.round()}%',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getMoistureStatus(_moistureLevel),
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Slider
            Slider(
              value: _moistureLevel,
              min: 0,
              max: 100,
              divisions: 20,
              label: '${_moistureLevel.round()}%',
              onChanged: (value) {
                setState(() => _moistureLevel = value);
              },
            ),

            const SizedBox(height: 10),

            // Moisture guide
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Dry (0-30%)', style: TextStyle(fontSize: 12)),
                Text('Optimal (30-70%)', style: TextStyle(fontSize: 12)),
                Text('Wet (70-100%)', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGetRoutineButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _getSuggestedRoutine,
        icon: const Icon(Icons.psychology_outlined),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  'GET SUGGESTED WATERING ROUTINE',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildRoutineSuggestionSection() {
    if (_suggestedRoutine == null) return Container();

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💡 Suggested Watering Routine',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),

            // Suggestion
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Text(
                _suggestedRoutine!.suggestion,
                style: const TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 20),

            // Routine details
            _buildRoutineDetail(
              '💧 Water Amount',
              '${_suggestedRoutine!.waterAmount.round()} mL',
            ),
            _buildRoutineDetail(
              '⏱️ Duration',
              '${_suggestedRoutine!.durationMinutes} minutes',
            ),
            _buildRoutineDetail(
              '📅 Interval',
              'Every ${_suggestedRoutine!.intervalDays} days',
            ),

            const SizedBox(height: 20),

            // Calculations
            const Text(
              '📊 Based on:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('• ${_plantCount} lavender plants'),
            Text('• ${_moistureLevel.round()}% soil moisture'),
            Text('• Lavender water requirement: 500mL/week per plant'),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineDetail(String label, String value) {
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

  Widget _buildStartSystemButton() {
    return Column(
      children: [
        // Automation toggle
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Automated System',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'System will automatically water plants',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                Switch(
                  value: _startAutomated,
                  onChanged: (value) {
                    setState(() => _startAutomated = value);
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Start button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _startIrrigationSystem,
            icon: const Icon(Icons.play_arrow),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'START IRRIGATION ROUTINE',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods
  int _calculateBaseWater(int plants) {
    return ((500 / (7 / 3)) * plants).round();
  }

  Color _getMoistureColor(double moisture) {
    if (moisture < 30) return Colors.orange;
    if (moisture > 70) return Colors.blue;
    return Colors.green;
  }

  String _getMoistureStatus(double moisture) {
    if (moisture < 30) return 'Dry - Needs more water';
    if (moisture > 70) return 'Wet - Reduce watering';
    return 'Optimal - Good for lavender';
  }

  // Get suggested routine from backend
  Future<void> _getSuggestedRoutine() async {
    setState(() => _isLoading = true);

    try {
      final routine = await _service.getSuggestedRoutine(
        plantCount: _plantCount,
        moistureLevel: _moistureLevel,
      );

      setState(() {
        _suggestedRoutine = routine;
        _showSuggestion = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Start the irrigation system
  Future<void> _startIrrigationSystem() async {
    try {
      final result = await _service.setupIrrigationWithMoisture(
        plantCount: _plantCount,
        currentMoisture: _moistureLevel,
        startAutomated: _startAutomated,
      );

      if (result.success) {
        if (_startAutomated) {
          // Start automated routine
          await _service.startAutomatedRoutine();
        }

        // Navigate to dashboard
        Navigator.pushReplacementNamed(context, '/irrigation');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
