`timescale 1ns/1ns

module tb_jpeg_data_to_spi;

  reg           clk, reset_n, je_done, spi_rd;
  reg    [7:0]  hd_data, je_data;
  wire   [16:0] je_addr;
  wire   [9:0]  hd_addr;
  wire   [7:0]  spi_data;
  
  reg    [7:0] header_rom [606:0];  
  reg    [7:0] je_mem [131071:0];
  integer      idx;
  
  reg          spi_can_rd;
  reg    [2:0] spi_rd_cnt;
  

  jpeg_data_to_spi dut (
    .clk      (clk),
    .reset_n  (reset_n),
    
    .je_done  (je_done),
    
    .hd_addr  (hd_addr),
    .hd_data  (hd_data),
    
    .je_addr  (je_addr),
    .je_data  (je_data),
    
    .spi_rd   (spi_rd),
    .spi_data (spi_data)
    );
  
  initial
    begin
      $readmemh("header_rom_data.h", header_rom);
      clk = 0;
      reset_n = 0;
      je_done = 0;
      spi_rd = 0;
      hd_data = 8'h00;
      je_data = 8'h00;
      for (idx = 0; idx <= 131071; idx = idx+1)
        je_mem[idx] = {$random}%256;
        
      je_mem[10240] = 8'hFF;
      je_mem[10241] = 8'hD9;      
      #100
      reset_n = 1;
      #200
      je_done = 1;
      #50
      je_done = 0;
    end
  
  always @ (*)
    #10 clk <= !clk;
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        hd_data <= #1 8'h00;
      else
        hd_data <= #1 header_rom[hd_addr];     
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        je_data <= #1 8'h00;
      else
        je_data <= #1 je_mem[je_addr];     
    end  
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        spi_can_rd <= #1 1'b0;
      else
      if (je_done)
        spi_can_rd <= #1 1'b1;
      else
        spi_can_rd <= #1 spi_can_rd;      
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        spi_rd_cnt <= #1 3'h0;
      else
      if (spi_can_rd)
        spi_rd_cnt <= #1 spi_rd_cnt + 3'h1;
      else
        spi_rd_cnt <= #1 spi_rd_cnt;   
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        spi_rd <= #1 1'b0;
      else
      if (&spi_rd_cnt)
        spi_rd <= #1 1'b1;
      else
        spi_rd <= #1 1'b0;      
    end
  
endmodule