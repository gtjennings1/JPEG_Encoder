#include <WiFi.h>
#include <HTTPClient.h>
#include "DataStream.h"
#include <SPI.h>

#define CSPIN  5  // A1 for IU board

#define LED_BUILTIN 2
#define LOCAL_DETECT 23

#define IMG_REQ 16 //Upduino Pin 03
#define IMG_RDY 4  //Upduino Pin 48

#define JPEG_HEADER_SIZE 607

// Wifi ssid
const char* ssid = "IF Router 03";

// Wifi password
const char* password = "n8154900999";

// Set the ip of the server
const char* upload_url = "http://34.205.156.128:8080/upload?run=true&face=true";

const char* filename = "face.jpg";

byte pixdata;

void setup() {
  
  pinMode(CSPIN, OUTPUT);	
  pinMode(IMG_REQ, OUTPUT);
  pinMode(IMG_RDY, INPUT);

  digitalWrite(IMG_REQ, LOW);  
  digitalWrite(CSPIN, HIGH); 
  
  SPI.begin(18, 19, 17, 25); // sck, miso, mosi, ss (ss can be any GPIO)
  SPI.beginTransaction(SPISettings(500000, MSBFIRST, SPI_MODE0));  
  
  Serial.begin(115200);
  delay(3000);
  //Serial.write(0xA5);
  //Serial.write(0x5A);
  //delay(1000);
  //Serial.write(0x00);
  //delay(1000);
  //Serial.write((1 << 5) | ((0x2 & 0x3) << 3));

  WiFi.begin(ssid, password);

  Serial.println();
  Serial.print("MAC: ");
  Serial.println(WiFi.macAddress());

  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi..");
  }
  Serial.println("Connected to the WiFi network");

  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH);

  pinMode(LOCAL_DETECT, INPUT);

  turn_led_off(1000);
}

void blink_led() {
  digitalWrite(LED_BUILTIN, LOW);
  delay(100);
  digitalWrite(LED_BUILTIN, HIGH);
  delay(100);
  digitalWrite(LED_BUILTIN, LOW);
  delay(100);
  digitalWrite(LED_BUILTIN, HIGH);
  delay(100);
  digitalWrite(LED_BUILTIN, LOW);
}

void turn_led_on(int dly) {
  digitalWrite(LED_BUILTIN, HIGH);
  delay(dly);
}

void turn_led_off(int dly) {
  digitalWrite(LED_BUILTIN, LOW);
  delay(dly);
}

int send_data(HTTPClient& http, String filename, int data_size) {
  DataStream data_stream(filename, data_size);
  data_stream.begin();

  http.setTimeout(120000);
  http.addHeader("Content-Type", "application/json");

  return http.sendRequest("POST", &data_stream, data_stream.get_total_size());
}

void loop() {
  int data_size;
  
  if (WiFi.status() == WL_CONNECTED) {
    if (1)/*(digitalRead(LOCAL_DETECT))*/ {
      Serial.println("Sending image to cloud...");
	  
	  digitalWrite(IMG_REQ, HIGH);

	  while (!digitalRead(IMG_RDY)){}	  

	  digitalWrite(CSPIN, LOW);
    data_size = 0;
	  pixdata = SPI.transfer(0xFF);
	  data_size = pixdata;
	  data_size <<= 8;
	  pixdata = SPI.transfer(0xFF);
	  data_size |= pixdata;
	  data_size <<= 8;
	  pixdata = SPI.transfer(0xFF);
	  data_size |= pixdata;	

	  data_size = (data_size & 0x1FFFF) + JPEG_HEADER_SIZE;   
	  Serial.print("JPEG Size: ");
	  Serial.print(data_size);
	  Serial.print("\n"); 	  
	  
      if (data_size > 0) {
        HTTPClient http;
        http.begin(upload_url);

        int http_response_code = send_data(http, filename, data_size);

        if (http_response_code >= 400) {
          Serial.print("Error on sending POST: ");
          Serial.println(http_response_code);
        }

        http.end();
      }
	  
	  digitalWrite(CSPIN, HIGH);
	  digitalWrite(IMG_REQ, LOW);
    delay(100);

    } else {
      Serial.println("No data to send");
    }

  } else {
    Serial.println("Error in WiFi connection");
  }
}
