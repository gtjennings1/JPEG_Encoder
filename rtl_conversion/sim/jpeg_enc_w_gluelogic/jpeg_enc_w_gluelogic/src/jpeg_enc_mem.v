module jpeg_enc_mem (
  input         clk,
  input         reset_n,
  
  //Header ROM
  input  [9:0]  header_rom_a,
  output [7:0]  header_rom_d,
  
  //DU RAM (YDU, VDU, UDU)
  input  [7:0]  du_ram_aw,
  input  [7:0]  du_ram_di,
  input         du_ram_we,
  input  [7:0]  du_ram_ar,
  output [7:0]  du_ram_do,
  
  //fdtbl ROM (Y, UV)
  input  [6:0]  fdtbl_rom_a,
  output [7:0]  fdtbl_rom_d,
  
  //ZIGZAG DU RAM
  input  [5:0]  zzdu_ram_aw,
  input  [14:0] zzdu_ram_di,
  input         zzdu_ram_we,
  input  [5:0]  zzdu_ram_ar,
  output [14:0] zzdu_ram_do,
  
  //ZIGZAG INDEX ROM
  input  [5:0]  zzidx_rom_a,
  output [5:0]  zzidx_rom_d,
  
  //DC HT BC ROM (YDC, UVDC)
  input  [4:0]  dcht_bc_rom_a,
  output [4:0]  dcht_bc_rom_d,
  
  //DC HT BB ROM (YDC, UVDC)
  input  [4:0]  dcht_bb_rom_a,
  output [15:0] dcht_bb_rom_d,
  
  //AC HT BC ROM (YDC, UVDC)
  input  [8:0]  acht_bc_rom_a,
  output [4:0]  acht_bc_rom_d,
  
  //AC HT BB ROM (YDC, UVDC)
  input  [8:0]  acht_bb_rom_a,
  output [15:0] acht_bb_rom_d,
  
  //DCTDU RAM
  input  [5:0]  dctdu_ram_aw,
  input  [17:0] dctdu_ram_di,
  input         dctdu_ram_we,
  input  [5:0]  dctdu_ram_ar,
  output [17:0] dctdu_ram_do  
  
  );
  
  
  reg    [7:0] header_rom [606:0];
  reg    [7:0] header_rom_data;
  
  reg    [7:0] du_ram [191:0];
  reg    [7:0] du_ram_data;
  
  reg    [7:0] fdtbl_rom [127:0];
  reg    [7:0] fdtbl_rom_data;
  
  reg    [14:0] zzdu_ram [63:0];
  reg    [14:0] zzdu_ram_data;
  
  reg    [5:0]  zzidx_rom [63:0];
  reg    [5:0]  zzidx_rom_data;
  
  reg    [4:0]  dcht_bc_rom [31:0];
  reg    [4:0]  dcht_bc_rom_data;
  
  reg    [15:0] dcht_bb_rom [31:0];
  reg    [15:0] dcht_bb_rom_data;
  
  reg    [4:0]  acht_bc_rom [511:0];
  reg    [4:0]  acht_bc_rom_data;
  
  reg    [15:0] acht_bb_rom [511:0];
  reg    [15:0] acht_bb_rom_data;
  
  reg    [17:0] dctdu_ram [63:0];
  reg    [17:0] dctdu_ram_data;
  
  assign       header_rom_d  = header_rom_data;
  assign       du_ram_do     = du_ram_data;
  assign       fdtbl_rom_d   = fdtbl_rom_data;
  assign       zzdu_ram_do   = zzdu_ram_data;
  assign       zzidx_rom_d   = zzidx_rom_data;
  assign       dcht_bc_rom_d = dcht_bc_rom_data;
  assign       dcht_bb_rom_d = dcht_bb_rom_data;
  assign       acht_bc_rom_d = acht_bc_rom_data;
  assign       acht_bb_rom_d = acht_bb_rom_data;
  assign       dctdu_ram_do  = dctdu_ram_data;
  
  initial
    begin
      $readmemh("header_rom_data.h", header_rom);
      $readmemh("fdtbl_rom.mem", fdtbl_rom);
      $readmemh("zzidx_rom_data.h", zzidx_rom);
      $readmemh("dcht_bc_rom.mem", dcht_bc_rom);
      $readmemh("dcht_bb_rom.mem", dcht_bb_rom);
      $readmemh("acht_bc_rom.mem", acht_bc_rom);
      $readmemh("acht_bb_rom.mem", acht_bb_rom);      
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        header_rom_data <= #1 8'h00;
      else
        header_rom_data <= #1 header_rom[header_rom_a];     
    end
  
  always @ (posedge clk)
    begin
      if (du_ram_we)
        du_ram[du_ram_aw] <= #1 du_ram_di;
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        du_ram_data <= #1 8'h00;
      else
        du_ram_data <= #1 du_ram[du_ram_ar];      
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        fdtbl_rom_data <= #1 8'h00;
      else
        fdtbl_rom_data <= #1 fdtbl_rom[fdtbl_rom_a];      
    end
  
  always @ (posedge clk)
    begin
      if (zzdu_ram_we)
        zzdu_ram[zzdu_ram_aw] <= #1 zzdu_ram_di;
    end  
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        zzdu_ram_data <= #1 8'h00;
      else
        zzdu_ram_data <= #1 zzdu_ram[zzdu_ram_ar];      
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        zzidx_rom_data <= #1 8'h00;
      else
        zzidx_rom_data <= #1 zzidx_rom[zzidx_rom_a];   
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        dcht_bc_rom_data <= #1 5'h00;
      else
        dcht_bc_rom_data <= #1 dcht_bc_rom[dcht_bc_rom_a];      
    end
    
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        dcht_bb_rom_data <= #1 16'h0000;
      else
        dcht_bb_rom_data <= #1 dcht_bb_rom[dcht_bb_rom_a];      
    end    

  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        acht_bc_rom_data <= #1 5'h00;
      else
        acht_bc_rom_data <= #1 acht_bc_rom[acht_bc_rom_a];      
    end
    
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        acht_bb_rom_data <= #1 16'h0000;
      else
        acht_bb_rom_data <= #1 acht_bb_rom[acht_bb_rom_a];      
    end    
    
  always @ (posedge clk)
    begin
      if (dctdu_ram_we)
        dctdu_ram[dctdu_ram_aw] <= #1 dctdu_ram_di;
    end
  
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        dctdu_ram_data <= #1 8'h00;
      else
        dctdu_ram_data <= #1 dctdu_ram[dctdu_ram_ar];      
    end    
    
endmodule  