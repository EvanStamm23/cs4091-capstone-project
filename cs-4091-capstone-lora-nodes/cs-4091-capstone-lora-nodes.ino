#include <LoRa.h>
#include "BluetoothSerial.h"

BluetoothSerial SerialBT;

void setup() {
  Serial.begin(115200);
  SerialBT.begin("LoRaNode");

  LoRa.begin(433E6);

}

void loop() {
  SerialBT.println("Hello over Bluetooth!");
  delay(1000);
}
