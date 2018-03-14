parameter HEADER_SIZE = 607;

reg [7:0] header_rom [HEADER_SIZE-1:0];
reg [15:0] ydc_ht_rom [11:0][1:0];
reg [15:0] uvdc_ht_rom [11:0][1:0];
reg [15:0] yac_ht_rom [255:0][1:0];
reg [15:0] uvac_ht_rom [255:0][1:0];
reg [5:0] zigzag_idx [63:0];
reg [7:0] fdtbl_Y [63:0];
reg [7:0] fdtbl_UV [63:0]; 

initial
  begin			   
    $readmemh("header_rom_data.v", header_rom);
    $readmemh("ydcht_rom_data.v", ydc_ht_rom);//$readmemh("ht_rom_data.v", ydc_ht_rom, 0, 23);
    $readmemh("uvdcht_rom_data.v", uvdc_ht_rom);//$readmemh("ht_rom_data.v", uvdc_ht_rom, 24, 47);
    $readmemh("yacht_rom_data.v", yac_ht_rom);//$readmemh("ht_rom_data.v", yac_ht_rom, 48, 303);
    $readmemh("uvacht_rom_data.v", uvac_ht_rom);//$readmemh("ht_rom_data.v", uvac_ht_rom, 304, 559);
    $readmemh("zzidx_rom_data.v", zigzag_idx);//$readmemh("misc_rom_data.v", zigzag_idx, 1, 64);
    $readmemh("fdty_rom_data.v", fdtbl_Y);//$readmemh("misc_rom_data.v", fdtbl_Y, 65, 128);
    $readmemh("fdtuv_rom_data.v", fdtbl_UV);//$readmemh("misc_rom_data.v", fdtbl_UV, 129, 192);
  end
  
  