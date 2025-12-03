# BatSignal - CS4091 Capstone II Project
A LoRa and BLE-based system for safety and proximity awareness in cave exploration.

**BatSignal** is a LoRa-based proximity and communication system designed to help keep a team of spelunkers safe underground. It uses short-range wireless communication and proximity detection via LoRa (Long Range) radios and Bluetooth Low Energy (BLE).

Three LoRa nodes communicate with each other to measure RSSI (signal strength), which is used to estimate relative proximity between team members. <br>
With built-in alert systems and emergency button functionality, this project enhances team safety by warning users when a memebr is out of range or when an emergency signal is triggered.

A companion iOS app connects via BLE to one LoRa node and displays real-time proximity data visually.

## 2.0 Features
1. LoRa Communication between mutliple devices
2. Low-Energy Bluetooth connection to iOS app
3. Real-time RSSI visualization
4. Alert features using LoRa button input
5. Alert and LED signaling based on proximity threshold

## 3.0 - Project Structure
```
cs4091-capstone-project/ 
├── BatSignal_App/                  # iOS Swift app for LoRa BLE messages 
│   ├── LoRaApp/                    # Xcode project folder 
│   ├── LoRaApp.xcodeproj 
│   ├── LoRaAppTests/               # Unit Tests 
│   ├── LoRaAppUITests/             # UI tests 
├── lora-nodes/                     # Arduino/LoRa node code <br>
│   ├── lora-nodes.ino              # Shared logic between LoRa nodes (BLE setup, function to send data over BLE)
├── lora-node-master/               # Logic for LoRa-node-master, unquie node_id, calc. RSSI
│   ├── lora-node-1.ino              
├── lora-node-client1/              # Logic for LoRa-node-client1
│   ├── lora-node-client1.ino
├── lora-node-client2/              # Logic for LoRa-node-client2    
│   ├── lora-node-client2.ino             
├── lora-recv/                      # LoRa receiver code (test code) 
│   └── lora-recv.ino 
├── lora/                           # LoRa sender code (test code) 
│   └── lora.ino   
└── README.md                       # Top-level project README 
```

## 4.0 - IDE Setup
Install Arduino IDE from https://www.arduino.cc/en/software/ 
On the left panel, find and click on 'Boards Manager' and search for esp32. Click install on esp32 by Espressif Systems.
Click on the 'Select Board' Dropdown and select 'Esp32 Dev Module' 
Navigate to File < Preferences and paste 'https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_dev_index.json' into the 'Additional Boards Manager URLs' field

### 4.1 - Required Dependencies
- Adafruit SSD1306 by Adafruit (Version 2.5.15)
- Adafruit GFX Library by Adafruit (Version 1.12.4)
- Adafruit BusIO by Adafruit (Version 1.17.4)
- LoRa by Sandeep Mistry (Version 0.8.0)
- NimBLE-Arduino by h2zero (Version 2.3.6)

## 5.0 - Mobile App
### Bluetooth Communication
The app implements BLE (Bluetooth Low Energy),a Bluetooth protocol optimized for low-power communication. BLE is a lightweight, energy-efficient, and compatible with iOS devices. BLE allows us to receive real-time messages or signal strength (RSSI) from nearby LoRa nodes.

### App Setup
We implemented the mobile app using Swift in Xcode. The iOS app connects to the LoRa node via BLE and displays the messages sent by the LoRa device

### App Testing
1. **Flash the LoRa Node**: First, upload the BLE logic to the LoRa device. The code is stored in 'lora-nodes/lora-nodes.ino'
2. **Connect Device**: Plug Apple device into machine that is running the app code: 'BatSignal_App/LoRaApp'
3. **Build**: Set your apple device as the build target, and press the build/run button or (Cmd + R).
4. **Test the Connection**: Once the app is running on your iOS device, it should connect to the LoRa node and display messages sent via BLE, might need to give permission in bluetooth settings.

## 6.0 - Hardware Requirements
1. 3 x LoRa modules (ESP32 + LoRa)
2. 1 x iPhone (for BLE connection)
3. Antennas and USB cables
