<div align="center">
  
![Header](https://capsule-render.vercel.app/api?type=waving&color=gradient&height=200&section=header&text=Mobile%20Application%20UI&fontSize=55&animation=fadeIn&fontAlignY=35)

<img width="100%" height="50" src="https://i.imgur.com/dBaSKWF.gif" />

# 📱 Pest Detection Mobile Interface

[![Typing SVG](https://readme-typing-svg.demolab.com?font=Fira+Code&pause=1000&color=9D4EDD&center=true&vCenter=true&width=435&lines=Real-time+Pest+Monitoring;Flutter+Mobile+Dashboard;Instant+Alert+Notifications)](https://git.io/typing-svg)

</div>

---

## 👨‍💻 Developer Information

<div align="center">

**Developer:** WBWMRK Aluvihare - IT22304506  
**Component:** Mobile Application - Pest & Disease Monitoring Interface  
**Project:** SmartFarming-Lavender-AI 🌱💜

</div>

---

## 📋 Overview

The **Pest Detection Mobile Interface** is a cross-platform Flutter application that provides farmers with real-time access to the pest and disease monitoring system. It displays live camera feeds from ESP32-CAM, shows detection results, sends instant push notifications, and allows remote control of the alert system.

---

## 🎯 Mobile Application Architecture
```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Mobile Application Architecture                      │
├─────────────────────────────────── ─────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────┐         ┌─────────────────┐                        │
│  │  Flutter App    │◀──────▶│  Firebase       │                        │
│  │  (Mobile)       │         │  Realtime DB    │                        │
│  │                 │         │                 │                        │
│  └────────┬────────┘         └────────┬────────┘                        │
│           │                           │                                 │
│           ▼                           ▼                                 │
│  ┌─────────────────┐         ┌─────────────────┐                        │
│  │  Push           │         │  Detection      │                        │
│  │  Notifications  │         │  Data Stream    │                        │
│  │  (FCM)          │         │  (Real-time)    │                        │
│  └─────────────────┘         └────────┬────────┘                        │
│                                       │                                 │
│                                       ▼                                 │
│                          ┌─────────────────────┐                        │
│                          │  Python Backend     │                        │
│                          │  - YOLOv8 Results   │                        │
│                          │  - Alert Trigger    │                        │
│                          └──────────┬──────────┘                        │
│                                     │                                   │
│                                     ▼                                   │
│                          ┌─────────────────────┐                        │
│                          │  ESP32-CAM Stream   │                        │
│                          │  - Live Video       │                        │
│                          │  - Detection Overlay│                        │
│                          └─────────────────────┘                        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## ✨ Key Features

<div align="center">

| Feature | Description | User Benefit |
|---------|-------------|--------------|
| 📹 **Live Camera Feed** | Real-time ESP32-CAM stream view | Monitor field remotely |
| 🔔 **Push Notifications** | Instant pest detection alerts | Immediate awareness |
| 📊 **Detection Dashboard** | View all detections with timestamps | Historical tracking |
| 🎯 **Detection Statistics** | Count of diseases, healthy, insects | Quick overview |
| 🖼️ **Detection Gallery** | Saved detection images with annotations | Visual evidence |
| 🎮 **Remote Control** | Manual alert system ON/OFF | User control |
| 📈 **Analytics** | Daily/Weekly detection trends | Pattern recognition |
| 🌙 **Dark Mode** | Eye-friendly night viewing | User comfort |

</div>

---

## 🛠️ Technology Stack

<div align="center">

### Frontend Framework
![Flutter](https://img.shields.io/badge/Flutter_3.x-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)

### Backend & Cloud
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)
![Realtime DB](https://img.shields.io/badge/Realtime_DB-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![FCM](https://img.shields.io/badge/FCM-FFA000?style=for-the-badge&logo=firebase&logoColor=white)

### State Management
![Provider](https://img.shields.io/badge/Provider-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![GetX](https://img.shields.io/badge/GetX-8B5CF6?style=for-the-badge)

### Additional Packages
![HTTP](https://img.shields.io/badge/HTTP-005571?style=for-the-badge)
![WebSocket](https://img.shields.io/badge/WebSocket-010101?style=for-the-badge)

</div>

---

## 📱 App Screens & UI Components

### 1. **Pest Detection Dashboard**

**Screen Purpose:** Main monitoring interface for pest detection

**UI Elements:**
```dart
Components:
- Real-time detection status card
- ESP32-CAM live stream preview
- Quick stats (Disease/Healthy/Insect counts)
- Recent alerts list
- Alert system control toggle
- Refresh button
```

**Features:**
- Color-coded status indicators
  - 🔴 Red: Disease detected
  - 🟢 Green: All healthy
  - 🟡 Yellow: Insect detected
- Live detection count
- Last detection timestamp
- System status (Online/Offline)

**Layout:**
```
┌─────────────────────────────┐
│     System Status: 🟢       
├─────────────────────────────┤
│  📹 Live Camera Feed        
│  [ESP32-CAM Stream View]    │
│                             │
├─────────────────────────────┤
│  📊 Today's Detections      
│  Disease: 5 | Healthy: 120  │
│  Insects: 3                 │
├─────────────────────────────┤
│  🔔 Recent Alerts           
│  • Insect detected - 2m ago │
│  • Disease found - 15m ago  │
│                             │
├─────────────────────────────┤
│  [Alert System: ON/OFF]     │
└─────────────────────────────┘
```

---

### 2. **Live Camera View Screen**

**Screen Purpose:** Full-screen camera feed with detection overlay

**UI Elements:**
```dart
Components:
- Full-screen ESP32-CAM stream
- Detection bounding boxes overlay
- Confidence scores display
- FPS counter
- Recording indicator
- Screenshot button
- Back navigation
```

**Features:**
- Pinch-to-zoom
- Double-tap to capture
- Color-coded bounding boxes (Red/Green/Yellow)
- Real-time confidence percentage
- Connection status indicator

**Overlay Design:**
```
┌─────────────────────────────┐
│  ◀ Back    FPS: 10    📷   │
├─────────────────────────────┤
│                             │
│     [Live Camera Feed]      │
│                             │
│   ┌─────────────┐           │
│   │  Insect     │           │
│   │  Conf: 0.87 │           │
│   └─────────────┘           │
│                             │
├─────────────────────────────┤
│  Status: Connected 🟢       
└─────────────────────────────┘
```

---

### 3. **Detection History Screen**

**Screen Purpose:** View past detection events with details

**UI Elements:**
```dart
Components:
- Date filter (Today/Week/Month/All)
- Detection cards with images
- Class filter (All/Disease/Healthy/Insect)
- Sort options (Newest/Oldest/Confidence)
- Search functionality
- Export to PDF button
```

**Detection Card Design:**
```
┌─────────────────────────────┐
│  [Detection Thumbnail]      │
│                             │
│  🐛 Insect Detected        
│  Confidence: 87%            │
│  Time: 2:30 PM, Jan 10      │
│  Location: Camera-01        │
│                             │
│  [View Details]             │
└─────────────────────────────┘
```

---

### 4. **Alert Notifications Screen**

**Screen Purpose:** Manage and view all alerts

**UI Elements:**
```dart
Components:
- Alert list (Unread/All)
- Alert severity badges
- Mark as read/unread
- Delete/Archive options
- Filter by type
- Notification settings
```

**Alert Types:**
```
🔴 Critical: Pest detected (Immediate action)
🟡 Warning: Disease found (Attention needed)
🔵 Info: System status updates
🟢 Success: Issue resolved
```

**Alert Card:**
```
┌─────────────────────────────┐
│  🔴 Critical Alert          
│                             │
│  Insect Detected!           │
│  Camera-01 detected pest    │
│  with 87% confidence        │
│                             │
│  📅 Jan 10, 2:30 PM         
│  [View] [Mark as Read]      │
└─────────────────────────────┘
```

---

### 5. **Analytics & Reports Screen**

**Screen Purpose:** Visualize detection trends and statistics

**UI Elements:**
```dart
Components:
- Interactive line charts
- Bar graphs for class distribution
- Pie charts for detection ratios
- Date range selector
- Export options (PDF/CSV)
- Comparison views
```

**Chart Types:**
1. **Detection Trend (Line Chart)**
   - X-axis: Time (Hours/Days/Weeks)
   - Y-axis: Detection count
   - Multiple lines for each class

2. **Class Distribution (Pie Chart)**
   - Disease: Red slice
   - Healthy: Green slice
   - Insect: Yellow slice

3. **Hourly Pattern (Bar Chart)**
   - Peak detection times
   - Activity heatmap

---

### 6. **Settings & Control Screen**

**Screen Purpose:** Configure app and system preferences

**UI Elements:**
```dart
Sections:
1. Alert Settings
   - Enable/disable push notifications
   - Alert sound preferences
   - Vibration settings
   - Notification priority

2. Camera Settings
   - ESP32-CAM IP configuration
   - Stream quality (Low/Medium/High)
   - Auto-refresh interval
   - Connection timeout

3. Detection Settings
   - Confidence threshold adjustment
   - Target classes selection
   - Alert sensitivity
   - Auto-capture on detection

4. App Preferences
   - Theme (Light/Dark/Auto)
   - Language selection
   - Data usage settings
   - Cache management

5. System Control
   - Manual alert test
   - Reset detection counters
   - Clear cache
   - About & Help
```

---

## 🔄 Real-Time Data Flow
```
┌──────────────────────────────────────────────────────────────┐
│                    Data Flow Diagram                         │
└──────────────────────────────────────────────────────────────┘

1. Detection Event
   Python detects pest → YOLOv8 inference
   ↓
2. Firebase Update
   Detection data pushed to Realtime Database
   {
     timestamp: 1736492400,
     class: "Insect",
     confidence: 0.87,
     imageUrl: "storage/detections/img_001.jpg",
     cameraId: "Camera-01",
     status: "alert"
   }
   ↓
3. Real-time Sync
   Flutter StreamBuilder listens to Firebase
   ↓
4. UI Update
   - Dashboard counter updates
   - Detection list refreshes
   - Status indicator changes color
   ↓
5. Push Notification
   Firebase Cloud Messaging triggers
   "🐛 Insect Detected! Camera-01"
   ↓
6. User Action
   - Opens app from notification
   - Views detection details
   - Acknowledges alert
```

---

## 🎨 UI/UX Design Principles

### Color Palette
```dart
// Primary Colors (Lavender Theme)
Primary: #9D4EDD (Purple)
Secondary: #10B981 (Green - Agriculture)
Accent: #F59E0B (Amber - Alerts)

// Detection Colors
Disease: #EF4444 (Red)
Healthy: #22C55E (Green)
Insect: #FBBF24 (Yellow)

// Neutral Colors
Background Light: #F3F4F6
Background Dark: #1F2937
Text Primary: #111827
Text Secondary: #6B7280
```

### Typography
```dart
// Font Family
Font: 'Inter' / 'Roboto'

// Font Sizes
Heading 1: 32px (Bold)
Heading 2: 24px (SemiBold)
Heading 3: 20px (Medium)
Body: 16px (Regular)
Caption: 14px (Regular)
Small: 12px (Regular)
```

### Design System
```dart
// Card Design
- Rounded corners (12px radius)
- Subtle shadow (elevation: 2)
- White background (light mode)
- Dark gray background (dark mode)

// Buttons
- Primary: Purple gradient
- Secondary: Outlined with purple border
- Disabled: Gray with low opacity

// Icons
- Outlined style
- 24px size (standard)
- Match class colors for detection types
```

---

## 📲 Firebase Integration

### Realtime Database Structure
```json
{
  "detections": {
    "detection_001": {
      "timestamp": 1736492400,
      "class": "Insect",
      "classId": 2,
      "confidence": 0.87,
      "imageUrl": "gs://bucket/detections/img_001.jpg",
      "cameraId": "Camera-01",
      "location": {
        "lat": 7.8731,
        "lng": 80.7718
      },
      "boundingBox": {
        "x": 120,
        "y": 80,
        "width": 200,
        "height": 150
      },
      "acknowledged": false
    }
  },
  "alerts": {
    "alert_001": {
      "detectionId": "detection_001",
      "severity": "critical",
      "message": "Insect detected in Camera-01",
      "timestamp": 1736492400,
      "read": false
    }
  },
  "cameras": {
    "Camera-01": {
      "name": "Field Camera 1",
      "ip": "192.168.1.100",
      "status": "online",
      "lastUpdate": 1736492400
    }
  },
  "statistics": {
    "2026-01-10": {
      "disease": 5,
      "healthy": 120,
      "insect": 3,
      "total": 128
    }
  }
}
```

### Firebase Cloud Messaging (FCM)
```dart
// Notification Payload
{
  "notification": {
    "title": "🐛 Pest Alert!",
    "body": "Insect detected with 87% confidence in Camera-01",
    "sound": "default",
    "badge": "1"
  },
  "data": {
    "type": "pest_detection",
    "detectionId": "detection_001",
    "cameraId": "Camera-01",
    "class": "Insect",
    "confidence": "0.87",
    "timestamp": "1736492400"
  },
  "priority": "high",
  "content_available": true
}
```

---



---

## 🔔 Push Notification Implementation

### Notification Types & Handlers
```dart
// 1. Critical Alert - Pest Detected
{
  "title": "🐛 Critical: Pest Detected!",
  "body": "Insect found in Camera-01 (87% confidence)",
  "priority": "high",
  "sound": "alarm.mp3",
  "actions": ["View", "Acknowledge"]
}

// 2. Warning - Disease Found
{
  "title": "⚠️ Warning: Disease Detected",
  "body": "Lavender disease in Camera-01 (84% confidence)",
  "priority": "high",
  "sound": "notification.mp3",
  "actions": ["View", "Dismiss"]
}

// 3. Info - System Status
{
  "title": "ℹ️ System Update",
  "body": "Camera-01 is now online",
  "priority": "normal",
  "sound": "default"
}

// 4. Success - Issue Resolved
{
  "title": "✅ Alert Resolved",
  "body": "No pests detected in last hour",
  "priority": "low",
  "sound": "success.mp3"
}
```

### Notification Handling Code
```dart
// Initialize FCM
Future<void> initializeNotifications() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  // Request permission
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );
  
  // Handle foreground notifications
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.data['type'] == 'pest_detection') {
      showLocalNotification(message);
      updateDetectionList(message.data);
    }
  });
  
  // Handle notification tap
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    navigateToDetectionDetail(message.data['detectionId']);
  });
}
```

---

## 📊 Data Visualization Components

### 1. Detection Trend Line Chart
```dart
// Chart Configuration
LineChart(
  detectionData,
  xAxis: TimeAxis(hours/days/weeks),
  yAxis: CountAxis,
  series: [
    Series(name: "Disease", color: Colors.red),
    Series(name: "Healthy", color: Colors.green),
    Series(name: "Insect", color: Colors.yellow),
  ],
  animate: true,
  behaviors: [
    ChartTitle("Detection Trends"),
    Legend(),
    DateRangeSelector(),
  ]
)
```

### 2. Class Distribution Pie Chart
```dart
// Pie Chart Data
PieChart(
  slices: [
    PieSlice(label: "Disease", value: diseaseCount, color: Colors.red),
    PieSlice(label: "Healthy", value: healthyCount, color: Colors.green),
    PieSlice(label: "Insect", value: insectCount, color: Colors.yellow),
  ],
  showPercentage: true,
  showLabels: true,
  animate: true
)
```

### 3. Hourly Activity Bar Chart
```dart
// Bar Chart Configuration
BarChart(
  hourlyData,
  xAxis: HourAxis(0-23),
  yAxis: CountAxis,
  barColor: Colors.purple,
  showValues: true,
  animate: true
)
```

---

## 🎮 User Interactions & Controls

### Alert System Control
```dart
// Toggle Switch Widget
SwitchListTile(
  title: "Alert System",
  subtitle: alertActive ? "Active" : "Inactive",
  value: alertActive,
  activeColor: Colors.green,
  onChanged: (bool value) {
    setState(() {
      alertActive = value;
    });
    sendAlertCommand(value ? "LED_ON" : "LED_OFF");
  },
)
```

### Manual Alert Test
```dart
// Test Button
ElevatedButton.icon(
  icon: Icon(Icons.notifications_active),
  label: Text("Test Alert System"),
  onPressed: () async {
    await sendTestAlert();
    showSnackBar("Test alert sent to ESP32-CAM");
  },
)
```

### Camera Stream Controls
```dart
// Stream Control Buttons
Row(
  children: [
    IconButton(
      icon: Icon(Icons.play_arrow),
      onPressed: startStream,
    ),
    IconButton(
      icon: Icon(Icons.pause),
      onPressed: pauseStream,
    ),
    IconButton(
      icon: Icon(Icons.camera_alt),
      onPressed: captureScreenshot,
    ),
    IconButton(
      icon: Icon(Icons.refresh),
      onPressed: refreshStream,
    ),
  ],
)
```

---

## 🔐 Security & Authentication

### User Authentication
```dart
// Firebase Authentication
- Email/Password login
- Google Sign-In
- Phone number verification
- Biometric authentication (fingerprint/face)

