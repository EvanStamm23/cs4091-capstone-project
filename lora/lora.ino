#include <SPI.h>
#include <LoRa.h>

void setup() {
  Serial.begin(115200);
  while (!Serial);
  Serial.println("Starting LoRa Transmitter");
  
  LoRa.begin(433E6); //our board is 433 mHz
}

void loop() {
  Serial.println("Sending packet...");

  LoRa.beginPacket();
  LoRa.print("Hello World");
  LoRa.endPacket();

  delay(2000);
}
