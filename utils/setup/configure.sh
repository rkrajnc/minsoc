. ${SCRIPT_DIR}/beautify.sh

#Configuring MinSoC
cecho "\nConfiguring MinSoC"
execcmd "cd ${DIR_TO_INSTALL}/minsoc/backend/std"
execcmd "Configuring MinSoC as standard board (simulatable but not synthesizable)" "./configure"
execcmd "cd ${DIR_TO_INSTALL}"


#Configuring Advanced Debug System to work with MinSoC
cecho "\nConfiguring Advanced Debug System to work with MinSoC"
execcmd "cd ${DIR_TO_INSTALL}/minsoc/rtl/verilog/adv_debug_sys/Hardware/adv_dbg_if/rtl/verilog"
execcmd "Turning off Advanced Debug System's JSP" "sed 's%\`define DBG_JSP_SUPPORTED%//\`define DBG_JSP_SUPPORTED%' adbg_defines.v > TMPFILE && mv TMPFILE adbg_defines.v"

#Compiling and moving adv_jtag_bridge debug modules for simulation
execcmd "cd ${DIR_TO_INSTALL}/minsoc/rtl/verilog/adv_debug_sys/Software/adv_jtag_bridge/sim_lib/icarus"
execcmd "Compiling VPI interface to connect GDB with simulation" "make"
execcmd "cp jp-io-vpi.vpi ${DIR_TO_INSTALL}/minsoc/bench/verilog/vpi"
