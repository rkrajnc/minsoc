`include "minsoc_bench_defines.v"
`include "minsoc_defines.v"
`include "or1200_defines.v"

module minsoc_bench();

reg clock, reset;

wire dbg_tms_i;
wire dbg_tck_i;
wire dbg_tdi_i;
wire dbg_tdo_o;
wire jtag_vref;
wire jtag_gnd;

wire spi_mosi;
reg spi_miso;
wire spi_sclk;
wire [1:0] spi_ss;

wire uart_stx;
reg uart_srx;

wire eth_col;
wire eth_crs;
wire eth_trst;
wire eth_tx_clk;
wire eth_tx_en;
wire eth_tx_er;
wire [3:0] eth_txd;
wire eth_rx_clk;
wire eth_rx_dv;
wire eth_rx_er;
wire [3:0] eth_rxd;
wire eth_fds_mdint;
wire eth_mdc;
wire eth_mdio;

//
//	TASKS registers to communicate with interfaces
//
reg [7:0] tx_data [0:1518];		//receive buffer
reg [31:0] data_in [1023:0];		//send buffer


//
// Testbench mechanics
//
reg [7:0] program_mem[(1<<(`MEMORY_ADR_WIDTH+2))-1:0];
integer initialize, final, ptr;
reg [8*64:0] file_name;
reg load_file;

initial begin
    reset = 1'b0;
    clock = 1'b0;
    uart_srx = 1'b1;

//dual and two port rams from FPGA memory instances have to be initialized to
//0
    init_fpga_memory();

	load_file = 1'b0;
`ifdef INITIALIZE_MEMORY_MODEL 
	load_file = 1'b1;
`endif
`ifdef START_UP
	load_file = 1'b1;
`endif

	//get firmware hex file from command line input
	if ( load_file ) begin
		if ( ! $value$plusargs("file_name=%s", file_name) || file_name == 0 ) begin
			$display("ERROR: please specify an input file to start.");
			$finish;
		end
		$readmemh(file_name, program_mem);
		// First word comprehends size of program
		final = { program_mem[0] , program_mem[1] , program_mem[2] , program_mem[3] };
	end

`ifdef INITIALIZE_MEMORY_MODEL 
	// Initialize memory with firmware
	initialize = 0;
	while ( initialize < final ) begin
		minsoc_top_0.onchip_ram_top.block_ram_3.mem[initialize/4] = program_mem[initialize];
		minsoc_top_0.onchip_ram_top.block_ram_2.mem[initialize/4] = program_mem[initialize+1];
		minsoc_top_0.onchip_ram_top.block_ram_1.mem[initialize/4] = program_mem[initialize+2];
		minsoc_top_0.onchip_ram_top.block_ram_0.mem[initialize/4] = program_mem[initialize+3];
        initialize = initialize + 4;
	end
	$display("Memory model initialized with firmware:");
	$display("%s", file_name);
	$display("%d Bytes loaded from %d ...", initialize , final);
`endif

    // Reset controller
    repeat (2) @ (negedge clock);
    reset = 1'b1;
    repeat (16) @ (negedge clock);
    reset = 1'b0;

`ifdef START_UP
	// Pass firmware over spi to or1k_startup
	ptr = 0;
	//read dummy
	send_spi(program_mem[ptr]);
	send_spi(program_mem[ptr]);
	send_spi(program_mem[ptr]);
	send_spi(program_mem[ptr]);
	//~read dummy
	while ( ptr < final ) begin
		send_spi(program_mem[ptr]);
		ptr = ptr + 1;
	end
	$display("Memory start-up completed...");
	$display("Loaded firmware:");
	$display("%s", file_name);
`endif
	//
    // Testbench START
	//


end


//
// Modules instantiations
//
minsoc_top minsoc_top_0(
   .clk(clock),
   .reset(reset)

   //JTAG ports
`ifdef GENERIC_TAP
   , .jtag_tdi(dbg_tdi_i),
   .jtag_tms(dbg_tms_i),
   .jtag_tck(dbg_tck_i),
   .jtag_tdo(dbg_tdo_o),
   .jtag_vref(jtag_vref),
   .jtag_gnd(jtag_gnd)
`endif

   //SPI ports
`ifdef START_UP
   , .spi_flash_mosi(spi_mosi), 
   .spi_flash_miso(spi_miso), 
   .spi_flash_sclk(spi_sclk), 
   .spi_flash_ss(spi_ss)
`endif

   //UART ports
`ifdef UART
   , .uart_stx(uart_stx),
   .uart_srx(uart_srx)
`endif // !UART

	// Ethernet ports
`ifdef ETHERNET
	, .eth_col(eth_col), 
    .eth_crs(eth_crs), 
    .eth_trste(eth_trst), 
    .eth_tx_clk(eth_tx_clk),
	.eth_tx_en(eth_tx_en), 
    .eth_tx_er(eth_tx_er), 
    .eth_txd(eth_txd), 
    .eth_rx_clk(eth_rx_clk),
	.eth_rx_dv(eth_rx_dv), 
    .eth_rx_er(eth_rx_er), 
    .eth_rxd(eth_rxd), 
    .eth_fds_mdint(eth_fds_mdint),
	.eth_mdc(eth_mdc), 
    .eth_mdio(eth_mdio)
`endif // !ETHERNET
);

