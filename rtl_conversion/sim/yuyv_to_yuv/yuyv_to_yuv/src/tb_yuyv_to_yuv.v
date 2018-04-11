`timescale 1ns/1ns

module tb_yuyv_to_yuv;

  reg           clk, reset_n, img_req, je_rd;
  reg    [7:0]  data;
  wire   [7:0]  je_data;
  wire   [16:0] addr;
  
  reg    [8:0]  data_count;
  reg    [15:0] delay_count;
  parameter     DELAY = 16'h4A8;
  parameter     BLOCK_DATA = 3*8*8;
  
  yuyv_to_yuv dut (
    .clk      (clk),
    .reset_n  (reset_n),
    
    .img_req  (img_req),
    
    .addr     (addr),
    .data     (data),
    
    .je_rd    (je_rd),
    .je_data  (je_data)  
  );

  initial
    begin
      clk = 0;
      reset_n = 0;
      img_req = 0;
      //je_rd = 0;
      #100
      reset_n = 1;
      #100
      img_req = 1;
      #1000
      img_req = 0;
    end
    
  always @ (*)
    #10 clk <= !clk;

  always @ (posedge clk)
    data <= #1 ~addr[7:0];
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        delay_count <= #1 DELAY;
      else
      if (delay_count == 16'h0000)
        delay_count <= #1 DELAY;
      else        
        delay_count <= #1 delay_count - 16'h0001;
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        data_count <= #1 8'h00;
      else
      if (delay_count == 16'h0000)
        data_count <= #1 BLOCK_DATA;
      else
      if (data_count != 8'h00)
        data_count <= #1 data_count - 8'h01;
      else
        data_count <= #1 data_count;      
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        je_rd <= #1 1'b0;
      else
      if (|data_count)
        je_rd <= #1 1'b1;
      else
        je_rd <= #1 1'b0;      
    end
  
endmodule