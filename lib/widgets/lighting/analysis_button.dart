// lib/widgets/dashboard/analysis_button.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AnalysisButton extends StatelessWidget {
  final bool isAnalyzing;
  final XFile? selectedImage;
  final VoidCallback onAnalyze;

  static const Color primaryColor = Color(0xFF8A4FFF);

  const AnalysisButton({
    super.key,
    required this.isAnalyzing,
    required this.selectedImage,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = selectedImage != null && !isAnalyzing;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled ? onAnalyze : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: primaryColor.withOpacity(0.4),
        ),
        child: isAnalyzing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ANALYZE PLANT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
      ),
    );
  }
}
