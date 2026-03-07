import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class ESP32HatDetectionPage extends StatefulWidget {
  final String apiUrl = "http://10.0.2.2:5000"; // For emulator
  // final String apiUrl = "http://192.168.1.100:5000"; // For physical device - replace with your PC's IP

  @override
  _ESP32HatDetectionPageState createState() => _ESP32HatDetectionPageState();
}

class _ESP32HatDetectionPageState extends State<ESP32HatDetectionPage> {
  // Connection status
  bool _isConnected = false;
  bool _isConnecting = false;
  String _errorMessage = '';

  // Stream data
  Timer? _streamTimer;
  Uint8List? _currentFrame;
  Map<String, dynamic> _detections = {
    'hat_count': 0,
    'led_active': false,
    'fps': 0,
    'stability_ratio': 0.0,
    'total_detections': 0
  };

  // Settings
  double _confidenceThreshold = 0.20;
  bool _debugMode = false;
  bool _autoLedControl = true;

  // Statistics
  int _totalDetections = 0;
  DateTime? _lastDetectionTime;

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    _disconnect();
    super.dispose();
  }

  Future<void> _checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.apiUrl}/health'),
      ).timeout(Duration(seconds: 3));

      if (response.statusCode == 200) {
        print('API Health: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Cannot connect to API server';
      });
    }
  }

  Future<void> _connect() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('${widget.apiUrl}/connect'),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _isConnected = true;
          _isConnecting = false;
        });

        _startStreaming();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ESP32-CAM'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Connection failed');
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = 'Failed to connect: $e';
      });
    }
  }

  Future<void> _disconnect() async {
    try {
      await http.post(
        Uri.parse('${widget.apiUrl}/disconnect'),
      );
    } catch (e) {
      print('Disconnect error: $e');
    }

    _streamTimer?.cancel();
    setState(() {
      _isConnected = false;
      _currentFrame = null;
    });
  }

  void _startStreaming() {
    _streamTimer = Timer.periodic(Duration(milliseconds: 100), (timer) async {
      if (!_isConnected) return;

      try {
        final response = await http.get(
          Uri.parse('${widget.apiUrl}/stream'),
        ).timeout(Duration(seconds: 2));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          // Decode base64 image
          if (data['frame'] != null) {
            setState(() {
              _currentFrame = base64.decode(data['frame']);
              _detections = data['detections'] ?? _detections;

              // Update total detections
              if (_detections['hat_count'] > 0) {
                _totalDetections++;
                _lastDetectionTime = DateTime.now();
              }
            });
          }
        }
      } catch (e) {
        print('Stream error: $e');
      }
    });
  }

  Future<void> _toggleLed() async {
    try {
      final response = await http.post(
        Uri.parse('${widget.apiUrl}/led/${_detections['led_active'] ? 'off' : 'on'}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _detections['led_active'] = !_detections['led_active'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle LED'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _testLed() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Testing LED...')),
      );

      final response = await http.post(
        Uri.parse('${widget.apiUrl}/led/test'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('LED test successful'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('LED test failed'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveSnapshot() async {
    try {
      final response = await http.post(
        Uri.parse('${widget.apiUrl}/snapshot'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Snapshot saved'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save snapshot'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateConfig() async {
    try {
      await http.post(
        Uri.parse('${widget.apiUrl}/config'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'confidence': _confidenceThreshold,
        }),
      );
    } catch (e) {
      print('Config update error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Detection'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade900, Colors.blue.shade700],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Status Bar
              _buildStatusBar(),

              // Video Feed
              Expanded(
                flex: 3,
                child: _buildVideoFeed(),
              ),

              // Detection Info
              _buildDetectionInfo(),

              // Control Buttons
              _buildControlButtons(),

              // Manual LED Control
              if (_isConnected) _buildLedControl(),

              // Error Message
              if (_errorMessage.isNotEmpty) _buildErrorMessage(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black26,
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isConnected ? Colors.green : Colors.red,
            ),
          ),
          SizedBox(width: 8),
          Text(
            _isConnected ? 'Connected' : 'Disconnected',
            style: TextStyle(color: Colors.white),
          ),
          if (_isConnected) ...[
            SizedBox(width: 16),
            Icon(Icons.speed, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              '${_detections['fps']} FPS',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(width: 16),
            Icon(Icons.lightbulb,
              color: _detections['led_active'] ? Colors.yellow : Colors.white54,
              size: 16,
            ),
            SizedBox(width: 4),
            Text(
              _detections['led_active'] ? 'LED ON' : 'LED OFF',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoFeed() {
    if (_currentFrame != null) {
      return Container(
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(
                _currentFrame!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 50, color: Colors.white54),
                        Text('Frame Error', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  );
                },
              ),

              // Detection overlay
              if (_detections['hat_count'] > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '${_detections['hat_count']} hat(s)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

              // LED status overlay
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _detections['led_active'] ? Colors.green : Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: _detections['led_active'] ? Colors.yellow : Colors.white54,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        _detections['led_active'] ? 'LED ON' : 'LED OFF',
                        style: TextStyle(
                          color: _detections['led_active'] ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Debug info
              if (_debugMode && _detections['stability_ratio'] > 0)
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: Colors.black54,
                    child: Text(
                      'Stability: ${(_detections['stability_ratio'] * 100).toStringAsFixed(0)}%',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isConnecting ? Icons.wifi : Icons.videocam_off,
                size: 50,
                color: Colors.white54,
              ),
              SizedBox(height: 10),
              Text(
                _isConnecting ? 'Connecting...' : 'No Video Feed',
                style: TextStyle(color: Colors.white54),
              ),
              if (_isConnecting) ...[
                SizedBox(height: 10),
                CircularProgressIndicator(color: Colors.white),
              ],
            ],
          ),
        ),
      );
    }
  }

  Widget _buildDetectionInfo() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoCard(
            'Current',
            '${_detections['hat_count']}',
            Icons.person,
            _detections['hat_count'] > 0 ? Colors.orange : Colors.grey,
          ),
          _buildInfoCard(
            'Total',
            '$_totalDetections',
            Icons.history,
            Colors.blue,
          ),
          _buildInfoCard(
            'LED',
            _detections['led_active'] ? 'ON' : 'OFF',
            Icons.lightbulb,
            _detections['led_active'] ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Row(
        children: [
          if (!_isConnected)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isConnecting ? null : _connect,
                icon: Icon(Icons.link),
                label: Text(_isConnecting ? 'Connecting...' : 'Connect'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            )
          else
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _disconnect,
                icon: Icon(Icons.link_off),
                label: Text('Disconnect'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

          if (_isConnected) ...[
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _saveSnapshot,
                icon: Icon(Icons.camera_alt),
                label: Text('Snapshot'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLedControl() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _toggleLed,
              icon: Icon(_detections['led_active'] ? Icons.power_off : Icons.power),
              label: Text(_detections['led_active'] ? 'Turn LED OFF' : 'Turn LED ON'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            onPressed: _testLed,
            icon: Icon(Icons.science),
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(color: Colors.red.shade900),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: Text('Auto LED Control'),
                    value: _autoLedControl,
                    onChanged: (value) {
                      setState(() {
                        _autoLedControl = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text('Debug Mode'),
                    value: _debugMode,
                    onChanged: (value) {
                      setState(() {
                        _debugMode = value;
                        this.setState(() {});
                      });
                    },
                  ),
                  ListTile(
                    title: Text('Confidence Threshold'),
                    subtitle: Text('${(_confidenceThreshold * 100).toStringAsFixed(0)}%'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              _confidenceThreshold = (_confidenceThreshold - 0.05).clamp(0.05, 0.95);
                              _updateConfig();
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              _confidenceThreshold = (_confidenceThreshold + 0.05).clamp(0.05, 0.95);
                              _updateConfig();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
                TextButton(
                  onPressed: _testLed,
                  child: Text('Test LED'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}