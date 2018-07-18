`timescale 1ns/1ns

module tb_jpeg_data_writer;

  reg             clk, reset_n, je_valid, je_done;
  reg    [7:0]    je_data;
  wire   [16:0]   addr;
  wire   [7:0]    data;
  wire            we;
  
  reg    [13:0]   valid_cnt;
  
  jpeg_data_writer dut (
    .clk        (clk),
    .reset_n    (reset_n),
    
    .je_valid   (je_valid),
    .je_data    (je_data),
    .je_done    (je_done),

    .addr       (addr),
    .data       (data),
    .we         (we)
    );
  
  initial
    begin
      clk = 0;
      reset_n = 0;
      je_valid = 0;
      je_done = 0;
      je_data = 8'h00;
      valid_cnt = 14'h0000;
      #100
      reset_n = 1;
    end
  
  always @ (*)
    #10 clk <= !clk;
    
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        valid_cnt <= #1 14'h0000;
      else
      if (je_valid)
        valid_cnt <= #1 valid_cnt + 14'h0001;
      else
        valid_cnt <= #1 valid_cnt;      
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          je_valid <= #1 1'b0;
          je_data  <= #1 8'h00;
        end
      else
      if (&valid_cnt)
        begin
          je_valid <= #1 1'b0;
          je_data  <= #1 8'h00;        
        end
      else        
        begin
          je_valid <= #1 {$random} % 2;
          je_data  <= #1 {$random} % 256;
        end        
    end
  
  always @ (posedge clk or negedge reset_n)  
    begin
      if (!reset_n)
        je_done <= #1 1'b0;
      else
      if (&valid_cnt)
        je_done <= #1 1'b1;
      else
        je_done <= #1 1'b0;      
    end
    
endmodule