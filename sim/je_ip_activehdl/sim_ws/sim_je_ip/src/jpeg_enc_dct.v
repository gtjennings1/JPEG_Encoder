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
//`define UNSIGNED_SHIFT
module jpeg_enc_dct (
  input           clk,
  input           reset_n,
  
  input           s_conv,
  
  output [5:0]    du_ram_a,
  input  [7:0]    du_ram_d,
  
  output [5:0]    dctdu_ram_aw,
  output          dctdu_ram_we,
  output [17:0]   dctdu_ram_do,
  output [5:0]    dctdu_ram_ar,
  input  [17:0]   dctdu_ram_di,
  
  output          e_conv
  );
  
  
  
  localparam       IDLE       = 0;
  localparam       FETCH_DU_S = 1;
  localparam       FETCH_DU_R = 2;
  localparam       FETCH_DU_E = 3;
  localparam       DCT_CAL_P1 = 4;
  localparam       DCT_CAL_P2 = 5;
  localparam       DCT_CAL_P3 = 6;
  localparam       DCT_CAL_P4 = 7;
  localparam       DCT_CAL_P5 = 8;
  localparam       DCT_CAL_P6 = 9;
  localparam       DCT_CAL_P7 = 10;
`ifdef UNSIGNED_SHIFT  
  localparam       DCT_CAL_P8 = 11;
  localparam       DCT_CAL_P9 = 12;
`endif  
  localparam       SV_DCTDU_S = 13;
  localparam       SV_DCTDU_R = 14;
  localparam       SV_DCTDU_E = 15;
  localparam       SCAN_CHECK = 16;
  localparam       EXIT       = 17;
  
  
  reg    [5:0]    c_state, n_state;
  
  reg    [5:0]    du_idx;
  reg    [5:0]    dctdu_w_idx, dctdu_w_idx_fl, dctdu_r_idx;
  reg             dctdu_w_en;
  reg    [17:0]   dctdu_w_d;
  
  reg    [2:0]    tmp_du_w_idx;
  
  reg             vertical_scan,vertical_scan_fl;
  reg             e_conv_reg;
  
  reg signed   [17:0]   tmp_du [7:0];  
  reg signed   [17:0]   tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7,
                        tmp10, tmp11, tmp12, tmp13, tmp20, tmp21, tmp22;
  
  wire            last_du_element = (&du_idx[2:0]);
  wire            last_dctdu_element = (&dctdu_w_idx[2:0]);
  wire            change_scan = !(|du_idx);
 
  assign          du_ram_a = du_idx;
  assign          dctdu_ram_ar = {du_idx[2:0], du_idx[5:3]};
  assign          dctdu_ram_aw = vertical_scan ? {dctdu_w_idx_fl[2:0], dctdu_w_idx_fl[5:3]} : dctdu_w_idx_fl;
  assign          dctdu_ram_we = dctdu_w_en;
  assign          dctdu_ram_do = dctdu_w_d;
  assign          e_conv = e_conv_reg;
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        c_state <= #1 IDLE;
      else
        c_state <= #1 n_state;      
    end
  
  always @ (c_state, s_conv, last_du_element, last_dctdu_element, change_scan, vertical_scan_fl)
    begin
      case (c_state)
        IDLE        : begin
                        if (s_conv)
                          n_state <= #1 FETCH_DU_S;
                        else
                          n_state <= #1 IDLE;                        
                      end
        FETCH_DU_S  : n_state <= #1 FETCH_DU_R;
        FETCH_DU_R  : begin
                        if (last_du_element)
                          n_state <= #1 FETCH_DU_E;
                        else
                          n_state <= #1 FETCH_DU_R;                        
                      end        
        FETCH_DU_E  : n_state <= #1 DCT_CAL_P1;
        DCT_CAL_P1  : n_state <= #1 DCT_CAL_P2;
        DCT_CAL_P2  : n_state <= #1 DCT_CAL_P3;
        DCT_CAL_P3  : n_state <= #1 DCT_CAL_P4;
        DCT_CAL_P4  : n_state <= #1 DCT_CAL_P5;
        DCT_CAL_P5  : n_state <= #1 DCT_CAL_P6;
        DCT_CAL_P6  : n_state <= #1 DCT_CAL_P7;        
