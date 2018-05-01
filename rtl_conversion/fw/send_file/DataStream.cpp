#include "DataStream.h"
#include "Base64.h"
#include <SPI.h>

#define LED_BUILTIN 13
#define CSPIN  5  // A1 for IU board

//const char* bitmapHeader = "BM6á......6...(... ...x............á..................";
//const char* base64BitmapHeader = "Qk02w6EuLi4uLi42Li4uKC4uLsKgLi4ueC4uLi4uLi4uLi4uLsOhLi4uLi4uLi4uLi4uLi4uLi4u";

DataStream::DataStream(String fname, int data_size):
  filename(fname),
  data_size(data_size),
  total_size(data_size),
  startStream(),
  headerStream(),
  endStream() { }

void DataStream::begin() {
  String start = "{\"filename\":\"" + filename + "\",\"jpeg\":true,\"overwrite\":true,\"data\":\"";
  uint8_t start_data[start.length() + 2];
  start.getBytes(start_data, start.length() + 2);
  startStream.write(start_data, sizeof(start_data));

  //160x120 Y String header = "Qk024QAAAAAAADYAAAAoAAAAoAAAAHgAAAABABgAAAAAAADhAAAAAAAAAAAAAAAAAAAAAAAA";
  //String header = "Qk023AUAAAAAADYAAAAoAAAAQAEAAJABAAABABgAAAAAAADcBQAAAAAAAAAAAAAAAAAAAAAA";

  //uint8_t header_data[header.length() + 2];
  //header.getBytes(header_data, header.length() + 2);
  //headerStream.write(header_data, sizeof(header_data));

  String endstr = "\"} ";
  uint8_t end_data[endstr.length() + 2];
  endstr.getBytes(end_data, endstr.length() + 2);
  endStream.write(end_data, sizeof(end_data));

  //base64_encode(base64BitmapHeader, (char*) bitmapHeader, sizeof(bitmapHeader));

  left_start = start.length();
  left_header = 0;//header.length();
  left_data = base64_enc_len(data_size);
  left_end = endstr.length();
  total_size = left_start + left_header + left_data + left_end;
}

int DataStream::get_total_size() {
  return total_size;
}

int DataStream::available() {
  if (left_start + left_header + left_data + left_end > 0) {
    return left_start + left_header + left_data + left_end;
  }

  return -1;
}

int DataStream::read() {
  int current_read = -1;

  pinMode(CSPIN, OUTPUT);
  SPI.begin(18, 19, 17, 25); // sck, miso, mosi, ss (ss can be any GPIO)

  if (available()) {
    if (left_start > 0) {
      current_read = startStream.read();
      if (current_read > 0) {
        left_start--;
      }
    }  else if (left_header > 0) {
      current_read = headerStream.read();
      if (current_read > 0) {
        left_header--;
      }
    }  else if (left_data > 0) {

      if (left_data == base64_enc_len(data_size))
      {
        //digitalWrite(CSPIN, HIGH);
        //delay(50);
        //digitalWrite(CSPIN, LOW);
        //delay(50);                                    //wait for frame to finish writing
        imgData[0] = SPI.transfer(0xFF);//(char) readRegister(0x0, 1);
        imgData[1] = SPI.transfer(0xFF);//imgData[0];
        imgData[2] = SPI.transfer(0xFF);//imgData[1];
        base64_encode(base64ImgData, imgData, 3);
      }
      else if (left_data % 4 == 0)
      {
        imgData[0] = SPI.transfer(0xFF);//(char) readRegisterDataOnly(1);
        imgData[1] = SPI.transfer(0xFF);//imgData[0];
        imgData[2] = SPI.transfer(0xFF);//imgData[1];
        base64_encode(base64ImgData, imgData, 3);
      }

      if ((left_data) % 4 == 0)
      {
        current_read = (int) base64ImgData[0];
      }
      else if ((left_data) % 4 == 3)
      {
        current_read = (int) base64ImgData[1];
      }
      else if ((left_data) % 4 == 2)
      {
        current_read = (int) base64ImgData[2];
      }
      else
      {
        current_read = (int) base64ImgData[3];
      }

      if (current_read > 0) {
        left_data--;
      }
    } else if (left_end > 0) {
      current_read = endStream.read();
      if (current_read > 0) {
        left_end--;
      }
    }
  }
  return current_read;
}

int DataStream::peek() {
  return startStream.peek();
}

//Read from or write to register from the SCP1000:
unsigned int readRegisterDataOnly(int bytesToRead) {
  char inByte = 0;           // incoming byte from the SPI
  unsigned int result = 0;   // result to return
  // send a value of 0 to read the first byte returned:
  result = SPI.transfer(0x00);
  // decrement the number of bytes left to read:
  bytesToRead--;
  // if you still have another byte to read:
  if (bytesToRead > 0) {
    // shift the first byte left, then get the second byte:
    result = result << 8;
    inByte = SPI.transfer(0x00);
    // combine the byte you just got with the previous one:
    result = inByte;
    // decrement the number of bytes left to read:
    bytesToRead--;
  }
  // return the result:
  return (result);
}

//Read from or write to register from the SCP1000:
unsigned int readRegister(char thisRegister, int bytesToRead) {
  char inByte = 0;           // incoming byte from the SPI
  unsigned int result = 0;   // result to return
  // now combine the address and the command into one byte
  char dataToSend = thisRegister ;//& READ;
  // send the device the register you want to read:
  SPI.transfer(dataToSend);
  // send a value of 0 to read the first byte returned:
  result = SPI.transfer(0x00);
  // decrement the number of bytes left to read:
  bytesToRead--;
  // if you still have another byte to read:
  if (bytesToRead > 0) {
    // shift the first byte left, then get the second byte:
    result = result << 8;
    inByte = SPI.transfer(0x00);
    // combine the byte you just got with the previous one:
    result = inByte;
    // decrement the number of bytes left to read:
    bytesToRead--;
  }
  // return the result:
  return (result);
}
