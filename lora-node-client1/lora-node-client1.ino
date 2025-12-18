#include <SPI.h>
#include <LoRa.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

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

const byte MASTER_ID = 0xAA;
const byte CLIENT1_ID = 0xB1;
const byte CLIENT2_ID = 0xB2;

byte localAddress = CLIENT1_ID;
byte messageID = 0;

//Creates object for OLED screen called display
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RST);
  
static unsigned long lastUpdate = 0;

void setup() {
  Serial.begin(115200);                   // initialize serial
  
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

  Serial.println("LoRa Client initialize succeeded at address 0x" + String(localAddress, HEX));

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
  display.print("Client Device ");
  display.println("1");
  display.display();
}

void loop() {
  receiveMessage(LoRa.parsePacket());
}

void updateDisplay(int rssiValue, float dist){
  bool flash = (millis() / 500) % 2;
  const float DIST_THRESHOLD = 20.0;

  display.clearDisplay();
  display.setTextColor(WHITE);
  display.setTextSize(1);
  display.setCursor(0,0);
  display.print("Device: ");
  display.println("Client 1");
  display.setCursor(0,20);
  display.print("RSSI of Leader: ");
  display.println(rssiValue);

  display.setCursor(0,30);
  display.print("Estimated Distance: ");
  display.setCursor(0,40);
  display.println(String(dist) + "m");
  if (dist >= DIST_THRESHOLD){
    display.setCursor(0, 50); 
    display.print("OUT OF RANGE");
  }

  display.display();
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

  float dist = calculateDist(LoRa.packetRssi());

  Serial.println("Received from LoRa Node: 0x" + String(sender, HEX));
  Serial.println("Sent to LoRa Node: 0x" + String(recipient, HEX));
  Serial.println("Message ID: " + String(incomingMessageID));
  Serial.println("Message length: " + String(incomingLength));
  Serial.println("Message: " + incomingMessage);
  Serial.println("RSSI: " + String(LoRa.packetRssi()));
  Serial.println("Snr: " + String(LoRa.packetSnr())); // snr gives ratio of recieved signal power compared to background noise power, the higer the snr, the stronger and clearer the signal is
  Serial.println("Distance: " + String(dist));
  Serial.println();
  
  //On device screen
  if (millis() - lastUpdate > 200) {  // update every second to avoid constant display calls
    updateDisplay(LoRa.packetRssi(), dist);
    lastUpdate = millis();
  }

  if (incomingMessage == "Status Check") { //If message case is normal status check, send status response
    sendReply(sender);
  }
}

void sendReply(byte destination) {
  String reply = "Status Reply from 0x" + String(localAddress, HEX);

  LoRa.beginPacket();
  LoRa.write(destination);
  LoRa.write(localAddress);
  LoRa.write(messageID++);
  LoRa.write(reply.length());
  LoRa.print(reply);
  LoRa.endPacket();

  Serial.println("Sent reply to MASTER at 0x" + String(destination, HEX));
}

float calculateDist(int rssiValue) {
  float dist = 0; //Estimated distance
  float power = -35.0; //Measured power(RSSI at 1 meter)
  double n = 2.7; //environmental factor(can range from 2-4)
  dist = pow(10,( (power - rssiValue) / (10 * n) ) );
  return dist;
}
