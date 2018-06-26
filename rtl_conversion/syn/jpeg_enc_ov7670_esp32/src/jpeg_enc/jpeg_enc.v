`timescale 1ns/1ns

`define WIDTH   (320)//(1024)
`define HEIGHT  (200)//(768)

//`define QUANT_MULT

module jpeg_enc (
  input           clk,
  input           reset_n,
  input           conv_en,
  input  [7:0]    fb_data,
  output          fb_rd,
  output [7:0]    img_out,
  
  input  [9:0]    hd_addr,
  output [7:0]    hd_data,
  
  output          img_valid,
  output          img_done
  );
  
  
  reg    [7:0]    img_out_reg;
  reg             img_valid_reg, img_valid_reg_fl;
  reg             img_done_reg;
  reg    [9:0]    byte_count;
  wire   [7:0]    header_rom_d;
  
  reg             du_ram_we;
  reg    [7:0]    du_ram_aw;

  reg signed   [14:0]   QNT_DU;
`ifdef QUANT_MULT  
  reg signed   [25:0]   QNT_DU_pre;
`endif  
  reg    [1:0]    dct_comp_sel;
  reg    [5:0]    dct_comp_idx[7:0];
  reg    [3:0]    dct_idx_cnt;
  reg signed   [14:0]   DCY, DCU, DCV, diff_DC;  
  
  reg             zzdu_ram_we;
  reg    [5:0]    zzdu_ram_ar;
  
  reg    [4:0]    dcht_bc_rom_a, dcht_bb_rom_a;
  reg    [8:0]    acht_bc_rom_a, acht_bb_rom_a;
  
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
  
  reg    [4:0]    wb_bit_cnt, wb_bc_tmp;
  reg    [23:0]   wb_bit_buf, wb_bb_tmp;
  reg    [7:0]    wb_c;
  
  reg    [12:0]   cb_bb_mask, cb_bit_buf, cb_bb_tmp;
  reg    [4:0]    cb_bit_cnt;
  
  reg    [5:0]    end0pos;
  reg signed   [14:0]   du_ac0;
  reg    [7:0]    ac_idx;
  reg    [6:0]    ac0_idx;
  reg    [5:0]    ac0_cnt;
  reg             last_du, last_du_p;
  reg    [1:0]    fb_rd_reg;
  
  
  assign img_out    = (byte_count != 10'h000) ? header_rom_d : img_out_reg;
  assign img_valid  = img_valid_reg;
  assign img_done   = img_done_reg;	 
  
  assign fb_rd      = fb_rd_reg[0];
  
  parameter       IDLE      = 0;
  parameter       LOAD_DU   = 1;
  parameter       WAIT_DU   = 2;
  parameter       COMP_SEL  = 3;
  parameter       DCT_P1    = 4;
  parameter       DCT_P7    = 5;
  parameter       QUANTIZE  = 6;
  parameter       ZIGZAG    = 7;
  parameter       DIFF_DC   = 8;
  parameter       CHK_DIFF  = 9;
  parameter       WB_HTDC0  = 10;
  parameter       WR_BITS   = 11;
  parameter       WB_STEP1  = 12;
  parameter       WB_STEP2  = 13;
  parameter       WB_STEP3  = 14;
  parameter       WB_STEP4  = 15;
  parameter       WB_STEP5  = 16;
  parameter       WB_NSTATE = 17; 
  parameter       CB_DIFF   = 18;
  parameter       CALC_BITS = 19;
  parameter       CB_STEP1  = 20;
  parameter       CB_NSTATE = 21;
  parameter       WB_HTDCB1 = 22; 
  parameter       WB_DIFFB  = 23;
  parameter       FIND_TR0  = 24;
  parameter       CHECK_ELM = 25;
  parameter       DEC_E0P   = 26;  
  parameter       CHECK_E0P = 27;
  parameter       ENC_AC    = 28;
  parameter       FIND_AC0  = 29;
  parameter       CHECK_AC0 = 30;
  parameter       INC_AC0   = 31;
  parameter       CHK_NRZ16 = 32;
  parameter       WB_M16B   = 33;
  parameter       CHK_M16B  = 34;
  parameter       CB_DUAC   = 35;
  parameter       PREP_ACIDX= 36;
  parameter       WB_HTAC   = 37;
  parameter       WB_DUAC   = 38;
  parameter       CHK_ACIDX = 39;
  parameter       CHK_EOP63 = 40;
  parameter       WB_EOB    = 41;
  parameter       EXIT_PROC = 42;
  parameter       CHECK_EOF = 43;
  parameter       WB_EOI    = 44;
  parameter       EOI1      = 45;
  parameter       EOI2      = 46;
  parameter       CONV_DONE = 47;
  parameter       LOAD_xDU  = 48;
  parameter       PRE_QUANT = 49;
  parameter       READ_TR0  = 50;
  parameter       READ_AC0  = 51;
  parameter       READ_HTAC = 52;
  parameter       CB_NSTATE2= 53;
  parameter       READ_HTAC2= 54;
`ifdef QUANT_MULT  
  parameter       PRE_ZIGZAG= 61;
`endif  
  
  wire signed [14:0]   zzdu_ram_do;
  wire            inc_img_col_p = (c_state == LOAD_DU);
  wire            rst_img_col_p = (img_col_p == 2'h2);
  wire            col_max = (img_col == (`WIDTH-1));
  wire            row_max = (img_row == (`HEIGHT-1));
  wire            inc_row_cnt = (&col_cnt) && rst_img_col_p;
  wire            load_du_done = (&col_cnt) && (&row_cnt) && rst_img_col_p;
  wire            dct_done;
  wire            qz_done = &qz_cnt;
  wire            diff_dc_zero = !(|diff_DC);
  wire            diff_dc_neg  = diff_DC[14];
  wire            bit_cnt_gte_8 = |wb_bit_cnt[4:3];
  wire            byte_out_eq_255 = &wb_bit_buf[23:16];
  
  wire            check_next_element = ((end0pos != 6'h00) && (zzdu_ram_do == 15'h0000));  
  wire            e0p_zero = (end0pos == 6'h00);
  wire            inc_ac0_idx = (ac0_idx <= end0pos);
  
  wire            inc_ac0_cnt = (inc_ac0_idx && (zzdu_ram_do == 15'h0000));
  wire            ac0_cnt_gte_16 = |ac0_cnt[5:4];
  wire            e0p_ne_63 = (end0pos != 6'h3F);
  wire            du_ac_neg = du_ac0[14];
  wire            last_comp = (dct_comp_sel == 2'h2);
  
  wire   [7:0]    du_ram_do;
  wire signed [7:0] fdtbl_rom_d;
  wire   [5:0]    zzidx_rom_d;
  
  wire   [4:0]    dcht_bc_rom_d, acht_bc_rom_d;
  wire   [15:0]   dcht_bb_rom_d, acht_bb_rom_d;
  wire            start_dct = (c_state == DCT_P1);
  wire   [5:0]    du_ram_a_dct;
  
  wire   [5:0]    dctdu_ram_aw, dctdu_ram_ar_dct;
  wire   [5:0]    dctdu_ram_ar = (c_state == DCT_P7) ? dctdu_ram_ar_dct : qz_cnt;
  wire            dctdu_ram_we;
  wire   [17:0]   dctdu_ram_di, dctdu_ram_do;
  
  
  jpeg_enc_mem ram_rom (
    .clk            (clk),
    .reset_n        (reset_n),
    
    //Header ROM
    .header_rom_a   (hd_addr),
    .header_rom_d   (hd_data),
    
    //DU RAM (YDU, VDU, UDU)
    .du_ram_aw      ({img_col_p_fl2, row_cnt_fl2,col_cnt_fl2}),
    .du_ram_di      (fb_data),
    .du_ram_we      (du_ram_we),
    .du_ram_ar      ({dct_comp_sel, du_ram_a_dct}),
    .du_ram_do      (du_ram_do),
    
    //fdtbl ROM (Y, UV)
    .fdtbl_rom_a    ({(|dct_comp_sel), qz_cnt}),
    .fdtbl_rom_d    (fdtbl_rom_d),

    //ZIGZAG DU RAM
    .zzdu_ram_aw    (zzidx_rom_d),
    .zzdu_ram_di    (QNT_DU),
    .zzdu_ram_we    (zzdu_ram_we),
    .zzdu_ram_ar    (zzdu_ram_ar),
    .zzdu_ram_do    (zzdu_ram_do),
    
    //ZIGZAG INDEX ROM
    .zzidx_rom_a    (qz_cnt),
    .zzidx_rom_d    (zzidx_rom_d),

    //DC HT BC ROM (YDC, UVDC)
    .dcht_bc_rom_a  (dcht_bc_rom_a),
    .dcht_bc_rom_d  (dcht_bc_rom_d),
    
    //DC HT BB ROM (YDC, UVDC)
    .dcht_bb_rom_a  (dcht_bb_rom_a),
    .dcht_bb_rom_d  (dcht_bb_rom_d),
    
    //AC HT BC ROM (YDC, UVDC)
    .acht_bc_rom_a  (acht_bc_rom_a),
    .acht_bc_rom_d  (acht_bc_rom_d),
    
    //AC HT BB ROM (YDC, UVDC)
    .acht_bb_rom_a  (acht_bb_rom_a),
    .acht_bb_rom_d  (acht_bb_rom_d),

    //DCTDU RAM
    .dctdu_ram_aw   (dctdu_ram_aw),
    .dctdu_ram_di   (dctdu_ram_di),
    .dctdu_ram_we   (dctdu_ram_we),
    .dctdu_ram_ar   (dctdu_ram_ar),
    .dctdu_ram_do   (dctdu_ram_do) 
    
  );

  jpeg_enc_dct dct (

  .clk              (clk),
  .reset_n          (reset_n),
  
  .s_conv           (start_dct),
  
  .du_ram_a         (du_ram_a_dct),
  .du_ram_d         (du_ram_do),
  
  .dctdu_ram_aw     (dctdu_ram_aw),
  .dctdu_ram_we     (dctdu_ram_we),
  .dctdu_ram_do     (dctdu_ram_di),
  .dctdu_ram_ar     (dctdu_ram_ar_dct),
  .dctdu_ram_di     (dctdu_ram_do),
  
  .e_conv           (dct_done)

  );  
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        fb_rd_reg <= #1 2'h0;
      else
        fb_rd_reg <= #1 {fb_rd_reg[0], inc_img_col_p};      
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        img_valid_reg_fl <= #1 1'b0;
      else
        img_valid_reg_fl <= #1 img_valid_reg;      
    end    

  //Main State Machine Current State
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        c_state <= #1 IDLE;
      else
        c_state <= #1 n_state;      
    end
  
  //Main State Machine Next State  
  always @ (c_state, conv_en, load_du_done, load_du_done_fl[1], dct_done, qz_done, diff_dc_zero, b_state, bit_cnt_gte_8, byte_out_eq_255,
            check_next_element, e0p_zero, inc_ac0_idx, inc_ac0_cnt, ac0_cnt_gte_16, e0p_ne_63, last_comp, last_du)
    case(c_state)
      IDLE        : begin
                      if (conv_en)
                        n_state <= #1 LOAD_DU;
                      else
                        n_state <= #1 IDLE;
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
                        n_state <= #1 WAIT_DU;                      
                    end
      COMP_SEL    : n_state <= #1 DCT_P1;

      DCT_P1      : n_state <= #1 DCT_P7;
      DCT_P7      : begin
                      if (dct_done)
                        n_state <= #1 PRE_QUANT;
                      else
                        n_state <= #1 DCT_P7;                      
                    end
      PRE_QUANT   : n_state <= #1 QUANTIZE;
`ifdef QUANT_MULT      
      QUANTIZE    : n_state <= #1 PRE_ZIGZAG;
      PRE_ZIGZAG  : n_state <= #1 ZIGZAG;
`else
      QUANTIZE    : n_state <= #1 ZIGZAG;
`endif      
      ZIGZAG      : begin
                      if (qz_done)
                        n_state <= #1 DIFF_DC;
                      else
                        n_state <= #1 PRE_QUANT;
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
      CB_NSTATE   : n_state <= #1 CB_NSTATE2; 
      CB_NSTATE2  : n_state <= #1 b_state;
      WB_HTDCB1   : n_state <= #1 WR_BITS;
      WB_DIFFB    : n_state <= #1 WR_BITS;
      FIND_TR0    : n_state <= #1 READ_TR0;
      READ_TR0    : n_state <= #1 CHECK_ELM;
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
      FIND_AC0    : n_state <= #1 READ_AC0;
      READ_AC0    : n_state <= #1 CHECK_AC0;
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
      PREP_ACIDX  : n_state <= #1 READ_HTAC;
      READ_HTAC   : n_state <= #1 READ_HTAC2;
      READ_HTAC2  : n_state <= #1 WB_HTAC;
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
          byte_count <= #1 10'h000;
          img_out_reg <= #1 8'h00;
          img_valid_reg <= #1 1'b0;
          img_done_reg <= #1 1'b0;
        end
      else
        begin
          byte_count <= #1 10'h000;
          img_out_reg <= #1 img_out_reg;
          img_valid_reg <= #1 1'b0;
          img_done_reg <= #1 1'b0;
          case (c_state)
            WB_STEP4    : begin
                            img_out_reg <= #1 wb_bit_buf[23:16];
                            img_valid_reg <= #1 1'b1;
                          end
            WB_STEP5    : begin
                            img_out_reg <= #1 8'h00;
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
            default     : begin
                            byte_count <= #1 10'h000;
                            img_out_reg <= #1 img_out_reg;
                            img_valid_reg <= #1 1'b0;
                            img_done_reg <= #1 1'b0;            
                          end            
          endcase          
        end        
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
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        du_ram_we <= #1 1'b0;
      else
      if ((c_state == LOAD_DU) || (load_du_done_fl[0]))
        du_ram_we <= #1 1'b1;
      else
        du_ram_we <= #1 1'b0;      
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
      if ((c_state == EXIT_PROC))
        dct_comp_sel <= #1 dct_comp_sel + 2'h1;
      else
        dct_comp_sel <= #1 dct_comp_sel;      
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
`ifdef QUANT_MULT        
          QNT_DU_pre <= #1 26'h0000000;
`endif          
          QNT_DU <= #1 15'h0000;
          zzdu_ram_we <= #1 1'b0;
        end
      else
        begin
`ifdef QUANT_MULT        
          QNT_DU_pre <= #1 QNT_DU_pre;
`endif          
          QNT_DU <= #1 QNT_DU;
          zzdu_ram_we <= #1 1'b0;          
          case (c_state)
`ifdef QUANT_MULT          
            QUANTIZE  : begin
                          QNT_DU_pre <= $signed(dctdu_ram_do) * fdtbl_rom_d;
                        end
            PRE_ZIGZAG: begin
                          QNT_DU <= QNT_DU_pre[25:11];
                        end
`else
            QUANTIZE  : begin
                          QNT_DU <= #1 $signed(dctdu_ram_do) / fdtbl_rom_d;
                        end
`endif                        
            ZIGZAG    : zzdu_ram_we <= #1 1'b1;
            default   : QNT_DU <= #1 QNT_DU;
          endcase
        end
    end
  
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        zzdu_ram_ar <= #1 6'h00;
      else
        case(c_state)
          FIND_TR0    : zzdu_ram_ar <= #1 end0pos;
          FIND_AC0    : zzdu_ram_ar <= #1 ac0_idx[5:0];
          default     : zzdu_ram_ar <= #1 6'h00;
        endcase        
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
          2'h0    : diff_DC <= #1 zzdu_ram_do - DCY;
          2'h1    : diff_DC <= #1 zzdu_ram_do - DCU;
          2'h2    : diff_DC <= #1 zzdu_ram_do - DCV;
          default : diff_DC <= #1 diff_DC;
        endcase
      else
        diff_DC <= #1 diff_DC;      
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          dcht_bc_rom_a <= #1 5'h00;
          dcht_bb_rom_a <= #1 5'h00;
          acht_bc_rom_a <= #1 9'h000;
          acht_bb_rom_a <= #1 9'h000;
        end
      else
        begin
          dcht_bc_rom_a <= #1 dcht_bc_rom_a;
          dcht_bb_rom_a <= #1 dcht_bb_rom_a;
          acht_bc_rom_a <= #1 acht_bc_rom_a;
          acht_bb_rom_a <= #1 acht_bb_rom_a;
          case(c_state)
            DIFF_DC     : begin
                            dcht_bc_rom_a <= #1 {(|dct_comp_sel), 4'h0};
                            dcht_bb_rom_a <= #1 {(|dct_comp_sel), 4'h0};
                          end
            CB_NSTATE   : begin
                            dcht_bc_rom_a <= #1 {(|dct_comp_sel), cb_bit_cnt[3:0]};
                            dcht_bb_rom_a <= #1 {(|dct_comp_sel), cb_bit_cnt[3:0]};            
                          end
            CHECK_ELM,
            CHK_ACIDX   : begin
                            acht_bc_rom_a <= #1 {(|dct_comp_sel), 8'h00};
                            acht_bb_rom_a <= #1 {(|dct_comp_sel), 8'h00};
                          end
            CHECK_AC0   : begin
                            acht_bc_rom_a <= #1 {(|dct_comp_sel), 8'hF0};
                            acht_bb_rom_a <= #1 {(|dct_comp_sel), 8'hF0};                            
                          end    
            READ_HTAC   : begin
                            acht_bc_rom_a <= #1 {(|dct_comp_sel), ac_idx};
                            acht_bb_rom_a <= #1 {(|dct_comp_sel), ac_idx};            
                          end            
            default     : begin
                            dcht_bc_rom_a <= #1 dcht_bc_rom_a;
                            dcht_bb_rom_a <= #1 dcht_bb_rom_a;
                            acht_bc_rom_a <= #1 acht_bc_rom_a;
                            acht_bb_rom_a <= #1 acht_bb_rom_a;            
                          end
          endcase          
        end        
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
                          wb_bit_cnt <= #1 wb_bit_cnt + dcht_bc_rom_d;
                          wb_bb_tmp  <= #1 {8'h00, dcht_bb_rom_d};                        
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
                          wb_bit_cnt <= #1 wb_bit_cnt + dcht_bc_rom_d;
                          wb_bb_tmp  <= #1 {8'h00, dcht_bb_rom_d};            
                        end
            WB_DIFFB,
            WB_DUAC   : begin
                          wb_bit_cnt <= #1 wb_bit_cnt + cb_bit_cnt; 
                          wb_bb_tmp <= #1 {11'h00, cb_bit_buf};
                        end
            WB_EOB    : begin
                          wb_bit_cnt <= #1 wb_bit_cnt + acht_bc_rom_d;
                          wb_bb_tmp  <= #1 {8'h00, acht_bb_rom_d};            
                        end
            WB_M16B   : begin
                          wb_bit_cnt <= #1 wb_bit_cnt + acht_bc_rom_d;
                          wb_bb_tmp  <= #1 {8'h00, acht_bb_rom_d};            
                        end
            WB_HTAC   : begin
                          wb_bit_cnt <= #1 wb_bit_cnt + acht_bc_rom_d;
                          wb_bb_tmp  <= #1 {8'h00, acht_bb_rom_d};            
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
        end
      else
        begin
          end0pos <= #1 end0pos;        
          case(c_state)
            CHK_DIFF  : begin
                          end0pos <= #1 6'h3F;                     
                        end
            DEC_E0P   : begin
                          end0pos <= #1 end0pos - 6'h01;
                        end            
            default   : begin
                          end0pos <= #1 end0pos;                         
                        end
          endcase
        end        
    end 
  
  //Find zeros in AC components (1..63) of DCT_DU
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          ac0_idx <= #1 7'h01;
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
            CHECK_AC0 : begin
                          du_ac0 <= #1 zzdu_ram_do;                          
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
        //LOAD_DU   : last_du <= #1 last_du_p;
          WAIT_DU   : last_du <= #1 last_du_p ? 1'b1 : last_du;
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
            EXIT_PROC : begin
                          case (dct_comp_sel)
                            2'h0    : DCY <= #1 zzdu_ram_do;
                            2'h1    : DCU <= #1 zzdu_ram_do;
                            2'h2    : DCV <= #1 zzdu_ram_do;
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