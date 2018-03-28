`timescale 1ns/1ns

module jpeg_enc_tb;

  reg             clk;
  reg             reset_n;
  reg             conv_en;
  reg    [7:0]    fb_data;
  wire   [7:0]    img_out;
  wire            img_valid;
  wire            img_done;
  wire   [21:0]   fb_addr;
  
  reg    [2:0]    c_state, n_state;
  
  reg    [7:0]    frame_buf [(1024*768*3-1):0];
  
  integer         file_in, file_out, r;
  
  parameter       IDLE          = 3'h0;
  parameter       START_CONV    = 3'h1;
  parameter       START_STREAM  = 3'h2;
  parameter       READ_JPEG     = 3'h3;
  parameter       FINISH        = 3'h4;
  

  jpeg_enc dut (
    .clk        ( clk       ),
    .reset_n    ( reset_n   ),
    .conv_en    ( conv_en   ),
    .fb_addr    ( fb_addr   ),
    .fb_data    ( fb_data   ),
    .img_out    ( img_out   ),
    .img_valid  ( img_valid ),
    .img_done   ( img_done  )
  );
  
  
  initial
    begin
      clk       = 1'b0;
      reset_n   = 1'b0;
      conv_en   = 1'b0;
      //$readmemb("flower_1024x768_rgb.hex", frame_buf);
      file_in = $fopen("flower_1024x768_yuv.hex", "rb");
      if(!file_in)
        begin 
          $display("Could not open output file");
          $finish;
        end

      r = $fread(frame_buf, file_in);
      $fclose(file_in);      
      
      file_out = $fopen("flower_1024x768_yuv.jpg", "wb");
      if (!file_out)
        begin
          $display("Could not open output file");
          $finish;
        end 
      #100
      reset_n = 1'b1;      
    end
    
  always #10 clk = !clk;

  
  always @ (posedge clk)
    fb_data <= #1 frame_buf[fb_addr];
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        c_state <= #1 IDLE;
      else
        c_state <= #1 n_state;      
    end
    
  always @ (c_state or img_done)
    begin
      case(c_state)
        IDLE          : n_state <= #1 START_CONV;
        START_CONV    : n_state <= #1 START_STREAM;
        START_STREAM  : n_state <= #1 READ_JPEG;
        READ_JPEG     : if (img_done)
                          n_state <= #1 FINISH;
                        else
                          n_state <= #1 READ_JPEG;
        FINISH        : n_state <= #1 FINISH;  
        default       : n_state <= #1 IDLE;        
      endcase
    end    
    
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        conv_en <= #1 1'b0;
      else
      if (c_state == START_CONV)
        conv_en <= #1 1'b1;
      else
        conv_en <= #1 1'b0;
    end    
  
  always @ (posedge clk)
    begin
      if (img_valid)
        $fwriteb(file_out, "%c", img_out);//r = $fputc(file_out, img_out);//      
    end    
  
  always @ (posedge clk)
    begin
      if (c_state == FINISH)
        begin
          //$fclose(file_in);
          $fclose(file_out);
          $display("Conversion Done");
          $finish;
        end
    end
    
endmodule