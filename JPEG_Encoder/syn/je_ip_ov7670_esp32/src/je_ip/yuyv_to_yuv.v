`timescale 1ns/1ns

//`define WIDTH  (320)
//`define HEIGHT (200)
//`define BPP    (2)

module yuyv_to_yuv #(
  parameter WIDTH  = 320,
  parameter HEIGHT = 200,
  parameter WSZ = 9,
  parameter HSZ = 8,
  parameter ASZ = 17
  )(
  input         clk,
  input         reset_n,
  
  input         img_req,
  
  output [(ASZ-1):0] addr,
  input  [7:0]  data,
  
  input         mem_wr,
  //input         jedf_empty,
  //output        mem_rd,
  output        mem_wr_acc,
  
  output        ready,
  
  input         je_rd,
  output [7:0]  je_data  
  );
  
  localparam      IDLE      = 0;
  localparam      CHECK_FF  = 1;
  localparam      FETCH_Y0  = 2;
  localparam      FETCH_U01 = 3;
  localparam      FETCH_Y1  = 4;
  localparam      FETCH_V01 = 5;
  localparam      CHECK_EOF = 6;
  localparam      WAIT_1C   = 7;
  localparam      WRITE_Y0  = 8;
  localparam      WRITE_U0  = 9;
  localparam      WRITE_V0  = 10;
  localparam      WRITE_Y1  = 11;
  localparam      WRITE_U1  = 12;
  localparam      WRITE_V1  = 13;
  localparam      IS_EOF    = 14;  
  
  
  reg    [3:0]   c_state, n_state;
  reg    [(WSZ-1):0]   img_col, img_x/*, img_col_fl0, img_col_fl1, img_col_fl2, img_col_fl3*/;
  reg    [(HSZ-1):0]   img_row, img_y;
  reg    [(ASZ-1):0]  addr_reg;
  
  reg    [2:0]   col_cnt, row_cnt;
  reg            addr_lsb, last_blk;
  reg    [1:0]   img_req_reg;
  
  reg    [31:0]  yuyv;
  reg            ff_wr;
  reg    [7:0]   ff_din;
  
  reg            eof;
  //reg    [23:0]  const_color;
  // reg    [1:0]   mem_wr_fl;
  
  //reg            mem_rd_acc;
  
  wire           reset = !reset_n;
  wire   [9:0]   fifo_level;
  wire           fetch_memory = ((fifo_level < (512-10)) && (!mem_wr));/* && jedf_empty*/
  //wire           block_available = (fifo_level > (191));
  
