# File to be included in all makefiles

ROOTDIR = ..

BACKEND_DIR := $(ROOTDIR)/../backend
SUPPORT_DIR := $(ROOTDIR)/support
DRIVERS_DIR := $(ROOTDIR)/drivers
UTILS_DIR := $(ROOTDIR)/utils

OR1200_HDR := $(SUPPORT_DIR)/or1200.h
BOARD_HDR := $(BACKEND_DIR)/board.h
SUPPORT_HDR := $(SUPPORT_DIR)/support.h
UART_HDR := $(DRIVERS_DIR)/uart.h
ETH_HDR := $(DRIVERS_DIR)/eth.h

RESET_NOCACHE := $(SUPPORT_DIR)/reset-nocache.o
RESET_ICDC := $(SUPPORT_DIR)/reset-icdc.o

EXCPT_HNDLR := $(SUPPORT_DIR)/except.o
LIB_SUPPORT := $(SUPPORT_DIR)/libsupport.a

SUPPORT := $(EXCPT_HNDLR) $(LIB_SUPPORT)
DRIVERS := $(DRIVERS_DIR)/libdrivers.a

LINKER_SCRIPT := $(BACKEND_DIR)/orp.ld

OR32_TOOL_PREFIX=or32-elf

include ../../backend/gcc-opt.mk

BIN2HEX = $(UTILS_DIR)/bin2hex

ifdef UART_PRINTF
GCC_OPT += -DUART_PRINTF
endif

all: all_internal

# Global clean rule
clean:
	@echo "Cleaning `pwd`"
	@rm -f *.o *.or32 *.log *.bin *.srec *.hex *.log stdout.txt *.vmem *.asm *.a stdout.txt