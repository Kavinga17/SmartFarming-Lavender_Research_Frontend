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

  // App theme colors (matching existing app)
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color darkPurple = Color(0xFF7C3AED);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);

  // Pages in order: Live, Image Predict, History
  final List<Widget> _pages = [
    ESP32HatDetectionPage(),
    AddLavenderDiseasePage(),
    ViewLavenderHistoryPage(),
  ];

  String _getPageTitle() {
    switch (_currentIndex) {
      case 0: return 'Live Detection';
      case 1: return 'Image Prediction';
      case 2: return 'Detection History';
      default: return 'Disease Detection';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header matching climate screen
            _buildHeader(),
            // Page content
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _pages,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primaryPurple,
          unselectedItemColor: textGrey,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.videocam_outlined),
              activeIcon: Icon(Icons.videocam),
              label: 'Live',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.image_search_outlined),
              activeIcon: Icon(Icons.image_search),
              label: 'Predict',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: textDark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Lavender ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                TextSpan(
                  text: 'AI',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: textDark,
                  ),
                ),
                TextSpan(
                  text: '\uD83C\uDF3F',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Page context badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _currentIndex == 0
                      ? Icons.videocam
                      : _currentIndex == 1
                          ? Icons.image_search
                          : Icons.history,
                  size: 14,
                  color: primaryPurple,
                ),
                const SizedBox(width: 4),
                Text(
                  _getPageTitle(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: primaryPurple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
