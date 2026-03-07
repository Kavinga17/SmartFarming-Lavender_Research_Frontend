import 'package:flutter/material.dart';
import 'package:lavender_ai_app/pages/Diagnosis.dart';
import 'package:lavender_ai_app/pages/DiagnosisData.dart';
import 'package:lavender_ai_app/pages/Live.dart';

class Home extends StatefulWidget {
  final String userId;
  final String? role;

  const Home({Key? key, required this.userId, this.role}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;

  // Lavender color theme (matching login page)
  final Color lavenderPrimary = Color(0xFF9B6B9E); // Lavender purple
  final Color lavenderLight = Color(0xFFE6C8E8); // Light lavender
  final Color lavenderDark = Color(0xFF7B4B7E); // Dark lavender
  final Color lavenderAccent = Color(0xFFD6B0D8); // Soft lavender
  final Color lavenderMist = Color(0xFFF3E5F5); // Very light lavender

  // Pages in order: Live, Image Predict, History
  final List<Widget> _pages = [
    ESP32HatDetectionPage(),      // Live Camera Detection
    AddLavenderDiseasePage(),     // Image Upload & Prediction
    ViewLavenderHistoryPage(),    // History View
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Function to handle logout
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: lavenderPrimary),
              SizedBox(width: 8),
              Text(
                'Logout',
                style: TextStyle(color: lavenderDark),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [lavenderPrimary, lavenderDark],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Add your logout logic here
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Live Detection';
      case 1:
        return 'Image Prediction';
      case 2:
        return 'History';
      default:
        return 'Lavender Disease Diagnosis';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.local_florist, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              _getAppBarTitle(),
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: lavenderPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: lavenderDark.withOpacity(0.5),
        actions: [
          if (widget.role != null)
            Container(
              margin: EdgeInsets.only(right: 16),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    widget.role!,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      ),
      drawer: Drawer(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                lavenderMist,
              ],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Drawer Header with Lavender Theme
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [lavenderPrimary, lavenderDark],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: lavenderDark.withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: lavenderLight.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: lavenderAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Header content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  lavenderLight,
                                  lavenderAccent,
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.local_florist,
                              size: 35,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 15),
                          Text(
                            'Lavender',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Disease Diagnosis',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          if (widget.role != null) ...[
                            SizedBox(height: 5),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Role: ${widget.role}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Menu Items
              SizedBox(height: 20),

              _buildDrawerItem(
                icon: Icons.videocam,
                title: 'Live Detection',
                index: 0,
              ),

              _buildDrawerItem(
                icon: Icons.image_search,
                title: 'Image Prediction',
                index: 1,
              ),

              _buildDrawerItem(
                icon: Icons.history,
                title: 'History',
                index: 2,
              ),

              Divider(
                color: lavenderLight,
                thickness: 1,
                indent: 20,
                endIndent: 20,
              ),

              // Logout Item
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.logout,
                    color: Colors.red.shade400,
                  ),
                ),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  _handleLogout();
                },
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    bool isSelected = _currentIndex == index;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: isSelected
          ? BoxDecoration(
        gradient: LinearGradient(
          colors: [lavenderLight, lavenderMist],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: lavenderPrimary,
          width: 1,
        ),
      )
          : null,
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? lavenderPrimary.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isSelected ? lavenderPrimary : Colors.grey.shade600,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? lavenderDark : Colors.grey.shade700,
            fontSize: 16,
          ),
        ),
        trailing: isSelected
            ? Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: lavenderPrimary,
            shape: BoxShape.circle,
          ),
        )
            : null,
        onTap: () {
          _onItemTapped(index);
          Navigator.pop(context);
        },
      ),
    );
  }
}