`ifdef UNSIGNED_SHIFT        
        DCT_CAL_P7  : n_state <= #1 DCT_CAL_P8;
        DCT_CAL_P8  : n_state <= #1 DCT_CAL_P9;
        DCT_CAL_P9  : n_state <= #1 SV_DCTDU_S;
`else
        DCT_CAL_P7  : n_state <= #1 SV_DCTDU_S;
`endif        
        SV_DCTDU_S  : n_state <= #1 SV_DCTDU_R;
        SV_DCTDU_R  : begin
                        if (last_dctdu_element)
                          n_state <= #1 SV_DCTDU_E;
                        else
                          n_state <= #1 SV_DCTDU_R;                        
                      end
        SV_DCTDU_E  : n_state <= #1 SCAN_CHECK;
        SCAN_CHECK  : begin
                        if (change_scan && vertical_scan_fl)
                          n_state <= #1 EXIT;
                        else
                          n_state <= #1 FETCH_DU_S;                        
                      end
        EXIT        : n_state <= #1 IDLE;                      
        default     : n_state <= #1 IDLE;
      endcase
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        du_idx <= #1 6'h00;
      else
        case (c_state)
          FETCH_DU_S,
          FETCH_DU_R  : du_idx <= #1 du_idx + 6'h01;
          default     : du_idx <= #1 du_idx;
        endcase        
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        tmp_du_w_idx <= #1 3'h0;
      else
        case (c_state)
          FETCH_DU_S,
          FETCH_DU_R  : tmp_du_w_idx <= #1 du_idx[2:0];
          default     : tmp_du_w_idx <= #1 tmp_du_w_idx;
        endcase        
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          tmp_du[0] <= #1 18'h0000;
          tmp_du[1] <= #1 18'h0000;
          tmp_du[2] <= #1 18'h0000;
          tmp_du[3] <= #1 18'h0000;
          tmp_du[4] <= #1 18'h0000;
          tmp_du[5] <= #1 18'h0000;
          tmp_du[6] <= #1 18'h0000;
          tmp_du[7] <= #1 18'h0000;
        end
      else
        begin      
          tmp_du[0] <= #1 tmp_du[0];
          tmp_du[1] <= #1 tmp_du[1];
          tmp_du[2] <= #1 tmp_du[2];
          tmp_du[3] <= #1 tmp_du[3];
          tmp_du[4] <= #1 tmp_du[4];
          tmp_du[5] <= #1 tmp_du[5];
          tmp_du[6] <= #1 tmp_du[6];
          tmp_du[7] <= #1 tmp_du[7];        
          case (c_state)
            FETCH_DU_R,
            FETCH_DU_E  : begin
                            if (vertical_scan)
                              tmp_du[tmp_du_w_idx] <= #1 dctdu_ram_di;
                            else
                              tmp_du[tmp_du_w_idx] <= #1 $signed(du_ram_d);
                          end  
            DCT_CAL_P3  : begin
                            tmp_du[0] <= #1 tmp10 + tmp11;
                            tmp_du[4] <= #1 tmp10 - tmp11;
                          end
`ifdef UNSIGNED_SHIFT            
            DCT_CAL_P8  : begin
                            tmp_du[2] <= #1 (tmp0[17]) ? 19'h40000-tmp10 : tmp10;
                            tmp_du[6] <= #1 (tmp7[17]) ? 19'h40000-tmp11 : tmp11;
                          end
            DCT_CAL_P9  : begin
                            tmp_du[5] <= #1 (tmp1[17]) ? 19'h40000-tmp13 : tmp13;
                            tmp_du[3] <= #1 (tmp2[17]) ? 19'h40000-tmp20 : tmp20;
                            tmp_du[1] <= #1 (tmp3[17]) ? 19'h40000-tmp21 : tmp21;
                            tmp_du[7] <= #1 (tmp4[17]) ? 19'h40000-tmp22 : tmp22;
                          end
