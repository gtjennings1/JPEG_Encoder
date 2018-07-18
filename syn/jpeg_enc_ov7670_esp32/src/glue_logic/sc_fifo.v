`timescale 1ns/1ns

module sc_fifo (
  data_in, 
  data_out, 
  clk, 
  reset, 
  write, 
  read, 
  clear,
  almost_full, 
  full, 
  almost_empty, 
  empty, 
  cnt
  );
 
parameter DATA_WIDTH    = 8;
parameter DEPTH         = 512;
parameter CNT_WIDTH     = 10;
 
input                     clk;
input                     reset;
input                     write;
input                     read;
input                     clear;
input   [DATA_WIDTH-1:0]  data_in;
 
output  [DATA_WIDTH-1:0]  data_out;
output                    almost_full;
output                    full;
output                    almost_empty;
output                    empty;
output  [CNT_WIDTH-1:0]   cnt;
 

    reg     [DATA_WIDTH-1:0]  fifo  [0:DEPTH-1];
    reg     [DATA_WIDTH-1:0]  data_out;
 
reg     [CNT_WIDTH-1:0]   cnt;
reg     [CNT_WIDTH-2:0]   read_pointer;
reg     [CNT_WIDTH-2:0]   write_pointer;
    /*
    fifo_mem fm (
    .wr_clk_i( clk ), 
    .rd_clk_i( clk ), 
    .wr_clk_en_i( 1'b1 ), 
    .rd_en_i( 1'b1 ), 
    .rd_clk_en_i( 1'b1 ), 
    .wr_en_i( ), 
    .wr_data_i( data_in ), 
    .wr_addr_i( ), 
    .rd_addr_i( ), 
    .rd_data_o( )
    
    );
    */
 
always @ (posedge clk or posedge reset)
begin
  if(reset)
    cnt <= 0;
  else
  if(clear)
    cnt <= { {(CNT_WIDTH-1){1'b0}}, read^write};
  else
  if(read ^ write)
    if(read)
      cnt <= cnt - 1;
    else
      cnt <= cnt + 1;
end
 
 
always @ (posedge clk or posedge reset)
begin
  if(reset)
    read_pointer <= 0;
  else
  if(clear)
    read_pointer <= { {(CNT_WIDTH-2){1'b0}}, read};
  else
  if(read & ~empty)
    read_pointer <= read_pointer + 1'b1;
end
 
always @ (posedge clk or posedge reset)
begin
  if(reset)
    write_pointer <= 0;
  else
  if(clear)
    write_pointer <= { {(CNT_WIDTH-2){1'b0}}, write};
  else
  if(write & ~full)
    write_pointer <= write_pointer + 1'b1;
end
 
assign empty = ~(|cnt);
assign almost_empty = cnt == 1;
assign full  = cnt == DEPTH;
assign almost_full  = &cnt[CNT_WIDTH-2:0];
 
 
 

  always @ (posedge clk)
  begin
    //if(write & clear)
    //  fifo[0] <= data_in;
    //else
   if(write & ~full)
      fifo[write_pointer] <= data_in;
  end
 
 
  always @ (posedge clk)
  begin
    //if(clear)
    //  data_out <= fifo[0];
    //else
      data_out <= fifo[read_pointer];
  end

 
 
endmodule
