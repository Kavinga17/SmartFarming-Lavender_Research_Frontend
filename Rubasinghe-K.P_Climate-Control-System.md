# 🌿 Intelligent Climate Control - Frontend Component

## SmartFarming-Lavender-AI - Climate Control Module

A **Flutter-based Cross-Platform Application** for greenhouse climate monitoring and control, specifically designed to interface with the AI-powered Intelligent Climate Control System for lavender cultivation.

---

## 📋 Table of Contents

- [Component Overview](#component-overview)
- [System Architecture](#system-architecture)
- [Climate Screens](#climate-screens)
- [Features](#features)
- [UI/UX Design](#uiux-design)
- [API Integration](#api-integration)
- [Data Models](#data-models)
- [Firebase Integration](#firebase-integration)
- [Technologies Used](#technologies-used)
- [Project Structure](#project-structure)
- [Installation and Setup](#installation-and-setup)
- [Usage](#usage)
- [Contributors](#contributors)

---

## 🎯 Component Overview

The **Climate Control Frontend** provides a user-friendly interface for monitoring and controlling the greenhouse climate system. This cross-platform Flutter application enables users to visualize real-time sensor data (air temperature, humidity, soil temperature), control ventilation fans and humidifiers, and review historical climate analytics with PDF export.

### Key Objectives

| Objective | Description |
|-----------|-------------|
| **Real-time Sensor Monitoring** | Display live air temperature, humidity, and soil temperature from the ESP32 via Flask backend |
| **Ventilation Control** | Interface for managing fan mode (Off / Manual / Auto) and speed (1–100%) |
| **Humidifier Control** | Interface for managing mist-maker mode (Off / Manual / Auto) and level (Off / Low / Medium / High) |
| **Analytics Visualization** | Charts and statistics for historical climate data stored in Firestore |
| **PDF Report Export** | Generate and share analytics reports as PDF |
| **AI-Driven Auto Mode** | Sends sensor readings to Flask ML model; displays predicted fan speed and humidifier level |
| **Intuitive UI/UX** | Modern Material Design 3 interface with circular dial controls and animated charts |

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
│               CLIMATE CONTROL COMPONENT ARCHITECTURE                     │
└─────────────────────────────────────────────────────────────────────────┘

                              ┌─────────────┐
                              │    USER     │
                              │  INTERFACE  │
                              └──────┬──────┘
                                     │
                                     ▼
                         ┌───────────────────────┐
                         │  Climate Main Screen  │
                         │  climate_main_screen  │
                         │  ─────────────────    │
                         │  • Air Temp Display   │
                         │  • Humidity Display   │
                         │  • Soil Temp Display  │
                         │  • Target Sliders     │
                         │  • AI Prediction Card │
                         │  • Activity Log       │
                         │  • Chart Previews     │
                         └──────────┬────────────┘
                                    │
         ┌──────────────────────────┼──────────────────────────┐
         │                          │                          │
         ▼                          ▼                          ▼
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│  Venting Mode   │       │  Humidity Mode  │       │  Analytics      │
│ ─────────────── │       │ ─────────────── │       │  Report         │
│ • Off/Manual/   │       │ • Off/Manual/   │       │ ─────────────── │
│   Auto Modes    │       │   Auto Modes    │       │ • Temp Chart    │
│ • Circular Dial │       │ • Level Picker  │       │ • Humidity Chart│
│ • Fan Speed     │       │ • Humidifier    │       │ • Fan Chart     │
│   1-100%        │       │   Level 0-3     │       │ • Stats Table   │
│ • Chart History │       │ • Chart History │       │ • PDF Export    │
└─────────────────┘       └─────────────────┘       └─────────────────┘

                                    │
         ┌──────────────────────────┼──────────────────────────┐
         │                          │                          │
         ▼                          ▼                          ▼
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│ ClimateApiSvc   │       │ ClimateDataSvc  │       │ SensorDataSvc   │
│ ─────────────── │       │ ─────────────── │       │ ─────────────── │
│ Flask HTTP API  │       │ Firestore CRUD  │       │ Sensor Polling  │
│ Predictions     │       │ Readings Store  │       │ Stream (5s)     │
│ Fan/Hum Control │       │ Stats / Charts  │       │ SensorReading   │
└─────────────────┘       └─────────────────┘       └─────────────────┘
         │                          │
         │  HTTP/REST               │  Firestore SDK
         ▼                          ▼
┌─────────────────┐       ┌─────────────────┐
│  Flask Backend  │       │  Firebase /     │
│  (ESP32 Bridge) │       │  Firestore DB   │
│ ─────────────── │       │ ─────────────── │
│  /health        │       │climate_readings │
│  /sensors       │       │ collection      │
│  /predict       │       │                 │
│  /fan/...       │       │                 │
│  /humidifier/.. │       │                 │
└─────────────────┘       └─────────────────┘
```

---

## 📱 Climate Screens

### Screen Navigation Flow

```
┌──────────────────────────────────────────────────────────────────────────┐
│                   CLIMATE MODULE NAVIGATION FLOW                          │
└──────────────────────────────────────────────────────────────────────────┘

                         ┌─────────────────────────┐
                         │  Dashboard (shared)     │
                         │  Climate card shown;    │
                         │  reads ClimateDataSvc   │
                         └────────────┬────────────┘
                                      │  Navigate to
                                      ▼
                         ┌─────────────────────────┐
                         │   Climate Main Screen   │
                         │  climate_main_screen    │
                         │  ──────────────────     │
                         │ • Live sensor readings  │
                         │ • Target temp/humidity  │
                         │   adjustment sliders    │
                         │ • AI prediction display │
                         │ • Fan speed + Hum mode  │
                         │   status cards          │
                         │ • Chart previews        │
                         │ • Recent activity log   │
                         │ • Server connection     │
                         │   status indicator      │
                         └────────────┬────────────┘
                                      │
            ┌─────────────────────────┼─────────────────────────┐
            │                         │                         │
            ▼                         ▼                         ▼
  ┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
  │  Venting Mode    │     │  Humidity Mode   │     │  Analytics       │
  │  Screen          │     │  Screen          │     │  Report Screen   │
  │  ─────────────── │     │  ─────────────── │     │  ─────────────── │
  │ • Off / Manual / │     │ • Off / Manual / │     │ • Today / 7-day  │
  │   Auto modes     │     │   Auto modes     │     │   30-day filters │
  │ • Circular fan   │     │ • Level picker   │     │ • Air temp chart │
  │   speed dial     │     │   (Off/Low/Med/  │     │ • Humidity chart │
  │ • Manual: on/off │     │    High)         │     │ • Fan speed chart│
  │   + speed slider │     │ • Manual: direct │     │ • Summary stats  │
  │ • Ventilation    │     │   level select   │     │   table          │
  │   history chart  │     │ • Humidity       │     │ • PDF export     │
  │ • Metric picker  │     │   history chart  │     │   (print/share)  │
  └──────────────────┘     └──────────────────┘     └──────────────────┘
```

### Screen Descriptions

| Screen | File | Description |
|--------|------|-------------|
| **Climate Main** | `climate/climate_main_screen.dart` | Hub screen showing live sensor readings, AI prediction status cards, target sliders, chart previews, and activity log |
| **Venting Mode** | `climate/climate_venting_mode_screen.dart` | Fan control with Off / Manual / Auto mode selector, circular speed dial, manual on/off + speed slider, and Firestore-backed history chart |
| **Humidity Mode** | `climate/climate_humidity_mode_screen.dart` | Humidifier control with Off / Manual / Auto mode selector, level picker (Off/Low/Medium/High), and Firestore-backed humidity history chart |
| **Analytics Report** | `climate/climate_analytics_report_screen.dart` | Historical data visualization (temperature, humidity, fan speed) across Today / Last 7 Days / Last 30 Days with computed statistics and PDF export via `printing` package |

---

## ✨ Features

### Climate Control Features

| Feature | Description |
|---------|-------------|
| **Live Sensor Display** | Polls `GET /sensors` every 5 seconds via `SensorDataService` to show live air temp, humidity, and soil temp |
| **AI Prediction** | Sends sensor + target values to `POST /predict`; displays AI-predicted fan speed (0–100%) and humidifier mode (Off/Low/Medium/High) |
| **Fan Mode Control** | Calls `POST /fan/mode` with `"off"`, `"manual"`, or `"auto"`; reads current state from `GET /fan/state` |
| **Manual Fan Speed** | In manual mode, sends on/off + speed (1–100) to `POST /fan/manual` |
| **Humidifier Mode Control** | Calls `POST /humidifier/mode` with `"off"`, `"manual"`, or `"auto"` |
| **Manual Humidifier Level** | In manual mode, sends level (0–3) to `POST /humidifier/manual` |
| **Target Customisation** | User adjusts target temperature (default 24.0 °C) and target humidity (default 65.0%) which are fed into the AI prediction request |
| **Firestore Persistence** | Every AI prediction is saved to `climate_readings` Firestore collection via `ClimateDataService.saveReading()` |
| **Analytics Charts** | Line charts rendered with `fl_chart` for temperature, humidity, and fan speed trends |
| **PDF Report Export** | Generates a PDF from the analytics chart widget using `pdf` + `printing` packages for print/share |
| **Activity Log** | Recent prediction events (timestamp, fan speed, humidifier mode) displayed as a scrollable activity list |
| **Server Status Badge** | Real-time indicator showing whether the Flask backend is reachable |
| **Automatic Prediction Refresh** | `Timer.periodic` triggers a new prediction + Firestore save at a configured interval on the Climate Main screen |

### Control Modes

| Mode | Fan Behaviour | Humidifier Behaviour |
|------|--------------|----------------------|
| **Auto** | AI-controlled — Flask ML model predicts speed | AI-controlled — Flask ML model predicts level |
| **Manual** | User sets on/off and exact speed (1–100%) | User selects level (Off / Low / Medium / High) |
| **Off** | Fan fully disabled | Humidifier fully disabled |

---

## 🎨 UI/UX Design

### Color Palette

| Color | Hex Code | Usage |
|-------|----------|-------|
| **Primary Purple** | `#8B5CF6` | Primary actions, dial accents, app bar |
| **Primary Green** | `#22C55E` | Success states, connected indicators |
| **Primary Blue** | `#3B82F6` | Information cards, chart lines |
| **Primary Orange** | `#FF7A45` | Warning states, manual mode indicator |
| **Background** | `#F8F9FA` | Screen background |
| **Card Background** | `#FFFFFF` | Card surfaces |
| **Text Dark** | `#1F2937` | Primary text |
| **Text Grey** | `#6B7280` | Secondary / label text |

### Design System

```
Typography:
├── Screen Titles:   Roboto Bold    20 px
├── Card Headers:    Roboto SemiBold 16 px
├── Body / Labels:   Roboto Regular 14 px
└── Captions:        Roboto Regular 12 px

Cards:
├── Border Radius: 16–24 px
├── Elevation: subtle shadow (BoxShadow)
└── Padding: 12–16 px

Controls:
├── Mode Selector: segmented icon buttons (Off / Manual / Auto)
├── Fan Speed Dial: custom circular-arc painter (0–100%)
├── Level Picker: row of labelled option buttons
└── Sliders: target temp and humidity adjustment

Charts (fl_chart):
├── LineChart with gradient fill below the line
├── Spot data from Firestore downsample (12 buckets)
└── Metric filter buttons: Today / Last 7 Days / Last Month

App Bar:
└── Custom gradient app bar (purple gradient)
```

### Circular Dial Control (Venting Mode)

```
                         ╭─────────────╮
                       ╱    Fan Speed   ╲
                      │    ┌─────────┐   │
                      │    │  75%    │   │
                      │    │  ████   │   │
                      │    │  Level3 │   │
                      │    └─────────┘   │
                       ╲               ╱
                         ╰─────────────╯

                   Arc fills clockwise with fan speed %
                   Colour: primaryPurple (#8B5CF6)
```

### Humidifier Level Picker (Humidity Mode)

```
  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐
  │  Off │  │ Low  │  │ Med  │  │ High │
  │  0   │  │  1   │  │  2   │  │  3   │
  └──────┘  └──────┘  └──────┘  └──────┘
                ▲
          Selected option highlighted with primaryPurple border
```

---

## 🔌 API Integration

### ClimateApiService — Flask Backend Communication

| Property | Value |
|----------|-------|
| **Base URL** | `http://192.168.0.100:5000` (configurable via `ClimateApiService.baseUrl`) |
| **Content-Type** | `application/json` |
| **Default Timeout** | 5–10 seconds per endpoint |

### Endpoints Used

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/health` | GET | Verify Flask server is running and ML models are loaded |
| `/` | GET | Fetch API metadata / version info |
| `/sensors` | GET | Retrieve latest sensor snapshot stored by ESP32 via `/predict` |
| `/predict` | POST | Submit sensor + target values; receive AI-predicted fan speed and humidifier mode |
| `/fan/mode` | POST | Set fan operating mode: `"off"`, `"manual"`, or `"auto"` |
| `/fan/manual` | POST | Set manual fan state — on/off flag and speed (1–100) |
| `/fan/state` | GET | Read current fan mode, manual_on flag, and manual_speed |
| `/humidifier/mode` | POST | Set humidifier operating mode: `"off"`, `"manual"`, or `"auto"` |
| `/humidifier/manual` | POST | Set manual humidifier level (0=Off, 1=Low, 2=Medium, 3=High) |
| `/humidifier/state` | GET | Read current humidifier mode and manual_level |

### Request / Response Flows

```
┌──────────────────────────────────────────────────────────────────────────┐
│ SENSOR FETCH  →  GET /sensors                                            │
├──────────────────────────────────────────────────────────────────────────┤
│  Response:                                                               │
│  {                                                                       │
│      "air_temp":   28.5,                                                 │
│      "humidity":   65.0,                                                 │
│      "soil_temp":  22.0                                                  │
│  }                                                                       │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│ AI PREDICTION  →  POST /predict                                          │
├──────────────────────────────────────────────────────────────────────────┤
│  Request body:                                                           │
│  {                                                                       │
│      "air_temp":              28.5,                                      │
│      "humidity":              65.0,                                      │
│      "soil_temp":             22.0,                                      │
│      "target_temp":           24.0,                                      │
│      "target_humidity":       65.0,                                      │
│      "prev_fan_speed":        50.0,                                      │
│      "prev_humidifier_mode":  1                                          │
│  }                                                                       │
│                                                                          │
│  Response:                                                               │
│  {                                                                       │
│      "fan_speed":                  75.5,                                 │
│      "effective_fan_speed":        75.5,                                 │
│      "fan_mode":                   "auto",                               │
│      "humidifier_mode":            2,                                    │
│      "effective_humidifier_level": 2,                                    │
│      "humidifier_control_mode":    "auto",                               │
│      "air_temp":                   28.5,                                 │
│      "humidity":                   65.0,                                 │
│      "soil_temp":                  22.0                                  │
│  }                                                                       │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│ FAN CONTROL  →  POST /fan/mode   |   POST /fan/manual                   │
├──────────────────────────────────────────────────────────────────────────┤
│  POST /fan/mode body:       { "mode": "auto" }                           │
│  POST /fan/manual body:     { "on": true, "speed": 75 }                 │
│  GET  /fan/state response:  { "mode": "manual",                          │
│                               "manual_on": true,                         │
│                               "manual_speed": 75 }                       │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│ HUMIDIFIER CONTROL  →  POST /humidifier/mode  |  POST /humidifier/manual │
├──────────────────────────────────────────────────────────────────────────┤
│  POST /humidifier/mode   body:     { "mode": "manual" }                  │
│  POST /humidifier/manual body:     { "level": 2 }                        │
│  GET  /humidifier/state  response: { "mode": "manual",                   │
│                                      "manual_level": 2 }                 │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 📦 Data Models

All models are defined within the climate service files.

### ClimatePrediction (`climate_api_service.dart`)

| Field | Type | Description |
|-------|------|-------------|
| `fanSpeed` | `double` | AI-predicted fan speed (0–100) |
| `effectiveFanSpeed` | `double` | Actual fan speed sent to Arduino (respects mode) |
| `fanMode` | `String` | Current fan mode: `"off"` / `"manual"` / `"auto"` |
| `humidifierMode` | `int` | AI-predicted humidifier level (0–3) |
| `effectiveHumidifierLevel` | `int` | Actual humidifier level sent to Arduino (respects mode) |
| `humidifierControlMode` | `String` | Current humidifier mode: `"off"` / `"manual"` / `"auto"` |
| `airTemp` | `double` | Greenhouse air temperature (°C) |
| `humidity` | `double` | Relative humidity (%) |
| `soilTemp` | `double` | Soil temperature (°C) |
| `fanLevel` *(computed)* | `int` | Fan level 1–4 derived from `fanSpeed` |
| `humidifierLabel` *(computed)* | `String` | Effective label: Off / Low / Medium / High |

### FanState (`climate_api_service.dart`)

| Field | Type | Description |
|-------|------|-------------|
| `mode` | `String` | `"off"` / `"manual"` / `"auto"` |
| `manualOn` | `bool` | Whether fan is on in manual mode |
| `manualSpeed` | `int` | Manual fan speed (0–100) |

### HumidifierState (`climate_api_service.dart`)

| Field | Type | Description |
|-------|------|-------------|
| `mode` | `String` | `"off"` / `"manual"` / `"auto"` |
| `manualLevel` | `int` | Manual humidifier level (0–3) |

### SensorReading (`climate_sensor_data_service.dart`)

| Field | Type | Description |
|-------|------|-------------|
| `airTemp` | `double` | Greenhouse air temperature (°C) |
| `humidity` | `double` | Relative humidity (%) |
| `soilTemp` | `double` | Soil temperature (°C) |
| `timestamp` | `DateTime?` | Time reading was fetched |
| `hasData` *(computed)* | `bool` | True when at least one value is non-zero |

### ClimateReading (`climate_data_service.dart`) — Firestore-parsed

| Field | Type | Description |
|-------|------|-------------|
| `airTemp` | `double` | Air temperature (°C) |
| `humidity` | `double` | Humidity (%) |
| `soilTemp` | `double` | Soil temperature (°C) |
| `fanSpeed` | `double` | Effective fan speed (0–100) |
| `fanMode` | `String` | Fan mode string |
| `humidifierMode` | `int` | AI-predicted humidifier level (0–3) |
| `effectiveHumidifierLevel` | `int` | Actual humidifier level applied |
| `humidifierControlMode` | `String` | Humidifier control mode string |
| `timestamp` | `DateTime?` | Firestore server timestamp converted to DateTime |

### ClimateStats (`climate_data_service.dart`) — Aggregated Analytics

| Field | Type | Description |
|-------|------|-------------|
| `avgTemp` | `double` | Average air temperature over period |
| `avgHumidity` | `double` | Average humidity over period |
| `avgSoilTemp` | `double` | Average soil temperature over period |
| `avgFanSpeed` | `double` | Average fan speed over period |
| `minTemp` / `maxTemp` | `double` | Temperature range |
| `minHumidity` / `maxHumidity` | `double` | Humidity range |
| `minFanSpeed` / `maxFanSpeed` | `double` | Fan speed range |
| `totalReadings` | `int` | Number of readings in the period |

---

## 🔥 Firebase Integration

### Firestore — `climate_readings` Collection

Every successful AI prediction is persisted to Firestore by `ClimateDataService.saveReading()`.

**Document structure:**

```
climate_readings/{docId}
├── air_temp                   (double)  – Greenhouse air temperature °C
├── humidity                   (double)  – Relative humidity %
├── soil_temp                  (double)  – Soil temperature °C
├── fan_speed                  (double)  – AI-predicted fan speed 0–100
├── effective_fan_speed        (double)  – Actual speed applied to Arduino
├── fan_mode                   (String)  – "off" / "manual" / "auto"
├── fan_level                  (int)     – Derived fan level 1–4
├── humidifier_mode            (int)     – AI-predicted mode 0–3
├── effective_humidifier_level (int)     – Actual humidifier level applied
├── humidifier_control_mode    (String)  – "off" / "manual" / "auto"
├── humidifier_label           (String)  – "Off" / "Low" / "Medium" / "High"
├── target_temp                (double)  – User-set target temperature
├── target_humidity            (double)  – User-set target humidity
├── user_id                    (String)  – Firebase Auth UID
├── timestamp                  (Timestamp) – Server-side write time
└── source                     (String)  – "api_prediction"
```

### Firestore Query Patterns

| Operation | Method | Details |
|-----------|--------|---------|
| Save reading | `saveReading()` | `collection.add(doc)` |
| Latest reading | `getLatestReading()` | `orderBy timestamp desc, limit 1` |
| Stream recent | `streamReadings(limit)` | Real-time snapshot listener |
| Period fetch | `getReadingsForPeriod(period)` | Client-side date filter on `getRecentReadings(limit:500)` |
| Date range | `getReadingsByDateRange(from, to)` | Firestore range query with composite index |
| Prune old | `pruneOldReadings(keep:500)` | Batch delete docs beyond keep count |

### Firestore Composite Index Required

An index on `(user_id ASC, timestamp DESC)` in the `climate_readings` collection is needed for the primary query. The service includes fallback query strategies if the index is unavailable.

### Firebase Auth

`ClimateDataService` uses `FirebaseAuth.instance.currentUser?.uid` to scope all Firestore queries to the authenticated user.

---

## 🛠️ Technologies Used

### Core Framework

| Technology | Version | Purpose |
|------------|---------|---------|
| **Flutter** | 3.x | Cross-platform UI framework |
| **Dart** | ≥3.10.4 | Programming language |
| **Material Design 3** | Latest | UI design system |

### Dependencies Used by Climate Component

| Package | Version | Purpose |
|---------|---------|---------|
| **http** | ^1.1.0 | HTTP client — Flask API calls in `ClimateApiService` |
| **fl_chart** | ^0.66.0 | Line charts for temperature, humidity, fan speed trends |
| **pdf** | ^3.11.0 | PDF document generation for analytics report |
| **printing** | ^5.12.0 | PDF printing and sharing |
| **intl** | ^0.19.0 | Date/time formatting in charts and activity log |
| **firebase_core** | ^3.8.0 | Firebase SDK initialisation |
| **firebase_auth** | ^5.3.3 | User authentication (UID scoping in Firestore queries) |
| **cloud_firestore** | ^5.5.0 | Persist and query `climate_readings` collection |

---

## 📁 Project Structure (Climate Component)

```
SmartFarming-Lavender_Research_Frontend/
│
├── lib/
│   ├── screens/
│   │   └── climate/
│   │       ├── climate_main_screen.dart          # Climate hub – live readings, predictions, activity log
│   │       ├── climate_venting_mode_screen.dart  # Fan control – Off/Manual/Auto, circular dial
│   │       ├── climate_humidity_mode_screen.dart # Humidifier control – Off/Manual/Auto, level picker
│   │       └── climate_analytics_report_screen.dart # Charts + stats + PDF export
│   │
│   └── services/
│       ├── climate_api_service.dart              # Flask HTTP API – predict, fan, humidifier endpoints
│       ├── climate_data_service.dart             # Firestore CRUD – save, query, stats, downsample
│       └── climate_sensor_data_service.dart      # Sensor polling – 5-second broadcast stream
│
├── pubspec.yaml                                  # Dependencies (fl_chart, http, pdf, printing, Firebase)
└── android/app/google-services.json             # Firebase configuration
```

### File Descriptions

| File | Description |
|------|-------------|
| `climate_main_screen.dart` | Stateful widget — initialises sensor stream, timer-based prediction refresh, loads Firestore chart data, displays status cards, target sliders, activity log, chart previews |
| `climate_venting_mode_screen.dart` | Fan controller — receives initial sensor state from climate main screen; manages fan mode API calls, manual speed control, and Firestore-backed ventilation history chart |
| `climate_humidity_mode_screen.dart` | Humidifier controller — same pattern as venting mode; manages humidifier mode API calls, manual level selection, and Firestore-backed humidity history chart |
| `climate_analytics_report_screen.dart` | Reads Firestore via `getReadingsForPeriod()`, downsamples to 12 chart points, renders `fl_chart` `LineChart` widgets for temp/humidity/fan, builds PDF via `pdf` package |
| `climate_api_service.dart` | Static service — all Flask REST calls; defines `ClimatePrediction`, `FanState`, `HumidifierState` models; utility converters (`fanSpeedToLevel`, `humidifierModeLabel`) |
| `climate_data_service.dart` | Static Firestore service — `saveReading`, `getLatestReading`, `streamReadings`, `getRecentReadings`, `getReadingsForPeriod`, `computeStats`, `downsample`; defines `ClimateReading`, `ClimateStats` |
| `climate_sensor_data_service.dart` | `SensorDataService` — polls `GET /sensors` every 5 seconds using `Timer.periodic`; exposes broadcast stream; defines `SensorReading` |

---

## ⚙️ Installation and Setup

### Prerequisites

- Flutter SDK 3.x installed
- Dart SDK ≥ 3.10.4
- Android Studio or VS Code with Flutter extension
- Firebase project with Firestore and Auth enabled
- Flask Climate Control backend running on local network

### Step 1: Clone the Repository

```bash
git clone https://github.com/your-repo/SmartFarming-Lavender_Research_Frontend.git
cd SmartFarming-Lavender_Research_Frontend
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Configure Flask API Endpoint

Update the base URL in `lib/services/climate_api_service.dart`:

```dart
// Point to your Flask server's IP address and port
static String baseUrl = 'http://192.168.0.100:5000';
```

### Step 4: Configure Firebase

Ensure `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` are present and configured for your Firebase project. The `climate_readings` Firestore collection is created automatically on first write.

### Step 5: Create Firestore Composite Index

In the Firebase Console, create a composite index for the `climate_readings` collection:

| Collection | Fields | Order |
|------------|--------|-------|
| `climate_readings` | `user_id` ASC, `timestamp` DESC | — |

### Step 6: Run the Application

```bash
# Run on connected device or emulator
flutter run

# Run on specific platform
flutter run -d chrome      # Web
flutter run -d windows     # Windows
```

### Step 7: Build for Production

```bash
flutter build apk --release       # Android
flutter build ios --release       # iOS
flutter build web --release       # Web
flutter build windows --release   # Windows
```

---

## 🚀 Usage

### Climate Control Workflow

1. **Ensure Flask Backend is Running**
   - Start the Flask Climate Control API server
   - Verify at `http://<server-ip>:5000/health` — response should include `"models_loaded": true`

2. **Launch the App and Navigate to Climate**
   - Login → Dashboard → Climate Control card

3. **Monitor Live Sensor Data**
   - Climate Main Screen auto-polls `/sensors` every 5 seconds
   - Displays current air temp, humidity, and soil temp

4. **Adjust Targets (optional)**
   - Use sliders on the Climate Main Screen to set target temperature (default 24.0 °C) and target humidity (default 65.0%)

5. **View AI Predictions**
   - Periodic timer triggers `POST /predict` with live sensor + target values
   - Result displays predicted fan speed and humidifier mode on status cards
   - Each prediction is saved to Firestore `climate_readings`

6. **Control Ventilation**
   - Tap **Venting Mode** on the Climate Main Screen
   - Select **Auto** (AI-controlled), **Manual** (set own speed), or **Off**
   - In Manual mode: toggle fan on/off and set speed with slider

7. **Control Humidity**
   - Tap **Humidity Mode** on the Climate Main Screen
   - Select **Auto**, **Manual**, or **Off**
   - In Manual mode: choose Off / Low / Medium / High level

8. **View Analytics**
   - Tap **Analytics Report** on the Climate Main Screen
   - Select time period filter: Today / Last 7 Days / Last Month
   - Review temperature, humidity, and fan speed charts and statistical summary
   - Tap **Export PDF** to generate and share a printable report

### Ventilation Levels

| Level | Approx Fan Speed | Description |
|-------|-----------------|-------------|
| 1 | 0–25% | Minimal airflow |
| 2 | 26–50% | Moderate airflow |
| 3 | 51–75% | High airflow |
| 4 | 76–100% | Maximum airflow |

### Humidifier Modes

| Mode | Value | Description |
|------|-------|-------------|
| Off | 0 | Mist maker fully disabled |
| Low | 1 | Intermittent mist output |
| Medium | 2 | Moderate mist output |
| High | 3 | Maximum continuous mist output |

---

## 👥 Contributors

| Name | Student ID | Role | Component |
|------|------------|------|-----------|
| K.P. Rubasinghe | IT22894588 | Frontend Developer | Climate Control Frontend |

---

## 📄 License

This project is part of the SmartFarming-Lavender-AI final-year research project.

---

## 🌿 Intelligent Climate Control Frontend — Real-time Greenhouse Monitoring & AI-Driven Control 🌡️
