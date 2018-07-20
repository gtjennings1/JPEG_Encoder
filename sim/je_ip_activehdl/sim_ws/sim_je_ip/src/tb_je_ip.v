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

`timescale 1 ns / 1 ns

module tb_je_ip;

  reg    [7:0]    spram [131071:0];
  reg             pclk, reset_n, pixel_wr_disable, img_req;
  
  integer         file_in, r, file_out;
  
  wire            mem_wr;
  wire   [7:0]    mem_dataw;
  wire   [16:0]   mem_addrw;  
  wire   [16:0]   mem_addrr;
  reg    [7:0]    mem_datar;
  wire            img_rdy;
  
  reg    [2:0]    spi_rd_cnt;
  
  wire            esp32_spi_rd = (&spi_rd_cnt);
  wire   [7:0]    esp32_spi_data; 
  reg    [15:0]   eoi_check_reg;
  
  reg    [31:0]   jpeg_size;
  reg    [31:0]   jpeg_data_cnt;

  parameter       EOI_MARK = 16'hFFD9;
  
  initial
    begin
      pclk = 0;
      reset_n = 0;
      img_req = 0;
      pixel_wr_disable = 0;

      file_in = $fopen("default_320x200.yuyv", "rb");
      if(!file_in)
        begin 
          $display("Could not open output file");
          $finish;
        end

      r = $fread(spram, file_in);
      $fclose(file_in);

      file_out = $fopen("default_320x200.jpg", "wb");
      if (!file_out)
        begin
          $display("Could not open output file");
          $finish;
        end       
      
      #100
      reset_n = 1;
      #100
      img_req = 1;
      #100
      pixel_wr_disable = 1;
    end
    
  always @ (*)
    #5 pclk <= !pclk;
    
  always @ (posedge pclk)
    begin
      if (mem_wr)
        begin
          spram[mem_addrw] <= #1 mem_dataw;
          mem_datar <= #1 mem_datar;  
        end
      else
        begin
          mem_datar <= #1 spram[mem_addrr];
        end      
    end         
    
  je_ip #(
    .WIDTH  (320),
    .HEIGHT (200)
  ) dut (
    .clk            (pclk), 
    .reset_n        (reset_n), 
    .conv_start     (img_req && pixel_wr_disable), 
    .conv_end       (img_rdy), 
    .data_out       (esp32_spi_data), 
    .data_rd        (esp32_spi_rd), 
    .mem_write_en   (mem_wr), 
    .mem_write_data (mem_dataw), 
    .mem_write_addr (mem_addrw), 
    .mem_read_data  (mem_datar), 
    .mem_read_addr  (mem_addrr)
  ); 
  
  always @ (posedge pclk or negedge reset_n)
    begin
      if (!reset_n)
        spi_rd_cnt <= #1 3'h0;
      else
      if (img_rdy)
        spi_rd_cnt <= #1 spi_rd_cnt + 3'h1;
      else
        spi_rd_cnt <= #1 3'h0;      
    end    
    
  always @ (posedge pclk or negedge reset_n)
    begin
      if (!reset_n)
        eoi_check_reg <= #1 16'h0000;
      else
      if (esp32_spi_rd && (jpeg_data_cnt > 32'h3))
        eoi_check_reg <= #1 {eoi_check_reg[7:0], esp32_spi_data};      
    end

  always @ (posedge pclk or negedge reset_n)
    begin
      if (!reset_n)
        jpeg_data_cnt <= #1 32'h00000000;
      else
      if (esp32_spi_rd)
        jpeg_data_cnt <= #1 jpeg_data_cnt + 32'h00000001;
      else
        jpeg_data_cnt <= #1 jpeg_data_cnt;      
    end    
  
  always @ (posedge pclk or negedge reset_n)
    begin
      if (!reset_n)
        jpeg_size <= #1 32'h00000000;
      else
      if (esp32_spi_rd && (jpeg_data_cnt < 32'h4)) 
        jpeg_size <= #1 {jpeg_size[23:0], esp32_spi_data};
      else
        jpeg_size <= #1 jpeg_size;      
    end
  
  always @ (posedge pclk)
    begin
      if (esp32_spi_rd && (jpeg_data_cnt > 32'h3))
        $fwriteb(file_out, "%c", esp32_spi_data);     
    end
    
  always @ (posedge pclk)
    begin
      if (eoi_check_reg == EOI_MARK)
        begin
          $fclose(file_out);
          $display("Conversion Done");
          $finish;
        end
    end     

endmodule