`ifdef VPI_DEBUG
	dbg_comm_vpi dbg_if(
		.SYS_CLK(clock),
		.P_TMS(dbg_tms_i), 
		.P_TCK(dbg_tck_i), 
		.P_TRST(), 
		.P_TDI(dbg_tdi_i), 
		.P_TDO(dbg_tdo_o)
	);
`else
   assign dbg_tdi_i = 1;
   assign dbg_tck_i = 0;
   assign dbg_tms_i = 1;
`endif

`ifdef ETHERNET
eth_phy my_phy // This PHY model simulate simplified Intel LXT971A PHY
(
	  // COMMON
	  .m_rst_n_i(1'b1),

	  // MAC TX
	  .mtx_clk_o(eth_tx_clk),
	  .mtxd_i(eth_txd),
	  .mtxen_i(eth_tx_en),
	  .mtxerr_i(eth_tx_er),

	  // MAC RX
	  .mrx_clk_o(eth_rx_clk),
	  .mrxd_o(eth_rxd),
	  .mrxdv_o(eth_rx_dv),
	  .mrxerr_o(eth_rx_er),

	  .mcoll_o(eth_col),
	  .mcrs_o(eth_crs),

	  // MIIM
	  .mdc_i(eth_mdc),
	  .md_io(eth_mdio),

	  // SYSTEM
	  .phy_log()
);	
`endif // !ETHERNET


//
//	Regular clocking and output
//
always begin
    #((`CLK_PERIOD)/2) clock <= ~clock;
end

`ifdef VCD_OUTPUT
initial begin
	$dumpfile("../results/minsoc_wave.vcd");
	$dumpvars();
end
`endif


//
//	Functionalities tasks: SPI Startup and UART Monitor
//
//SPI START_UP
`ifdef START_UP
task send_spi;
    input [7:0] data_in;
    integer i;
    begin
	i = 7;
	for ( i = 7 ; i >= 0; i = i - 1 ) begin
        	spi_miso = data_in[i];
			@ (posedge spi_sclk);
	    end
    end
endtask
`endif
//~SPI START_UP

//UART Monitor (prints uart output on the terminal)
`ifdef UART
parameter UART_TX_WAIT = (`FREQ / `UART_BAUDRATE) * `CLK_PERIOD;

// Something to trigger the task
always @(posedge clock)
	uart_decoder;

