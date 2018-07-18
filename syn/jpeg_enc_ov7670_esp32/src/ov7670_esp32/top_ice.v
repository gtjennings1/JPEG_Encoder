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
  reg    [15:0]   pix_per_line;
  
  reg    [3:0]    c_state, n_state;

  reg    [31:0]   cb_yuyv;
  reg    [7:0]    cb_data;
  
  reg    [16:0]   jpeg_size;
  reg    [2:0]    je_done_fl;  
  
  wire            pixel_wr = q_href && (!pixel_wr_disable);// && (pixel_cnt[0]==0);
  
  parameter       WAIT0  = 0;
  parameter       JE_REQ = 1;
  parameter       WAIT1  = 2;
  parameter       YTY_RD = 3;
  parameter       WAIT2  = 4;
  parameter       JE_EN  = 5;
  parameter       WAIT3  = 6;
  parameter       SPI_RD = 7;
  parameter       WAIT4  = 8;
  
  wire            yty_req = (c_state == YTY_RD);
  wire            yty_rd  = ((c_state == WAIT2) || (c_state == JE_EN) || (c_state == WAIT3));
  wire            je_wr   = (c_state == WAIT3);
  wire            je_en   = (c_state == JE_EN);

  wire   [16:0]   jedw_addr, yty_addr, jdts_addr;
  wire   [7:0]    jedw_data, je_data, yty_data, esp32_spi_data, mem_datar, hd_data;
  wire   [9:0]    hd_addr;
  wire            je_rd, je_valid, je_done, jedw_wr, esp32_spi_rd;

  wire            jedf_empty, yty_mem_rd, mem_wr_acc;
  wire   [31:0]   jedf_do;  
  
  reg             jedf_mem_wr;  
  
  wire            mem_wr    = je_wr ? jedf_mem_wr : pixel_wr;
  wire   [7:0]    mem_dataw = je_wr ? jedf_do[7:0] : cb_data;//q_pdata;//
  wire   [16:0]   mem_addrw = je_wr ? jedf_do[24:8] : pixel_cnt[16:0];
  
  wire   [16:0]   mem_addrr = yty_rd ? yty_addr : jdts_addr;
  
  assign          img_rdy = (c_state == WAIT4);
  
  parameter       RED_VYUY   = 32'hFF4C544C;//32'h4C544CFF;
  parameter       GREEN_VYUY = 32'hFF4C544C;//32'h15962B96;//32'h962B9615;
  parameter       BLUE_VYUY  = 32'hFF4C544C;//32'h6B1DFF1D;//32'h1DFF1D6B;
  parameter       WHITE_VYUY = 32'hFF4C544C;//32'h80FF80FF;//32'hFF80FF80;  
  
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
    end

  always @ (posedge pclk or negedge reset_n)
    begin
      if (!reset_n)
        cb_yuyv <= #1 RED_VYUY;
      else
      if (pix_per_line < 16'd160)
        cb_yuyv <= #1 RED_VYUY;
      else
      if (pix_per_line < 16'd320)
        cb_yuyv <= #1 GREEN_VYUY;
      else
      if (pix_per_line < 16'd480)
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
  
  always @ (posedge pclk or negedge reset_n)
    begin
      if (!reset_n)
        c_state <= #1 WAIT0;
      else
        c_state <= #1 n_state;      
    end
    
  always @ (c_state, img_req, pixel_wr_disable, yty_ready, je_done_fl[2])
    begin
      case (c_state)
        WAIT0     : begin
                      if (img_req)
                        n_state <= #1 JE_REQ;
                      else
                        n_state <= #1 WAIT0;                      
                    end
        JE_REQ    : n_state <= #1 WAIT1;
        WAIT1     : begin
                      if (pixel_wr_disable)
                        n_state <= #1 YTY_RD;
                      else
                        n_state <= #1 WAIT1;                      
                    end
        YTY_RD    : n_state <= #1 WAIT2;
        WAIT2     : begin
                      if (yty_ready)
                        n_state <= #1 JE_EN;
                      else
                        n_state <= #1 WAIT2;                      
                    end
        JE_EN     : n_state <= #1 WAIT3;
        WAIT3     : begin
                      if (je_done_fl[2])
                        n_state <= #1 SPI_RD;
                      else
                        n_state <= #1 WAIT3;                        
                    end
        SPI_RD    : n_state <= #1 WAIT4;
        WAIT4     : begin
                      if (!img_req)
                        n_state <= WAIT0;
                      else
                        n_state <= WAIT4;                      
                    end
        default   : n_state <= #1 WAIT0;
      endcase
    end    
  
  always @ (posedge pclk or negedge reset_n)
    begin
      if (!reset_n)
        jpeg_size <= #1 17'h00000;
      else
        case (c_state)
          JE_EN   : jpeg_size <= #1 17'h00000;
          WAIT3   : begin
                      if (je_valid)
                        jpeg_size <= #1 jpeg_size + 17'h00001;
                      else
                        jpeg_size <= #1 jpeg_size;                      
                    end
          default : jpeg_size <= #1 jpeg_size;          
        endcase        
    end
  
  always @ (posedge pclk or negedge reset_n)
    begin
      if (!reset_n)
        jedf_mem_wr <= #1 1'b0;
      else
        jedf_mem_wr <= #1 ((!jedf_empty) && (mem_wr_acc) && (!jedf_mem_wr));
    end

  always @ (posedge pclk or negedge reset_n)
    begin
      if (!reset_n)
        je_done_fl <= #1 2'h0;
      else
        je_done_fl <= #1 {je_done_fl[1:0], je_done};      
    end
  
  SB_HFOSC  u_SB_HFOSC (
    .CLKHFPU  (1'b1), 
    .CLKHFEN  (1'b1), 
    .CLKHF    (xclk_in)
  ); 
  defparam u_SB_HFOSC.CLKHF_DIV = "0b01";  

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
  
  yuyv_to_yuv yty (
    .clk       (pclk),
    .reset_n   (reset_n),
    
    .img_req   (yty_req),
    
    .addr      (yty_addr),
    .data      (mem_datar),
    
    //.mem_wr    (mem_wr),
    //.jedf_empty(jedf_empty && (!jedf_mem_wr)),
    .mem_rd    (yty_mem_rd),
    .mem_wr_acc(mem_wr_acc),
    
    .ready     (yty_ready),
    
    .je_rd     (je_rd),
    .je_data   (yty_data)  
  );  
  
  jpeg_enc je (
    .clk       (pclk),
    .reset_n   (reset_n),
    .conv_en   (je_en),
    .fb_data   (yty_data),
    //.fb_addr   (),
    .fb_rd     (je_rd),
    .img_out   (je_data),
    
    .hd_addr   (hd_addr),
    .hd_data   (hd_data),
    
    .img_valid (je_valid),
    .img_done  (je_done)
  );  
    
  jpeg_data_writer jedw (
    .clk       (pclk),
    .reset_n   (reset_n),
    
    .je_valid  (je_valid),
    .je_data   (je_data),
    .je_done   (je_done),

    .addr      (jedw_addr),
    .data      (jedw_data),
    .we        (jedw_wr)
  );
  
  sc_fifo_32 jed_fifo (
    .data_in        ({7'h00,jedw_addr,jedw_data}), 
    .data_out       (jedf_do), 
    .clk            (pclk), 
    .reset          (!reset_n), 
    .write          (jedw_wr), 
    .read           (jedf_mem_wr), 
    .clear          (1'b0),
    .almost_full    (), 
    .full           (), 
    .almost_empty   (),   
    .empty          (jedf_empty), 
    .cnt            ()
  );
    
  jpeg_data_to_spi jdts (
    .clk       (pclk),
    .reset_n   (reset_n),
    
    .je_done   (je_done),
    
    .jpeg_size (jpeg_size),
    
    .hd_addr   (hd_addr),
    .hd_data   (hd_data),
    
    .je_addr   (jdts_addr),
    .je_data   (mem_datar),
    
    .spi_rd    (esp32_spi_rd),
    .spi_data  (esp32_spi_data)
  );    
    
  spi_slave esp32_spi (
    .clk      (pclk ),
    .reset_n  (reset_n),

    .sclk     (sclk),
    .mosi     (mosi),
    .ssel     (ssel),
    .miso     (miso),

    .mem_rd   (esp32_spi_rd),
    .mem_data (esp32_spi_data)  
  );
  
endmodule  