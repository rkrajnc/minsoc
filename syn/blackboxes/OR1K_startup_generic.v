
`include "minsoc_defines.v"

module OR1K_startup
  (
    input [6:2]       wb_adr_i,
    input 	      wb_stb_i,
    input 	      wb_cyc_i,
    output reg [31:0] wb_dat_o,
    output reg 	      wb_ack_o,
    input 	      wb_clk,
    input 	      wb_rst
   );
   
endmodule // OR1K_startup
