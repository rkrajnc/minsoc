eth-nocache.hex: eth-nocache.bin
	$(BIN2HEX) $? 1 -size_word > $@

eth-nocache.bin: eth-nocache.or32
	$(OR32_TOOL_PREFIX)-objcopy -O binary $? $@

eth-nocache.or32: eth.o $(RESET_NOCACHE) $(SUPPORT) $(DRIVERS) $(LINKER_SCRIPT)
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $(GCC_LIB_OPTS) -T $(LINKER_SCRIPT) eth.o $(RESET_NOCACHE) $(SUPPORT) $(DRIVERS) -o $@


eth-icdc.hex: eth-icdc.bin
	$(BIN2HEX) $? 1 -size_word > $@

eth-icdc.bin: eth-icdc.or32
	$(OR32_TOOL_PREFIX)-objcopy -O binary $? $@

eth-icdc.or32: eth.o $(RESET_ICDC) $(SUPPORT) $(DRIVERS) $(LINKER_SCRIPT)
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $(GCC_LIB_OPTS) -T $(LINKER_SCRIPT) eth.o $(RESET_ICDC) $(SUPPORT) $(DRIVERS) -o $@


eth.o: eth.c $(BOARD_HDR) $(SUPPORT_HDR) $(OR1200_HDR) $(UART_HDR) $(ETH_HDR)
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $< -c -o $@
