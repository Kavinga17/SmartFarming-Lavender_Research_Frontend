// lib/screens/irrigation_setup_screen.dart
import 'package:flutter/material.dart';
import '/services/soil_backend_service.dart';

class IrrigationSetupScreen extends StatefulWidget {
  const IrrigationSetupScreen({super.key});

  @override
  State<IrrigationSetupScreen> createState() => _IrrigationSetupScreenState();
}

class _IrrigationSetupScreenState extends State<IrrigationSetupScreen> {
  // Color palette
  static const Color primaryPurple = Color(0xFF8A4FFF);
  static const Color successGreen = Color(0xFF2ECC71);
  static const Color warningAmber = Color(0xFFFFA726);
  static const Color dangerRed = Color(0xFFE74C3C);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF2C3E50);
  static const Color lightTextColor = Color(0xFF95A5A6);

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _plantCountController = TextEditingController();
  final _areaController = TextEditingController();
  final _flowRateController = TextEditingController();

  // Dropdown values
  String _selectedSoilType = 'Loamy';
  String _selectedWateringTime = 'Morning';
  String _selectedSafetyMode = 'Normal';

  // Always automated (removed toggle)
  final bool _isAutomated = true;

  // Schedule preview
  Map<String, dynamic>? _calculatedSchedule;

  // Soil type options
  final List<String> _soilTypes = ['Sandy', 'Loamy', 'Clay'];
  final List<String> _wateringTimes = ['Morning', 'Evening', 'Night'];
  final List<String> _safetyModes = ['Conservative', 'Normal', 'Aggressive'];

  @override
  void dispose() {
    _plantCountController.dispose();
    _areaController.dispose();
    _flowRateController.dispose();
    super.dispose();
  }

  void _calculateSchedule() {
    if (!_formKey.currentState!.validate()) return;

    // Get values
    final plantCount = int.parse(_plantCountController.text);
    final area = double.parse(_areaController.text);
    final flowRate = double.parse(_flowRateController.text);

    // Simple calculation logic
    double waterPerPlant;
    int frequencyDays;

    switch (_selectedSoilType) {
      case 'Sandy':
        waterPerPlant = 2.0;
        frequencyDays = 2;
        break;
      case 'Loamy':
        waterPerPlant = 1.5;
        frequencyDays = 3;
        break;
      case 'Clay':
        waterPerPlant = 1.0;
        frequencyDays = 4;
        break;
      default:
        waterPerPlant = 1.5;
        frequencyDays = 3;
    }

    // Adjust based on safety mode
    if (_selectedSafetyMode == 'Conservative') {
      waterPerPlant *= 0.8;
      frequencyDays += 1;
    } else if (_selectedSafetyMode == 'Aggressive') {
      waterPerPlant *= 1.2;
      frequencyDays = (frequencyDays - 1).clamp(1, 7);
    }

    final totalWater = waterPerPlant * plantCount;
    final durationMinutes = (totalWater / flowRate * 60).round();

    setState(() {
      _calculatedSchedule = {
        'waterPerPlant': waterPerPlant,
        'frequencyDays': frequencyDays,
        'totalWater': totalWater,
        'durationMinutes': durationMinutes,
        'nextWatering': _getNextWateringTime(frequencyDays),
        'targetMoistureMin': _selectedSoilType == 'Sandy' ? 30 : 40,
        'targetMoistureMax': _selectedSoilType == 'Clay' ? 60 : 70,
      };
    });
  }

  String _getNextWateringTime(int frequencyDays) {
    final now = DateTime.now();
    final next = now.add(Duration(days: frequencyDays));
    final hour = _selectedWateringTime == 'Morning'
        ? 8
        : _selectedWateringTime == 'Evening'
        ? 18
        : 22;
    return '${next.day}/${next.month} at $hour:00';
  }

  Future<void> _saveRoutine() async {
    if (_calculatedSchedule == null) return;

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: primaryPurple)),
    );

    try {
      final result = await SoilBackendService.saveRoutine({
        'plantCount': int.parse(_plantCountController.text),
        'area': double.parse(_areaController.text),
        'flowRate': double.parse(_flowRateController.text),
        'soilType': _selectedSoilType,
        'wateringTime': _selectedWateringTime,
        'safetyMode': _selectedSafetyMode,
        'isAutomated': _isAutomated,
        'schedule': _calculatedSchedule,
      });

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (result != null && result['success'] == true) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Irrigation routine saved successfully!'),
            backgroundColor: successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context, true);
      } else {
        // Check if error is due to existing routine
        if (result != null && result['error'] == 'Active routine exists') {
          _showTerminateDialog(result['existingRoutine']);
        } else {
          // Other error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result?['message'] ?? 'Failed to save routine'),
              backgroundColor: dangerRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: dangerRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showTerminateDialog(Map<String, dynamic>? existingRoutine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Active Routine Exists'),
        content: Text(
          'You already have an active routine. Please terminate it before creating a new one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              // Show loading
              if (!mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(color: primaryPurple),
                ),
              );

              final terminated = await SoilBackendService.terminateRoutine();

              if (!mounted) return;
              Navigator.pop(context); // Close loading

              if (terminated != null && terminated['success'] == true) {
                // Retry saving
                _saveRoutine();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Failed to terminate routine'),
                    backgroundColor: dangerRed,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Terminate & Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Irrigation Setup',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Greenhouse Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Plant Count
                    TextFormField(
                      controller: _plantCountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Number of Plants',
                        hintText: 'e.g., 50',
                        prefixIcon: Icon(Icons.eco, color: primaryPurple),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: primaryPurple,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter plant count';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Area
                    TextFormField(
                      controller: _areaController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Total Area (sq meters)',
                        hintText: 'e.g., 100',
                        suffixText: 'm²',
                        prefixIcon: Icon(
                          Icons.square_foot,
                          color: primaryPurple,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: primaryPurple,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter area';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Flow Rate
                    TextFormField(
                      controller: _flowRateController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Flow Rate (liters/minute)',
                        hintText: 'e.g., 10',
                        suffixText: 'L/min',
                        prefixIcon: Icon(Icons.speed, color: primaryPurple),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: primaryPurple,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter flow rate';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Soil & Preferences Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Soil & Preferences',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Soil Type Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedSoilType,
                      decoration: InputDecoration(
                        labelText: 'Soil Type',
                        prefixIcon: Icon(Icons.landslide, color: primaryPurple),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _soilTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedSoilType = value!);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Watering Time Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedWateringTime,
                      decoration: InputDecoration(
                        labelText: 'Preferred Watering Time',
                        prefixIcon: Icon(
                          Icons.access_time,
                          color: primaryPurple,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _wateringTimes.map((time) {
                        return DropdownMenuItem(value: time, child: Text(time));
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedWateringTime = value!);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Safety Mode Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedSafetyMode,
                      decoration: InputDecoration(
                        labelText: 'Safety Mode',
                        prefixIcon: Icon(Icons.security, color: primaryPurple),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _safetyModes.map((mode) {
                        return DropdownMenuItem(value: mode, child: Text(mode));
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedSafetyMode = value!);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Calculate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _calculateSchedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'CALCULATE SCHEDULE',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              // Schedule Preview
              if (_calculatedSchedule != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryPurple.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryPurple.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule, color: primaryPurple),
                          const SizedBox(width: 8),
                          const Text(
                            'Your Irrigation Schedule',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildScheduleRow(
                        'Water per plant',
                        '${_calculatedSchedule!['waterPerPlant']} L',
                      ),
                      _buildScheduleRow(
                        'Frequency',
                        'Every ${_calculatedSchedule!['frequencyDays']} days',
                      ),
                      _buildScheduleRow(
                        'Total water',
                        '${_calculatedSchedule!['totalWater'].toStringAsFixed(1)} L',
                      ),
                      _buildScheduleRow(
                        'Duration',
                        '${_calculatedSchedule!['durationMinutes']} minutes',
                      ),
                      _buildScheduleRow(
                        'Next watering',
                        _calculatedSchedule!['nextWatering'],
                      ),
                      _buildScheduleRow(
                        'Target moisture',
                        '${_calculatedSchedule!['targetMoistureMin']}-${_calculatedSchedule!['targetMoistureMax']}%',
                      ),

                      const SizedBox(height: 20),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveRoutine,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: successGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'SAVE ROUTINE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: lightTextColor, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
