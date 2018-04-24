`timescale 1 ns / 1 ns

module tb_jpeg_enc_w_gluelogic;

  reg    [7:0]    spram [131071:0];
  reg             pclk, reset_n, pixel_wr_disable, img_req;
  reg    [2:0]    spi_rd_cnt;
  
  reg    [3:0]    c_state, n_state;
  
  reg    [7:0]    mem_datar;
  
  reg    [15:0]   eoi_check_reg;

  
  parameter       WAIT0  = 0;
  parameter       JE_REQ = 1;
  parameter       WAIT1  = 2;
  parameter       YTY_RD = 3;
  parameter       WAIT2  = 4;
  parameter       JE_EN  = 5;
  parameter       WAIT3  = 6;
  parameter       SPI_RD = 7;
  parameter       WAIT4  = 8;
  
  parameter       EOI_MARK = 16'hFFD9;
  
  wire            yty_req = (c_state == YTY_RD);
  wire            yty_rd  = ((c_state == WAIT2) || (c_state == JE_EN) || (c_state == WAIT3));
  wire            je_wr   = (c_state == WAIT3);
  wire            je_en   = (c_state == JE_EN);

  wire   [16:0]   jedw_addr, yty_addr, jdts_addr;
  wire   [7:0]    jedw_data, je_data, yty_data, esp32_spi_data, hd_data;
  wire   [9:0]    hd_addr;
  wire            je_rd, je_valid, je_done, jedw_wr;
  
  wire            mem_wr    = je_wr ? jedw_wr : 1'b0;
  wire   [7:0]    mem_dataw = je_wr ? jedw_data : 8'h00;
  wire   [16:0]   mem_addrw = je_wr ? jedw_addr : 17'h00000;
  
  wire   [16:0]   mem_addrr = yty_rd ? yty_addr : jdts_addr;
  
  wire            img_rdy = (c_state == WAIT4);  
  wire            esp32_spi_rd = (&spi_rd_cnt);
  
  integer         file_in, r, file_out;

  yuyv_to_yuv yty (
    .clk       (pclk),
    .reset_n   (reset_n),
    
    .img_req   (yty_req),
    
    .addr      (yty_addr),
    .data      (mem_datar),
    
    .mem_wr    (mem_wr),
    
    .ready     (yty_ready),
    
    .je_rd     (je_rd),
    .je_data   (yty_data)  
  );  
  
  jpeg_enc je (
    .clk       (pclk),
    .reset_n   (reset_n),
    .conv_en   (je_en),
    .fb_data   (yty_data),
    //.fb_addr   (),
    .fb_rd     (je_rd),
    .img_out   (je_data),
    
    .hd_addr   (hd_addr),
    .hd_data   (hd_data),
    
    .img_valid (je_valid),
    .img_done  (je_done)
  );  
    
  jpeg_data_writer jedw (
    .clk       (pclk),
    .reset_n   (reset_n),
    
    .je_valid  (je_valid),
    .je_data   (je_data),
    .je_done   (je_done),

    .addr      (jedw_addr),
    .data      (jedw_data),
    .we        (jedw_wr)
  );
    
  jpeg_data_to_spi jdts (
    .clk       (pclk),
    .reset_n   (reset_n),
    
    .je_done   (je_done),
    
    .hd_addr   (hd_addr),
    .hd_data   (hd_data),
    
    .je_addr   (jdts_addr),
    .je_data   (mem_datar),
    
    .spi_rd    (esp32_spi_rd),
    .spi_data  (esp32_spi_data)
  );    
  
  initial
    begin
      pclk = 0;
      reset_n = 0;
      img_req = 0;
      pixel_wr_disable = 0;

      file_in = $fopen("default_320x200.uyvy", "rb");
      if(!file_in)
        begin 
          $display("Could not open output file");
          $finish;
        end

      r = $fread(spram, file_in);
      $fclose(file_in);

      file_out = $fopen("default_320x200.jpg", "wb");
      if (!file_out)
        begin
          $display("Could not open output file");
          $finish;
        end       
      
      #100
      reset_n = 1;
      #100
      img_req = 1;
      #100
      pixel_wr_disable = 1;
    end
  
  always @ (*)
    #5 pclk <= !pclk;
    
  always @ (posedge pclk)
    begin
      if (mem_wr)
        begin
          spram[mem_addrw] <= #1 mem_dataw;
          mem_datar <= #1 mem_datar;  
        end
      else
        begin
          mem_datar <= #1 spram[mem_addrr];
        end      
    end      
  
  always @ (posedge pclk or negedge reset_n)
    begin
      if (!reset_n)
        c_state <= #1 WAIT0;
      else
        c_state <= #1 n_state;      
    end
    
  always @ (c_state, img_req, pixel_wr_disable, yty_ready, je_done)
    begin
      case (c_state)
        WAIT0     : begin
                      if (img_req)
                        n_state <= #1 JE_REQ;
                      else
                        n_state <= #1 WAIT0;                      
                    end
        JE_REQ    : n_state <= #1 WAIT1;
        WAIT1     : begin
                      if (pixel_wr_disable)
                        n_state <= #1 YTY_RD;
                      else
                        n_state <= #1 WAIT1;                      
                    end
        YTY_RD    : n_state <= #1 WAIT2;
        WAIT2     : begin
                      if (yty_ready)
                        n_state <= #1 JE_EN;
                      else
                        n_state <= #1 WAIT2;                      
                    end
        JE_EN     : n_state <= #1 WAIT3;
        WAIT3     : begin
                      if (je_done)
                        n_state <= #1 SPI_RD;
                      else
                        n_state <= #1 WAIT3;                        
                    end
        SPI_RD    : n_state <= #1 WAIT4;
        WAIT4     : begin
                      if (!img_req)
                        n_state <= WAIT0;
                      else
                        n_state <= WAIT4;                      
                    end
        default   : n_state <= #1 WAIT0;
      endcase
    end 

  always @ (posedge pclk or negedge reset_n)
    begin
      if (!reset_n)
        spi_rd_cnt <= #1 3'h0;
      else
      if (img_rdy)
        spi_rd_cnt <= #1 spi_rd_cnt + 3'h1;
      else
        spi_rd_cnt <= #1 3'h0;      
    end    
    
  always @ (posedge pclk)
    begin
      if (esp32_spi_rd)
        $fwriteb(file_out, "%c", esp32_spi_data);     
    end

  always @ (posedge pclk or negedge reset_n)
    begin
      if (!reset_n)
        eoi_check_reg <= #1 16'h0000;
      else
      if (esp32_spi_rd)
        eoi_check_reg <= #1 {eoi_check_reg[7:0], esp32_spi_data};      
    end
  
  always @ (posedge pclk)
    begin
      if (eoi_check_reg == EOI_MARK)
        begin
          $fclose(file_out);
          $display("Conversion Done");
          $finish;
        end
    end 
  
endmodule
