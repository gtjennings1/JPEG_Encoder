`timescale 1ns/1ns

`define WIDTH (320)
`define HEIGHT (200)
`define BPP (2)

module jpeg_data_to_spi (
  input           clk,
  input           reset_n,
  
  input           je_done,
  
  input  [16:0]   jpeg_size,
  
  output [9:0]    hd_addr,
  input  [7:0]    hd_data,
  
  output [16:0]   je_addr,
  input  [7:0]    je_data,
  
  input           spi_rd,
  output [7:0]    spi_data
  );
  
  parameter       HEADER_SIZE = 607;
  parameter       EOI_MARKER  = 16'hFFD9;
  
  parameter       IDLE      = 0;
  parameter       JPG_SZ1   = 1;
  parameter       W_JPG_SZ1 = 2;
  parameter       JPG_SZ2   = 3;
  parameter       W_JPG_SZ2 = 4;
  parameter       JPG_SZ3   = 5;
  parameter       W_JPG_SZ3 = 6;
  parameter       RD_HDR    = 7;
  parameter       W_SPI_RD1 = 8;
  parameter       RD_JED    = 9;
  parameter       W_SPI_RD2 = 10;
  parameter       EOF       = 11;
  
  reg    [3:0]    c_state, n_state;
  reg    [9:0]    hd_addr_reg;
  reg    [16:0]   je_addr_reg;
  reg    [15:0]   eoi_reg;
  reg    [7:0]    spi_data_reg;
  
  reg             addr_lsb;
  reg   [2:0]     col_cnt, row_cnt;
  reg   [8:0]     col_idx, col_x;
  reg   [7:0]     row_idx, row_y;
  
  wire            col_max = (col_idx == (`WIDTH-1));
  wire            row_max = (row_idx == (`HEIGHT-1)); 
  
  wire            chg_col = addr_lsb && (c_state == RD_JED);
  wire            chg_row = ((&col_cnt) || (col_max)) && chg_col;
  wire            chg_blk = ((&row_cnt) || (row_max)) && chg_row;
  wire            rst_rcb = (c_state == IDLE);  
  
  wire            header_done = (hd_addr_reg == (HEADER_SIZE));
  wire            eoi = (eoi_reg == EOI_MARKER);
  
  assign          hd_addr = hd_addr_reg;
  assign          je_addr = je_addr_reg;
  assign          spi_data = eoi_reg[7:0];//spi_data_reg;
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        c_state <= #1 IDLE;
      else
        c_state <= #1 n_state;      
    end
  
  always @ (c_state, je_done, spi_rd, header_done, eoi)
    begin
      case (c_state)
        IDLE      : begin
                      if (je_done)
                        n_state <= #1 JPG_SZ1;//RD_HDR;
                      else
                        n_state <= #1 IDLE;                      
                    end
        JPG_SZ1   : begin
                      n_state <= #1 W_JPG_SZ1;
                    end   
        W_JPG_SZ1 : begin
                      if (spi_rd)
                        n_state <= #1 JPG_SZ2;
                      else
                        n_state <= #1 W_JPG_SZ1;                      
                    end
        JPG_SZ2   : begin
                      n_state <= #1 W_JPG_SZ2;                    
                    end
        W_JPG_SZ2 : begin
                      if (spi_rd)
                        n_state <= #1 JPG_SZ3;
                      else
                        n_state <= #1 W_JPG_SZ2;                       
                    end
        JPG_SZ3   : begin
                      n_state <= #1 W_JPG_SZ3;
                    end        
        W_JPG_SZ3 : begin
                      if (spi_rd)
                        n_state <= #1 RD_HDR;
                      else
                        n_state <= #1 W_JPG_SZ3;                      
                    end        
        RD_HDR    : begin
                      n_state <= #1 W_SPI_RD1;
                    end
        W_SPI_RD1 : begin
                      if (spi_rd)
                        if (header_done)
                          n_state <= #1 RD_JED;
                        else
                          n_state <= #1 RD_HDR;
                      else
                        n_state <= #1 W_SPI_RD1;                      
                    end
        RD_JED    : begin
                      n_state <= #1 W_SPI_RD2;
                    end
        W_SPI_RD2 : begin
                      if (spi_rd)
                        if (eoi)
                          n_state <= #1 EOF;
                        else
                          n_state <= #1 RD_JED;
                      else
                        n_state <= #1 W_SPI_RD2;                      
                    end
        EOF       : begin
                      n_state <= #1 IDLE;
                    end        
        default   : n_state <= #1 IDLE;
      endcase
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        hd_addr_reg <= #1 10'h000;
      else
        case (c_state)
          IDLE      : hd_addr_reg <= #1 10'h000;
          RD_HDR    : hd_addr_reg <= #1 hd_addr_reg + 10'h001;
          default   : hd_addr_reg <= #1 hd_addr_reg; 
        endcase        
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        eoi_reg <= #1 16'h0000;
      else
        case (c_state)
          IDLE      : eoi_reg <= #1 16'h0000;
          JPG_SZ1   : eoi_reg <= #1 {eoi_reg[7:0], 7'h00, jpeg_size[16]};
          JPG_SZ2   : eoi_reg <= #1 {eoi_reg[7:0], jpeg_size[15:8]};
          JPG_SZ3   : eoi_reg <= #1 {eoi_reg[7:0], jpeg_size[7:0]};
          RD_HDR    : eoi_reg <= #1 {eoi_reg[7:0], hd_data};
          RD_JED    : eoi_reg <= #1 {eoi_reg[7:0], je_data};
          default   : eoi_reg <= #1 eoi_reg;
        endcase        
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        spi_data_reg <= #1 8'h00;
      else
      if (c_state == RD_HDR)
        spi_data_reg <= #1 hd_data;
      //if (spi_rd)
      //  spi_data_reg <= #1 eoi_reg[7:0];
      else
        spi_data_reg <= #1 spi_data_reg;      
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        addr_lsb <= #1 1'b0;
      else
        case (c_state)
          IDLE      : addr_lsb <= #1 1'b0;
          RD_JED    : addr_lsb <= #1 !addr_lsb;
          default   : addr_lsb <= #1 addr_lsb;
        endcase        
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        col_cnt <= #1 3'h0;
      else
        case ({rst_rcb, col_max, chg_col})
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
        case ({rst_rcb, row_max, chg_row})
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
          col_idx <= #1 9'h000;
          col_x   <= #1 9'h000;
          row_idx <= #1 8'h00;
          row_y   <= #1 8'h00;
        end
      else
      if (rst_rcb)
        begin
          col_idx <= #1 9'h000;
          col_x   <= #1 9'h000;
          row_idx <= #1 8'h00;
          row_y   <= #1 8'h00;        
        end
      else  
        begin
          col_idx <= #1 col_idx;
          col_x   <= #1 col_x;
          row_idx <= #1 row_idx;
          row_y   <= #1 row_y; 
          case ({/*rst_rcb, */row_max, col_max, chg_blk, chg_row, chg_col})
            5'h01     : col_idx <= #1 col_idx + 9'h001;
            5'h03,
            5'h0B     : begin
                          col_idx <= #1 col_x;
                          row_idx <= #1 row_idx + 8'h01;
                        end
            5'h07     : begin
                          col_idx <= #1 col_x + 9'h008;
                          col_x   <= #1 col_x + 9'h008;
                          row_idx <= #1 row_y;
                        end
            5'h0F     : begin
                          col_idx <= #1 9'h000;
                          col_x   <= #1 9'h000;
                          row_idx <= #1 row_y + 8'h08;
                          row_y   <= #1 row_y + 8'h08;
                        end
            //6'h1F,
            //6'h20,
            5'h1F     : begin
                          col_idx <= #1 9'h000;
                          col_x   <= #1 9'h000;
                          row_idx <= #1 8'h00;
                          row_y   <= #1 8'h00;                          
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
        je_addr_reg <= #1 17'h00000;
      else
        je_addr_reg <= #1 ({(row_idx*`WIDTH),1'b0}) + ({col_idx,addr_lsb});      
    end
  
endmodule  