// Role-Based Access
enum UserRole {
  admin,      // Full control
  manager,    // Monitor + control
  worker,     // View only
}
```

### Data Security
```dart
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /detections/{detectionId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      request.auth.token.role == 'admin';
    }
    
    match /cameras/{cameraId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      request.auth.token.role in ['admin', 'manager'];
    }
  }
}
```

---

## 📲 Installation & Setup

### Prerequisites
```bash
# Flutter SDK
Flutter 3.x or higher

# Dependencies
flutter pub add firebase_core
flutter pub add firebase_database
flutter pub add firebase_messaging
flutter pub add firebase_auth
flutter pub add firebase_storage
flutter pub add provider
flutter pub add fl_chart
flutter pub add http
flutter pub add web_socket_channel
flutter pub add shared_preferences
flutter pub add image_picker
flutter pub add cached_network_image
```

### Firebase Configuration
```bash
# 1. Create Firebase project
# 2. Add Android/iOS apps
# 3. Download google-services.json (Android)
# 4. Download GoogleService-Info.plist (iOS)
# 5. Enable Realtime Database
# 6. Enable Cloud Messaging
# 7. Enable Storage
# 8. Setup Authentication
```

### Run Application
```bash
# Install dependencies
flutter pub get

# Run on emulator/device
flutter run

