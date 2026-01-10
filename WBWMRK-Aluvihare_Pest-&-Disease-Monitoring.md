---

## 🖥️ User Interface (UI) Design

<div align="center">

### 🐛 Pest & Disease Monitoring UI  
**Component:** Pest & Disease Detection & Real-time Monitoring System  
**Author:** WBWMRK Aluvihare (IT22304506)  
**Project:** SmartFarming-Lavender-AI 🌱💜

</div>

---

### 🎯 UI Overview

The Pest & Disease Monitoring System features a **real-time, interactive desktop-based user interface** developed using **Python and OpenCV**.  
The UI enables continuous visual monitoring of lavender plants, clearly highlighting pests and diseases while allowing instant user interaction.

The interface is designed to be **simple, responsive, and farmer-friendly**, ensuring quick decision-making with minimal technical knowledge.

---

### 🎥 Live Monitoring Interface

- Displays **real-time video stream** from the ESP32-CAM (~10 FPS)
- Visual **bounding boxes** drawn on detected objects:
  - 🟥 **Red** – Lavender Disease  
  - 🟩 **Green** – Healthy Lavender Plant  
  - 🟨 **Yellow** – Insect / Pest
- Each detection includes:
  - Class label  
  - Confidence score
- Real-time **FPS counter** displayed on the screen

---

### 🧠 Visual Detection Feedback

- Bounding boxes update dynamically for every frame
- Uses a **10-frame stability buffer** to avoid false detections
- Clear color coding allows instant identification of threats
- Smooth rendering ensures real-time responsiveness

---

### 🎮 Interactive UI Controls

The UI allows real-time keyboard interaction without restarting the system:

| Key | Function | Description |
|:---:|---------|-------------|
| `Q` | Exit | Close the application safely |
| `S` | Screenshot | Save current video frame |
| `L` | LED Toggle | Manually switch alert LED |
| `T` | Test Alert | Test LED & buzzer connection |
| `D` | Debug Mode | Show detailed detection logs |
| `+` | Increase Threshold | Reduce false positives |
| `-` | Decrease Threshold | Increase detection sensitivity |

---

### 🖼️ Static Image Detection UI

- Displays annotated results for single images
- Shows:
  - Bounding boxes
  - Detection class labels
  - Confidence values
- Interactive image window
- Press **`Q`** to close the display

---

### 🔔 Alert Visualization in UI

- When pests are detected:
  - Insect bounding boxes are clearly highlighted
  - ESP32 activates **LED flashing** and **buzzer siren**
- UI remains active and responsive during alerts
- Alerts automatically stop when no detection is present

---

### 🎨 UI Design Objectives

- ✔ Simple and clutter-free layout  
- ✔ Easy-to-understand color indicators  
- ✔ Real-time visual feedback  
- ✔ Minimal user learning curve  
- ✔ Suitable for field and laboratory environments  

---

<div align="center">

**Designed & Developed by WBWMRK Aluvihare**  
*Pest & Disease Monitoring UI – SmartFarming-Lavender-AI*

</div>

---

