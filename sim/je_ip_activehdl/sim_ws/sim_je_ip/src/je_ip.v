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
module je_ip (clk, reset_n, conv_start, conv_end, data_out, data_rd, mem_write_en, mem_write_data, mem_write_addr, mem_read_data, mem_read_addr);
  parameter          HEIGHT = 200;
  parameter          WIDTH = 320;
  localparam         HSZ = $clog2(HEIGHT);
  localparam         WSZ = $clog2(WIDTH);
  localparam         ASZ = (HSZ + WSZ);
  
  input              clk;
  input              reset_n;
  
  input              conv_start;
  output             conv_end;
  
  output [7:0]       data_out;
  input              data_rd;
  
  output             mem_write_en;
  output [7:0]       mem_write_data;
  output [(ASZ-1):0] mem_write_addr;
  input  [7:0]       mem_read_data;
  output [(ASZ-1):0] mem_read_addr;
  
  localparam       WAIT0  = 0;
  localparam       JE_REQ = 1;
  localparam       WAIT1  = 2;
  localparam       YTY_RD = 3;
  localparam       WAIT2  = 4;
  localparam       JE_EN  = 5;
  localparam       WAIT3  = 6;
  localparam       SPI_RD = 7;
  localparam       WAIT4  = 8;
  
  reg    [3:0]    c_state, n_state;
    
  wire            yty_req = (c_state == YTY_RD);
  wire            yty_rd  = ((c_state == WAIT2) || (c_state == JE_EN) || (c_state == WAIT3));
  wire            je_wr   = (c_state == WAIT3);
  wire            je_en   = (c_state == JE_EN);

  wire   [(ASZ-1):0]   jedw_addr, yty_addr, jdts_addr;
  reg    [(ASZ-1):0]   jpeg_size;
  wire   [7:0]    jedw_data, je_data, yty_data, /*esp32_spi_data,*/ hd_data;
  wire   [9:0]    hd_addr;
  wire            je_rd, je_valid, je_done, jedw_wr, /*esp32_spi_rd,*/ yty_ready;
  
  wire            jedf_empty, /*yty_mem_rd,*/ mem_wr_acc;
  wire   [(ASZ+7):0]   jedf_do;

  reg             jedf_mem_wr;
  reg    [2:0]    je_done_fl;
  
  assign          mem_write_en   = je_wr ? jedf_mem_wr : 1'b0;
  assign          mem_write_data = jedf_do[7:0];
  assign          mem_write_addr = jedf_do[(ASZ+7):8];
  assign          mem_read_addr  = yty_rd ? yty_addr : jdts_addr;
  //wire            mem_wr    = je_wr ? jedf_mem_wr : pixel_wr;
  //wire   [7:0]    mem_dataw = je_wr ? jedf_do[7:0] : q_pdata;//cb_data;// 
  //wire   [(ASZ-1):0]   mem_addrw = je_wr ? jedf_do[24:8] : pixel_cnt[16:0];
  
  //assign          img_rdy = (c_state == WAIT4);
  assign          conv_end = (c_state == WAIT4);
  
  //wire   [(ASZ-1):0]   mem_addrr = yty_rd ? yty_addr : jdts_addr;

  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        c_state <= #1 WAIT0;
      else
        c_state <= #1 n_state;      
    end
    
  always @ (c_state, conv_start,/*img_req, pixel_wr_disable,*/ yty_ready, je_done_fl[2])
    begin
      case (c_state)
        WAIT0     : begin
                      if (conv_start/*img_req*/)
                        n_state <= #1 YTY_RD;//JE_REQ;
                      else
                        n_state <= #1 WAIT0;                      
                    end
        /*            
        JE_REQ    : n_state <= #1 WAIT1;
        WAIT1     : begin
                      if (pixel_wr_disable)
                        n_state <= #1 YTY_RD;//RAW_RD;//
                      else
                        n_state <= #1 WAIT1;                      
                    end
        */            
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
                      if (!conv_start/*!img_req*/)
                        n_state <= WAIT0;
                      else
                        n_state <= WAIT4;                      
                    end
        default   : n_state <= #1 WAIT0;
      endcase
    end    
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        jpeg_size <= #1 {ASZ{1'b0}};//17'h00000;
      else
        case (c_state)
          JE_EN   : jpeg_size <= #1 {ASZ{1'b0}};//17'h00000;
          WAIT3   : begin
                      if (je_valid)
                        jpeg_size <= #1 jpeg_size + {{(ASZ-1){1'b0}}, 1'b1};//17'h00001;
                      else
                        jpeg_size <= #1 jpeg_size;                      
                    end
          default : jpeg_size <= #1 jpeg_size;          
        endcase        
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        jedf_mem_wr <= #1 1'b0;
      else
        jedf_mem_wr <= #1 ((!jedf_empty) && (mem_wr_acc) && (!jedf_mem_wr));
    end

  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        je_done_fl <= #1 3'h0;
      else
        je_done_fl <= #1 {je_done_fl[1:0], je_done};      
    end    
  
  yuyv_to_yuv #(
    .WIDTH  (WIDTH),
    .HEIGHT (HEIGHT),
    .WSZ    (WSZ),
    .HSZ    (HSZ),
    .ASZ    (ASZ)
  ) yty (
    .clk       (clk),
    .reset_n   (reset_n),
    
    .img_req   (yty_req),
    
    .addr      (yty_addr),
    .data      (mem_read_data),
    
    .mem_wr    (jedf_mem_wr),
    //.mem_rd    (yty_mem_rd),
    .mem_wr_acc(mem_wr_acc),
    
    .ready     (yty_ready),
    
    .je_rd     (je_rd),
    .je_data   (yty_data)  
  );  
  
  jpeg_enc #(
    .WIDTH  (WIDTH),
    .HEIGHT (HEIGHT),
    .WSZ    (WSZ),
    .HSZ    (HSZ)
  ) je (
    .clk       (clk),
    .reset_n   (reset_n),
    .conv_en   (je_en),
    .fb_data   (yty_data),
    .fb_rd     (je_rd),
    .img_out   (je_data),
    
    .hd_addr   (hd_addr),
    .hd_data   (hd_data),
    
    .img_valid (je_valid),
    .img_done  (je_done)
  );  
    
  jpeg_data_writer #(
    .WIDTH  (WIDTH),
    .HEIGHT (HEIGHT),
    .WSZ    (WSZ),
    .HSZ    (HSZ),
    .ASZ    (ASZ)
  ) jedw (
    .clk       (clk),
    .reset_n   (reset_n),
    
    .je_valid  (je_valid),
    .je_data   (je_data),
    .je_done   (je_done),

    .addr      (jedw_addr),
    .data      (jedw_data),
    .we        (jedw_wr)
  );
  
  sc_fifo_32 #(
    .ASZ    (ASZ)
  ) jed_fifo (
    .data_in        ({jedw_addr,jedw_data}), 
    .data_out       (jedf_do), 
    .clk            (clk), 
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
    
  jpeg_data_to_spi #(
    .WIDTH  (WIDTH),
    .HEIGHT (HEIGHT),
    .WSZ    (WSZ),
    .HSZ    (HSZ),
    .ASZ    (ASZ)
  ) jdts (
    .clk       (clk),
    .reset_n   (reset_n),
    
    .je_done   (je_done),
    
    .jpeg_size (jpeg_size),
    
    .hd_addr   (hd_addr),
    .hd_data   (hd_data),
    
    .je_addr   (jdts_addr),
    .je_data   (mem_read_data),
    
    .spi_rd    (data_rd/*esp32_spi_rd*/),
    .spi_data  (data_out/*esp32_spi_data*/)
  );   

endmodule