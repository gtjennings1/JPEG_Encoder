`timescale 1ns/1ns

`define WIDTH   (1024)
`define HEIGHT  (768)
`define COLORS  (3)
`define QUALITY (90)

`define QUAL1   (`QUALITY ? `QUALITY : 90)
`define QUAL2   ((`QUAL1 < 1) ? 1 : (`QUAL1 > 100) ? 100 : `QUAL1)
`define QUAL3   ((`QUAL2 < 50) ? 5000/`QUAL2 : 200 - `QUAL2*2)

module jpeg_enc (
  input           clk,
  input           reset_n,
  input           conv_en,
  input  [7:0]    fb_data,
  output [21:0]   fb_addr,
  output [7:0]    img_out,
  output          img_valid,
  output          img_done,
  );
  
  
  reg    [7:0]    img_out_reg;
  reg             img_valid_reg;
  reg             img_done_reg;
  reg    [11:0]   byte_count;
  
  reg signed   [7:0]    YDU [63:0];
  reg signed   [7:0]    UDU [63:0];
  reg signed   [7:0]    VDU [63:0];
  
  reg signed   [17:0]   DCT_DU [63:0];
  reg signed   [14:0]   ZIG_DU [63:0];
  reg signed   [14:0]   QNT_DU;
  //reg signed   [13:0]   DCT_UDU [63:0];
  //reg signed   [13:0]   DCT_VDU [63:0]; 

  reg signed   [16:0]   tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7,
                        tmp10, tmp11, tmp12, tmp13, tmp20, tmp21, tmp22;
  reg signed   [16:0]   z1, z2, z3, z4, z5, z11, z13; 

  reg    [1:0]    dct_comp_sel;
  reg    [5:0]    dct_comp_idx[7:0];
  reg    [3:0]    dct_idx_cnt;
  reg signed   [14:0]   DCY, DCU, DCV, diff_DC;  
  
  reg    [10:0]   img_x, img_col;
  reg    [9:0]    img_y, img_row;
  reg    [1:0]    img_col_p;
  reg    [1:0]    img_col_p_fl1;
  reg    [1:0]    img_col_p_fl2;
  reg    [2:0]    col_cnt, row_cnt;
  reg    [2:0]    col_cnt_fl1, row_cnt_fl1;
  reg    [2:0]    col_cnt_fl2, row_cnt_fl2;
  reg    [1:0]    load_du_done_fl;
  reg    [5:0]    qz_cnt;
  
  reg    [7:0]    c_state, n_state, b_state;
  reg    [21:0]   fb_addr_reg;
  
  reg    [4:0]    wb_bit_cnt, wb_bc_tmp;
  reg    [23:0]   wb_bit_buf, wb_bb_tmp;
  reg    [7:0]    wb_c;
  
  reg    [12:0]   cb_bb_mask, cb_bit_buf, cb_bb_tmp;
  reg    [4:0]    cb_bit_cnt;
  
  reg    [5:0]    end0pos;
  reg signed   [14:0]   du_e0p, du_ac0;
  reg    [7:0]    ac_idx;
  reg    [6:0]    ac0_idx;
  reg    [5:0]    ac0_cnt;
  reg             last_du, last_du_p;
  
  
  assign img_out    = img_out_reg;
  assign img_valid  = img_valid_reg;
  assign img_done   = img_done_reg;	 
  assign fb_addr    = fb_addr_reg;
  
  parameter       IDLE      = 0;
  parameter       TX_HEADER = 1;
  parameter       LOAD_DU   = 2;
  parameter       WAIT_DU   = 3;
  parameter       COMP_SEL  = 4;
  parameter       DCT_P1    = 5;
  parameter       DCT_P2    = 6;
  parameter       DCT_P3    = 7;
  parameter       DCT_P4    = 8;
  parameter       DCT_P5    = 9;
  parameter       DCT_P6    = 10;
  parameter       DCT_P7    = 11;
  parameter       QUANTIZE  = 12;
  parameter       ZIGZAG    = 13;
  parameter       DIFF_DC   = 14;
  parameter       CHK_DIFF  = 15;
  parameter       WB_HTDC0  = 16;
  parameter       WR_BITS   = 17;
  parameter       WB_STEP1  = 18;
  parameter       WB_STEP2  = 19;
  parameter       WB_STEP3  = 20;
  parameter       WB_STEP4  = 21;
  parameter       WB_STEP5  = 22;
  parameter       WB_NSTATE = 23; 
  parameter       CB_DIFF   = 24;
  parameter       CALC_BITS = 25;
  parameter       CB_STEP1  = 26;
  parameter       CB_NSTATE = 27;
  parameter       WB_HTDCB1 = 28; 
  parameter       WB_DIFFB  = 29;
  parameter       FIND_TR0  = 30;
  parameter       CHECK_ELM = 31;
  parameter       DEC_E0P   = 32;  
  parameter       CHECK_E0P = 33;
  parameter       ENC_AC    = 34;
  parameter       FIND_AC0  = 35;
  parameter       CHECK_AC0 = 36;
  parameter       INC_AC0   = 37;
  parameter       CHK_NRZ16 = 38;
  parameter       WB_M16B   = 39;
  parameter       CHK_M16B  = 40;
  parameter       CB_DUAC   = 41;
  parameter       PREP_ACIDX= 42;
  parameter       WB_HTAC   = 43;
  parameter       WB_DUAC   = 44;
  parameter       CHK_ACIDX = 45;
  parameter       CHK_EOP63 = 46;
  parameter       WB_EOB    = 47;
  parameter       EXIT_PROC = 48;
  parameter       CHECK_EOF = 49;
  parameter       WB_EOI    = 50;
  parameter       EOI1      = 51;
  parameter       EOI2      = 52;
  parameter       CONV_DONE = 53;
  
