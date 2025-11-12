#include <SPI.h>
#include <LoRa.h>

#define SCK   5
#define MISO  19
#define MOSI  27
#define NSS   18
#define RST   14
#define DIO0  26

String messageText;

byte messageID = 0;
byte localAddress = 0xAA;     // address of this device
byte destination01 = 0xBB;
byte destination02 = 0xCC;
long lastSendTime = 0;        // last send time
int interval = 5000;          // interval between sends, default starting at 5s

void setup() {
  Serial.begin(115200);                   // initialize serial
  while (!Serial);

  Serial.println("Starting LoRa Transciever");

    // Initialize SPI with correct pins
  SPI.begin(SCK, MISO, MOSI, NSS);
  
  // Configure LoRa pins
  LoRa.setPins(NSS, RST, DIO0);

  if (!LoRa.begin(433E6)) {             // initialize ratio at 433 MHz
    Serial.println("LoRa init failed. Check your connections.");
    while (true);                       // if failed, do nothing
  }

  Serial.println("LoRa initialized succeeded.");
}

void loop() {
  if (millis() - lastSendTime > interval) { // check time against last send time
    String message = "Status Message";
    sendMessage(message);
    Serial.println("Sending " + message);
    lastSendTime = millis();            // timestamp the message
    interval = random(2000) + 3000;    // 3-5 seconds
  }

  recieveMessage(LoRa.parsePacket()); // parse for a packet, and handle recieve logic:
}

void sendMessage(String outgoingMessage){
  LoRa.beginPacket();
  
  LoRa.write(destination01);
  LoRa.write(localAddress);
  LoRa.write(messageID);
  LoRa.write(outgoingMessage.length());
  LoRa.print(outgoingMessage);   

  LoRa.endPacket(); //finalizes packet and sends it
}

void recieveMessage(int packetSize){
  if (packetSize == 0) return;  
  
  int recipient = LoRa.read();
  byte sender = LoRa.read();
  byte incomingMessageID = LoRa.read();    
  byte incomingLength = LoRa.read();

  String incomingMessage = "";

  while (LoRa.available()) {
    incomingMessage += (char)LoRa.read();
  }

  if (incomingLength != incomingMessage.length()) {   // check for length mismatch
    Serial.println("Error: message length does not match length");
    return;
  }

  // if the recipient isn't this device or broadcast,
  if (recipient != localAddress && recipient != 0xFF) {
    Serial.println("Sent message is not meant for this receiver.");
    return;
  }

  Serial.println("Received from LoRa Node: 0x" + String(sender, HEX));
  Serial.println("Sent to LoRa Node: 0x" + String(recipient, HEX));
  Serial.println("Message ID: " + String(incomingMessageID));
  Serial.println("Message length: " + String(incomingLength));
  Serial.println("Message: " + incomingMessage);
  Serial.println("RSSI: " + String(LoRa.packetRssi()));
  Serial.println("Snr: " + String(LoRa.packetSnr())); // snr gives ratio of recieved signal power compared to background noise power, the higer the snr, the stronger and clearer the signal is
  Serial.println();
}