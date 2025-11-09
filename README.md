# CS 4091 Capstone II Project
## 1.0 - IDE Setup
Install Arduino IDE from https://www.arduino.cc/en/software/ 
On the left panel, find and click on 'Boards Manager' and search for esp32. Click install on esp32 by Espressif Systems.
Click on the 'Select Board' Dropdown and select 'Esp32 Dev Module' 
Navigate to File < Preferences and paste 'https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_dev_index.json' into the 'Additional Boards Manager URLs' field

## 2.0 - Project Structure
cs4091-capstone-project/
├── BatSignal_App/                  # iOS Swift app for LoRa BLE messages
│   ├── LoRaApp/                    # Xcode project folder
│   ├── LoRaApp.xcodeproj
│   ├── LoRaAppTests/               # Unit Tests
│   ├── LoRaAppUITests/             # UI tests
├── lora-nodes/                     # Arduino/LoRa node code
│   ├── lora-nodes.ino
├── lora-recv/                      # LoRa receiver code (test code)
│   └── lora-recv.ino
├── lora/                           # LoRa sender code (test code)
│   └── lora.ino  
└── README.md                       # Top-level project README

## 3.0 - Mobile App
### Bluetooth Communication
For this project, we chose to implement BLE (Bluetooth Low Energy), a Bluetooth protocol optimized for low-power communication. BLE is a lightweight, energy-efficient, and compatible with iOS devices.

### App Setup
We implemented the mobile app using Swift in Xcode. The iOS app connects to the LoRa node via BLE and displays the messages sent by the LoRa device

### App Testing
1. **Flash the LoRa Node**: First, upload the BLE logic to the LoRa device. The code is stored in 'lora-nodes/lora-nodes.ino'
2. **Build the iOS App**: For this you will need a second device that is plugged into the machine running your app code. Open the Xcode project in 'BatSignal_App/LoRaApp/', set your device as the build target, and press the build/run button.
3. **Test the Connection**: Once the app is running on your iOS device, it should connect to the LoRa node and display messages sent via BLE
