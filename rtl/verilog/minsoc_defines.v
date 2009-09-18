//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1K test app definitions                                   ////
////                                                              ////
////  This file is part of the OR1K test application              ////
////  http://www.opencores.org/cores/or1k/xess/                   ////
////                                                              ////
////  Description                                                 ////
////  DEfine target technology etc. Right now FIFOs are available ////
////  only for Xilinx Virtex FPGAs. (TARGET_VIRTEX)               ////
////                                                              ////
////  To Do:                                                      ////
////   - nothing really                                           ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, damjan.lampret@opencores.org          ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2001 Authors                                   ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//
// CVS Revision History
//
// $Log: xsv_fpga_defines.v,v $
// Revision 1.4  2004/04/05 08:44:35  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.2  2002/03/29 20:58:51  lampret
// Changed hardcoded address for fake MC to use a define.
//
// Revision 1.1.1.1  2002/03/21 16:55:44  lampret
// First import of the "new" XESS XSV environment.
//
//
//


//
// Define FPGA manufacturer
//
//`define GENERIC_FPGA
//`define ALTERA_FPGA
`define XILINX_FPGA

// 
// Define FPGA Model (comment all out for ALTERA)
//
//`define SPARTAN2
//`define SPARTAN3
//`define SPARTAN3E
`define SPARTAN3A
//`define VIRTEX
//`define VIRTEX2
//`define VIRTEX4
//`define VIRTEX5


//
// Memory
//
`define MEMORY_ADR_WIDTH   13	//MEMORY_ADR_WIDTH IS NOT ALLOWED TO BE LESS THAN 12, memory is composed by blocks of address width 11
								//Address width of memory -> select memory depth, 2 powers MEMORY_ADR_WIDTH defines the memory depth 
								//the memory data width is 32 bit, memory amount in Bytes = 4*memory depth

//
// Memory type	(uncomment something if ASIC or if you want generic memory)
//
//`define GENERIC_MEMORY
//`define AVANT_ATP
//`define VIRAGE_SSP
//`define VIRTUALSILICON_SSP


//
// TAP selection
//
//`define GENERIC_TAP
`define FPGA_TAP

//
// Clock Division selection
//
//`define NO_CLOCK_DIVISION
//`define GENERIC_CLOCK_DIVISION
`define FPGA_CLOCK_DIVISION		//Altera ALTPLL is not implemented, didn't find the code for its verilog instantiation
								//if you selected altera and this, the GENERIC_CLOCK_DIVISION will be automatically taken

//
// Define division
//
`define CLOCK_DIVISOR 5		//in case of GENERIC_CLOCK_DIVISION the real value will be rounded down to an even value
							//in FPGA case, check minsoc_clock_manager for allowed divisors
							//DO NOT USE CLOCK_DIVISOR = 1 COMMENT THE CLOCK DIVISION SELECTION INSTEAD

//
// Start-up circuit (only necessary later to load firmware automatically from SPI memory)
//
//`define START_UP

//
// Connected modules
//
`define UART
//`define ETHERNET

//
// Ethernet reset
//
//`define ETH_RESET 	1'b0
`define ETH_RESET	1'b1

//
// Interrupts
//
`define APP_INT_RES1	1:0
`define APP_INT_UART	2
`define APP_INT_RES2	3
`define APP_INT_ETH	4
`define APP_INT_PS2	5
`define APP_INT_RES3	19:6

//
// Address map
//
`define APP_ADDR_DEC_W	8
`define APP_ADDR_SRAM	`APP_ADDR_DEC_W'h00
`define APP_ADDR_FLASH	`APP_ADDR_DEC_W'h04
`define APP_ADDR_DECP_W  4
`define APP_ADDR_PERIP  `APP_ADDR_DECP_W'h9
`define APP_ADDR_SPI	`APP_ADDR_DEC_W'h97
`define APP_ADDR_ETH	`APP_ADDR_DEC_W'h92
`define APP_ADDR_AUDIO	`APP_ADDR_DEC_W'h9d
`define APP_ADDR_UART	`APP_ADDR_DEC_W'h90
`define APP_ADDR_PS2	`APP_ADDR_DEC_W'h94
`define APP_ADDR_RES1	`APP_ADDR_DEC_W'h9e
`define APP_ADDR_RES2	`APP_ADDR_DEC_W'h9f

//
// Set-up GENERIC_TAP, GENERIC_MEMORY if GENERIC_FPGA was chosen
// and GENERIC_CLOCK_DIVISION if NO_CLOCK_DIVISION was not set
//
`ifdef GENERIC_FPGA
	`define GENERIC_TAP
	`define GENERIC_MEMORY
	`ifndef NO_CLOCK_DIVISION
		`define GENERIC_CLOCK_DIVISION
	`endif
`endif
