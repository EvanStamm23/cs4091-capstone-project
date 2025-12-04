#include <SPI.h>
#include <LoRa.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <LoRaBLE.h>

#define SCK   5
#define MISO  19
#define MOSI  27
#define NSS   18
#define RST   14
#define DIO0  26

//Pins for OLED screen
#define OLED_SDA 21
#define OLED_SCL 22
#define OLED_RST -1
#define SCREEN_WIDTH 128 //OLED display width, in pixels
#define SCREEN_HEIGHT 64 //OLED display height, in pixels

String messageText;

const byte MASTER_ID = 0xAA;
const byte CLIENT1_ID = 0xB1;
const byte CLIENT2_ID = 0xB2;

// create BLE object
LoRaBLE bleNode("Master", "12345678-1234-1234-1234-1234567890ab", "abcd1234-5678-90ab-cdef-1234567890ab");

byte messageID = 0;
byte localAddress = MASTER_ID;     // address of this device
long lastSendTime = 0;        // last send time
int interval = 2500;          // interval between sends, default starting at 12s
byte nextClient = CLIENT1_ID;

//Creates object for OLED screen called display
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RST);
  
static unsigned long lastUpdate = 0;

struct ClientRSSI {
  byte id;
  int rssi;
  bool active;
  long lastResponse;
  float lastDistance;
};
ClientRSSI clients[2] = {{CLIENT1_ID, 0, false, 0}, {CLIENT2_ID, 0, false, 0}};

// RSSI distance formula constants
// PATH_LOSS_EXPONENT: environment factor (2.0 = free space, 2.7-4 indoor)
const float RSSI_AT_ONE_METER = -35.0; 
const float PATH_LOSS_EXPONENT = 2.7;

// Convert RSSI to distanceusing d = 10^{(A - R) / (10 * n)}
float rssiToDistance(int rssi) {
  if (rssi == 0) return -1.0;
  float exponent = (RSSI_AT_ONE_METER - (float)rssi) / (10.0 * PATH_LOSS_EXPONENT);
  return pow(10.0, exponent);
}

bool isClientLost(const ClientRSSI &client) {
  const unsigned long TIMEOUT_THRESHOLD = 16000;
  const float DIST_THRESHOLD = 20.0;

  if (!client.active) return true;
  if (millis() - client.lastResponse > TIMEOUT_THRESHOLD) return true;
  if (client.lastDistance >= DIST_THRESHOLD) return true;

  return false;
}


void setup() {
  Serial.begin(115200);                   // initialize serial
  bleNode.begin();  // initialize begin

  while (!Serial);
  Serial.println("Starting LoRa Transciever");
  
  //initialize OLED
  Wire.begin(OLED_SDA, OLED_SCL);

  // Initialize SPI with correct pins
  SPI.begin(SCK, MISO, MOSI, NSS);
  
  // Configure LoRa pins
  LoRa.setPins(NSS, RST, DIO0);

  if (!LoRa.begin(433E6)) {             // initialize ratio at 433 MHz
    Serial.println("LoRa init failed. Check your connections.");
    while (true);                       // if failed, do nothing
  }

  Serial.println("LoRa Master initialize succeeded at address 0x" + String(localAddress, HEX));

  //Begin OLED stuff
  //reset OLED display via software
  pinMode(OLED_RST, OUTPUT);
  digitalWrite(OLED_RST, LOW);
  delay(20);
  digitalWrite(OLED_RST, HIGH);

  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3c, false, false)) { //Address 0x3c for 128x32
    Serial.println(F("SSD1306 allocation failed"));
  }

  display.clearDisplay();
  display.setTextColor(WHITE);
  display.setTextSize(1);
  display.setCursor(0,0);
  display.print("Master Device");
  display.display();
}

