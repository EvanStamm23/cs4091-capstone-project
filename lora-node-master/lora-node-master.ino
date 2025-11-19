#include <SPI.h>
#include <LoRa.h>

#define SCK   5
#define MISO  19
#define MOSI  27
#define NSS   18
#define RST   14
#define DIO0  26

String messageText;

const byte MASTER_ID = 0xAA;
const byte CLIENT1_ID = 0xB1;
const byte CLIENT2_ID = 0xB2;

byte messageID = 0;
byte localAddress = MASTER_ID;     // address of this device
long lastSendTime = 0;        // last send time
int interval = 12000;          // interval between sends, default starting at 12s
byte nextClient = CLIENT1_ID;

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

  Serial.println("LoRa Master initialize succeeded at address 0x" + String(localAddress, HEX));
}

void loop() {
  if (millis() - lastSendTime > interval) { // check time against last send time
    String message = "Status Check";
    sendMessage(message, nextClient);
    nextClient = (nextClient == CLIENT1_ID) ? CLIENT2_ID : CLIENT1_ID;
    Serial.println("Sending " + message);
    lastSendTime = millis();            // timestamp the message
  }

  receiveMessage(LoRa.parsePacket()); // check for packet response, parse, and handle receive logic
}

void sendMessage(String outgoingMessage, byte destination){
  LoRa.beginPacket();
  
  LoRa.write(destination);
  LoRa.write(localAddress);
  LoRa.write(messageID++);
  LoRa.write(outgoingMessage.length());
  LoRa.print(outgoingMessage);   

  LoRa.endPacket(); //finalizes packet and sends it
}

void receiveMessage(int packetSize){
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
    Serial.println("Received message not meant for this receiver.");
    return;
  }

  Serial.println("Received from LoRa Node: 0x" + String(sender, HEX));
  Serial.println("Sent to LoRa Node: 0x" + String(recipient, HEX));
  Serial.println("Message ID: " + String(incomingMessageID));
  Serial.println("Message length: " + String(incomingLength));
  Serial.println("Message: " + incomingMessage);
  Serial.println("RSSI: " + String(LoRa.packetRssi()));
  Serial.println("Snr: " + String(LoRa.packetSnr())); // snr gives ratio of received signal power compared to background noise power, the higer the snr, the stronger and clearer the signal is
  Serial.println();
}