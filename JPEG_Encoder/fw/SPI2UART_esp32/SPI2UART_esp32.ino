/******************************************************************************
Copyright 2018 Gnarly Grey LLC

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

//#define RAW_READ
/*
SPI  ESP32 Upduino2
SCLK  18     47
MISO  19     02
MOSI  17     45
SS    05     46
 
*/

int i = 0;
int j = 0;
byte pixdata, pixdata_p;
char Y0, U, Y1, V;
char r0, g0, b0, r1, g1, b1;
int address, jpeg_size;
  
void setup(void)
{
  pinMode(CSPIN, OUTPUT);
  pinMode(IMG_REQ, OUTPUT);
  pinMode(IMG_RDY, INPUT);

  digitalWrite(IMG_REQ, LOW);  
  digitalWrite(CSPIN, HIGH); 
           
  SPI.begin(18, 19, 17, 25); // sck, miso, mosi, ss (ss can be any GPIO)
  SPI.beginTransaction(SPISettings(150000, MSBFIRST, SPI_MODE0));
  
  Serial.begin(115200);
  delay(500);
  digitalWrite(IMG_REQ, HIGH);

#ifdef RAW_READ
  //Serial.println("Reading RAW, Converting to BMP");
  Serial.println("Reading RAW");
  //Serial.println("424D36DC05000000000036000000280000004001000090010000010018000000000000DC050000000000000000000000000000000000");
  delay(100);  
  digitalWrite(CSPIN, LOW);
  Y0 = SPI.transfer(0);
  while(j<200)
  {
    while(i<(320/2))
    {
      Y0 = SPI.transfer(0);
      if (Y0 < 16)
      {
        Serial.print("0");
        Serial.print(Y0, HEX);
      }
      else
        Serial.print(Y0, HEX);
        
      U  = SPI.transfer(0);
      if (U < 16)
      {
        Serial.print("0");
        Serial.print(U, HEX);
      }
      else
        Serial.print(U, HEX);
              
      Y1 = SPI.transfer(0);
      if (Y1 < 16)
      {
        Serial.print("0");
        Serial.print(Y1, HEX);
      }
      else
        Serial.print(Y1, HEX);
              
      V  = SPI.transfer(0);
      if (V < 16)
      {
        Serial.print("0");
        Serial.print(V, HEX);
      }
      else
        Serial.print(V, HEX);      
/*
      U = U - 128;
      V = V - 128;

      r0 = Y0 + V + (V>>2) + (V>>3) + (V>>5);
      if (r0 < 16)
      {
        Serial.print("0");
        Serial.print(r0, HEX);
      }
      else
        Serial.print(r0, HEX);
        
      g0 = Y0 - ((U>>2) + (U>>4) + (U>>5)) - ((V>>1) + (V>>3) + (V>>4) + (V>>5));
      if (g0 < 16)
      {
        Serial.print("0");
        Serial.print(g0, HEX);
      }
      else
        Serial.print(g0, HEX);
        

      b0 = Y0 + U + (U>>1) + (U>>2) + (U>>6);
      if (b0 < 16)
      {
        Serial.print("0");
        Serial.print(b0, HEX);
      }
      else
        Serial.print(b0, HEX);
        

      r1 = Y1 + V + (V>>2) + (V>>3) + (V>>5);
      if (r1 < 16)
      {
        Serial.print("0");
        Serial.print(r1, HEX);
      }
      else
        Serial.print(r1, HEX);
        

      g1 = Y1 - ((U>>2) + (U>>4) + (U>>5)) - ((V>>1) + (V>>3) + (V>>4) + (V>>5));
      if (g1 < 16)
      {
        Serial.print("0");
        Serial.print(g1, HEX);
      }
      else
        Serial.print(g1, HEX);
        

      b1 = Y1 + U + (U>>1) + (U>>2) + (U>>6);
      if (b1 < 16)
      {
        Serial.print("0");
        Serial.print(b1, HEX);
      }
      else
        Serial.print(b1, HEX);
*/        
      i++;      
      
    }
    i=0;
    j++;
    Serial.print("\n");
  }

  digitalWrite(CSPIN, HIGH);
  Serial.print("\n"); 
#endif  
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



