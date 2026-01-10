# 📱 Mobile Application - SmartFarming Lavender AI

<div align="center">

**Cross-Platform Mobile Dashboard for Smart Lavender Farm Management**

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)

</div>

---

## 📋 Overview

The **SmartFarming Lavender AI Mobile Application** is a cross-platform solution built with **Flutter** that serves as the central control and monitoring dashboard for farmers. It provides real-time access to all four system components, allowing farmers to monitor their lavender fields, receive instant alerts, and control various systems from anywhere.

---

## 🎯 Key Features

### 📊 Real-Time Monitoring Dashboard
- Live data visualization from all sensors
- Interactive charts and graphs
- Historical data trends
- Component-specific monitoring views

### 🔔 Push Notifications & Alerts
- Instant pest detection alerts
- Soil moisture warnings
- Climate anomaly notifications
- Irrigation schedule reminders
- Custom alert preferences

### 🎮 Remote Control
- Manual irrigation control
- Climate system adjustments
- Lighting schedule management
- Alert system testing

### 📈 Analytics & Reports
- Daily/Weekly/Monthly reports
- Yield predictions
- Resource consumption tracking
- Cost analysis
- Export data to PDF/CSV

### 👤 User Management
- Multi-user access
- Role-based permissions (Admin, Manager, Worker)
- Activity logs
- Profile customization

---

## 🛠️ Technology Stack

### **Frontend Framework**
```
Flutter 3.x - Cross-platform UI framework
Dart - Programming language
Material Design 3 - UI/UX design system
```

### **State Management**
```
Provider / Riverpod - State management solution
GetX - Navigation and dependency injection (optional)
```

### **Backend Integration**
```
Firebase Realtime Database - Real-time data sync
Firebase Cloud Messaging (FCM) - Push notifications
Firebase Authentication - User authentication
Firebase Storage - Image/file storage
```

### **APIs & Communication**
```
REST API - Communication with backend services
WebSocket - Real-time data streaming
MQTT - IoT device communication
HTTP - API requests
```

### **Data Visualization**
```
fl_chart - Interactive charts and graphs
syncfusion_flutter_charts - Advanced charting
charts_flutter - Google Charts integration
```

### **Additional Packages**
```
camera - Camera access for manual inspection
image_picker - Image selection and upload
geolocator - Location services
local_notifications - Local push notifications
shared_preferences - Local data storage
dio - HTTP client
flutter_map - Map integration
```

---

## 🎨 UI/UX Design

### **Design Principles**
- **Minimalist & Intuitive** - Easy navigation for farmers
- **Responsive Design** - Adapts to different screen sizes
- **Dark Mode Support** - Comfortable viewing in all conditions
- **Offline Capability** - Works with limited connectivity
- **Accessibility** - Large text, high contrast options

### **Color Palette**
```
Primary: #9D4EDD (Purple - Lavender theme)
Secondary: #10B981 (Green - Agriculture)
Accent: #F59E0B (Amber - Alerts)
Background: #F3F4F6 (Light Gray)
Text: #1F2937 (Dark Gray)
Error: #EF4444 (Red - Warnings)
```

---

## 📱 App Screens & Features

### 1. **Authentication Screens**
```
- Login Screen
- Registration Screen
- Forgot Password
- OTP Verification
- Profile Setup
```

### 2. **Dashboard (Home)**
```
- Overview Cards (Soil, Climate, Pests, Lighting)
- Real-time Status Indicators
- Quick Action Buttons
- Recent Alerts Summary
- Weather Widget
```

### 3. **Component-Specific Screens**

#### 🌍 Soil & Irrigation Monitor
```
- Soil moisture levels (%)
- pH levels
- Nutrient status (NPK)
- Irrigation schedule
- Water consumption metrics
- Manual pump control
```

#### 🌡️ Climate Control Monitor
```
- Temperature readings
- Humidity levels
- CO2 concentration
- Ventilation status
- HVAC control panel
- Climate history graphs
```

#### 🐛 Pest Detection Monitor
```
- Live camera feed from ESP32-CAM
- Detection history with images
- Pest count statistics
- Disease identification results
- Alert logs
- Manual detection trigger
- View annotated images
```

#### 💡 Lighting Control
```
- Light spectrum settings
- Intensity levels (%)
- Automated schedule
- Growth phase selection
- Energy consumption
- Manual override controls
```

### 4. **Alerts & Notifications**
```
- Alert History
- Filter by type/severity
- Mark as read/resolved
- Alert preferences settings
- Push notification settings
```

### 5. **Analytics & Reports**
```
- Interactive charts
- Date range selection
- Component comparison
- Export options (PDF/CSV)
- Yield predictions
- Cost analysis
```

### 6. **Settings**
```
- User profile
- App preferences
- Notification settings
- Language selection
- Dark mode toggle
- System configuration
- About & Help
```

---

## 🔄 Real-Time Data Flow
```
┌─────────────────┐
│  IoT Sensors    │
│  (ESP32/Arduino)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Firebase       │
│  Realtime DB    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Flutter App    │
│  (StreamBuilder)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  UI Update      │
│  (Live Refresh) │
└─────────────────┘
```

---

## 📊 Key Functionalities

### **1. Real-Time Pest Detection View**
```dart
Features:
- Live video stream from ESP32-CAM
- Detection overlay with bounding boxes
- Confidence scores display
- Color-coded detection (Red: Disease, Green: Healthy, Yellow: Insect)
- Capture & save detection screenshots
- Alert history with timestamps
```

