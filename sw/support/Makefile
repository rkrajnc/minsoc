all: libsupport.a reset-nocache.o reset-ic.o reset-dc.o reset-icdc.o except.o

libsupport.a: support.o tick.o int.o 
	$(OR32_TOOL_PREFIX)-ar cru libsupport.a support.o tick.o int.o 
	$(OR32_TOOL_PREFIX)-ranlib libsupport.a

support.o: support.c
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -c -o $@ $?

reset-nocache.o: reset.S
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -c -DIC=0 -DDC=0 -o $@ $?

reset-dc.o: reset.S
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -c -DIC=0 -DDC=1 -o $@ $?

reset-ic.o: reset.S
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -c -DIC=1 -DDC=0 -o $@ $?

reset-icdc.o: reset.S
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -c -DIC=1 -DDC=1 -o $@ $?

except.o: except.S
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -c -o $@ $?

int.o: int.c
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -c -o $@ $?

tick.o: tick.c
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -c -o $@ $?

include Makefile.inc
