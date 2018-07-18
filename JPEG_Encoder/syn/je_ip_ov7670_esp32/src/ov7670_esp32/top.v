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

module top (
 
  output          xclk,
  input           pclk,
  input           vsync,
  input           href,
  input  [7:0]    pdata,
  output          cam_reset_n,
  output          cam_pwrdn,
  
  output          sioc,
  inout           siod,
  
  input           img_req,
  output          img_rdy,
  
  input           sclk,
  input           mosi,
  output          miso,
  input           ssel  

  );
  
  wire            clk_24m /* synthesis syn_keep=1 */;
  
  reg    [17:0]   pixel_cnt;
  reg             pixel_wr_disable;
  wire            cam_config_done;
  
  //wire   [16:0]   mem_rd_addr;
  //wire   [7:0]    mem_rd_data;
  wire            reset_n = 1'b1; 
  
  //considering two bytes per pixel, taking only one byte out of two by having condition (pixel_cnt[0] == 1'b0)
  
  wire            xclk_in;  
  
  reg    [7:0]    q_pdata;
  reg             q_vsync, q_href;
  reg    [15:0]   pix_per_line, pix_per_line_fl, pix_per_line_fl2;
  
  
  reg    [31:0]   cb_yuyv;
  reg    [7:0]    cb_data;  
  
  wire            pixel_wr = q_href && (!pixel_wr_disable);// && (pixel_cnt[0]==0);

  wire   [7:0]    esp32_spi_data, mem_datar, hd_data;
  wire            esp32_spi_rd;
  
  wire            mem_write_en;
  wire   [7:0]    mem_write_data;
  wire   [16:0]   mem_write_addr;
  
  wire            mem_wr    = pixel_wr_disable ? mem_write_en : pixel_wr; //je_wr ? jedf_mem_wr : pixel_wr;
  wire   [7:0]    mem_dataw = pixel_wr_disable ? mem_write_data : q_pdata; //je_wr ? jedf_do[7:0] : q_pdata;//cb_data;// 
  wire   [16:0]   mem_addrw = pixel_wr_disable ? mem_write_addr : pixel_cnt[16:0];//je_wr ? jedf_do[24:8] : pixel_cnt[16:0];
  
  parameter       RED_VYUY   = 32'hF0525A52;//32'h4C544CFF;
  parameter       GREEN_VYUY = 32'h22913691;//32'h15962B96;//32'h962B9615;
  parameter       BLUE_VYUY  = 32'h6E29F029;//32'h6B1DFF1D;//32'h1DFF1D6B;
  parameter       WHITE_VYUY = 32'h80EB80EB;//32'h80FF80FF;//32'hFF80FF80;
  
  parameter       RAW_RD_END = 320*200*2;
  wire   [16:0]   spi_mem_addr;
  
  wire   [16:0]   mem_addrr;// = yty_rd ? yty_addr : jdts_addr;
  wire   [7:0]    spi_mem_data = esp32_spi_data;
  
  always @(posedge pclk)
    begin
      q_pdata <= pdata;
      q_vsync <= vsync;
      q_href  <= href & (pix_per_line < (320*2));  
    end

  assign          xclk = clk_24m;

  always @ (posedge pclk)
    begin
      pix_per_line <= href ? pix_per_line+1 : 0;
      //pix_per_line_fl <= #1 pix_per_line;
      //pix_per_line_fl2 <= #1 pix_per_line_fl;
    end
  
  always @ (posedge pclk or negedge reset_n)
    begin
      if (!reset_n)
        cb_yuyv <= #1 RED_VYUY;
      else
      if (pix_per_line < 16'd159)
        cb_yuyv <= #1 RED_VYUY;
      else
      if (pix_per_line < 16'd319)
        cb_yuyv <= #1 GREEN_VYUY;
      else
      if (pix_per_line < 16'd479)
        cb_yuyv <= #1 BLUE_VYUY;
      else
        cb_yuyv <= #1 WHITE_VYUY;      
    end
  
  always @ (posedge pclk)
    begin
      if (href)
        case (pix_per_line[1:0])
          2'b00   : cb_data <= #1 cb_yuyv[7:0];
          2'b01   : cb_data <= #1 cb_yuyv[15:8];
          2'b10   : cb_data <= #1 cb_yuyv[23:16];
          2'b11   : cb_data <= #1 cb_yuyv[31:24];
          default : cb_data <= #1 cb_data;
        endcase
      else
        cb_data <= #1 cb_data;      
    end
  
  //Manage address for writing in DPRAM through pixel counter
  always @ (posedge pclk)
    begin
      if (!reset_n)
        begin
          pixel_cnt    <= 18'h00000;
        end
      else
      if (q_vsync)
        begin
          pixel_cnt    <= 18'h00000;
        end
      else
      if (q_href) 
        begin
          //pixel_cnt    <= (pixel_cnt<(320*400*2))    ?  pixel_cnt + 18'h00001 : pixel_cnt;
          pixel_cnt    <= (pixel_cnt<(320*200*2))    ?  pixel_cnt + 18'h00001 : pixel_cnt;
        end
      else
        begin
          pixel_cnt <= pixel_cnt;     
        end  
    end    
    
	
  //Disable pixel data write from next frame if SPI transfer has been initiated
  always @ (posedge pclk)
    begin
      if (q_vsync)
        pixel_wr_disable <= img_req;//!ssel;
      else
        pixel_wr_disable <= pixel_wr_disable;
    end
     
    
//SB_HFOSC  u_SB_HFOSC (
  HSOSC  u_HSOSC (
    .CLKHFPU  (1'b1), 
    .CLKHFEN  (1'b1), 
    .CLKHF    (xclk_in)
  ); 
  defparam u_HSOSC.CLKHF_DIV = "0b01";  

  assign clk_24m = xclk_in;

  up_spram cam_buf (
    .reset_n  (reset_n),
    
    .wr_clk   (pclk ),
    .wr_addr  (mem_addrw),
    .wr_data  (mem_dataw),  
    .wr_en    (mem_wr),
    
    .rd_clk   (pclk ),
    .rd_addr  (mem_addrr),
    .rd_data  (mem_datar)
    );  
  
  OV7670_Controller u_OV7670_Controller(
    .clk             (clk_24m),          // 24Mhz clock signal
    .resend          (1'b0),             // Reset signal
    .config_finished (cam_config_done),  // Flag to indicate that the configuration is finished
    .sioc            (sioc),             // SCCB interface - clock signal
    .siod            (siod),             // SCCB interface - data signal
    .reset           (cam_reset_n),      // RESET signal for OV7670
    .pwdn            (cam_pwrdn)         // PWDN signal for OV7670
  );  
  
  je_ip #(
    .WIDTH  (320),
    .HEIGHT (200)
  ) jeip (
    .clk            (pclk), 
    .reset_n        (reset_n), 
    .conv_start     (img_req && pixel_wr_disable), 
    .conv_end       (img_rdy), 
    .data_out       (esp32_spi_data), 
    .data_rd        (esp32_spi_rd), 
    .mem_write_en   (mem_write_en), 
    .mem_write_data (mem_write_data), 
    .mem_write_addr (mem_write_addr), 
    .mem_read_data  (mem_datar), 
    .mem_read_addr  (mem_addrr)
  );  
    
  spi_slave esp32_spi (
    .clk      (pclk ),
    .reset_n  (reset_n),

    .sclk     (sclk),
    .mosi     (mosi),
    .ssel     (ssel),
    .miso     (miso),

    .mem_addr (spi_mem_addr),
    .mem_rd   (esp32_spi_rd),
    .mem_data (spi_mem_data)  
  );
  
endmodule  