// lib/widgets/dashboard/plant_analysis_card.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PlantAnalysisCard extends StatelessWidget {
  final XFile? selectedImage;
  final VoidCallback onPickImage;
  final VoidCallback onTakePhoto;

  static const Color primaryColor = Color(0xFF8A4FFF);
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8A4FFF), Color(0xFF6C3CE6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color textColor = Color(0xFF2C3E50);
  static const Color lightTextColor = Color(0xFF95A5A6);

  const PlantAnalysisCard({
    super.key,
    required this.selectedImage,
    required this.onPickImage,
    required this.onTakePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.cloud_upload,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Upload & Analyze',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Image Preview
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 2),
              ),
              child: selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        selectedImage!.path,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                  color: lightTextColor,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Cannot load image',
                                  style: TextStyle(color: lightTextColor),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: lightTextColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Upload or capture plant image',
                          style: TextStyle(
                            color: lightTextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPickImage,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library, size: 20),
                        SizedBox(width: 8),
                        Text('Gallery'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onTakePhoto,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 20),
                        SizedBox(width: 8),
                        Text('Camera'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
