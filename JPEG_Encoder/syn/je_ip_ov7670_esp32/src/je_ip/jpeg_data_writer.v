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
`timescale 1ns/1ns

//`define WIDTH (320)
//`define HEIGHT (200)
//`define BPP (2)

module jpeg_data_writer #(
  parameter WIDTH  = 320,
  parameter HEIGHT = 200,
  parameter WSZ = 9,
  parameter HSZ = 8,
  parameter ASZ = 17
  )(
  input           clk,
  input           reset_n,
  
  input           je_valid,
  input  [7:0]    je_data,
  input           je_done,

  output [(ASZ-1):0]   addr,
  output [7:0]    data,
  output          we
  ); 

  reg             addr_lsb;
  reg   [2:0]     col_cnt, row_cnt;
  reg   [(WSZ-1):0]     col_idx, col_x;
  reg   [(HSZ-1):0]     row_idx, row_y;
  
  reg   [(ASZ-1):0]    addr_reg;
  reg   [7:0]     data_reg;
  reg             we_reg;

  wire            col_max = (col_idx == (WIDTH-1));
  wire            row_max = (row_idx == (HEIGHT-1)); 
  
  wire            chg_col = addr_lsb && je_valid;
  wire            chg_row = ((&col_cnt) || (col_max)) && chg_col;
  wire            chg_blk = ((&row_cnt) || (row_max)) && chg_row;
 
  assign          addr = addr_reg;
  assign          data = data_reg;
  assign          we   = we_reg;
  

  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        addr_lsb <= #1 1'b0;
      else
        case({je_done, je_valid})      
          2'h1      : addr_lsb <= #1 !addr_lsb;
          2'h2,
          2'h3      : addr_lsb <= #1 1'b0;
          default   : addr_lsb <= #1 addr_lsb;
        endcase  
    end

  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        col_cnt <= #1 3'h0;
      else
        case ({je_done, col_max, chg_col})
          3'h1      : col_cnt <= #1 col_cnt + 3'h1;
          3'h3,
          3'h4,
          3'h5,
          3'h6,
          3'h7      : col_cnt <= #1 3'h0;
          default   : col_cnt <= #1 col_cnt;
        endcase        
    end

  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        row_cnt <= #1 3'h0;
      else
        case ({je_done, row_max, chg_row})
          3'h1      : row_cnt <= #1 row_cnt + 3'h1;
          3'h3,
          3'h4,
          3'h5,
          3'h6,
          3'h7      : row_cnt <= #1 3'h0;
          default   : row_cnt <= #1 row_cnt;
        endcase        
    end
    
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          col_idx <= #1 {WSZ{1'b0}};//9'h000;
          col_x   <= #1 {WSZ{1'b0}};//9'h000;
          row_idx <= #1 {HSZ{1'b0}};//8'h00;
          row_y   <= #1 {HSZ{1'b0}};//8'h00;
        end
      else
        begin
          col_idx <= #1 col_idx;
          col_x   <= #1 col_x;
          row_idx <= #1 row_idx;
          row_y   <= #1 row_y; 
          case ({je_done, row_max, col_max, chg_blk, chg_row, chg_col})
            6'h01     : col_idx <= #1 col_idx + {{(WSZ-1){1'b0}}, {1'b1}};//9'h001;
            6'h03,
            6'h0B     : begin
                          col_idx <= #1 col_x;
                          row_idx <= #1 row_idx + {{(HSZ-1){1'b0}}, {1'b1}};//8'h01;
                        end
            6'h07     : begin
                          col_idx <= #1 col_x + {{(WSZ-4){1'b0}}, {4'h8}};//9'h008;
                          col_x   <= #1 col_x + {{(WSZ-4){1'b0}}, {4'h8}};//9'h008;
                          row_idx <= #1 row_y;
                        end
            6'h0F     : begin
                          col_idx <= #1 {WSZ{1'b0}};//9'h000;
                          col_x   <= #1 {WSZ{1'b0}};//9'h000;
                          row_idx <= #1 row_y + {{(HSZ-4){1'b0}}, {4'h8}};//8'h08;
                          row_y   <= #1 row_y + {{(HSZ-4){1'b0}}, {4'h8}};//8'h08;
                        end
            6'h1F,
            6'h20,
            6'h3F     : begin
                          col_idx <= #1 {WSZ{1'b0}};//9'h000;
                          col_x   <= #1 {WSZ{1'b0}};//9'h000;
                          row_idx <= #1 {HSZ{1'b0}};//8'h00;
                          row_y   <= #1 {HSZ{1'b0}};//8'h00;                          
                        end            
            default   : begin
                          col_idx <= #1 col_idx;
                          col_x   <= #1 col_x;
                          row_idx <= #1 row_idx;
                          row_y   <= #1 row_y;             
                        end
          endcase          
        end        
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        addr_reg <= #1 {ASZ{1'b0}};//17'h00000;
      else
//        addr_reg <= #1 ({(row_idx*`WIDTH),1'b0}) + ({col_idx,addr_lsb});      
        addr_reg <= #1 ({(row_idx*WIDTH),1'b0}) + ({col_idx,addr_lsb});      
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          data_reg <= #1 8'h00;
          we_reg   <= #1 1'b0;
        end
      else
        begin
          data_reg <= #1 je_data;
          we_reg   <= #1 je_valid;
        end
    end
  
endmodule  