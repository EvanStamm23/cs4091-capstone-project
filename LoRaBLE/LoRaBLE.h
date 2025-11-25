/*
  Use BLE bluetooth to connect to iOS devices
*/
#ifndef LORABLE_H
#define LORABLE_H

#include <NimBLEDevice.h>

class LoRaBLE {
private:
  NimBLEServer* pServer;
  NimBLECharacteristic* pCharacteristic;
  string nodeName;
  string characteristicUUID;
  unsigned long lastSendTime;

public:
  LoRaBLE(String _nodeName, String _serviceUUID, String _characteristicUUID)
    : nodeName(_nodeName), serviceUUID(_serciceUUID), characteristicUUID(_characteristicUUID), lastSendTime(0) {}

  void begin() {
    Serial.println("Initializing BLE...");
    NimBLEDevice::init(nodeName.c_str());
    pServer = NimBLEDevice::createServer();
    NimBLEService* pService = pServer->createService(serviceUUID.c_str());
    pCharacteristic = pService->createCharacteristic(
        characteristicUUID.c_str(),
        NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY
    );
    pService->start();

    NimBLEAdvertising* pAdvertising = NimBLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(serviceUUID.c_str());
    pAdvertising->start();

    Serial.println("BLE Advertising started");
  }

  void notifyMessage(String message) {
    if (pServer->getConnectedCount() > 0) {
      pCharacteristic->setValue(message.c_str());
      pCharacteristic->notify();
      Serial.println("Sent: " + message);
      }
  }

  void notifyRSSI(int sourceId, int targetId, int rssiValue) {
    String msg = "RSSI,source=" + String(sourceId) + ",target=" + String(targetId) + ",value=" + String(rssiValue);
    notifyMessage(msg);
  }
};

#endif

