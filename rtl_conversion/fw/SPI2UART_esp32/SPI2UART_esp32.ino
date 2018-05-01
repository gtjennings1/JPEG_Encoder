/******************************************************************************
Copyright 2017 Gnarly Grey LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
******************************************************************************/

#include <SPI.h>

#define CSPIN  5  // A1 for IU board
#define IMG_REQ 16 //Upduino Pin 03
#define IMG_RDY 4  //Upduino Pin 48
/*
SPI  ESP32 Upduino2
SCLK  18     47
MISO  17     02
MOSI  19     45
SS    05     46
 
*/

int i = 0;
int j = 0;
byte pixdata, pixdata_p;
int address, jpeg_size;
  
void setup(void)
{
  pinMode(CSPIN, OUTPUT);
  pinMode(IMG_REQ, OUTPUT);
  pinMode(IMG_RDY, INPUT);

  digitalWrite(IMG_REQ, LOW);  
  digitalWrite(CSPIN, HIGH); 
           
  SPI.begin(18, 19, 17, 25); // sck, miso, mosi, ss (ss can be any GPIO)
  SPI.beginTransaction(SPISettings(500000, MSBFIRST, SPI_MODE0));
  
  Serial.begin(115200);
  delay(500);
  digitalWrite(IMG_REQ, HIGH);

  while (!digitalRead(IMG_RDY)){}

  digitalWrite(CSPIN, LOW);
  pixdata = SPI.transfer(0xFF);
  jpeg_size = pixdata;
  jpeg_size <<= 8;
  pixdata = SPI.transfer(0xFF);
  jpeg_size |= pixdata;
  jpeg_size <<= 8;
  pixdata = SPI.transfer(0xFF);
  jpeg_size |= pixdata;
  
  jpeg_size = (jpeg_size & 0x1FFFF) + 607;   
  Serial.print("JPEG Size: ");
  Serial.print(jpeg_size);
  Serial.print("\n"); 
  pixdata = 0x00;
  
  do {
    pixdata_p = pixdata;
    pixdata = SPI.transfer(0xFF);

    if (pixdata < 16)
    {
        Serial.print("0"); //hex print prints "0" instead of "00", so this fixes it
        Serial.print(pixdata, HEX);            
    }
    else
    {
        Serial.print(pixdata, HEX);
    }

    i++;
  }while (!((pixdata_p == 0xFF) && (pixdata == 0xD9)));//(i<100);
  
  digitalWrite(CSPIN, HIGH);
  digitalWrite(IMG_REQ, LOW);
     
}

void loop(void)
{
}