# Build APK (Android)
flutter build apk --release

# Build IPA (iOS)
flutter build ios --release
```

---

## 📈 Performance Optimization

### Image Caching
```dart
// Use CachedNetworkImage for detection images
CachedNetworkImage(
  imageUrl: detectionImageUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  cacheKey: detectionId,
  maxHeightDiskCache: 800,
  maxWidthDiskCache: 800,
)
```

### Real-time Data Management
```dart
// Limit realtime listeners
- Use pagination for large lists
- Implement lazy loading
- Cache frequently accessed data locally
- Unsubscribe from streams when not needed
```

### Network Optimization
```dart
// Handle poor connectivity
- Show offline indicators
- Queue operations when offline
- Sync data when connection restored
- Compress images before upload
```

---

## 🐛 Troubleshooting Mobile App

<details>
<summary><b>1. Notifications Not Received</b></summary>

**Problem:** Push notifications not appearing

**Solutions:**
```bash
✓ Check FCM token registration
✓ Verify notification permissions
✓ Ensure app is allowed in battery optimization
✓ Check Firebase Cloud Messaging settings
✓ Test with Firebase console test message
✓ Verify device token in Firebase
```
</details>

<details>
<summary><b>2. Camera Stream Not Loading</b></summary>

**Problem:** ESP32-CAM stream not displaying

**Solutions:**
```bash
✓ Check WiFi connection
✓ Verify ESP32-CAM IP address
✓ Test stream URL in browser first
✓ Check firewall settings
✓ Ensure ESP32 is powered on
✓ Verify network permissions in app
```
</details>

<details>
<summary><b>3. Firebase Connection Failed</b></summary>

**Problem:** Cannot connect to Firebase

**Solutions:**
```bash
✓ Check google-services.json configuration
✓ Verify Firebase project setup
✓ Enable required Firebase services
✓ Check internet connection
✓ Update Firebase packages
✓ Clear app cache and rebuild
```
</details>

<details>
<summary><b>4. Detection Data Not Syncing</b></summary>

**Problem:** Detection list not updating

**Solutions:**
```bash
✓ Check Firebase Realtime Database rules
✓ Verify StreamBuilder implementation
✓ Check authentication status
✓ Ensure proper data path in code
✓ Test with Firebase console
✓ Check for rate limiting
```
</details>

---

## 🔮 Future Enhancements

<div align="center">

| Enhancement | Status | Priority |
|-------------|--------|----------|
| 🗺️ Map View | Planned | High |
| 📊 ML Insights | Planned | High |
| 🎙️ Voice Commands | Planned | Medium |
| 📱 Watch App | Planned | Low |
| 🌐 Multi-language | Planned | Medium |
| 🔔 Custom Alert Sounds | Planned | Low |

</div>

---

## 📸 App Screenshots

*(Screenshots to be added)*
```
[Dashboard]  [Live Camera]  [History]  [Analytics]  [Settings]
```

---

## 🎓 Development Notes

### State Management
```dart
// Using Provider pattern
- DetectionProvider: Manages detection state
- AlertProvider: Manages alert state  
- CameraProvider: Manages camera connection
- ThemeProvider: Manages app theme
```

### Navigation
```dart
// Named routes for easy navigation
routes: {
  '/': (context) => DashboardScreen(),
  '/live-camera': (context) => LiveCameraScreen(),
  '/history': (context) => HistoryScreen(),
  '/analytics': (context) => AnalyticsScreen(),
  '/settings': (context) => SettingsScreen(),
}
```

### Error Handling
```dart
// Graceful error handling
try {
  await fetchDetections();
} catch (e) {
  showErrorDialog(
    title: "Error",
    message: "Failed to load detections. Please try again.",
  );
}
```

---

<div align="center">

<img width="100%" height="50" src="https://i.imgur.com/dBaSKWF.gif" />

## 📞 Support

For issues or questions about the mobile application:

📧 **Email:** kavingaaluwihare2001@gmail.com  
📱 **Developer:** WBWMRK Aluvihare  
🎓 **Student ID:** IT22304506

---

**Built with 💜 using Flutter**

*Bringing smart farming to your fingertips* 📱🌱

<img width="100%" height="50" src="https://i.imgur.com/dBaSKWF.gif" />

![Footer](https://capsule-render.vercel.app/api?type=waving&color=gradient&height=100&section=footer)

</div>
