PROJECTS = minsoc_bench.prj minsoc_top.prj or1200_top.prj adbg_top.prj jtag_top.prj uart_top.prj ethmac.prj

SRC_DIR = src
SCRIPTS_DIR = scripts

SIMULATION_DIR = sim
XILINX_DIR = xilinx
ALTERA_DIR = altera

SIMULATION_FILES = $(addprefix $(SIMULATION_DIR)/, $(addsuffix .src, $(basename $(PROJECTS))))
XILINX_PRJ_FILES = $(addprefix $(XILINX_DIR)/, $(addsuffix .prj, $(basename $(PROJECTS))))
XILINX_XST_FILES = $(addprefix $(XILINX_DIR)/, $(addsuffix .xst, $(basename $(PROJECTS))))

all: $(SIMULATION_DIR)/minsoc.src $(XILINX_PRJ_FILES) $(XILINX_XST_FILES)

clean:
	rm -rf $(SIMULATION_DIR)/*.src $(XILINX_DIR)/*.prj $(XILINX_DIR)/*.xst

$(XILINX_DIR)/minsoc_top.xst: $(SRC_DIR)/minsoc_top.prj
	bash $(SCRIPTS_DIR)/xilinxxst.sh $^ $@ minsoc_top.prj minsoc_top topmodule

$(XILINX_DIR)/minsoc_top.prj: $(SRC_DIR)/minsoc_top.prj
	bash $(SCRIPTS_DIR)/xilinxprj.sh $^ $@ topmodule

$(XILINX_DIR)/%.xst: $(SRC_DIR)/%.prj
	bash $(SCRIPTS_DIR)/xilinxxst.sh $^ $@ $*.prj $*

$(XILINX_DIR)/%.prj: $(SRC_DIR)/%.prj
	bash $(SCRIPTS_DIR)/xilinxprj.sh $^ $@

$(SIMULATION_DIR)/minsoc.src: $(SIMULATION_FILES)
	cat $(SIMULATION_FILES) > $(SIMULATION_DIR)/minsoc.src

$(SIMULATION_DIR)/%.src: $(SRC_DIR)/%.prj
	bash $(SCRIPTS_DIR)/simprj.sh $^ $@