`else
            DCT_CAL_P6  : begin
                            tmp_du[2] <= #1 (tmp0 >>> 3);
                            tmp_du[6] <= #1 (tmp7 >>> 3);
                          end       
            DCT_CAL_P7  : begin
                            tmp_du[5] <= #1 (tmp1 >>> 3);
                            tmp_du[3] <= #1 (tmp2 >>> 3);
                            tmp_du[1] <= #1 (tmp3 >>> 3);
                            tmp_du[7] <= #1 (tmp4 >>> 3);
                          end
`endif                          
            default     : begin
                            tmp_du[0] <= #1 tmp_du[0];
                            tmp_du[1] <= #1 tmp_du[1];
                            tmp_du[2] <= #1 tmp_du[2];
                            tmp_du[3] <= #1 tmp_du[3];
                            tmp_du[4] <= #1 tmp_du[4];
                            tmp_du[5] <= #1 tmp_du[5];
                            tmp_du[6] <= #1 tmp_du[6];
                            tmp_du[7] <= #1 tmp_du[7];             
                          end            
          endcase
        end
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          tmp0 <= #1 18'h0000;
          tmp1 <= #1 18'h0000;
          tmp2 <= #1 18'h0000;
          tmp3 <= #1 18'h0000;
          tmp4 <= #1 18'h0000;
          tmp5 <= #1 18'h0000;
          tmp6 <= #1 18'h0000;
          tmp7 <= #1 18'h0000;
        end
      else
        begin
          tmp0 <= #1 tmp0;
          tmp1 <= #1 tmp1;
          tmp2 <= #1 tmp2;
          tmp3 <= #1 tmp3;
          tmp4 <= #1 tmp4;
          tmp5 <= #1 tmp5;
          tmp6 <= #1 tmp6;
          tmp7 <= #1 tmp7; 
          case (c_state)
            DCT_CAL_P1  : begin
                            tmp0 <= #1 tmp_du[0] + tmp_du[7];
                            tmp1 <= #1 tmp_du[1] + tmp_du[6];
                            tmp2 <= #1 tmp_du[2] + tmp_du[5];
                            tmp3 <= #1 tmp_du[3] + tmp_du[4];
                            tmp4 <= #1 tmp_du[3] - tmp_du[4];
                            tmp5 <= #1 tmp_du[2] - tmp_du[5];
                            tmp6 <= #1 tmp_du[1] - tmp_du[6];
                            tmp7 <= #1 tmp_du[0] - tmp_du[7];            
                          end
            DCT_CAL_P3  : begin
                            tmp1 <= #1 tmp12 + tmp13; //z1
                            tmp2 <= #1 tmp20 << 2;    //z2                           
                            tmp3 <= #1 {tmp21[15:0], 2'b00} + tmp21;  //z3                          
                            tmp4 <= #1 {tmp22[14:0], 3'b000} + {tmp22[16:0], 1'b0}; //z4
                            tmp5 <= #1 tmp20 - tmp22; //z5
                            tmp6 <= #1 tmp13 << 3;    //du2/6: (tmp13 * 10)                            
                          end
            DCT_CAL_P5  : begin
                            tmp0 <= #1 tmp6 + tmp10;  //du2/6: + z1
                            tmp7 <= #1 tmp6 - tmp10;  //du2/6: - z1          
                          end     
            DCT_CAL_P6  : begin
                            tmp1 <= #1 tmp20 + tmp21; //du5: z13 + z2
                            tmp2 <= #1 tmp20 - tmp21; //du3: z13 - z2
                            tmp3 <= #1 tmp13 + tmp22; //du1: z11 + z4
                            tmp4 <= #1 tmp13 - tmp22; //du7: z11 - z4
                          end
            default     : begin
                            tmp0 <= #1 tmp0;
                            tmp1 <= #1 tmp1;
                            tmp2 <= #1 tmp2;
                            tmp3 <= #1 tmp3;
                            tmp4 <= #1 tmp4;
                            tmp5 <= #1 tmp5;
                            tmp6 <= #1 tmp6;
                            tmp7 <= #1 tmp7;             
                          end            
          endcase          
        end        
    end
    
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          tmp10 <= #1 18'h0000;
          tmp11 <= #1 18'h0000;
          tmp12 <= #1 18'h0000;
          tmp13 <= #1 18'h0000;
          tmp20 <= #1 18'h0000;
          tmp21 <= #1 18'h0000;
          tmp22 <= #1 18'h0000;
        end
      else
        begin
          tmp10 <= #1 tmp10;
          tmp11 <= #1 tmp11;
          tmp12 <= #1 tmp12;
          tmp13 <= #1 tmp13;
          tmp20 <= #1 tmp20;
          tmp21 <= #1 tmp21;
          tmp22 <= #1 tmp22; 
          case (c_state)
            DCT_CAL_P2  : begin
                            tmp10 <= #1 tmp0 + tmp3;
                            tmp11 <= #1 tmp1 + tmp2;
                            tmp12 <= #1 tmp1 - tmp2;
                            tmp13 <= #1 tmp0 - tmp3;
                            tmp20 <= #1 tmp4 + tmp5;
                            tmp21 <= #1 tmp5 + tmp6;
                            tmp22 <= #1 tmp6 + tmp7;           
                          end
            DCT_CAL_P4  : begin                        
                            tmp10 <= #1 {tmp1[15:0], 2'b00} + tmp1; //z1                           
                            tmp11 <= #1 {tmp5[16:0], 1'b0} + tmp5; //z5
                            tmp12 <= #1 tmp7 << 3;   //z11/z13: (tmp7 * 10)           
                          end 
            DCT_CAL_P5  : begin
                            tmp13 <= #1 tmp12 + tmp3; //z11
                            tmp20 <= #1 tmp12 - tmp3; //z13
                            tmp21 <= #1 tmp2 + tmp11; //z2
                            tmp22 <= #1 tmp4 + tmp11; //z4                            
                          end 
