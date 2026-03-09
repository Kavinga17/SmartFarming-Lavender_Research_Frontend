import 'package:flutter/material.dart';
import '../../models/lighting_model.dart';
import '../../services/lighting_api_service.dart';

class GrowthStageScreen extends StatefulWidget {
  const GrowthStageScreen({super.key});

  @override
  State<GrowthStageScreen> createState() => _GrowthStageScreenState();
}

class _GrowthStageScreenState extends State<GrowthStageScreen> {
  // Colors (same as ClimateScreen)
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryGreen = Color(0xFF22C55E);
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryOrange = Color(0xFFFF7A45);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);

  GrowthStage _currentStage = GrowthStage.vegetative;
  bool _isLoading = false;

  final Map<GrowthStage, Map<String, dynamic>> stageDetails = {
    GrowthStage.germination: {
      'name': 'Germination',
      'description': 'Seeds sprout and initial roots develop. Keep medium moist.',
      'red': 50,
      'blue': 100,
      'white': 30,
      'duration': '7-14 days',
      'tips': ['Humidity: 70-80%', 'Temperature: 20-25°C', 'Light cycle: 16h on / 8h off'],
    },
    GrowthStage.seedling: {
      'name': 'Seedling',
      'description': 'True leaves appear. Balanced light for photosynthesis.',
      'red': 80,
      'blue': 120,
      'white': 50,
      'duration': '14-21 days',
      'tips': ['Start mild nutrients', 'Humidity: 60-70%', 'Light intensity: gradually increase'],
    },
    GrowthStage.vegetative: {
      'name': 'Vegetative',
      'description': 'Rapid growth of leaves and stems. Higher red light.',
      'red': 150,
      'blue': 100,
      'white': 70,
      'duration': '21-30 days',
      'tips': ['Increase nitrogen-rich nutrients', 'Prune lower leaves', 'Light cycle: 18h on / 6h off'],
    },
    GrowthStage.flowering: {
      'name': 'Flowering',
      'description': 'Bud formation begins. More red light to stimulate flowering.',
      'red': 200,
      'blue': 80,
      'white': 60,
      'duration': '30-45 days',
      'tips': ['Switch to bloom nutrients', 'Reduce humidity to 50-60%', 'Light cycle: 12h on / 12h off'],
    },
    GrowthStage.oilMaturation: {
      'name': 'Oil Maturation',
      'description': 'Essential oil production peaks. High red and white light.',
      'red': 220,
      'blue': 60,
      'white': 100,
      'duration': '45-60 days',
      'tips': ['Flush nutrients before harvest', 'Monitor trichomes', 'Maintain moderate temperatures'],
    },
  };

  Future<void> _setStage(GrowthStage stage) async {
    setState(() => _isLoading = true);
    final newState = LightingState(
      red: stageDetails[stage]!['red'],
      blue: stageDetails[stage]!['blue'],
      white: stageDetails[stage]!['white'],
      stage: stage,
    );
    final success = await LightingApiService.updateLighting(newState);
    if (!mounted) return;
    if (success) {
      setState(() {
        _currentStage = stage;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stage updated to ${stageDetails[stage]!['name']}')),
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Update failed'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentStageCard(),
                    const SizedBox(height: 20),
                    const Text('All Growth Stages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
                    const SizedBox(height: 12),
                    ...stageDetails.entries.map((entry) => _buildStageCard(entry.key, entry.value)),
                  ],
                ),
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
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
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark),
                  ),
                  const TextSpan(
                    text: 'AI',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: textDark),
                  ),
                  const TextSpan(text: '🌿', style: TextStyle(fontSize: 18)),
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
      ),
    );
  }

  Widget _buildCurrentStageCard() {
    final current = stageDetails[_currentStage]!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryGreen.withOpacity(0.1), Colors.white],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current Stage', style: TextStyle(fontSize: 12, color: textGrey)),
          const SizedBox(height: 4),
          Text(current['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSpectrumChip('R: ${current['red']}', Colors.red),
              const SizedBox(width: 8),
              _buildSpectrumChip('B: ${current['blue']}', Colors.blue),
              const SizedBox(width: 8),
              _buildSpectrumChip('W: ${current['white']}', Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          Text(current['description'], style: const TextStyle(fontSize: 14, color: textGrey)),
        ],
      ),
    );
  }

  Widget _buildStageCard(GrowthStage stage, Map<String, dynamic> data) {
    final isCurrent = stage == _currentStage;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCurrent
              ? [primaryPurple.withOpacity(0.1), Colors.white]
              : [Colors.white, Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCurrent ? primaryPurple : Colors.grey.shade200, width: isCurrent ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: isCurrent ? primaryPurple.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
                    const SizedBox(height: 4),
                    Text('Duration: ${data['duration']}', style: TextStyle(fontSize: 12, color: textGrey)),
                  ],
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: primaryPurple, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Current', style: TextStyle(fontSize: 12, color: Colors.white)),
                )
              else
                ElevatedButton(
                  onPressed: () => _setStage(stage),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Select'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Light preview bars
          Row(
            children: [
              Expanded(child: _buildLightBar('Red', data['red'], Colors.red)),
              const SizedBox(width: 4),
              Expanded(child: _buildLightBar('Blue', data['blue'], Colors.blue)),
              const SizedBox(width: 4),
              Expanded(child: _buildLightBar('White', data['white'], Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          Text(data['description'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: textGrey)),
        ],
      ),
    );
  }

  Widget _buildSpectrumChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLightBar(String label, int value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10)),
        const SizedBox(height: 2),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(color: color.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value / 255,
            child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          ),
        ),
        const SizedBox(height: 2),
        Text('$value', style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
