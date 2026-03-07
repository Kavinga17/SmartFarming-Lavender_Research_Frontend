import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ViewLavenderHistoryPage extends StatefulWidget {
  @override
  _ViewLavenderHistoryPageState createState() => _ViewLavenderHistoryPageState();
}

class _ViewLavenderHistoryPageState extends State<ViewLavenderHistoryPage> {
  late Stream<QuerySnapshot> _diagnosisDataStream;
  TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All'; // For filtering by disease status

  // Lavender color theme (matching login page)
  final Color lavenderPrimary = Color(0xFF9B6B9E); // Lavender purple
  final Color lavenderLight = Color(0xFFE6C8E8); // Light lavender
  final Color lavenderDark = Color(0xFF7B4B7E); // Dark lavender
  final Color lavenderAccent = Color(0xFFD6B0D8); // Soft lavender
  final Color lavenderMist = Color(0xFFF3E5F5); // Very light lavender

  final List<String> _filterOptions = [
    'All',
    'Has Disease',
    'Healthy Only',
    'No Detection'
  ];

  @override
  void initState() {
    super.initState();
    // Fetch the diagnosis data stream from Firestore
    _diagnosisDataStream = FirebaseFirestore.instance
        .collection('lavender_detections')
        .orderBy('date_time', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.history, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'Detection History',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ),
            ),
          ],
        ),
        backgroundColor: lavenderPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: lavenderDark.withOpacity(0.5),
        actions: [
          // Filter dropdown
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, color: Colors.white, size: 22),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (BuildContext context) {
              return _filterOptions.map((String option) {
                return PopupMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    style: TextStyle(
                      color: option == _selectedFilter ? lavenderPrimary : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lavenderMist,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Search and Filter Bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // Search Field
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: lavenderPrimary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search by disease',
                        labelStyle: TextStyle(color: lavenderPrimary, fontSize: 14),
                        hintText: 'Type to search...',
                        hintStyle: TextStyle(fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: lavenderPrimary, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: lavenderPrimary, width: 1.5),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      style: TextStyle(fontSize: 14),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                  SizedBox(height: 6),
                  // Active filter indicator
                  if (_selectedFilter != 'All')
                    Container(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        label: Text(
                          'Filter: $_selectedFilter',
                          style: TextStyle(color: lavenderDark, fontSize: 12),
                        ),
                        backgroundColor: lavenderLight,
                        deleteIcon: Icon(Icons.close, size: 16, color: lavenderDark),
                        onDeleted: () {
                          setState(() {
                            _selectedFilter = 'All';
                          });
                        },
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ),

            // Data Table
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _diagnosisDataStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(lavenderPrimary),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Loading history...',
                            style: TextStyle(color: lavenderDark, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 40, color: Colors.red.shade400),
                          SizedBox(height: 8),
                          Text(
                            'Error loading data',
                            style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: lavenderPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: Text('Retry', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: lavenderLight.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.history,
                              size: 40,
                              color: lavenderPrimary.withOpacity(0.5),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No detection history',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: lavenderDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your detected images will appear here',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Get filtered data
                  List<DocumentSnapshot> filteredDocs = _filterDocuments(snapshot.data!.docs);

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.filter_alt_off,
                            size: 40,
                            color: lavenderPrimary.withOpacity(0.5),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No matches found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: lavenderDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Try adjusting your search or filter',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Return the data table
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: lavenderPrimary.withOpacity(0.1),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DataTable(
                          columnSpacing: 12,
                          horizontalMargin: 10,
                          headingRowHeight: 36,
                          dataRowHeight: 52,
                          headingRowColor: MaterialStateProperty.all(lavenderLight.withOpacity(0.3)),
                          columns: [
                            DataColumn(
                              label: Text(
                                'Date & Time',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: lavenderDark,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: lavenderDark,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Detections',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: lavenderDark,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Photo',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: lavenderDark,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                          rows: _buildDataRows(filteredDocs),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DocumentSnapshot> _filterDocuments(List<DocumentSnapshot> docs) {
    return docs.where((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Apply status filter
      if (_selectedFilter != 'All') {
        bool hasDisease = data['has_disease'] ?? false;
        int detectionCount = data['detection_count'] ?? 0;

        switch (_selectedFilter) {
          case 'Has Disease':
            if (!hasDisease) return false;
            break;
          case 'Healthy Only':
            if (hasDisease) return false;
            if (detectionCount == 0) return false;
            break;
          case 'No Detection':
            if (detectionCount > 0) return false;
            break;
        }
      }

      // Apply search filter
      if (_searchController.text.isNotEmpty) {
        String searchTerm = _searchController.text.toLowerCase();
        String overallStatus = data['overall_status']?.toLowerCase() ?? '';
        List detections = data['detections'] ?? [];

        // Search in overall status
        if (overallStatus.contains(searchTerm)) return true;

        // Search in individual detections
        for (var detection in detections) {
          String className = detection['class_name']?.toLowerCase() ?? '';
          if (className.contains(searchTerm)) return true;
        }

        return false;
      }

      return true;
    }).toList();
  }

  List<DataRow> _buildDataRows(List<DocumentSnapshot> docs) {
    return docs.map((document) {
      Map<String, dynamic> data = document.data() as Map<String, dynamic>;

      // Get data with defaults
      String overallStatus = data['overall_status'] ?? 'Unknown';
      int detectionCount = data['detection_count'] ?? 0;
      bool hasDisease = data['has_disease'] ?? false;
      List detections = data['detections'] ?? [];
      Timestamp dateTime = data['date_time'] ?? Timestamp.now();
      String photoPath = data['photo_path'] ?? '';

      // Create detection summary text
      String detectionSummary = '';
      if (detections.isNotEmpty) {
        detectionSummary = detections.map((d) {
          String className = d['class_name'] ?? 'Unknown';
          double confidence = d['confidence'] ?? 0;
          return '$className (${(confidence * 100).toStringAsFixed(0)}%)';
        }).join('\n');
      } else {
        detectionSummary = 'No detections';
      }

      // Determine status color
      Color statusColor;
      IconData statusIcon;
      String statusText;

      if (detectionCount == 0) {
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = 'No Detection';
      } else if (hasDisease) {
        statusColor = Colors.red.shade400;
        statusIcon = Icons.warning;
        statusText = 'Disease';
      } else {
        statusColor = Colors.green.shade600;
        statusIcon = Icons.check_circle;
        statusText = 'Healthy';
      }

      return DataRow(
        cells: [
          // Date & Time - Fixed with Row to prevent overflow
          DataCell(
            Container(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: lavenderPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('yyyy-MM-dd').format(dateTime.toDate()),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: lavenderDark,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(dateTime.toDate()),
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Status with icon
          DataCell(
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.3), width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 10, color: statusColor),
                  SizedBox(width: 2),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 9,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),

          // Detections Summary
          DataCell(
            Tooltip(
              message: detectionSummary,
              child: Container(
                constraints: BoxConstraints(maxWidth: 100),
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  detectionSummary.length > 15
                      ? '${detectionSummary.substring(0, 15)}...'
                      : detectionSummary,
                  style: TextStyle(
                    fontSize: 9,
                    color: lavenderDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),

          // Photo with tap to view full image
          DataCell(
            GestureDetector(
              onTap: () => _showFullImage(photoPath, detections),
              child: photoPath.isNotEmpty
                  ? Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: lavenderLight, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: lavenderPrimary.withOpacity(0.2),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                  image: DecorationImage(
                    image: NetworkImage(photoPath),
                    fit: BoxFit.cover,
                  ),
                ),
              )
                  : Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: lavenderLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: lavenderLight, width: 1),
                ),
                child: Icon(
                  Icons.image_not_supported,
                  size: 14,
                  color: lavenderPrimary.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ],
      );
    }).toList();
  }

  String _getFormattedDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  void _showFullImage(String imageUrl, List detections) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  lavenderMist,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.image, color: lavenderPrimary, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Image Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: lavenderDark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 180,
                        color: lavenderLight.withOpacity(0.3),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(lavenderPrimary),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: lavenderLight.withOpacity(0.3),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 30,
                                color: lavenderPrimary.withOpacity(0.5),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Image not available',
                                style: TextStyle(color: lavenderDark, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 12),

                // Detections in this image
                if (detections.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: lavenderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detections:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: lavenderDark,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 4),
                        ...detections.map((d) => Padding(
                          padding: EdgeInsets.only(bottom: 3),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: (d['class_name'] == 'Lavender_Disease'
                                      ? Colors.red
                                      : Colors.green).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  d['class_name'] == 'Lavender_Disease'
                                      ? Icons.warning
                                      : Icons.check_circle,
                                  size: 12,
                                  color: d['class_name'] == 'Lavender_Disease'
                                      ? Colors.red.shade400
                                      : Colors.green.shade600,
                                ),
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d['class_name'] ?? 'Unknown',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: lavenderDark,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      '${(d['confidence'] * 100).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ],
                    ),
                  ),

                SizedBox(height: 12),

                // Close button
                Container(
                  width: double.infinity,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [lavenderPrimary, lavenderDark],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}