`ifdef UNSIGNED_SHIFT                          
            DCT_CAL_P6  : begin
                            tmp10 <= #1 (tmp0[17]) ? 19'h40000-tmp0 : tmp0;
                            tmp11 <= #1 (tmp7[17]) ? 19'h40000-tmp7 : tmp7;
                          end         
            DCT_CAL_P7  : begin
                            tmp13 <= #1 (tmp1[17]) ? 19'h40000-tmp1 : tmp1;
                            tmp20 <= #1 (tmp2[17]) ? 19'h40000-tmp2 : tmp2;
                            tmp21 <= #1 (tmp3[17]) ? 19'h40000-tmp3 : tmp3;
                            tmp22 <= #1 (tmp4[17]) ? 19'h40000-tmp4 : tmp4;
                            tmp10 <= #1 tmp10 >> 3;
                            tmp11 <= #1 tmp11 >> 3;
                          end
            DCT_CAL_P8  : begin
                            tmp13 <= #1 tmp13 >> 3;
                            tmp20 <= #1 tmp20 >> 3;
                            tmp21 <= #1 tmp21 >> 3;
                            tmp22 <= #1 tmp22 >> 3;
                          end
`endif                          
            default     : begin
                            tmp10 <= #1 tmp10;
                            tmp11 <= #1 tmp11;
                            tmp12 <= #1 tmp12;
                            tmp13 <= #1 tmp13;
                            tmp20 <= #1 tmp20;
                            tmp21 <= #1 tmp21;
                            tmp22 <= #1 tmp22;             
                          end            
          endcase          
        end        
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          dctdu_w_idx <= #1 6'h00;
          dctdu_w_en  <= #1 1'b0;
          dctdu_w_d   <= #1 18'h00000;
        end
      else
        begin
          dctdu_w_idx <= #1 dctdu_w_idx;
          dctdu_w_en  <= #1 1'b0;
          dctdu_w_d   <= #1 dctdu_w_d;
          case (c_state)
            SV_DCTDU_S,
            SV_DCTDU_R  : begin
                            dctdu_w_idx <= #1 dctdu_w_idx + 6'h01;
                            dctdu_w_en  <= #1 1'b1;
                            dctdu_w_d   <= #1 tmp_du[dctdu_w_idx[2:0]];             
                          end
            default     : begin
                            dctdu_w_idx <= #1 dctdu_w_idx;
                            dctdu_w_en  <= #1 1'b0;
                            dctdu_w_d   <= #1 dctdu_w_d;            
                          end            
          endcase          
        end        
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        dctdu_w_idx_fl <= #1 6'h00;
      else
        dctdu_w_idx_fl <= #1 dctdu_w_idx;      
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        vertical_scan <= #1 1'b0;
      else
        case (c_state)
          IDLE        : vertical_scan <= #1 1'b0;
          SCAN_CHECK  : vertical_scan <= #1 change_scan ? 1'b1 : vertical_scan;
          default     : vertical_scan <= #1 vertical_scan;
        endcase        
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        vertical_scan_fl <= #1 1'b0;
      else
        vertical_scan_fl <= #1 vertical_scan;      
    end    
    
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        e_conv_reg <= #1 1'b0;
      else
      if (c_state == EXIT)
        e_conv_reg <= #1 1'b1;
      else
        e_conv_reg <= #1 1'b0;      
    end    
  
endmodule  