void loop() {
  if (millis() - lastSendTime > interval) { // check time against last send time
    String message = "Status Check";
    // Send the same message to both clients back-to-back
    sendMessage(message, nextClient);
    nextClient = (nextClient == CLIENT1_ID) ? CLIENT2_ID : CLIENT1_ID;
    Serial.println("Sending " + message);
    // sendMessage(message, CLIENT1_ID);
    // sendMessage(message, CLIENT2_ID);
    // Serial.println("Sent to both clients: " + message);
    lastSendTime = millis();            // timestamp the message
  }

  receiveMessage(LoRa.parsePacket()); // check for packet response, parse, and handle receive logic

  static unsigned long lastBLEUpdate = 0;
  if (millis() - lastBLEUpdate > 1000) {

      for (int i = 0; i < 2; i++) {

          bool lost = isClientLost(clients[i]);

          String json = "{";
          json += "\"id\":\"" + String(clients[i].id, HEX) + "\",";
          json += "\"rssi\":" + String(clients[i].rssi) + ",";
          json += "\"isLost\":" + String(lost ? "true" : "false");
          json += "}";

          bleNode.notifyMessage(json);   // send JSON to iPhone
      }

      lastBLEUpdate = millis();
  }

    //On device screen
  if (millis() - lastUpdate > 200) {  // update every second to avoid constant display calls
    updateDisplay();
    lastUpdate = millis();
  }
}

void updateDisplay(){
  const unsigned long TIMEOUT_THRESHOLD = 16000;
  const float DIST_THRESHOLD = 20.0;
  bool flash = (millis() / 500) % 2;

  display.clearDisplay();
  display.setTextColor(WHITE);
  display.setTextSize(1);

  display.setCursor(0,0);
  display.print("Device: Master");

  for(int i = 0; i < 2; i++){
    display.setTextColor(WHITE);
    int y = 16 + (i * 24);
    if (!clients[i].active){ // only display the rssi and distance for a client which has responded
      continue;
    }
    if (millis() - clients[i].lastResponse > TIMEOUT_THRESHOLD){
      //display.setTextColor(INVERSE);
      if (flash){
        display.setCursor(0, y);
        display.println("Client 0x" + String(clients[i].id, HEX));
        display.print("UNRESPONSIVE");
      }
      continue;
    }
    if (clients[i].lastDistance >= DIST_THRESHOLD){
      if (flash){
        display.setCursor(0, y);
        display.println("Client 0x" + String(clients[i].id, HEX)); 
        display.print("OUT OF RANGE");
      }
      continue;
    }

    display.setCursor(0, y);
    display.print("Client 0x" + String(clients[i].id, HEX) + " RSSI: " + clients[i].rssi);
  
    float dist = rssiToDistance(clients[i].rssi); // Convert RSSI to estimated distance
    display.setCursor(0, y + 12);
    display.print("Dist: ");
    if (dist < 0)
      display.print("N/A");
    else{
      display.print(String(dist, 2)); // show two decimal places
      display.print(" m");
    }
  }
  display.display();
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

  // Update RSSI for correct client
  for (int i = 0; i < 2; i++) {
    if (clients[i].id == sender) {
        clients[i].rssi = LoRa.packetRssi();
        clients[i].active = true;
        clients[i].lastResponse = millis();
        clients[i].lastDistance = rssiToDistance(clients[i].rssi);
        break;
    }
  }

  Serial.println("Received from LoRa Node: 0x" + String(sender, HEX));
  Serial.println("Sent to LoRa Node: 0x" + String(recipient, HEX));
  Serial.println("Message ID: " + String(incomingMessageID));
  Serial.println("Message length: " + String(incomingLength));
  Serial.println("Message: " + incomingMessage);
  Serial.println("RSSI: " + String(LoRa.packetRssi()));
  Serial.println("Snr: " + String(LoRa.packetSnr())); // snr gives ratio of received signal power compared to background noise power, the higer the snr, the stronger and clearer the signal is
  Serial.println();

  // //On device screen
  // if (millis() - lastUpdate > 200) {  // update every second to avoid constant display calls
  //   updateDisplay();
  //   lastUpdate = millis();
  // }
}

