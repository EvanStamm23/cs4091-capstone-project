/*
  Use BLE bluetooth to connect to iOS devices
*/
#include <NimBLEDevice.h>

#define SERVICE_UUID        "12345678-1234-1234-1234-1234567890ab"
#define CHARACTERISTIC_UUID "abcd1234-5678-90ab-cdef-1234567890ab"

NimBLEServer* pServer;
NimBLECharacteristic* pCharacteristic;

void setup() {
  Serial.begin(115200);

  // Initialize BLE device
  NimBLEDevice::init("LoRaBLENode");

  // Create BLE server
  pServer = NimBLEDevice::createServer();

  // Create a BLE service
  NimBLEService* pService = pServer->createService(SERVICE_UUID);

  // Create a BLE characteristic
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      NIMBLE_PROPERTY::READ |
                      NIMBLE_PROPERTY::NOTIFY
                    );

  // Start the service
  pService->start();
  // Start advertising
  NimBLEAdvertising* pAdvertising = NimBLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->start();

  Serial.println("BLE Advertising started");
}

void loop() {
  static unsigned long lastTime = 0;
  
  // Check if any device is connected to the server
  if (pServer->getConnectedCount() > 0) {
    if (millis() - lastTime > 1000) {
      lastTime = millis();
      pCharacteristic->setValue("Hello over Bluetooth!");
      pCharacteristic->notify();
      Serial.println("Sent: Hello over Bluetooth!");
    }
  }
}