### **2. Sensor Data Visualization**
```dart
Components:
- Line charts for temperature/humidity trends
- Bar charts for soil nutrient levels
- Gauge meters for moisture levels
- Pie charts for resource distribution
- Real-time value updates
```

### **3. Control Panel**
```dart
Actions:
- Toggle irrigation ON/OFF
- Adjust climate settings (temp/humidity setpoints)
- Modify lighting schedules
- Test alert systems
- Emergency stop functionality
```

### **4. Notification System**
```dart
Alert Types:
- Critical: Pest detected, System failure
- Warning: Low moisture, High temperature
- Info: Irrigation completed, Schedule reminder
- Success: Task completed, System healthy
```

---

## 🔐 Security Features

- **Firebase Authentication** - Secure user login
- **Role-Based Access Control** - Different permission levels
- **Encrypted Data Transmission** - SSL/TLS
- **Local Data Encryption** - Secure storage
- **Session Management** - Auto logout on inactivity
- **Two-Factor Authentication** - Optional 2FA

---

## 📲 Installation & Setup

### **Development Environment**
```bash
# Install Flutter SDK
# https://docs.flutter.dev/get-started/install

# Clone repository
git clone https://github.com/yourusername/SmartFarming-Lavender-AI.git
cd SmartFarming-Lavender-AI/mobile-app

# Install dependencies
flutter pub get

# Configure Firebase
# Add google-services.json (Android)
# Add GoogleService-Info.plist (iOS)

# Run the app
flutter run
```

### **Firebase Configuration**
```yaml
1. Create Firebase project
2. Enable Authentication (Email/Password)
3. Setup Realtime Database
4. Configure Cloud Messaging
5. Add SHA keys for Android
6. Download configuration files
```

---

## 📱 App Architecture
```
lib/
├── main.dart                    # App entry point
├── config/
│   ├── theme.dart              # App theme
│   ├── routes.dart             # Navigation routes
│   └── constants.dart          # App constants
├── models/
│   ├── user_model.dart         # User data model
│   ├── sensor_data_model.dart  # Sensor data model
│   ├── pest_detection_model.dart
│   └── alert_model.dart
├── services/
│   ├── auth_service.dart       # Authentication
│   ├── database_service.dart   # Firebase DB
│   ├── notification_service.dart
│   └── api_service.dart        # REST API calls
├── providers/
│   ├── auth_provider.dart      # Auth state
│   ├── sensor_provider.dart    # Sensor data state
│   └── theme_provider.dart     # Theme state
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── dashboard/
│   │   └── home_screen.dart
│   ├── components/
│   │   ├── soil_screen.dart
│   │   ├── climate_screen.dart
│   │   ├── pest_detection_screen.dart
│   │   └── lighting_screen.dart
│   ├── alerts/
│   │   └── alerts_screen.dart
│   ├── analytics/
│   │   └── reports_screen.dart
│   └── settings/
│       └── settings_screen.dart
└── widgets/
    ├── common/
    │   ├── custom_button.dart
    │   ├── custom_card.dart
    │   └── loading_indicator.dart
    ├── charts/
    │   ├── line_chart_widget.dart
    │   └── gauge_meter_widget.dart
    └── sensors/
        └── sensor_card_widget.dart
```

---

## 🎯 Key Integrations

### **ESP32-CAM Integration**
```dart
- WebSocket connection for live video stream
- HTTP requests for manual capture
- UDP commands for LED/buzzer control
- Real-time detection overlay
```

### **Firebase Integration**
```dart
- Realtime Database: StreamBuilder for live data
- Cloud Messaging: Push notifications
- Authentication: User management
- Storage: Image upload/download
```

### **API Integration**
```dart
- REST API for CRUD operations
- WebSocket for real-time updates
- MQTT for IoT device communication
```

---

## 📊 Performance Optimization

- **Lazy Loading** - Load data on demand
- **Image Caching** - Cache detection images locally
- **Pagination** - Load alerts/reports in batches
- **Background Services** - Fetch data in background
- **Local Storage** - Cache frequently accessed data
- **Optimized Build** - Reduce app size with tree shaking

---

## 🔮 Future Enhancements

- [ ] Offline mode with local database
- [ ] Multi-language support (Sinhala, Tamil)
- [ ] Voice commands integration
- [ ] AR visualization for field mapping
- [ ] Machine learning insights
- [ ] Social sharing features
- [ ] Weather forecast integration
- [ ] Community forum

---

## 📸 Screenshots

*(Add app screenshots here)*
```
[Dashboard] [Pest Detection] [Analytics] [Alerts]
```

---

## 🐛 Known Issues & Troubleshooting

### Common Issues:
1. **Camera stream not loading** - Check ESP32 IP configuration
2. **Notifications not working** - Verify FCM setup
3. **Data not syncing** - Check Firebase connection
4. **App crashes on startup** - Clear app cache

---

## 👥 Development Team

**Frontend Developer:** [Team Member Name]  
**UI/UX Designer:** [Team Member Name]  
**Backend Integration:** All Team Members

---

## 📄 Dependencies
```yaml
dependencies:
  flutter: sdk: flutter
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  firebase_database: ^10.4.0
  firebase_messaging: ^14.7.0
  provider: ^6.1.1
  fl_chart: ^0.66.0
  dio: ^5.4.0
  shared_preferences: ^2.2.2
  image_picker: ^1.0.7
  camera: ^0.10.5
  geolocator: ^11.0.0
  flutter_local_notifications: ^16.3.0
  web_socket_channel: ^2.4.0
  intl: ^0.19.0
```

---

<div align="center">

**Built with 💜 using Flutter**

*Bringing smart farming to your fingertips* 📱🌱

</div>
