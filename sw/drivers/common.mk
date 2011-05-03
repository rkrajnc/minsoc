$(DRIVERS): $(DRIVERS_DIR)/interrupts.o $(DRIVERS_DIR)/eth.o $(DRIVERS_DIR)/uart.o $(DRIVERS_DIR)/can.o $(DRIVERS_DIR)/i2c.o
	$(OR32_TOOL_PREFIX)-ar cru $(DRIVERS_DIR)/libdrivers.a $(DRIVERS_DIR)/interrupts.o $(DRIVERS_DIR)/eth.o $(DRIVERS_DIR)/uart.o $(DRIVERS_DIR)/can.o $(DRIVERS_DIR)/i2c.o
	$(OR32_TOOL_PREFIX)-ranlib $(DRIVERS_DIR)/libdrivers.a

$(DRIVERS_DIR)/interrupts.o: $(DRIVERS_DIR)/interrupts.c
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $? -c -o $@

$(DRIVERS_DIR)/eth.o: $(DRIVERS_DIR)/eth.c $(BOARD_HDR) $(SUPPORT_HDR) $(DRIVERS_DIR)/eth.h
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $< -c -o $@

$(DRIVERS_DIR)/uart.o: $(DRIVERS_DIR)/uart.c $(BOARD_HDR) $(SUPPORT_HDR) $(DRIVERS_DIR)/uart.h
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $< -c -o $@

$(DRIVERS_DIR)/can.o: $(DRIVERS_DIR)/can.c $(BOARD_HDR) $(SUPPORT_HDR) $(DRIVERS_DIR)/can.h
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $< -c -o $@

$(DRIVERS_DIR)/i2c.o: $(DRIVERS_DIR)/i2c.c $(BOARD_HDR) $(SUPPORT_HDR) $(DRIVERS_DIR)/i2c.h
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $< -c -o $@
