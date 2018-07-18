#include <Stream.h>
#include <WString.h>
#include <HardwareSerial.h>
#include <StreamString.h>

unsigned int readRegister(char thisRegister, int bytesToRead);
unsigned int readRegisterDataOnly(int bytesToRead);

class DataStream: public Stream {

    String filename;
    int data_size;
    int total_size;
    int left_start = 0;
    int left_header = 0;
    int left_data = 0;
    int left_end = 0;
    char imgData[3];
    char base64ImgData[4];
    StreamString startStream;
    StreamString headerStream;
    StreamString endStream;

  public:
    DataStream(String fname, int data_size);

    void begin();
    int get_total_size();

    virtual int available();
    virtual int read();
    virtual int peek();

    virtual void flush() { };

    virtual size_t write(uint8_t c) { };
};

