# JPEG_Encoder

The Gnarly Grey JPEG Encoder is a minimalistic, low resource JPEG encoder targeting the Lattice Ultraplus FPGA and UPDuino v1.0 and v2.0 boards.

The JPEG Encoder was used to reduced the image size in order to send images to cloud servers faster for AI projects.

The JPEG encoder was tested using the following hardware:
  - UPDuino v1.0 or v2.0 board
  - UPDuino OV7670 Camera Adapter
  - OV7670 Camera Module
  - ESP32 WiFi Module
  
As long as it doesn't cost me too much I will leave our person detection AI server running.  It's a webpage that detects if a person is present or not.  If there is a person present if checks if they are in our database.  If they're our database it presents the persons name.  If they are not in the database they are listed as "unknown person" and a textbox is provided to enter the person's name.  After a name for the person is entered they are in the database and their name will be presented for any time they are detected in future images.

  - http://34.205.156.128:8080

Directories:
  - /doc                         (Description of JPEG IP)
  - /syn/je_ip_ov7670_esp32      (FPGA Source and Lattice Radiant project)
  - /fw/SPI2UART_esp32           (ESP32 Arduino code to print JPEG data to terminal window)
  - /fw/SPI2UART_nano            (Arduino Nano code to print JPEG data to terminal window)
  - /fw/send_file                (ESP32 Arduino code to send JPEG data to person detection server)

Code Sources and Shoutouts:
JPEG Encoder RTL design was written from scratch, but referenced a JPEG encoder written in C++ from Jon Olick, which is public domain.  Thanks Jon for the great, simple encoder examples!
https://www.jonolick.com/code.html

The RTL and register settings for the OV7670 was partially written and assisted by Thanh Tien Truong from Portland State University. Thank you for your help Thanh Tien Truong!

RTL for sc_fifo.v and sc_fifo_32.v is from OpenCores.org and provided under LPGL license.  Thanks Open Cores!
https://opencores.org/websvn/filedetails?repname=ethmac&path=%2Fethmac%2Ftrunk%2Frtl%2Fverilog%2Feth_fifo.v
