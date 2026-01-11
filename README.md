# 🌿 Intelligent Climate Control - Frontend Application

## SmartFarming-Lavender-AI - Mobile & Web Frontend

A **Flutter-based Cross-Platform Application** for greenhouse climate monitoring and control, specifically designed to interface with the AI-powered Intelligent Climate Control System for lavender cultivation.

---

## 📋 Table of Contents

- [Component Overview](#component-overview)
- [System Architecture](#system-architecture)
- [Application Screens](#application-screens)
- [Features](#features)
- [UI/UX Design](#uiux-design)
- [API Integration](#api-integration)
- [Technologies Used](#technologies-used)
- [Project Structure](#project-structure)
- [Installation and Setup](#installation-and-setup)
- [Usage](#usage)
- [Contributors](#contributors)

---

## 🎯 Component Overview

The **Frontend Application** provides a user-friendly interface for monitoring and controlling the greenhouse climate system. This cross-platform Flutter application enables users to visualize real-time sensor data, control ventilation and humidity systems, and view AI-driven analytics reports.

### Key Objectives

| Objective | Description |
|-----------|-------------|
| **Real-time Monitoring** | Display live temperature, humidity, and soil conditions |
| **Climate Control** | Interface for managing fan speed and humidifier modes |
| **Analytics Visualization** | Charts and graphs for historical climate data |
| **Cross-Platform Support** | Works on Android, iOS, Web, Windows, macOS, and Linux |
| **Intuitive UI/UX** | Modern Material Design 3 interface with smooth animations |

### Supported Platforms

| Platform | Status | Description |
|----------|--------|-------------|
| **Android** | ✅ Supported | Native Android application |
| **iOS** | ✅ Supported | Native iOS application |
| **Web** | ✅ Supported | Progressive Web Application (PWA) |
| **Windows** | ✅ Supported | Native Windows desktop app |
| **macOS** | ✅ Supported | Native macOS desktop app |
| **Linux** | ✅ Supported | Native Linux desktop app |

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    FRONTEND APPLICATION ARCHITECTURE                     │
└─────────────────────────────────────────────────────────────────────────┘

                              ┌─────────────┐
                              │    USER     │
                              │  INTERFACE  │
                              └──────┬──────┘
                                     │
         ┌───────────────────────────┼───────────────────────────┐
         │                           │                           │
         ▼                           ▼                           ▼
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│  Login Screen   │       │   Dashboard     │       │  Climate Screen │
│  ┌───────────┐  │       │  ┌───────────┐  │       │  ┌───────────┐  │
│  │ Auth Flow │  │       │  │ Overview  │  │       │  │ Temp/Hum  │  │
│  │ UI        │  │       │  │ Cards     │  │       │  │ Controls  │  │
│  └───────────┘  │       │  └───────────┘  │       │  └───────────┘  │
└────────┬────────┘       └────────┬────────┘       └────────┬────────┘
         │                         │                         │
         └─────────────────────────┼─────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           SERVICES LAYER                                 │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ API Service                                                      │    │
│  │ ├── HTTP Requests to Flask Backend                              │    │
│  │ ├── Real-time Sensor Data Fetching                              │    │
│  │ ├── ML Prediction Requests                                      │    │
│  │ └── Analysis History Management                                 │    │
│  │                                                                  │    │
│  │ Diagnostic History Service                                      │    │
│  │ ├── Local Storage (SharedPreferences)                           │    │
│  │ ├── Health Score Tracking                                       │    │
│  │ └── Result Caching                                              │    │
│  └─────────────────────────────────────────────────────────────────┘    │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     │ HTTP/REST API
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          FLASK BACKEND API                               │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ • POST /predict - Climate control predictions                   │    │
│  │ • POST /api/analysis - Plant health analysis                    │    │
│  │ • GET /health - Connection health check                         │    │
│  │ • GET /api/analysis/history - Historical data                   │    │
│  └─────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📱 Application Screens

### Screen Navigation Flow

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        APPLICATION NAVIGATION FLOW                        │
└──────────────────────────────────────────────────────────────────────────┘

                            ┌─────────────────┐
                            │  Login Screen   │
                            │  ─────────────  │
                            │ • Email Input   │
                            │ • Password      │
                            │ • Social Login  │
                            └────────┬────────┘
                                     │
                                     ▼
                            ┌─────────────────┐
                            │   Dashboard     │
                            │  ─────────────  │
                            │ • Health Card   │
                            │ • Feature Cards │
                            │ • Quick Actions │
                            └────────┬────────┘
                                     │
         ┌───────────────────────────┼───────────────────────────┐
         │                           │                           │
         ▼                           ▼                           ▼
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│ Disease Detect  │       │ Climate Control │       │  Soil Health    │
│ ─────────────── │       │ ─────────────── │       │ ─────────────── │
│ • Image Capture │       │ • Temp Display  │       │ • Moisture      │
│ • AI Analysis   │       │ • Humidity      │       │ • Diagnostics   │
│ • Diagnosis     │       │ • Status Cards  │       │ • Analysis      │
└────────┬────────┘       └────────┬────────┘       └─────────────────┘
         │                         │
         ▼                         │
┌─────────────────┐                │
│  Diagnostic     │                │
│  Screen         │                │
│ ─────────────── │                │
│ • AI Results    │                │
│ • Action Plan   │                │
│ • Sensor Data   │                │
└─────────────────┘                │
                                   │
         ┌─────────────────────────┼─────────────────────────────┐
         │                         │                             │
         ▼                         ▼                             ▼
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│  Venting Mode   │       │  Humidity Mode  │       │   Analytics     │
│ ─────────────── │       │ ─────────────── │       │    Report       │
│ • Auto/Manual   │       │ • Auto/Manual   │       │ ─────────────── │
│ • Speed Control │       │ • Level Control │       │ • Charts        │
│ • Dial UI       │       │ • Dial UI       │       │ • PDF Export    │
│ • Metrics       │       │ • Metrics       │       │ • Statistics    │
└─────────────────┘       └─────────────────┘       └─────────────────┘
```

### Screen Descriptions

| Screen | File | Description |
|--------|------|-------------|
| **Login Screen** | `login_screen.dart` | User authentication with email/password and social login options |
| **Dashboard** | `dashboard_screen.dart` | Main overview with health status, feature cards, and quick actions |
| **Climate Screen** | `climate_screen.dart` | Climate control hub with temperature/humidity display and mode selection |
| **Venting Mode** | `venting_mode_screen.dart` | Fan speed control with circular dial, auto/manual modes, and charts |
| **Humidity Mode** | `humidity_mode_screen.dart` | Humidifier control with mode selection (Off/Low/Medium/High) |
| **Analytics Report** | `analytics_report_screen.dart` | Historical data visualization with PDF export functionality |
| **Diagnostic Screen** | `diagnostic_screen.dart` | AI-powered plant health analysis results and recommendations |

---

## ✨ Features

### Core Features

| Feature | Description |
|---------|-------------|
| **🌡️ Real-time Climate Monitoring** | Live temperature and humidity readings from IoT sensors |
| **🎛️ Fan Speed Control** | PWM-based fan speed adjustment (0-100%) with circular dial interface |
| **💧 Humidity Mode Control** | 4-level humidifier control (Off, Low, Medium, High) |
| **📊 Analytics Dashboard** | Historical data visualization with interactive charts |
| **🤖 AI-Powered Analysis** | ML-based plant health diagnostics and recommendations |
| **📄 PDF Report Export** | Generate and share analytics reports as PDF |
| **🔄 Auto/Manual Modes** | Toggle between AI-automated and manual control |
| **💾 Local Data Persistence** | Offline support with SharedPreferences storage |

### UI Components

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         WIDGET ARCHITECTURE                              │
└─────────────────────────────────────────────────────────────────────────┘

widgets/
├── dashboard/
│   ├── analysis_button.dart      → Start analysis action button
│   ├── health_wheel.dart         → Circular health score indicator
│   ├── plant_analysis_card.dart  → Plant health summary card
│   ├── quick_actions_row.dart    → Action buttons row
│   ├── quick_tips_card.dart      → AI tips display card
│   └── sensor_grid.dart          → Sensor data grid layout
│
└── shared/
    ├── connection_status.dart    → Backend connection indicator
    └── gradient_app_bar.dart     → Custom gradient app bar
```

---

## 🎨 UI/UX Design

### Color Palette

| Color | Hex Code | Usage |
|-------|----------|-------|
| **Primary Purple** | `#8B5CF6` | Primary actions, highlights |
| **Primary Green** | `#22C55E` | Success states, health indicators |
| **Primary Orange** | `#FF7A45` | Notifications, warnings |
| **Primary Blue** | `#3B82F6` | Information, links |
| **Primary Yellow** | `#FBBF24` | Alerts, lighting features |
| **Background** | `#F8F9FA` | App background |
| **Card Background** | `#FFFFFF` | Card surfaces |
| **Text Dark** | `#1F2937` | Primary text |
| **Text Grey** | `#6B7280` | Secondary text |

### Design System

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           DESIGN SYSTEM                                  │
└─────────────────────────────────────────────────────────────────────────┘

Typography:
├── Headings: Roboto Bold (20px)
├── Subheadings: Roboto SemiBold (16px)
├── Body: Roboto Regular (14px)
└── Captions: Roboto Regular (12px)

Components:
├── Cards: Rounded corners (16-24px), subtle shadows
├── Buttons: Gradient backgrounds, rounded (30px)
├── Dials: Circular progress with level indicators
├── Charts: Line graphs with gradient fills
└── Icons: Material Icons with custom colors

Spacing:
├── Screen Padding: 16px
├── Card Padding: 12-16px
├── Element Gap: 8-24px
└── Section Gap: 20-24px
```

### Circular Dial Control

```
                    ┌───────────────────┐
                    │   Circular Dial   │
                    │   Control UI      │
                    └───────────────────┘
                    
                         ╭─────────╮
                       ╱    75%    ╲
                      │   ┌─────┐   │
                      │   │     │   │
                      │   │ 🌀  │   │
                      │   │     │   │
                      │   └─────┘   │
                       ╲  Level 3  ╱
                         ╰─────────╯
                    
            ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐
            │  1  │ │  2  │ │  3  │ │  4  │
            │ Low │ │ Med │ │High │ │Max  │
            └─────┘ └─────┘ └─────┘ └─────┘
                         ▲
                    Selected Level
```

---

## 🔌 API Integration

### API Service Configuration

| Property | Value |
|----------|-------|
| **Base URL** | `http://localhost:5000` |
| **Content-Type** | `application/json` |
| **Timeout** | 60 seconds |

### Endpoints Used

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/health` | GET | Test backend connection |
| `/predict` | POST | Get climate control predictions |
| `/api/analysis` | POST | Analyze plant health with image |
| `/api/analysis/history` | GET | Retrieve analysis history |
| `/api/analysis/summary` | GET | Get quick summary for dashboard |

### Request/Response Flow

```
┌──────────────────────────────────────────────────────────────────────────┐
│ CLIMATE CONTROL PREDICTION REQUEST                                       │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Request (POST /predict):                                               │
│   {                                                                      │
│       "air_temp": 28.5,                                                  │
│       "humidity": 65.0,                                                  │
│       "soil_temp": 22.0,                                                 │
│       "target_temp": 25.0,                                               │
│       "target_humidity": 60.0,                                           │
│       "prev_fan_speed": 50.0,                                            │
│       "prev_humidifier_mode": 1                                          │
│   }                                                                      │
│                                                                          │
│   Response:                                                              │
│   {                                                                      │
│       "fan_speed": 75.5,                                                 │
│       "humidifier_mode": 2                                               │
│   }                                                                      │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│ PLANT ANALYSIS REQUEST                                                   │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Request (POST /api/analysis):                                          │
│   FormData:                                                              │
│   ├── image: [Image Blob]                                                │
│   └── sensorData: JSON encoded sensor readings                           │
│                                                                          │
│   Response:                                                              │
│   {                                                                      │
│       "dashboardSummary": {                                              │
│           "healthScore": 85.5,                                           │
│           ...                                                            │
│       },                                                                 │
│       "crossVerification": {                                             │
│           "matchPercentage": 92.0,                                       │
│           ...                                                            │
│       },                                                                 │
│       "intelligentDiagnosis": {...},                                     │
│       "visualAssessment": {...},                                         │
│       "recommendations": {...}                                           │
│   }                                                                      │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Technologies Used

### Software Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| **Flutter** | 3.x | Cross-platform UI framework |
| **Dart** | 3.10.4+ | Programming language |
| **Material Design 3** | Latest | UI design system |

### Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| **cupertino_icons** | ^1.0.8 | iOS-style icons |
| **http** | ^1.1.0 | HTTP client for API calls |
| **image_picker** | ^1.0.7 | Camera and gallery access |
| **shared_preferences** | ^2.0.15 | Local data persistence |
| **pdf** | ^3.11.0 | PDF document generation |
| **printing** | ^5.12.0 | PDF printing and sharing |

### Development Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| **flutter_test** | SDK | Widget testing |
| **flutter_lints** | ^6.0.0 | Code quality analysis |

---

## 📁 Project Structure

```
SmartFarming-Lavender_Research_Frontend/
│
├── README.md                           # This documentation file
├── pubspec.yaml                        # Flutter dependencies and configuration
├── analysis_options.yaml               # Dart analysis rules
│
├── lib/
│   ├── main.dart                       # Application entry point
│   │
│   ├── screens/
│   │   ├── login_screen.dart           # User authentication screen
│   │   ├── dashboard_screen.dart       # Main dashboard with overview
│   │   ├── climate_screen.dart         # Climate control hub
│   │   ├── venting_mode_screen.dart    # Fan speed control interface
│   │   ├── humidity_mode_screen.dart   # Humidifier mode control
│   │   ├── analytics_report_screen.dart # Analytics with PDF export
│   │   └── diagnostic_screen.dart      # AI diagnosis results
│   │
│   ├── services/
│   │   ├── api_service.dart            # Backend API communication
│   │   └── diagnostic_history.dart     # Local storage for diagnostics
│   │
│   └── widgets/
│       ├── dashboard/
│       │   ├── analysis_button.dart    # Analysis action button
│       │   ├── health_wheel.dart       # Circular health indicator
│       │   ├── plant_analysis_card.dart # Plant health card
│       │   ├── quick_actions_row.dart  # Quick action buttons
│       │   ├── quick_tips_card.dart    # AI tips card
│       │   └── sensor_grid.dart        # Sensor data grid
│       │
│       └── shared/
│           ├── connection_status.dart  # Connection status widget
│           └── gradient_app_bar.dart   # Custom app bar
│
├── assets/
│   └── images/
│       ├── lavender.png                # Lavender plant image
│       ├── lavender2.png               # Alternative lavender image
│       └── lvd4.png                    # Lavender icon
│
├── android/                            # Android platform files
├── ios/                                # iOS platform files
├── web/                                # Web platform files
├── windows/                            # Windows platform files
├── macos/                              # macOS platform files
├── linux/                              # Linux platform files
│
├── test/
│   └── widget_test.dart                # Widget unit tests
│
└── build/                              # Build output directory
```

### File Descriptions

| File | Lines | Description |
|------|-------|-------------|
| `main.dart` | ~25 | App entry point with MaterialApp configuration |
| `login_screen.dart` | ~535 | Authentication UI with social login |
| `dashboard_screen.dart` | ~805 | Main dashboard with feature cards |
| `climate_screen.dart` | ~1057 | Climate control hub interface |
| `venting_mode_screen.dart` | ~1030 | Fan control with circular dial |
| `humidity_mode_screen.dart` | ~1075 | Humidity control with mode selection |
| `analytics_report_screen.dart` | ~455 | Analytics visualization with PDF export |
| `diagnostic_screen.dart` | ~1241 | AI diagnosis results display |
| `api_service.dart` | ~396 | HTTP client for backend communication |
| `diagnostic_history.dart` | ~90 | Local storage service |

---

## ⚙️ Installation and Setup

### Prerequisites

- Flutter SDK 3.x installed
- Dart SDK 3.10.4 or higher
- Android Studio / VS Code with Flutter extensions
- Git

### Step 1: Clone the Repository

```bash
git clone https://github.com/your-repo/SmartFarming-Lavender_Research_Frontend.git
cd SmartFarming-Lavender_Research_Frontend
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Configure API Endpoint

Update the base URL in `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://YOUR_SERVER_IP:5000';
```

### Step 4: Run the Application

```bash
# Run on connected device/emulator
flutter run

# Run on specific platform
flutter run -d chrome      # Web
flutter run -d windows     # Windows
flutter run -d macos       # macOS
flutter run -d linux       # Linux
```

### Step 5: Build for Production

```bash
# Build APK for Android
flutter build apk --release

# Build for iOS
flutter build ios --release

# Build for Web
flutter build web --release

# Build for Windows
flutter build windows --release

# Build for macOS
flutter build macos --release

# Build for Linux
flutter build linux --release
```

---

## 🚀 Usage

### Starting the Application

1. **Ensure Backend is Running**
   - Start the Flask API server on port 5000
   - Verify connection at `http://localhost:5000/health`

2. **Launch the App**
   ```bash
   flutter run
   ```

3. **Login**
   - Enter credentials or use social login
   - Navigate to the Dashboard

4. **Monitor Climate**
   - View real-time temperature and humidity
   - Check system status cards

5. **Control Climate**
   - Navigate to Climate Screen
   - Select Venting Mode or Humidity Mode
   - Toggle between Auto/Manual control
   - Adjust settings using circular dial

6. **View Analytics**
   - Access Analytics Report screen
   - Filter by time period
   - Export reports as PDF

### Control Modes

| Mode | Description |
|------|-------------|
| **Auto Mode** | AI-controlled based on ML predictions |
| **Manual Mode** | User-controlled settings |

### Ventilation Levels

| Level | Fan Speed | Description |
|-------|-----------|-------------|
| 1 | 25% | Minimal airflow |
| 2 | 50% | Moderate airflow |
| 3 | 75% | High airflow |
| 4 | 100% | Maximum airflow |

### Humidity Modes

| Mode | Value | Description |
|------|-------|-------------|
| Off | 0 | Mist maker disabled |
| Low | 1 | Intermittent mist |
| Medium | 2 | Moderate mist output |
| High | 3 | Maximum mist output |

---

## 📸 Screenshots

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         APPLICATION SCREENS                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│   │             │  │             │  │             │  │             │    │
│   │   Login     │  │  Dashboard  │  │   Climate   │  │  Venting    │    │
│   │   Screen    │  │   Screen    │  │   Screen    │  │   Mode      │    │
│   │             │  │             │  │             │  │             │    │
│   └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘    │
│                                                                          │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                     │
│   │             │  │             │  │             │                     │
│   │  Humidity   │  │  Analytics  │  │ Diagnostic  │                     │
│   │   Mode      │  │   Report    │  │   Screen    │                     │
│   │             │  │             │  │             │                     │
│   └─────────────┘  └─────────────┘  └─────────────┘                     │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 👥 Contributors

| Name | Student ID | Role | Component |
|------|------------|------|-----------|
| Developer | IT22894588 | Frontend Developer | Climate Control Frontend |

---

## 📄 License

This project is part of the SmartFarming-Lavender-AI final-year research project.

---

## 🌿 Intelligent Climate Control Frontend - Beautiful UI for Smart Greenhouse Management 🌡️
