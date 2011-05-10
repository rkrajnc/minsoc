$(LIB_SUPPORT): $(SUPPORT_DIR)/support.o $(SUPPORT_DIR)/tick.o $(SUPPORT_DIR)/int.o
	$(OR32_TOOL_PREFIX)-ar cru $(SUPPORT_DIR)/libsupport.a $(SUPPORT_DIR)/support.o $(SUPPORT_DIR)/tick.o $(SUPPORT_DIR)/int.o 
	$(OR32_TOOL_PREFIX)-ranlib $(SUPPORT_DIR)/libsupport.a

$(SUPPORT_DIR)/support.o: $(SUPPORT_DIR)/support.c $(OR1200_HDR) $(SUPPORT_HDR) $(SUPPORT_DIR)/int.h $(UART_HDR)
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -c -o $@ $<

$(SUPPORT_DIR)/tick.o: $(SUPPORT_DIR)/tick.c $(OR1200_HDR) $(SUPPORT_HDR) $(SUPPORT_DIR)/tick.h
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -c -o $@ $<

$(SUPPORT_DIR)/int.o: $(SUPPORT_DIR)/int.c $(SUPPORT_HDR) $(OR1200_HDR) $(SUPPORT_DIR)/int.h
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -c -o $@ $<

$(EXCPT_HNDLR): $(SUPPORT_DIR)/except.S $(OR1200_HDR)
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -c -o $@ $<

$(RESET_NOCACHE): $(SUPPORT_DIR)/reset.S $(OR1200_HDR) $(BOARD_HDR)
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -c -DIC=0 -DDC=0 -o $@ $<

$(RESET_ICDC): $(SUPPORT_DIR)/reset.S $(OR1200_HDR) $(BOARD_HDR)
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -c -DIC=1 -DDC=1 -o $@ $<
