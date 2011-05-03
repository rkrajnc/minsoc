
uart-nocache.hex: uart-nocache.bin
	$(BIN2HEX) $? 1 -size_word > $@

uart-nocache.bin: uart-nocache.or32
	$(OR32_TOOL_PREFIX)-objcopy -O binary $? $@

uart-nocache.or32: uart.o $(RESET_NOCACHE) $(SUPPORT) $(DRIVERS) $(LINKER_SCRIPT)
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $(GCC_LIB_OPTS) -T $(LINKER_SCRIPT) uart.o $(RESET_NOCACHE) $(SUPPORT) $(DRIVERS) -o $@


uart-icdc.hex: uart-icdc.bin
	$(BIN2HEX) $? 1 -size_word > $@

uart-icdc.bin: uart-icdc.or32
	$(OR32_TOOL_PREFIX)-objcopy -O binary $? $@

uart-icdc.or32: uart.o $(RESET_ICDC) $(SUPPORT) $(DRIVERS) $(LINKER_SCRIPT)
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $(GCC_LIB_OPTS) -T $(LINKER_SCRIPT) uart.o $(RESET_ICDC) $(SUPPORT) $(DRIVERS) -o $@


uart.o: uart.c $(BOARD_HDR) $(SUPPORT_HDR) $(OR1200_HDR) $(UART_HDR) $(ETH_HDR)
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $< -c -o $@