//  wire           col_max = (img_col == (`WIDTH-1));
//  wire           row_max = (img_row == (`HEIGHT-1));
  wire           col_max = (img_col == (WIDTH-1));
  wire           row_max = (img_row == (HEIGHT-1));
  
  wire           addr_inc = addr_lsb;// && (!mem_wr);
  
  wire           row_chg = (&col_cnt) && (addr_inc);
  wire           blk_chg = (&row_cnt) && row_chg;
  wire           img_req_pe = (img_req_reg[0] && (!img_req_reg[1]));
  
  assign         addr = addr_reg;
  assign         ready = blk_chg;//block_available;
  //assign         mem_rd = mem_rd_acc;
  assign         mem_wr_acc = (ff_wr || (c_state == IDLE));
  //assign         je_data = const_color[23:16];
  
  sc_fifo yuv_fifo (
    .data_in        (ff_din), 
    .data_out       (je_data), 
    .clk            (clk), 
    .reset          (reset), 
    .write          (ff_wr), 
    .read           (je_rd), 
    .clear          (1'b0),
    .almost_full    (), 
    .full           (), 
    .almost_empty   (),   
    .empty          (), 
    .cnt            (fifo_level)
  );
  
  // always @ (posedge clk or negedge reset_n)
    // begin
      // if (!reset_n)
        // mem_wr_fl <= #1 2'b00;
      // else
        // mem_wr_fl <= #1 {mem_wr_fl[0], mem_wr};        
    // end
  /*
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        const_color <= #1 24'h7FD4CC;
      else
      if (je_rd)
        const_color <= #1 {const_color[7:0], const_color[23:8]};
      else
        const_color <= #1 24'h7FD4CC;//const_color;      
    end
  */
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        img_req_reg <= #1 2'h0;
      else
        img_req_reg <= #1 {img_req_reg[0], img_req};      
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        c_state <= #1 IDLE;
      else
        c_state <= #1 n_state;      
    end
  
  always @ (c_state, img_req_pe, fetch_memory, eof /*, mem_wr*/)
    begin
      case (c_state)
        IDLE      : begin
                      if (img_req_pe)
                        n_state <= #1 CHECK_FF;
                      else
                        n_state <= #1 IDLE;                      
                    end
        CHECK_FF  : begin
                      if (fetch_memory)
                        n_state <= #1 FETCH_Y0;
                      else
                        n_state <= #1 CHECK_FF;                      
                    end
        FETCH_Y0  : begin
                      // if (mem_wr)
                        // n_state <= #1 FETCH_Y0;
                      // else  
                        n_state <= #1 FETCH_U01;
                    end  
        FETCH_U01 : begin
                      // if (mem_wr)
                        // n_state <= #1 FETCH_U01;
                      // else  
                        n_state <= #1 FETCH_Y1;
                    end  
        FETCH_Y1  : begin
                      // if (mem_wr)
                        // n_state <= #1 FETCH_Y1;
                      // else  
                        n_state <= #1 FETCH_V01;
                    end  
        FETCH_V01 : begin
                      // if (mem_wr)
                        // n_state <= #1 FETCH_V01;
                      // else  
                        n_state <= #1 CHECK_EOF;
                    end  
        CHECK_EOF : begin
                      // if (mem_wr)
                        // n_state <= #1 CHECK_EOF;
                      // else  
                        n_state <= #1 WAIT_1C;
                    end  
        WAIT_1C   : begin
                      // if (mem_wr)
                        // n_state <= #1 WAIT_1C;
                      // else  
                        n_state <= #1 WRITE_Y0;
                    end  
        WRITE_Y0  : n_state <= #1 WRITE_U0;
        WRITE_U0  : n_state <= #1 WRITE_V0;
        WRITE_V0  : n_state <= #1 WRITE_Y1;
        WRITE_Y1  : n_state <= #1 WRITE_U1;
        WRITE_U1  : n_state <= #1 WRITE_V1;
        WRITE_V1  : n_state <= #1 IS_EOF;
        IS_EOF    : begin
                      if (eof)
                        n_state <= #1 IDLE;
                      else
                        n_state <= #1 CHECK_FF;                      
                    end  
        default   : n_state <= #1 IDLE;
      endcase
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        addr_lsb <= #1 1'b0;
      else
        case(c_state)
          IDLE      : addr_lsb <= #1 1'b0;
          FETCH_Y0,
          FETCH_U01,
          FETCH_Y1,
          FETCH_V01 : begin
                        // if (mem_wr)
                          // addr_lsb <= #1 addr_lsb;
                        // else  
                          addr_lsb <= #1 !addr_lsb;
                      end  
          default   : addr_lsb <= #1 addr_lsb;
        endcase        
    end
  /*
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        mem_rd_acc <= #1 1'b0;
      else
        case (c_state)
          FETCH_Y0,
          FETCH_U01,
          FETCH_Y1,
          FETCH_V01,
          CHECK_EOF,
          WAIT_1C   : mem_rd_acc <= #1 1'b1;
          default   : mem_rd_acc <= #1 1'b0;
        endcase        
    end
  */
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          img_col <= #1 {WSZ{1'b0}};//9'h000;
          img_x   <= #1 {WSZ{1'b0}};//9'h000;
          img_row <= #1 {HSZ{1'b0}};//8'h00;
          img_y   <= #1 {HSZ{1'b0}};//8'h00;
          last_blk<= #1 1'b0;
        end
      else
        begin
          img_col <= #1 img_col;
          img_x   <= #1 img_x;
          img_row <= #1 img_row;
          img_y   <= #1 img_y;
          last_blk<= #1 1'b0;          
          case ({row_max, col_max, blk_chg, row_chg, addr_inc})
            5'h01,
            5'h11     : img_col <= #1 img_col + {{(WSZ-1){1'b0}}, {1'b1}};//9'h001;
            5'h03,
            5'h0B     : begin
                          img_col <= #1 img_x;
                          img_row <= #1 img_row + {{(HSZ-1){1'b0}}, {1'b1}};//8'h01;
                        end
            5'h07,
            5'h17     : begin
                          img_col <= #1 img_x + {{(WSZ-4){1'b0}}, {4'h8}};//9'h008;
                          img_x   <= #1 img_x + {{(WSZ-4){1'b0}}, {4'h8}};//9'h008;
                          img_row <= #1 img_y;
                        end  
            5'h0F     : begin
                          img_col <= #1 {WSZ{1'b0}};//9'h000;
                          img_x   <= #1 {WSZ{1'b0}};//9'h000;
                          img_row <= #1 img_y + {{(HSZ-4){1'b0}}, {4'h8}};//8'h08;
                          img_y   <= #1 img_y + {{(HSZ-4){1'b0}}, {4'h8}};//8'h08;
                        end
            5'h1F     : begin
                          img_col <= #1 {WSZ{1'b0}};//9'h000;
                          img_x   <= #1 {WSZ{1'b0}};//9'h000;
                          img_row <= #1 {HSZ{1'b0}};//8'h00;
                          img_y   <= #1 {HSZ{1'b0}};//8'h00;
                          last_blk<= #1 1'b1;                          
                        end            
            default   : begin
                          img_col <= #1 img_col;
                          img_x   <= #1 img_x;
                          img_row <= #1 img_row;
                          img_y   <= #1 img_y;
                          last_blk<= #1 1'b0;                          
                        end
          endcase
        end        
    end 
    
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        col_cnt <= #1 3'h0;
      else
      if (addr_inc)
        col_cnt <= #1 col_cnt + 3'h1;
      else
        col_cnt <= #1 col_cnt;      
    end 

  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        row_cnt <= #1 3'h0;
      else
      if (row_chg)
        row_cnt <= #1 row_cnt + 3'h1;
      else
        row_cnt <= #1 row_cnt;      
    end    
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        addr_reg <= #1 {ASZ{1'b0}};//17'h00000;
      // else
      // if (mem_wr)
        // addr_reg <= #1 addr_reg;
      else  
        //addr_reg <= #1 ({(img_row*`WIDTH),1'b0}) + ({img_col,addr_lsb});   
        addr_reg <= #1 ({(img_row*WIDTH),1'b0}) + ({img_col,addr_lsb});   
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        eof <= #1 1'b0;
      else
        case (c_state)
          IDLE      : eof <= #1 1'b0;
          CHECK_EOF : eof <= #1 last_blk;
          default   : eof <= #1 eof;
        endcase        
    end
 /* 
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          img_col_fl0 <= #1 9'h000;
          img_col_fl1 <= #1 9'h000;
          img_col_fl2 <= #1 9'h000;
          img_col_fl3 <= #1 9'h000;        
        end
      else
        begin
          img_col_fl0 <= #1 img_col;
          img_col_fl1 <= #1 img_col_fl0;
          img_col_fl2 <= #1 img_col_fl1;
          img_col_fl3 <= #1 img_col_fl2;
        end        
    end
 */ 
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        yuyv <= #1 32'h00000000;
      else
        case (c_state)
          IDLE      : yuyv <= #1 32'h00000000;
          //FETCH_U01,
          FETCH_Y1,
          FETCH_V01,
          CHECK_EOF,
          WAIT_1C   : begin
                        
                        //if (mem_wr)
                        // if (mem_wr_fl[0])
                          // yuyv <= #1 yuyv;
                        // else  
                          yuyv <= #1 {!data[7], data[6:0], yuyv[31:8]};//32'h7FCCD4CC;//
                        /*                     
                        if (img_col_fl3 < 9'd80)
                          yuyv <= #1 32'h70D2DAD2;//32'hF0525A52;
                        else
                        if (img_col_fl3 < 9'd160)
                          yuyv <= #1 32'hA211B611;//32'h22913691;
                        else
                        if (img_col_fl3 < 9'd240) 
                          yuyv <= #1 32'hEEA970A9;//32'h6E29F029;
                        else
                          yuyv <= #1 32'h006B006B;//32'h80EB80EB;
                        */                          
                      end  
          default   : yuyv <= #1 yuyv;
        endcase        
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          ff_din <= #1 8'h00;
          ff_wr  <= #1 1'b0;
        end
      else
        begin
          ff_din <= #1 ff_din;
          ff_wr  <= #1 1'b0;
          case (c_state)
            IDLE      : ff_din <= #1 8'h00;
            WRITE_Y0  : begin
                         ff_din <= #1 yuyv[7:0];//yuyv[15:8];//
                         ff_wr  <= #1 1'b1; 
                        end
            WRITE_U0,
            WRITE_U1  : begin
                         ff_din <= #1 yuyv[15:8];//yuyv[7:0];//
                         ff_wr  <= #1 1'b1;             
                        end
            WRITE_Y1  : begin
                         ff_din <= #1 yuyv[23:16];//yuyv[31:24];//
                         ff_wr  <= #1 1'b1;                           
                        end
            WRITE_V0,
            WRITE_V1  : begin
                         ff_din <= #1 yuyv[31:24];//yuyv[23:16];//
                         ff_wr  <= #1 1'b1;
                        end            
            default   : ff_din <= #1 ff_din;
          endcase
        end        
    end
  
endmodule  