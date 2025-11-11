#include <SPI.h>
#include <LoRa.h>

#define SCK   5
#define MISO  19
#define MOSI  27
#define NSS   18
#define RST   14
#define DIO0  26

int packet_num = 0;

void setup() {
  Serial.begin(115200);
  while (!Serial);
  Serial.println("Starting LoRa Transmitter");
  
  SPI.begin(SCK, MISO, MOSI, NSS);
  LoRa.setPins(NSS, RST, DIO0);

  if (!LoRa.begin(433E6)) { //our board is 433 mHz
    Serial.println("Starting LoRa failed!");
    while (1);
  }

  Serial.println("LoRa transmitter initialized successfully.");
}

void loop() {
  Serial.println("Sending packet " + String(packet_num));

  String message = "Hello World! Packet #" + String(packet_num);
  LoRa.beginPacket();
  LoRa.print(message);
  LoRa.endPacket();
  packet_num++;
  delay(2000);
}