task uart_decoder;
	integer i;
	reg [7:0] tx_byte;
	begin

	// Wait for start bit
	while (uart_stx == 1'b1)
		@(uart_stx);

	#(UART_TX_WAIT+(UART_TX_WAIT/2));

    for ( i = 0; i < 8 ; i = i + 1 ) begin
		tx_byte[i] = uart_stx;
		#UART_TX_WAIT;
	end

	//Check for stop bit
	if (uart_stx == 1'b0) begin
		  //$display("* WARNING: user stop bit not received when expected at time %d__", $time);
	  // Wait for return to idle
		while (uart_stx == 1'b0)
			@(uart_stx);
	  //$display("* USER UART returned to idle at time %d",$time);
	end
	// display the char
	$write("%c", tx_byte);
	end
endtask
`endif // !UART
//~UART Monitor


//
//	TASKS to communicate with interfaces
//
//MAC_DATA
//
`ifdef ETHERNET
reg [31:0] crc32_result;

task get_mac;
    integer conta;
    reg LSB;
    begin
        conta = 0;
        LSB = 1;
        @ ( posedge eth_tx_en);
        while ( eth_tx_en == 1'b1 ) begin
            @ (negedge eth_tx_clk) begin
                if ( LSB == 1'b1 )
                    tx_data[conta][3:0] = eth_txd;
                else begin
                    tx_data[conta][7:4] = eth_txd;
                    conta = conta + 1;
                end
                LSB = ~LSB;
            end
        end
    end
endtask

task send_mac;
    input [11:0] command;
    input [31:0] param1;
    input [31:0] param2;
    input [223:0] data;

    integer conta;

    begin
        //DEST MAC
        my_phy.rx_mem[0] = 8'h55;
        my_phy.rx_mem[1] = 8'h47;
        my_phy.rx_mem[2] = 8'h34;
        my_phy.rx_mem[3] = 8'h22;
        my_phy.rx_mem[4] = 8'h88;
        my_phy.rx_mem[5] = 8'h92;

        //SOURCE MAC
        my_phy.rx_mem[6] = 8'h00;
        my_phy.rx_mem[7] = 8'h00;
        my_phy.rx_mem[8] = 8'hC0;
        my_phy.rx_mem[9] = 8'h41;
        my_phy.rx_mem[10] = 8'h36;
        my_phy.rx_mem[11] = 8'hD3;

        //LEN
        my_phy.rx_mem[12] = 8'h00;
        my_phy.rx_mem[13] = 8'h04;

        //DATA
        my_phy.rx_mem[14] = 8'hFF;
        my_phy.rx_mem[15] = 8'hFA;
        my_phy.rx_mem[16] = command[11:4];
        my_phy.rx_mem[17] = { command[3:0] , 4'h7 };

        my_phy.rx_mem[18] = 8'hAA;
        my_phy.rx_mem[19] = 8'hAA;

        //parameter 1
        my_phy.rx_mem[20] = param1[31:24];
        my_phy.rx_mem[21] = param1[23:16];
        my_phy.rx_mem[22] = param1[15:8];
        my_phy.rx_mem[23] = param1[7:0];

        //parameter 2
        my_phy.rx_mem[24] = param2[31:24];
        my_phy.rx_mem[25] = param2[23:16];
        my_phy.rx_mem[26] = param2[15:8];
        my_phy.rx_mem[27] = param2[7:0];

        //data
        my_phy.rx_mem[28] = data[223:216];
        my_phy.rx_mem[29] = data[215:208];
        my_phy.rx_mem[30] = data[207:200];
        my_phy.rx_mem[31] = data[199:192];
        my_phy.rx_mem[32] = data[191:184];
        my_phy.rx_mem[33] = data[183:176];
        my_phy.rx_mem[34] = data[175:168];
        my_phy.rx_mem[35] = data[167:160];
        my_phy.rx_mem[36] = data[159:152];
        my_phy.rx_mem[37] = data[151:144];
        my_phy.rx_mem[38] = data[143:136];
        my_phy.rx_mem[39] = data[135:128];
        my_phy.rx_mem[40] = data[127:120];
        my_phy.rx_mem[41] = data[119:112];
        my_phy.rx_mem[42] = data[111:104];
        my_phy.rx_mem[43] = data[103:96];
        my_phy.rx_mem[44] = data[95:88];
        my_phy.rx_mem[45] = data[87:80];
        my_phy.rx_mem[46] = data[79:72];
        my_phy.rx_mem[47] = data[71:64];
        my_phy.rx_mem[48] = data[63:56];
        my_phy.rx_mem[49] = data[55:48];
        my_phy.rx_mem[50] = data[47:40];
        my_phy.rx_mem[51] = data[39:32];
        my_phy.rx_mem[52] = data[31:24];
        my_phy.rx_mem[53] = data[23:16];
        my_phy.rx_mem[54] = data[15:8];
        my_phy.rx_mem[55] = data[7:0];

        //PAD
        for ( conta = 56; conta < 60; conta = conta + 1 ) begin
            my_phy.rx_mem[conta] = 8'h00;
        end

        gencrc32;

        my_phy.rx_mem[60] = crc32_result[31:24];
        my_phy.rx_mem[61] = crc32_result[23:16];
        my_phy.rx_mem[62] = crc32_result[15:8];
        my_phy.rx_mem[63] = crc32_result[7:0];

        my_phy.send_rx_packet( 64'h0055_5555_5555_5555, 4'h7, 8'hD5, 32'h0000_0000, 32'h0000_0040, 1'b0 );  
    end

endtask

//CRC32
parameter [31:0] CRC32_POLY = 32'h04C11DB7;

task gencrc32;
    integer	byte, bit;
    reg		msb;
    reg [7:0]	current_byte;
    reg [31:0]	temp;

    integer crc32_length;

    begin
        crc32_length = 60;
        crc32_result = 32'hffffffff;
        for (byte = 0; byte < crc32_length; byte = byte + 1) begin
            current_byte = my_phy.rx_mem[byte];
            for (bit = 0; bit < 8; bit = bit + 1) begin
                msb = crc32_result[31];
                crc32_result = crc32_result << 1;
                if (msb != current_byte[bit]) begin
                    crc32_result = crc32_result ^ CRC32_POLY;
                    crc32_result[0] = 1;
                end
            end
        end

        // Last step is to "mirror" every bit, swap the 4 bytes, and then complement each bit.
        //
        // Mirror:
        for (bit = 0; bit < 32; bit = bit + 1)
            temp[31-bit] = crc32_result[bit];

        // Swap and Complement:
        crc32_result = ~{temp[7:0], temp[15:8], temp[23:16], temp[31:24]};
    end
endtask
//~CRC32
`endif // !ETHERNET
//~MAC_DATA



//
// TASK to initialize instantiated FPGA dual and two port memory to 0
//
task init_fpga_memory;
    integer i;
    begin
`ifdef OR1200_RFRAM_TWOPORT
`ifdef OR1200_XILINX_RAMB4
    for ( i = 0; i < (1<<8); i = i + 1 ) begin
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.ramb4_s16_s16_0.mem[i] = 16'h0000;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.ramb4_s16_s16_1.mem[i] = 16'h0000;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.ramb4_s16_s16_0.mem[i] = 16'h0000;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.ramb4_s16_s16_1.mem[i] = 16'h0000;
    end
`elsif OR1200_XILINX_RAMB16
    for ( i = 0; i < (1<<9); i = i + 1 ) begin
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.ramb16_s36_s36.mem[i] = 32'h0000_0000;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.ramb16_s36_s36.mem[i] = 32'h0000_0000;
    end
`elsif OR1200_ALTERA_LPM
`ifndef OR1200_ALTERA_LPM_XXX
    $display("Definition OR1200_ALTERA_LPM in or1200_defines.v does not enable ALTERA memory for neither DUAL nor TWO port RFRAM");
    $display("It uses GENERIC memory instead.");
    $display("Add '`define OR1200_ALTERA_LPM_XXX' under '`define OR1200_ALTERA_LPM' on or1200_defines.v to use ALTERA memory.");
`endif
`ifdef OR1200_ALTERA_LPM_XXX
    $display("...Using ALTERA memory for TWOPORT RFRAM!");
    for ( i = 0; i < (1<<5); i = i + 1 ) begin
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.altqpram_component.mem[i] = 32'h0000_0000;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.altqpram_component.mem[i] = 32'h0000_0000;
    end
`else
    $display("...Using GENERIC memory!");
    for ( i = 0; i < (1<<5); i = i + 1 ) begin
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.mem[i] = 32'h0000_0000;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.mem[i] = 32'h0000_0000;
    end
`endif
`elsif OR1200_XILINX_RAM32X1D
    $display("Definition OR1200_XILINX_RAM32X1D in or1200_defines.v does not enable FPGA memory for TWO port RFRAM");
    $display("It uses GENERIC memory instead.");
    $display("FPGA memory can be used if you choose OR1200_RFRAM_DUALPORT");
    for ( i = 0; i < (1<<5); i = i + 1 ) begin
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.mem[i] = 32'h0000_0000;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.mem[i] = 32'h0000_0000;
    end
`else
    for ( i = 0; i < (1<<5); i = i + 1 ) begin
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.mem[i] = 32'h0000_0000;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.mem[i] = 32'h0000_0000;
    end
`endif
`elsif OR1200_RFRAM_DUALPORT
`ifdef OR1200_XILINX_RAMB4
    for ( i = 0; i < (1<<8); i = i + 1 ) begin
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.ramb4_s16_0.mem[i] = 16'h0000;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.ramb4_s16_1.mem[i] = 16'h0000;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.ramb4_s16_0.mem[i] = 16'h0000;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.ramb4_s16_1.mem[i] = 16'h0000;
    end
`elsif OR1200_XILINX_RAMB16
    for ( i = 0; i < (1<<9); i = i + 1 ) begin
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.ramb16_s36_s36.mem[i] = 32'h0000_0000;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.ramb16_s36_s36.mem[i] = 32'h0000_0000;
    end
`elsif OR1200_ALTERA_LPM
`ifndef OR1200_ALTERA_LPM_XXX
    $display("Definition OR1200_ALTERA_LPM in or1200_defines.v does not enable ALTERA memory for neither DUAL nor TWO port RFRAM");
    $display("It uses GENERIC memory instead.");
    $display("Add '`define OR1200_ALTERA_LPM_XXX' under '`define OR1200_ALTERA_LPM' on or1200_defines.v to use ALTERA memory.");
`endif
`ifdef OR1200_ALTERA_LPM_XXX
    $display("...Using ALTERA memory for DUALPORT RFRAM!");
    for ( i = 0; i < (1<<5); i = i + 1 ) begin
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.altqpram_component.mem[i] = 32'h0000_0000;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.altqpram_component.mem[i] = 32'h0000_0000;
    end
`else
    $display("...Using GENERIC memory!");
    for ( i = 0; i < (1<<5); i = i + 1 ) begin
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.mem[i] = 32'h0000_0000;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.mem[i] = 32'h0000_0000;
    end
`endif
`elsif OR1200_XILINX_RAM32X1D
`ifdef OR1200_USE_RAM16X1D_FOR_RAM32X1D
    for ( i = 0; i < (1<<4); i = i + 1 ) begin
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_0_0.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_0_1.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_0_2.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_0_3.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_0_4.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_0_5.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_0_6.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_0_7.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_1_0.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_1_1.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_1_2.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_1_3.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_1_4.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_1_5.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_1_6.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_1_7.mem[i] = 1'b0;

        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_0_0.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_0_1.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_0_2.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_0_3.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_0_4.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_0_5.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_0_6.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_0_7.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_1_0.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_1_1.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_1_2.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_1_3.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_1_4.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_1_5.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_1_6.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_1_7.mem[i] = 1'b0;

        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_0_0.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_0_1.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_0_2.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_0_3.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_0_4.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_0_5.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_0_6.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_0_7.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_1_0.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_1_1.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_1_2.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_1_3.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_1_4.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_1_5.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_1_6.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_1_7.mem[i] = 1'b0;

        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_0_0.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_0_1.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_0_2.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_0_3.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_0_4.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_0_5.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_0_6.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_0_7.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_1_0.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_1_1.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_1_2.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_1_3.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_1_4.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_1_5.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_1_6.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_1_7.mem[i] = 1'b0;

        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_0_0.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_0_1.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_0_2.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_0_3.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_0_4.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_0_5.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_0_6.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_0_7.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_1_0.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_1_1.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_1_2.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_1_3.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_1_4.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_1_5.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_1_6.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_1_7.mem[i] = 1'b0;

        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_0_0.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_0_1.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_0_2.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_0_3.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_0_4.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_0_5.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_0_6.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_0_7.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_1_0.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_1_1.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_1_2.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_1_3.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_1_4.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_1_5.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_1_6.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_1_7.mem[i] = 1'b0;

        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_0_0.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_0_1.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_0_2.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_0_3.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_0_4.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_0_5.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_0_6.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_0_7.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_1_0.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_1_1.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_1_2.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_1_3.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_1_4.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_1_5.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_1_6.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_1_7.mem[i] = 1'b0;

        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_0_0.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_0_1.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_0_2.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_0_3.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_0_4.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_0_5.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_0_6.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_0_7.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_1_0.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_1_1.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_1_2.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_1_3.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_1_4.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_1_5.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_1_6.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_1_7.mem[i] = 1'b0;
    end
`else
    for ( i = 0; i < (1<<4); i = i + 1 ) begin
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_0.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_1.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_2.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_3.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_4.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_5.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_6.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_0.ram32x1d_7.mem[i] = 1'b0;

        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_0.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_1.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_2.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_3.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_4.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_5.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_6.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_1.ram32x1d_7.mem[i] = 1'b0;

        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_0.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_1.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_2.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_3.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_4.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_5.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_6.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_2.ram32x1d_7.mem[i] = 1'b0;

        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_0.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_1.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_2.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_3.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_4.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_5.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_6.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.xcv_ram32x8d_3.ram32x1d_7.mem[i] = 1'b0;

        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_0.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_1.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_2.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_3.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_4.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_5.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_6.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_0.ram32x1d_7.mem[i] = 1'b0;

        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_0.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_1.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_2.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_3.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_4.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_5.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_6.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_1.ram32x1d_7.mem[i] = 1'b0;

        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_0.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_1.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_2.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_3.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_4.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_5.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_6.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_2.ram32x1d_7.mem[i] = 1'b0;

        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_0.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_1.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_2.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_3.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_4.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_5.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_6.mem[i] = 1'b0;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.xcv_ram32x8d_3.ram32x1d_7.mem[i] = 1'b0;
    end
`endif
`else
    for ( i = 0; i < (1<<5); i = i + 1 ) begin
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_a.mem[i] = 32'h0000_0000;
        minsoc_top_0.or1200_top.or1200_cpu.or1200_rf.rf_b.mem[i] = 32'h0000_0000;
    end
`endif
`endif
    end
endtask



endmodule

