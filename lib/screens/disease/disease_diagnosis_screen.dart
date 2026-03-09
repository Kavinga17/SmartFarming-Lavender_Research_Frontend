import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class AddLavenderDiseasePage extends StatefulWidget {
  @override
  _AddLavenderDiseasePageState createState() => _AddLavenderDiseasePageState();
}

class _AddLavenderDiseasePageState extends State<AddLavenderDiseasePage> {
  String _errorText = "";
  String _photoPath = "";
  String _predictedClass = "";
  List<dynamic> _detections = [];
  Map<String, dynamic> _summary = {};
  String _annotatedImageBase64 = "";
  bool _predictionCompleted = false;
  bool _isLoading = false;
  bool _isSaving = false;

  // App theme colors (matching existing app)
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color darkPurple = Color(0xFF7C3AED);
  static const Color lightPurple = Color(0xFFEDE9FE);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);

  Future<String> _uploadPhoto() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _photoPath = pickedFile.path;
        });

        return pickedFile.path;
      }

      return '';
    } catch (e) {
      print('Error picking photo: $e');
      return '';
    }
  }

  Future<void> _makePredictionRequest(String filePath) async {
    try {
      if (filePath.isEmpty) {
        print('File path is empty');
        return;
      }

      setState(() {
        _isLoading = true;
        _errorText = "";
      });

      // Read the file and base64-encode it for the backend
      final bytes = await File(filePath).readAsBytes();
      final imageBase64 = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('http://192.168.0.100:5000/diseasPredict'), // Unified backend on port 5000
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'image_base64': imageBase64}),
      );

      if (response.statusCode == 200) {
        // Parse the response JSON
        final Map<String, dynamic> data = json.decode(response.body);

        setState(() {

          _detections = data['detections'] ?? [];
          _summary = data['summary'] ?? {};           // ✅ FIX: Now populated from Flask summary block
          _annotatedImageBase64 = data['annotated_image'] ?? '';

          if (_detections.isNotEmpty) {
            // Check if any disease detected
            bool hasDisease = _detections.any((d) => d['class_name'] == 'Lavender_Disease');
            if (hasDisease) {
              _predictedClass = 'Disease Detected';
            } else {
              _predictedClass = 'Healthy Lavender';
            }
          } else {
            _predictedClass = 'No Detection';
          }

          _predictionCompleted = true;
          _isLoading = false;
        });

        print('Detections: $_detections');
        print('Summary: $_summary');
      } else {
        setState(() {
          _isLoading = false;
          _errorText = 'Prediction failed with status: ${response.statusCode}';
        });
        print('Prediction request failed with status code: ${response.statusCode}');
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorText = 'Error making prediction: $e';
      });
      print('Error making prediction request: $e');
    }
  }

  Future<void> _addLavenderDisease() async {
    if (_isSaving) return;
    try {

      setState(() {
        _errorText = "";
        _isSaving = true;
      });

      // Ensure prediction is completed before adding data to Firestore
      if (!_predictionCompleted) {
        setState(() {
          _errorText = 'Please wait for the prediction to complete.';
          _isSaving = false;
        });
        return;
      }

      // Check if user is logged in
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _errorText = 'Please log in to save history.';
          _isSaving = false;
        });
        return;
      }


      String userId = currentUser.uid;
      DateTime currentDateTime = DateTime.now();


      int diseaseCount = _detections.where((d) => d['class_name'] == 'Lavender_Disease').length;
      int healthyCount = _detections.where((d) => d['class_name'] == 'Lavender_Healthy').length;


      Map<String, dynamic> lavenderData = {
        'user_id': userId,
        'overall_status': _predictedClass,
        'detection_count': _detections.length,
        'disease_count': diseaseCount,
        'healthy_count': healthyCount,
        'has_disease': diseaseCount > 0,
        'detections': _detections,
        'summary': _summary,
        'photo_path': _photoPath,
        'annotated_image_base64': _annotatedImageBase64,
        'date_time': currentDateTime,
        'timestamp': FieldValue.serverTimestamp(),
      };


      await FirebaseFirestore.instance.collection('lavender_detections').add(lavenderData);


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('Detection saved to history successfully!')),
            ],
          ),
          backgroundColor: primaryPurple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: Duration(seconds: 3),
        ),
      );


      setState(() {
        _photoPath = "";
        _predictionCompleted = false;
        _detections = [];
        _summary = {};
        _isSaving = false;
      });

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('Error saving detection: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildImageWidget() {
    if (_photoPath.isNotEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: lightPurple, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
          image: DecorationImage(
            image: FileImage(File(_photoPath)),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: lightPurple, width: 1.5),
          color: backgroundColor,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 40, color: primaryPurple.withOpacity(0.4)),
            SizedBox(height: 8),
            Text(
              'No image selected',
              style: TextStyle(color: textGrey, fontSize: 14),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildAnnotatedImage() {
    if (_annotatedImageBase64.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Annotated Image:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: lightPurple, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
              image: DecorationImage(
                image: MemoryImage(base64Decode(_annotatedImageBase64)),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      );
    }
    return SizedBox.shrink();
  }

  Color _getStatusColor() {
    if (_detections.isEmpty) return Colors.grey;
    bool hasDisease = _detections.any((d) => d['class_name'] == 'Lavender_Disease');
    return hasDisease ? Colors.red.shade400 : Colors.green.shade600;
  }

  String _getStatusIcon() {
    if (_detections.isEmpty) return '❓';
    bool hasDisease = _detections.any((d) => d['class_name'] == 'Lavender_Disease');
    return hasDisease ? '⚠️' : '✅';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Upload Card
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: primaryPurple.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cloud_upload,
                        size: 35,
                        color: primaryPurple,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Upload Lavender Image',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Select an image to detect disease',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textGrey, fontSize: 14),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () async {
                          String url = await _uploadPhoto();
                          if (url.isNotEmpty) {
                            await _makePredictionRequest(url);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Processing...',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ],
                        )
                            : Text(
                          'Select & Predict',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Display uploaded image
            if (_photoPath.isNotEmpty) ...[
              _buildImageWidget(),
              SizedBox(height: 16),
            ],

            // Display error if any
            if (_errorText.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorText,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Display prediction results
            if (_predictionCompleted && _detections.isNotEmpty)
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Header
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _getStatusColor(), width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _detections.any((d) => d['class_name'] == 'Lavender_Disease')
                                  ? Icons.warning_amber
                                  : Icons.check_circle,
                              color: _getStatusColor(),
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _predictedClass,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _getStatusColor(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      // Summary Stats
                      if (_summary.isNotEmpty) ...[
                        Text(
                          'Detection Summary',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
                        ),
                        SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildStatChip(
                              'Total',
                              '${(_summary['disease_count'] ?? 0) + (_summary['healthy_count'] ?? 0)}',
                              primaryPurple,
                            ),
                            _buildStatChip(
                              'Diseased',
                              '${_summary['disease_count'] ?? 0}',
                              Colors.red.shade400,
                            ),
                            _buildStatChip(
                              'Healthy',
                              '${_summary['healthy_count'] ?? 0}',
                              Colors.green.shade600,
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                      ],

                      // Individual Detections
                      if (_detections.isNotEmpty) ...[
                        Text(
                          'Individual Detections',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
                        ),
                        SizedBox(height: 10),
                        ..._detections.map((detection) => Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: detection['class_name'] == 'Lavender_Disease'
                                ? Colors.red.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: detection['class_name'] == 'Lavender_Disease'
                                  ? Colors.red.shade200
                                  : Colors.green.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: detection['class_name'] == 'Lavender_Disease'
                                      ? Colors.red.shade100
                                      : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  detection['class_name'] == 'Lavender_Disease'
                                      ? Icons.warning
                                      : Icons.check,
                                  color: detection['class_name'] == 'Lavender_Disease'
                                      ? Colors.red.shade700
                                      : Colors.green.shade700,
                                  size: 16,
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      detection['class_name'] ?? 'Unknown',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: textDark,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Confidence: ${(detection['confidence'] * 100).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ],

                      // Annotated Image
                      if (_annotatedImageBase64.isNotEmpty) ...[
                        SizedBox(height: 16),
                        _buildAnnotatedImage(),
                      ],

                      SizedBox(height: 16),

                      // Save to History Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _addLavenderDisease,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isSaving
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Saving...',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Save to History',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
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

            // No detections message
            if (_predictionCompleted && _detections.isEmpty)
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.info_outline,
                          size: 35,
                          color: Colors.orange.shade400,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No Objects Detected',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'The model could not detect any lavender plants.\nPlease try another image.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textGrey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
