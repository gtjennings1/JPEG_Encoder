//parameter HEADER_SIZE = 607;

//reg [7:0] header_rom [HEADER_SIZE-1:0];
//reg [15:0] ydc_ht_bb_rom [11:0];//[11:0][1:0];
//reg [4:0] ydc_ht_bc_rom [11:0];
//reg [15:0] uvdc_ht_bb_rom [11:0];
//reg [4:0] uvdc_ht_bc_rom [11:0];
//reg [15:0] yac_ht_bb_rom [255:0];
//reg [4:0] yac_ht_bc_rom [255:0];
//reg [15:0] uvac_ht_bb_rom [255:0];
//reg [4:0] uvac_ht_bc_rom [255:0];
//reg [5:0] zigzag_idx [63:0];
//reg [7:0] fdtbl_Y [63:0];
//reg [7:0] fdtbl_UV [63:0]; 

initial
  begin			   
    //$readmemh("../../src/header_rom_data.h", header_rom);
    //$readmemh("ydcht_bb_rom_data.h", ydc_ht_bb_rom);
	//$readmemh("ydcht_bc_rom_data.h", ydc_ht_bc_rom);
    //$readmemh("uvdcht_bb_rom_data.h", uvdc_ht_bb_rom);
	//$readmemh("uvdcht_bc_rom_data.h", uvdc_ht_bc_rom);
    //$readmemh("yacht_bb_rom_data.h", yac_ht_bb_rom);
	//$readmemh("yacht_bc_rom_data.h", yac_ht_bc_rom);
    //$readmemh("uvacht_bb_rom_data.h", uvac_ht_bb_rom);
	//$readmemh("uvacht_bc_rom_data.h", uvac_ht_bc_rom);
    //$readmemh("zzidx_rom_data.h", zigzag_idx);
    //$readmemh("src/fdty_rom_data.h", fdtbl_Y);
    //$readmemh("fdtuv_rom_data.h", fdtbl_UV);
  end
  
  