`include "jpeg_enc_inc.v"

  wire            header_tx_done = (byte_count == (HEADER_SIZE-1));
  
  wire            inc_img_col_p = (c_state == LOAD_DU);
  wire            rst_img_col_p = (img_col_p == 2'h2);
  wire            col_max = (img_col == (`WIDTH-1));
  wire            row_max = (img_row == (`HEIGHT-1));
  wire            inc_row_cnt = (&col_cnt) && rst_img_col_p;
  wire            load_du_done = (&col_cnt) && (&row_cnt) && rst_img_col_p;
  wire            dct_done = ((c_state == DCT_P7) && (dct_idx_cnt == 4'hF));// && (dct_comp_sel == 2'h2));
  wire            qz_done = &qz_cnt;
  wire            diff_dc_zero = !(|diff_DC);
  wire            diff_dc_neg  = diff_DC[14];
  wire            bit_cnt_gte_8 = |wb_bit_cnt[4:3];
  wire            byte_out_eq_255 = &wb_bit_buf[23:16];
  wire            check_next_element = ((end0pos != 6'h00) && (du_e0p == 14'h0000)); 
  wire            e0p_zero = (end0pos == 6'h00);
  wire            inc_ac0_idx = (ac0_idx <= end0pos);
  wire            inc_ac0_cnt = (inc_ac0_idx && (du_ac0 == 14'h0000));
  wire            ac0_cnt_gte_16 = |ac0_cnt[5:4];
  wire            e0p_ne_63 = (end0pos != 6'h3F);
  wire            du_ac_neg = du_ac0[14];
  wire            last_comp = (dct_comp_sel == 2'h2);
  

  //Main State Machine Current State
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        c_state <= #1 IDLE;
      else
        c_state <= #1 n_state;      
    end
  
  //Main State Machine Next State  
  always @ (c_state, conv_en, header_tx_done, load_du_done_fl, load_du_done_fl[1], dct_done, qz_done, diff_dc_zero, b_state, bit_cnt_gte_8, byte_out_eq_255,
            check_next_element, e0p_zero, inc_ac0_idx, inc_ac0_cnt, ac0_cnt_gte_16, e0p_ne_63, last_comp, last_du)
    case(c_state)
      IDLE        : begin
                      if (conv_en)
                        n_state <= #1 TX_HEADER;//LOAD_DU;//
                      else
                        n_state <= #1 IDLE;
                    end    
      TX_HEADER   : begin
                      if (header_tx_done)
                        n_state <= #1 LOAD_DU;
                      else
                        n_state <= #1 TX_HEADER;
                    end
      LOAD_DU     : begin
                      if (load_du_done)
                        n_state <= #1 WAIT_DU;
                      else
                        n_state <= #1 LOAD_DU;                      
                    end      
      WAIT_DU     : begin
                      if (load_du_done_fl[1])
                        n_state <= #1 COMP_SEL;
                      else
                        n_state <= #1 LOAD_DU;                      
                    end
      COMP_SEL    : n_state <= #1 DCT_P1;
      DCT_P1      : n_state <= #1 DCT_P2;
      DCT_P2      : n_state <= #1 DCT_P3;
      DCT_P3      : n_state <= #1 DCT_P4;
      DCT_P4      : n_state <= #1 DCT_P5;
      DCT_P5      : n_state <= #1 DCT_P6;
      DCT_P6      : n_state <= #1 DCT_P7;
      DCT_P7      : begin
                      if (dct_done)
                        n_state <= #1 QUANTIZE;
                      else
                        n_state <= #1 COMP_SEL;                      
                    end
      QUANTIZE    : n_state <= #1 ZIGZAG;
      ZIGZAG      : begin
                      if (qz_done)
                        n_state <= #1 DIFF_DC;
                      else
                        n_state <= #1 QUANTIZE;
                    end  
      DIFF_DC     : n_state <= #1 CHK_DIFF;
      CHK_DIFF    : begin
                      if (diff_dc_zero)
                        n_state <= #1 WB_HTDC0;
                      else
                        n_state <= #1 CB_DIFF;
                    end
      WB_HTDC0    : n_state <= #1 WR_BITS;
      WR_BITS     : n_state <= #1 WB_STEP1;
      WB_STEP1    : n_state <= #1 WB_STEP2;
      WB_STEP2    : n_state <= #1 WB_STEP3;
      WB_STEP3    : begin
                      if (bit_cnt_gte_8)
                        n_state <= #1 WB_STEP4;
                      else
                        n_state <= #1 WB_NSTATE;                      
                    end
      WB_STEP4    : begin
                     if (byte_out_eq_255)
                       n_state <= #1 WB_STEP5;
                     else
                       n_state <= #1 WB_STEP3;                     
                    end      
      WB_STEP5    : n_state <= #1 WB_STEP3;
      WB_NSTATE   : n_state <= #1 b_state; 
      CB_DIFF     : n_state <= #1 CALC_BITS;
      CALC_BITS   : n_state <= #1 CB_STEP1;
      CB_STEP1    : n_state <= #1 CB_NSTATE;
      CB_NSTATE   : n_state <= #1 b_state; 
      WB_HTDCB1   : n_state <= #1 WR_BITS;
      WB_DIFFB    : n_state <= #1 WR_BITS;
      FIND_TR0    : n_state <= #1 CHECK_ELM;
      CHECK_ELM   : begin
                      if (check_next_element)
                        n_state <= #1 DEC_E0P;
                      else
                        n_state <= #1 CHECK_E0P;                      
                    end      
      DEC_E0P     : n_state <= #1 FIND_TR0;
      CHECK_E0P   : begin
                      if (e0p_zero)
                        n_state <= #1 WB_EOB;
                      else
                        n_state <= #1 ENC_AC;
                    end
      ENC_AC      : n_state <= #1 FIND_AC0;
      FIND_AC0    : n_state <= #1 CHECK_AC0;
      CHECK_AC0   : begin
                      if (inc_ac0_cnt)
                        n_state <= #1 INC_AC0;
                      else
                        n_state <= #1 CHK_NRZ16;                      
                    end
      INC_AC0     : n_state <= #1 FIND_AC0;
      CHK_NRZ16   : begin
                      if (ac0_cnt_gte_16)
                        n_state <= #1 WB_M16B;      
                      else
                        n_state <= #1 CB_DUAC;                      
                    end      
      WB_M16B     : n_state <= #1 WR_BITS;
      CHK_M16B    : begin
                      if (ac0_cnt_gte_16)
                        n_state <= #1 WB_M16B;
                      else
                        n_state <= #1 CB_DUAC;                      
                    end      
      CB_DUAC     : n_state <= #1 CALC_BITS;
      PREP_ACIDX  : n_state <= #1 WB_HTAC;
      WB_HTAC     : n_state <= #1 WR_BITS;
      WB_DUAC     : n_state <= #1 WR_BITS;
      CHK_ACIDX   : begin
                      if (inc_ac0_idx)
                        n_state <= #1 FIND_AC0;
                      else
                        n_state <= #1 CHK_EOP63;                   
                    end
      CHK_EOP63   : begin
                      if (e0p_ne_63)
                        n_state <= #1 WB_EOB;
                      else
                        n_state <= #1 EXIT_PROC;                      
                    end      
      WB_EOB      : n_state <= #1 WR_BITS; 
      EXIT_PROC   : begin
                      if (last_comp)
                        n_state <= #1 CHECK_EOF;
                      else
                        n_state <= #1 COMP_SEL;                      
                    end
      CHECK_EOF   : begin
                      if (last_du)
                        n_state <= #1 WB_EOI;
                      else
                        n_state <= #1 LOAD_DU;                      
                    end 
      WB_EOI      : n_state <= #1 WR_BITS;
      EOI1        : n_state <= #1 EOI2;
      EOI2        : n_state <= #1 CONV_DONE;      
      CONV_DONE   : n_state <= #1 IDLE;                      
      default     : n_state <= #1 IDLE;
    endcase    
  
  //Handle Data Output
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          byte_count <= #1 12'h000;
          img_out_reg <= #1 8'h00;
          img_valid_reg <= #1 1'b0;
          img_done_reg <= #1 1'b0;
        end
      else
        begin
          byte_count <= #1 12'h000;
          img_out_reg <= #1 8'h00;
          img_valid_reg <= #1 1'b0;
          img_done_reg <= #1 1'b0;
          case (c_state)
            TX_HEADER   : begin
                            byte_count <= #1 byte_count + 12'h001;
                            img_out_reg <= #1 header_rom[byte_count];
                            img_valid_reg <= #1 1'b1;
                          end
            WB_STEP4    : begin
                            img_out_reg <= #1 wb_bit_buf[23:16];
                            img_valid_reg <= #1 1'b1;
                          end
            WB_STEP5    : begin
                            img_valid_reg <= #1 1'b1;
                          end 
            EOI1        : begin
                            img_out_reg <= #1 8'hFF;
                            img_valid_reg <= #1 1'b1;            
                          end
            EOI2        : begin
                            img_out_reg <= #1 8'hD9;
                            img_valid_reg <= #1 1'b1;            
                          end            
            CONV_DONE   : img_done_reg <= #1 1'b1;    
                        
          endcase          
        end        
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        fb_addr_reg <= #1 22'h000000;
      else
        fb_addr_reg <= #1 (img_row*`WIDTH*`COLORS) + (img_col*`COLORS) + img_col_p;      
    end
  
  //Handle frame buffer addressing through index counters
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          img_x   <= #1 11'h000;
          img_col <= #1 11'h000;
          img_y   <= #1 10'h000;
          img_row <= #1 10'h000;
          last_du_p <= #1 1'b0;
        end
      else
        begin
          img_x   <= #1 img_x;
          img_col <= #1 img_col;
          img_y   <= #1 img_y;
          img_row <= #1 img_row;
          last_du_p <= #1 1'b0;          
          case ({load_du_done, row_max, col_max, inc_row_cnt, rst_img_col_p})
            5'h01,
            5'h09   : img_col <= #1 img_col + 11'h001;
            5'h03,
            5'h07   : begin
                        img_col <= #1 img_x;
                        img_row <= #1 img_row + 10'h001;
                      end  
            5'h13,          
            5'h1B   : begin
                        img_col <= #1 img_x + 11'h008;
                        img_x   <= #1 img_x + 11'h008;
                        img_row <= #1 img_y;
                      end
            5'h17   : begin
                        img_col <= #1 11'h000;
                        img_x   <= #1 11'h000;
                        img_row <= #1 img_y + 10'h008;
                        img_y   <= #1 img_y + 10'h008;                      
                      end
            5'h1F   : begin
                        img_x   <= #1 11'h000;
                        img_col <= #1 11'h000;
                        img_y   <= #1 10'h000;
                        img_row <= #1 10'h000;
                        last_du_p <= #1 1'b1;                        
                      end
            default : begin
                        img_x   <= #1 img_x;
                        img_col <= #1 img_col;
                        img_y   <= #1 img_y;
                        img_row <= #1 img_row;        
                      end            
          endcase
        end        
    end
  
  //Handle column pixel component
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        img_col_p <= 2'h0;
      else
        case({rst_img_col_p, inc_img_col_p})
          2'h0, 
          2'h2,
          2'h3      : img_col_p <= #1 2'h0;
          2'h1      : img_col_p <= #1 img_col_p + 2'h1;
          default   : img_col_p <= #1 2'h0;
        endcase        
    end    
  
  //Handle col counters for 8x8 DU
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        col_cnt <= #1 3'h0;
      else
      if (rst_img_col_p)
        col_cnt <= #1 col_cnt + 3'h1;
      else
        col_cnt <= #1 col_cnt;      
    end
  
  //Handle row counters for 8x8 DU
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        row_cnt <= #1 3'h0;
      else
      if (inc_row_cnt)
        row_cnt <= #1 row_cnt + 3'h1;
      else
        row_cnt <= #1 row_cnt;           
    end    
    
  //Flop row_cnt and col_cnt two times to sync with frame buffer read
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          row_cnt_fl1 <= #1 3'h0;
          row_cnt_fl2 <= #1 3'h0;
          col_cnt_fl1 <= #1 3'h0;
          col_cnt_fl2 <= #1 3'h0;
          img_col_p_fl1 <= #1 2'h0;
          img_col_p_fl2 <= #1 2'h0;
          load_du_done_fl <= #1 2'h0;
        end
      else
        begin
          row_cnt_fl1 <= #1 row_cnt;
          row_cnt_fl2 <= #1 row_cnt_fl1;
          col_cnt_fl1 <= #1 col_cnt;
          col_cnt_fl2 <= #1 col_cnt_fl1;
          img_col_p_fl1 <= #1 img_col_p;
          img_col_p_fl2 <= #1 img_col_p_fl1;
          load_du_done_fl <= #1 {load_du_done_fl[0], load_du_done};          
        end        
    end
   
  //Load DU from frame buffer read
  always @ (posedge clk)
    begin
      case (c_state)
        LOAD_DU,
        WAIT_DU : begin                  
                    case (img_col_p_fl2)
                      2'h0    : begin
                                  YDU[{row_cnt_fl2,col_cnt_fl2}] <= #1 fb_data;
                                  UDU[{row_cnt_fl2,col_cnt_fl2}] <= #1 UDU[{row_cnt_fl2,col_cnt_fl2}];
                                  VDU[{row_cnt_fl2,col_cnt_fl2}] <= #1 VDU[{row_cnt_fl2,col_cnt_fl2}];
                                end
                      2'h1    : begin
                                  YDU[{row_cnt_fl2,col_cnt_fl2}] <= #1 YDU[{row_cnt_fl2,col_cnt_fl2}];
                                  UDU[{row_cnt_fl2,col_cnt_fl2}] <= #1 fb_data;
                                  VDU[{row_cnt_fl2,col_cnt_fl2}] <= #1 VDU[{row_cnt_fl2,col_cnt_fl2}];        
                                end
                      2'h2    : begin
                                  YDU[{row_cnt_fl2,col_cnt_fl2}] <= #1 YDU[{row_cnt_fl2,col_cnt_fl2}];
                                  UDU[{row_cnt_fl2,col_cnt_fl2}] <= #1 UDU[{row_cnt_fl2,col_cnt_fl2}];
                                  VDU[{row_cnt_fl2,col_cnt_fl2}] <= #1 fb_data;        
                                end
                      default : begin
                                  YDU[{row_cnt_fl2,col_cnt_fl2}] <= #1 YDU[{row_cnt_fl2,col_cnt_fl2}];
                                  UDU[{row_cnt_fl2,col_cnt_fl2}] <= #1 UDU[{row_cnt_fl2,col_cnt_fl2}];
                                  VDU[{row_cnt_fl2,col_cnt_fl2}] <= #1 VDU[{row_cnt_fl2,col_cnt_fl2}];        
                                end
                    endcase
                  end                  
      endcase            
    end    
  
  //Select color component while doing dct  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        dct_comp_sel <= #1 2'h0;
      else
      if (c_state == WAIT_DU)
        dct_comp_sel <= #1 2'h0;
      else
    //if ((c_state == DCT_P7) && (dct_idx_cnt == 4'hF))
      if ((c_state == EXIT_PROC))
        dct_comp_sel <= #1 dct_comp_sel + 2'h1;
      else
        dct_comp_sel <= #1 dct_comp_sel;      
    end    
  
  //index counter to select DU component for DCT
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        dct_idx_cnt <= #1 4'h0;
      else
      if (c_state == WAIT_DU)
        dct_idx_cnt <= #1 4'h0;
      else
      if (c_state == DCT_P7)
        dct_idx_cnt <= #1 dct_idx_cnt + 4'h1;
      else
        dct_idx_cnt <= #1 dct_idx_cnt;      
    end
  
  //index to select DU component for DCT
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          dct_comp_idx[0] <= #1 6'h00;
          dct_comp_idx[1] <= #1 6'h00;
          dct_comp_idx[2] <= #1 6'h00;
          dct_comp_idx[3] <= #1 6'h00;
          dct_comp_idx[4] <= #1 6'h00;
          dct_comp_idx[5] <= #1 6'h00;
          dct_comp_idx[6] <= #1 6'h00;
          dct_comp_idx[7] <= #1 6'h00;
        end
      else
      if (c_state == COMP_SEL)
        casex (dct_idx_cnt)
          4'b0xxx : begin
                      dct_comp_idx[0] <= #1 {dct_idx_cnt[2:0], 3'h0};
                      dct_comp_idx[1] <= #1 {dct_idx_cnt[2:0], 3'h0} + 6'h01;
                      dct_comp_idx[2] <= #1 {dct_idx_cnt[2:0], 3'h0} + 6'h02;
                      dct_comp_idx[3] <= #1 {dct_idx_cnt[2:0], 3'h0} + 6'h03;
                      dct_comp_idx[4] <= #1 {dct_idx_cnt[2:0], 3'h0} + 6'h04;
                      dct_comp_idx[5] <= #1 {dct_idx_cnt[2:0], 3'h0} + 6'h05;
                      dct_comp_idx[6] <= #1 {dct_idx_cnt[2:0], 3'h0} + 6'h06;
                      dct_comp_idx[7] <= #1 {dct_idx_cnt[2:0], 3'h0} + 6'h07;                
                    end
          4'b1xxx : begin
                      dct_comp_idx[0] <= #1 {3'h0, dct_idx_cnt[2:0]};
                      dct_comp_idx[1] <= #1 {3'h0, dct_idx_cnt[2:0]} + 6'h08;
                      dct_comp_idx[2] <= #1 {3'h0, dct_idx_cnt[2:0]} + 6'h10;
                      dct_comp_idx[3] <= #1 {3'h0, dct_idx_cnt[2:0]} + 6'h18;
                      dct_comp_idx[4] <= #1 {3'h0, dct_idx_cnt[2:0]} + 6'h20;
                      dct_comp_idx[5] <= #1 {3'h0, dct_idx_cnt[2:0]} + 6'h28;
                      dct_comp_idx[6] <= #1 {3'h0, dct_idx_cnt[2:0]} + 6'h30;
                      dct_comp_idx[7] <= #1 {3'h0, dct_idx_cnt[2:0]} + 6'h38;           
                    end          
          default : begin
                      dct_comp_idx[0] <= #1 dct_comp_idx[0];
                      dct_comp_idx[1] <= #1 dct_comp_idx[1];
                      dct_comp_idx[2] <= #1 dct_comp_idx[2];
                      dct_comp_idx[3] <= #1 dct_comp_idx[3];
                      dct_comp_idx[4] <= #1 dct_comp_idx[4];
                      dct_comp_idx[5] <= #1 dct_comp_idx[5];
                      dct_comp_idx[6] <= #1 dct_comp_idx[6];
                      dct_comp_idx[7] <= #1 dct_comp_idx[7];           
                    end
        endcase
      else
        begin
          dct_comp_idx[0] <= #1 dct_comp_idx[0];
          dct_comp_idx[1] <= #1 dct_comp_idx[1];
          dct_comp_idx[2] <= #1 dct_comp_idx[2];
          dct_comp_idx[3] <= #1 dct_comp_idx[3];
          dct_comp_idx[4] <= #1 dct_comp_idx[4];
          dct_comp_idx[5] <= #1 dct_comp_idx[5];
          dct_comp_idx[6] <= #1 dct_comp_idx[6];
          dct_comp_idx[7] <= #1 dct_comp_idx[7];          
        end        
    end    
  
  //Handle DCT variables and outputs
  always @ (posedge clk)
    begin
      z2 <= #1 z2;
      z4 <= #1 z4; 
      z1 <= #1 z1;
      z5 <= #1 z5;                       
      z11 <= #1 z11;
      z13 <= #1 z13;  
      z3 <= #1 z3;  
      tmp10 <= #1 tmp10;
      tmp13 <= #1 tmp13;
      tmp11 <= #1 tmp11;
      tmp12 <= #1 tmp12;
      tmp20 <= #1 tmp20;
      tmp21 <= #1 tmp21;
      tmp22 <= #1 tmp22;  
      tmp0 <= #1 tmp0;
      tmp7 <= #1 tmp7;
      tmp1 <= #1 tmp1;
      tmp6 <= #1 tmp6;
      tmp2 <= #1 tmp2;
      tmp5 <= #1 tmp5;
      tmp3 <= #1 tmp3;
      tmp4 <= #1 tmp4;    
      case (c_state)
        DCT_P1    : begin
                      case ({dct_idx_cnt[3], dct_comp_sel})
                        3'h0      : begin
                                      tmp0 <= #1 YDU[dct_comp_idx[0]] + YDU[dct_comp_idx[7]];
                                      tmp7 <= #1 YDU[dct_comp_idx[0]] - YDU[dct_comp_idx[7]];
                                      tmp1 <= #1 YDU[dct_comp_idx[1]] + YDU[dct_comp_idx[6]];
                                      tmp6 <= #1 YDU[dct_comp_idx[1]] - YDU[dct_comp_idx[6]];
                                      tmp2 <= #1 YDU[dct_comp_idx[2]] + YDU[dct_comp_idx[5]];
                                      tmp5 <= #1 YDU[dct_comp_idx[2]] - YDU[dct_comp_idx[5]];
                                      tmp3 <= #1 YDU[dct_comp_idx[3]] + YDU[dct_comp_idx[4]];
                                      tmp4 <= #1 YDU[dct_comp_idx[3]] - YDU[dct_comp_idx[4]];
                                    end
                        3'h1      : begin
                                      tmp0 <= #1 UDU[dct_comp_idx[0]] + UDU[dct_comp_idx[7]];
                                      tmp7 <= #1 UDU[dct_comp_idx[0]] - UDU[dct_comp_idx[7]];
                                      tmp1 <= #1 UDU[dct_comp_idx[1]] + UDU[dct_comp_idx[6]];
                                      tmp6 <= #1 UDU[dct_comp_idx[1]] - UDU[dct_comp_idx[6]];
                                      tmp2 <= #1 UDU[dct_comp_idx[2]] + UDU[dct_comp_idx[5]];
                                      tmp5 <= #1 UDU[dct_comp_idx[2]] - UDU[dct_comp_idx[5]];
                                      tmp3 <= #1 UDU[dct_comp_idx[3]] + UDU[dct_comp_idx[4]];
                                      tmp4 <= #1 UDU[dct_comp_idx[3]] - UDU[dct_comp_idx[4]];
                                    end
                        3'h2      : begin
                                      tmp0 <= #1 VDU[dct_comp_idx[0]] + VDU[dct_comp_idx[7]];
                                      tmp7 <= #1 VDU[dct_comp_idx[0]] - VDU[dct_comp_idx[7]];
                                      tmp1 <= #1 VDU[dct_comp_idx[1]] + VDU[dct_comp_idx[6]];
                                      tmp6 <= #1 VDU[dct_comp_idx[1]] - VDU[dct_comp_idx[6]];
                                      tmp2 <= #1 VDU[dct_comp_idx[2]] + VDU[dct_comp_idx[5]];
                                      tmp5 <= #1 VDU[dct_comp_idx[2]] - VDU[dct_comp_idx[5]];
                                      tmp3 <= #1 VDU[dct_comp_idx[3]] + VDU[dct_comp_idx[4]];
                                      tmp4 <= #1 VDU[dct_comp_idx[3]] - VDU[dct_comp_idx[4]];
                                    end
                        3'h4,
                        3'h5,
                        3'h6      : begin
                                      tmp0 <= #1 DCT_DU[dct_comp_idx[0]] + DCT_DU[dct_comp_idx[7]];
                                      tmp7 <= #1 DCT_DU[dct_comp_idx[0]] - DCT_DU[dct_comp_idx[7]];
                                      tmp1 <= #1 DCT_DU[dct_comp_idx[1]] + DCT_DU[dct_comp_idx[6]];
                                      tmp6 <= #1 DCT_DU[dct_comp_idx[1]] - DCT_DU[dct_comp_idx[6]];
                                      tmp2 <= #1 DCT_DU[dct_comp_idx[2]] + DCT_DU[dct_comp_idx[5]];
                                      tmp5 <= #1 DCT_DU[dct_comp_idx[2]] - DCT_DU[dct_comp_idx[5]];
                                      tmp3 <= #1 DCT_DU[dct_comp_idx[3]] + DCT_DU[dct_comp_idx[4]];
                                      tmp4 <= #1 DCT_DU[dct_comp_idx[3]] - DCT_DU[dct_comp_idx[4]];
                                    end                        
                        default   : begin
                                      tmp0 <= #1 tmp0;
                                      tmp7 <= #1 tmp7;
                                      tmp1 <= #1 tmp1;
                                      tmp6 <= #1 tmp6;
                                      tmp2 <= #1 tmp2;
                                      tmp5 <= #1 tmp5;
                                      tmp3 <= #1 tmp3;
                                      tmp4 <= #1 tmp4;
                                    end
                      endcase
                    end
        DCT_P2    : begin
                      tmp10 <= #1 tmp0 + tmp3;
                      tmp13 <= #1 tmp0 - tmp3;
                      tmp11 <= #1 tmp1 + tmp2;
                      tmp12 <= #1 tmp1 - tmp2;
                      tmp20 <= #1 tmp4 + tmp5;
                      tmp21 <= #1 tmp5 + tmp6;
                      tmp22 <= #1 tmp6 + tmp7;
                    end        
        DCT_P3    : begin
                      DCT_DU[dct_comp_idx[0]] <= #1 tmp10 + tmp11;
                      DCT_DU[dct_comp_idx[4]] <= #1 tmp10 - tmp11;
                      z1 <= #1 tmp12 + tmp13;
                      z5 <= #1 tmp20 - tmp22;
                      z2 <= #1 tmp20 * 5;//tmp20 * 9;
                      z4 <= #1 tmp22 * 13;//tmp22 * 21;
                      z3 <= #1 tmp21 * 7;//tmp21 * 11;
                    end 
        DCT_P4    : begin
                      z1 <= #1 z1 * 7;//z1 * 11;
                      z5 <= #1 z5 * 3;//z5 * 6;                       
                      z11 <= #1 (tmp7 * 10) + z3;//{tmp7, 4'h0} + z3;
                      z13 <= #1 (tmp7 * 10) - z3;//{tmp7, 4'h0} - z3;
                    end 
        DCT_P5    : begin
                      DCT_DU[dct_comp_idx[2]] <= #1 (tmp13 * 10) + z1;//{tmp13, 4'h0} + z1;
                      DCT_DU[dct_comp_idx[6]] <= #1 (tmp13 * 10) - z1;//{tmp13, 4'h0} - z1;       
                      z2 <= #1 z2 + z5;
                      z4 <= #1 z4 + z5;                      
                    end
        DCT_P6    : begin
                      DCT_DU[dct_comp_idx[2]] <= #1 DCT_DU[dct_comp_idx[2]]/10;//DCT_DU[dct_comp_idx[2]]>>4;
                      DCT_DU[dct_comp_idx[6]] <= #1 DCT_DU[dct_comp_idx[6]]/10;//DCT_DU[dct_comp_idx[6]]>>4;
                      DCT_DU[dct_comp_idx[5]] <= #1 z13 + z2;
                      DCT_DU[dct_comp_idx[3]] <= #1 z13 - z2;
                      DCT_DU[dct_comp_idx[1]] <= #1 z11 + z4;
                      DCT_DU[dct_comp_idx[7]] <= #1 z11 - z4;
                    end              
        DCT_P7    : begin
                      DCT_DU[dct_comp_idx[5]] <= #1 DCT_DU[dct_comp_idx[5]]/10;//DCT_DU[dct_comp_idx[5]]>>4;
                      DCT_DU[dct_comp_idx[3]] <= #1 DCT_DU[dct_comp_idx[3]]/10;//DCT_DU[dct_comp_idx[3]]>>4;
                      DCT_DU[dct_comp_idx[1]] <= #1 DCT_DU[dct_comp_idx[1]]/10;//DCT_DU[dct_comp_idx[1]]>>4;
                      DCT_DU[dct_comp_idx[7]] <= #1 DCT_DU[dct_comp_idx[7]]/10;//DCT_DU[dct_comp_idx[7]]>>4;
                    end       
        default   : begin
                      z2 <= #1 z2;
                      z4 <= #1 z4; 
                      z1 <= #1 z1;
                      z5 <= #1 z5;                       
                      z11 <= #1 z11;
                      z13 <= #1 z13;  
                      z3 <= #1 z3;  
                      tmp10 <= #1 tmp10;
                      tmp13 <= #1 tmp13;
                      tmp11 <= #1 tmp11;
                      tmp12 <= #1 tmp12;
                      tmp20 <= #1 tmp20;
                      tmp21 <= #1 tmp21;
                      tmp22 <= #1 tmp22;  
                      tmp0 <= #1 tmp0;
                      tmp7 <= #1 tmp7;
                      tmp1 <= #1 tmp1;
                      tmp6 <= #1 tmp6;
                      tmp2 <= #1 tmp2;
                      tmp5 <= #1 tmp5;
                      tmp3 <= #1 tmp3;
                      tmp4 <= #1 tmp4;                        
                    end                  
      endcase  
    end
  
  //Quantize/Zigzag index counter
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        qz_cnt <= #1 6'h00;
      else
      if (c_state == ZIGZAG)
        qz_cnt <= #1 qz_cnt + 6'h01;
      else
        qz_cnt <= #1 qz_cnt;      
    end
  
  //Quantize and Load ZigZag DU
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          QNT_DU <= #1 15'h0000;
        end
      else
        begin
          QNT_DU <= #1 QNT_DU;        
          case (c_state)
            QUANTIZE  : begin
                          case (dct_comp_sel)
                            2'h0    : QNT_DU <= #1 DCT_DU[qz_cnt] / $signed(fdtbl_Y[qz_cnt]);
                            2'h1,
                            2'h2    : QNT_DU <= #1 DCT_DU[qz_cnt] / $signed(fdtbl_UV[qz_cnt]);
                            default : QNT_DU <= #1 QNT_DU;
                          endcase
                        end  
            ZIGZAG    : ZIG_DU[zigzag_idx[qz_cnt]] <= #1 QNT_DU;
            default   : QNT_DU <= #1 QNT_DU;
          endcase
        end
    end
  
  
  //Check DC difference
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        diff_DC <= #1 15'h0000;
      else
      if (c_state == IDLE)
        diff_DC <= #1 15'h0000;
      else
      if (c_state == DIFF_DC)
        case (dct_comp_sel)
          2'h0    : diff_DC <= #1 ZIG_DU[0] - DCY;
          2'h1    : diff_DC <= #1 ZIG_DU[0] - DCU;
          2'h2    : diff_DC <= #1 ZIG_DU[0] - DCV;
          default : diff_DC <= #1 diff_DC;
        endcase
      else
        diff_DC <= #1 diff_DC;      
    end
   
  //Write output bits
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          wb_bit_buf <= #1 24'h000000;
          wb_bit_cnt <= #1 5'h00;
          wb_c <= #1 8'h00;
          wb_bb_tmp <= #1 24'h0000;
          wb_bc_tmp <= #1 5'h00;
        end
      else
        begin
          wb_bit_buf <= #1 wb_bit_buf;
          wb_bit_cnt <= #1 wb_bit_cnt;
          wb_c <= #1 wb_c;        
          wb_bb_tmp <= #1 wb_bb_tmp;
          wb_bc_tmp <= #1 wb_bc_tmp;
          case (c_state)
            IDLE      : begin
                          wb_bit_buf <= #1 24'h000000;
                          wb_bb_tmp <= #1 24'h0000;
                          wb_bit_cnt <= #1 5'h00;
                          wb_c <= #1 8'h00;                           
                        end
            WB_HTDC0  : begin
                          case (dct_comp_sel)
                            2'h0    : begin 
                                        wb_bit_cnt <= #1 wb_bit_cnt + ydc_ht_rom[0][1]; 
                                        wb_bb_tmp <= #1 {8'h00, ydc_ht_rom[0][0]};
                                      end
                            2'h1,   //SOI - instead of using 16 bits for bit count, 5 bit rom can be used to save space
                            2'h2    : begin
                                        wb_bit_cnt <= #1 wb_bit_cnt + uvdc_ht_rom[0][1]; 
                                        wb_bb_tmp <= #1 {8'h00, uvdc_ht_rom[0][0]};
                                      end
                            default : begin
                                        wb_bit_cnt <= #1 wb_bit_cnt; 
                                        wb_bb_tmp <= #1 wb_bb_tmp;
                                      end
                          endcase
                        end
            WR_BITS   : begin
                          wb_bc_tmp <= #1 5'd24 - wb_bit_cnt;
                        end
            WB_STEP1  : begin
                          wb_bb_tmp <= #1 (wb_bb_tmp << wb_bc_tmp);
                        end
            WB_STEP2  : begin
                          wb_bit_buf <= #1 wb_bit_buf | wb_bb_tmp;
                        end           
            WB_STEP4  : begin
                          wb_c <= #1 wb_bit_buf[23:16];
                          wb_bit_buf <= #1 wb_bit_buf << 8;
                          wb_bit_cnt <= #1 wb_bit_cnt - 5'h8;
                        end      
            WB_STEP5  : begin
                          wb_c <= #1 8'h00;
                        end 
            WB_HTDCB1 : begin
                          case (dct_comp_sel)
                            2'h0    : begin
                                        wb_bit_cnt <= #1 wb_bit_cnt + ydc_ht_rom[cb_bit_cnt][1]; 
                                        wb_bb_tmp <= #1 {8'h00, ydc_ht_rom[cb_bit_cnt][0]};
                                      end
                            2'h1,   //SOI - instead of using 16 bits for bit count, 5 bit rom can be used to save space
                            2'h2    : begin
                                        wb_bit_cnt <= #1 wb_bit_cnt + uvdc_ht_rom[cb_bit_cnt][1]; 
                                        wb_bb_tmp <= #1 {8'h00, uvdc_ht_rom[cb_bit_cnt][0]};
                                      end
                            default : begin
                                        wb_bit_cnt <= #1 wb_bit_cnt; 
                                        wb_bb_tmp <= #1 wb_bb_tmp;
                                      end
                          endcase
                        end
            WB_DIFFB,
            WB_DUAC   : begin
                          wb_bit_cnt <= #1 wb_bit_cnt + cb_bit_cnt; 
                          wb_bb_tmp <= #1 {11'h00, cb_bit_buf};
                        end
            WB_EOB    : begin
                          case (dct_comp_sel)
                            2'h0    : begin
                                        wb_bit_cnt <= #1 wb_bit_cnt + yac_ht_rom[0][1]; 
                                        wb_bb_tmp <= #1 {8'h00, yac_ht_rom[0][0]};
                                      end
                            2'h1,   //SOI - instead of using 16 bits for bit count, 5 bit rom can be used to save space
                            2'h2    : begin
                                        wb_bit_cnt <= #1 wb_bit_cnt + uvac_ht_rom[0][1]; 
                                        wb_bb_tmp <= #1 {8'h00, uvac_ht_rom[0][0]};
                                      end
                            default : begin
                                        wb_bit_cnt <= #1 wb_bit_cnt; 
                                        wb_bb_tmp <= #1 wb_bb_tmp;
                                      end
                          endcase
                        end
            WB_M16B   : begin
                          case (dct_comp_sel)
                            2'h0    : begin
                                        wb_bit_cnt <= #1 wb_bit_cnt + yac_ht_rom[240][1]; 
                                        wb_bb_tmp <= #1 {8'h00, yac_ht_rom[240][0]};
                                      end
                            2'h1,   //SOI - instead of using 16 bits for bit count, 5 bit rom can be used to save space
                            2'h2    : begin
                                        wb_bit_cnt <= #1 wb_bit_cnt + uvac_ht_rom[240][1]; 
                                        wb_bb_tmp <= #1 {8'h00, uvac_ht_rom[240][0]};
                                      end
                            default : begin
                                        wb_bit_cnt <= #1 wb_bit_cnt; 
                                        wb_bb_tmp <= #1 wb_bb_tmp;
                                      end
                          endcase
                        end
            WB_HTAC   : begin
                          case (dct_comp_sel)
                            2'h0    : begin
                                        wb_bit_cnt <= #1 wb_bit_cnt + yac_ht_rom[ac_idx][1]; 
                                        wb_bb_tmp <= #1 {8'h00, yac_ht_rom[ac_idx][0]};
                                      end
                            2'h1,   //SOI - instead of using 16 bits for bit count, 5 bit rom can be used to save space
                            2'h2    : begin
                                        wb_bit_cnt <= #1 wb_bit_cnt + uvac_ht_rom[ac_idx][1]; 
                                        wb_bb_tmp <= #1 {8'h00, uvac_ht_rom[ac_idx][0]};
                                      end
                            default : begin
                                        wb_bit_cnt <= #1 wb_bit_cnt; 
                                        wb_bb_tmp <= #1 wb_bb_tmp;
                                      end
                          endcase
                        end  
            WB_EOI    : begin
                          wb_bit_cnt <= #1 wb_bit_cnt + 5'h7; 
                          wb_bb_tmp <= #1 {17'h00000, 7'h7F};            
                        end            
            default   : begin
                          wb_bit_buf <= #1 wb_bit_buf;
                          wb_bit_cnt <= #1 wb_bit_cnt;
                          wb_c <= #1 wb_c;        
                          wb_bb_tmp <= #1 wb_bb_tmp;
                          wb_bc_tmp <= #1 wb_bc_tmp;            
                        end            
          endcase
        end        
    end
  
  //Calculate bits
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          cb_bit_cnt <= #1 5'h00;
          cb_bit_buf <= #1 13'h0000;
          cb_bb_tmp <= #1 13'h0000;
          cb_bb_mask <= #1 13'h0000;
        end
      else
        begin
          cb_bit_cnt <= #1 cb_bit_cnt;
          cb_bit_buf <= #1 cb_bit_buf;
          cb_bb_tmp <= #1 cb_bb_tmp;
          cb_bb_mask <= #1 cb_bb_mask; 
          case (c_state)
            IDLE      : begin
                          cb_bit_cnt <= #1 5'h00;
                          cb_bit_buf <= #1 13'h0000;
                          cb_bb_tmp <= #1 13'h0000;
                          cb_bb_mask <= #1 13'h0000;            
                        end
            CB_DIFF   : begin
                          if (diff_dc_neg)
                            begin
                              cb_bb_tmp <= #1 15'h0000 - diff_DC;
                              cb_bit_buf <= #1 diff_DC - 15'h0001;
                            end
                          else
                            begin
                              cb_bb_tmp <= #1 diff_DC;
                              cb_bit_buf <= #1 diff_DC;
                            end                            
                        end
            CB_DUAC   : begin
                          if (du_ac_neg)
                            begin
                              cb_bb_tmp <= #1 15'h0000 - du_ac0;
                              cb_bit_buf <= #1 du_ac0 - 15'h0001;
                            end
                          else
                            begin
                              cb_bb_tmp <= #1 du_ac0;
                              cb_bit_buf <= #1 du_ac0;
                            end                            
                        end                        
            CALC_BITS : begin
                          casex (cb_bb_tmp)
                            13'b1_xxxx_xxxx_xxxx  : begin
                                                      cb_bit_cnt <= #1 4'hD; 
                                                      cb_bb_mask <= #1 13'h1FFF;
                                                    end
                            13'b0_1xxx_xxxx_xxxx  : begin
                                                      cb_bit_cnt <= #1 4'hC; 
                                                      cb_bb_mask <= #1 13'h0FFF;
                                                    end
                            13'b0_01xx_xxxx_xxxx  : begin
                                                      cb_bit_cnt <= #1 4'hB; 
                                                      cb_bb_mask <= #1 13'h07FF;
                                                    end
                            13'b0_001x_xxxx_xxxx  : begin
                                                      cb_bit_cnt <= #1 4'hA; 
                                                      cb_bb_mask <= #1 13'h03FF;
                                                    end
                            13'b0_0001_xxxx_xxxx  : begin
                                                      cb_bit_cnt <= #1 4'h9; 
                                                      cb_bb_mask <= #1 13'h01FF;
                                                    end
                            13'b0_0000_1xxx_xxxx  : begin
                                                      cb_bit_cnt <= #1 4'h8; 
                                                      cb_bb_mask <= #1 13'h00FF;
                                                    end
                            13'b0_0000_01xx_xxxx  : begin
                                                      cb_bit_cnt <= #1 4'h7; 
                                                      cb_bb_mask <= #1 13'h007F;
                                                    end
                            13'b0_0000_001x_xxxx  : begin
                                                      cb_bit_cnt <= #1 4'h6; 
                                                      cb_bb_mask <= #1 13'h003F;
                                                    end
                            13'b0_0000_0001_xxxx  : begin
                                                      cb_bit_cnt <= #1 4'h5; 
                                                      cb_bb_mask <= #1 13'h001F;
                                                    end
                            13'b0_0000_0000_1xxx  : begin
                                                      cb_bit_cnt <= #1 4'h4; 
                                                      cb_bb_mask <= #1 13'h000F;
                                                    end
                            13'b0_0000_0000_01xx  : begin
                                                      cb_bit_cnt <= #1 4'h3; 
                                                      cb_bb_mask <= #1 13'h0007;
                                                    end
                            13'b0_0000_0000_001x  : begin
                                                      cb_bit_cnt <= #1 4'h2; 
                                                      cb_bb_mask <= #1 13'h0003;
                                                    end
                            13'b0_0000_0000_000x  : begin
                                                      cb_bit_cnt <= #1 4'h1; 
                                                      cb_bb_mask <= #1 13'h0001;
                                                    end
                            default               : begin
                                                      cb_bit_cnt <= #1 4'h1; 
                                                      cb_bb_mask <= #1 13'h0001;
                                                    end                            
                          endcase
                        end
            CB_STEP1  : begin
                          cb_bit_buf <= #1 cb_bit_buf & cb_bb_mask;
                        end
            default   : begin
                          cb_bit_cnt <= #1 cb_bit_cnt;
                          cb_bit_buf <= #1 cb_bit_buf;
                          cb_bb_tmp <= #1 cb_bb_tmp;
                          cb_bb_mask <= #1 cb_bb_mask;             
                        end            
          endcase          
        end        
    end
    
  //Branch State after CALC_BITS/WR_BITS 
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        b_state <= #1 IDLE;
      else
        begin
          case (c_state)
            WB_HTDC0  : b_state <= #1 FIND_TR0;
            CB_DIFF   : b_state <= #1 WB_HTDCB1;
            WB_HTDCB1 : b_state <= #1 WB_DIFFB;
            WB_DIFFB  : b_state <= #1 FIND_TR0;
            WB_EOB    : b_state <= #1 EXIT_PROC;
            CB_DUAC   : b_state <= #1 PREP_ACIDX;
            WB_HTAC   : b_state <= #1 WB_DUAC;
            WB_DUAC   : b_state <= #1 CHK_ACIDX;
            WB_EOI    : b_state <= #1 EOI1;
            WB_M16B   : b_state <= #1 CHK_M16B;
            default   : b_state <= #1 b_state;
          endcase
        end          
    end
      
  //Find trailing zero bytes in DCT_DU
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          end0pos <= #1 6'h3F;
          du_e0p <= #1 15'h7FFF;
        end
      else
        begin
          end0pos <= #1 end0pos;
          du_e0p <= #1 du_e0p;
          case(c_state)
            DIFF_DC   : begin
                          end0pos <= #1 6'h3F;
                          du_e0p <= #1 15'h7FFF;
                        end
            FIND_TR0  : begin
                          du_e0p <= #1 ZIG_DU[end0pos];                        
                        end
            DEC_E0P   : begin
                          end0pos <= #1 end0pos - 6'h01;
                        end            
            default   : begin
                          end0pos <= #1 end0pos;
                          du_e0p <= #1 du_e0p;                          
                        end
          endcase
        end        
    end 
  
  //Find zeros in AC components (1..63) of DCT_DU
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          ac0_idx <= #1 6'h01;
          du_ac0  <= #1 15'h7FFF;
          ac0_cnt <= #1 6'h00;
        end
      else
        begin
          ac0_idx <= #1 ac0_idx;
          du_ac0  <= #1 du_ac0;
          ac0_cnt <= #1 ac0_cnt;
          case (c_state)
            ENC_AC    : begin
                          ac0_idx <= #1 7'h01;
                          du_ac0  <= #1 15'h7FFF;
                          ac0_cnt <= #1 6'h00;            
                        end
            FIND_AC0  : begin
                          du_ac0  <= #1 ZIG_DU[ac0_idx[5:0]];
                        end
            CHECK_AC0 : begin
                          //ac0_idx <= #1 ac0_idx + 7'h01;
                        end 
            INC_AC0   : begin
                          ac0_cnt <= #1 ac0_cnt + 6'h01;
                          ac0_idx <= #1 ac0_idx + 7'h01;
                        end         
            WB_M16B   : begin
                          ac0_cnt[5:4] <= #1 ac0_cnt[5:4] - 2'h1; 
                        end
            WB_DUAC   :  begin
                          ac0_cnt <= #1 6'h00;
                          ac0_idx <= #1 ac0_idx + 7'h01;
                        end            
            default   : begin
                          ac0_idx <= #1 ac0_idx;
                          du_ac0  <= #1 du_ac0;
                          ac0_cnt <= #1 ac0_cnt;
                        end
          endcase
        end        
    end    
  
  //Calculate index for AC component to encode data
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        ac_idx <= #1 8'h00;
      else
      if (c_state == PREP_ACIDX)
        ac_idx <= #1 {ac0_cnt[3:0], 4'h0} + cb_bit_cnt;
      else
        ac_idx <= #1 ac_idx;      
    end
  
  //Keep track of last DU read from raw data
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        last_du <= #1 1'b0;
      else
        case (c_state)
          IDLE      : last_du <= #1 1'b0;
          LOAD_DU   : last_du <= #1 last_du_p;
          default   : last_du <= #1 last_du;          
        endcase        
    end
  
  //Return DC component when exiting Encoding process
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          DCY <= #1 15'h0000;
          DCU <= #1 15'h0000;
          DCV <= #1 15'h0000;
        end
      else
        begin
          DCY <= #1 DCY;
          DCU <= #1 DCU;
          DCV <= #1 DCV;
          case (c_state)
            IDLE      : begin
                          DCY <= #1 15'h0000;
                          DCU <= #1 15'h0000;
                          DCV <= #1 15'h0000;            
                        end
            WB_EOB    : begin
                          case (dct_comp_sel)
                            2'h0    : DCY <= #1 ZIG_DU[0];
                            2'h1    : DCU <= #1 ZIG_DU[0];
                            2'h2    : DCV <= #1 ZIG_DU[0];
                          endcase 
                        end            
            default   : begin
                          DCY <= #1 DCY;
                          DCU <= #1 DCU;
                          DCV <= #1 DCV;            
                        end
          endcase
        end        
    end    
  
endmodule  