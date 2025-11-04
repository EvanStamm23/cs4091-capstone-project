#include <SPI.h>
#include <LoRa.h>


void setup() {
  Serial.begin(115200);
  while (!Serial);
  Serial.println("Starting LoRa Reciever");

  if (!LoRa.begin(915E6)) {
    Serial.println("Starting LoRa failed!");
    while (1);
  }
}

void loop() {
  int packetSize = LoRa.parsePacket();
  if (packetSize) {
    String incoming = "";
    while (LoRa.available()) {
      incoming += (char)LoRa.read();
    }

  Serial.print("Received: ");
  Serial.println(incoming);
}
