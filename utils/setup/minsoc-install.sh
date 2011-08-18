#!/bin/bash
# Author: Constantinos Xanthopoulos
# This script install MinSOC tree
# under a specific directory.

# ===== CONFIGURATIONS =====
# ==========================

# Where should I put the dir. minsoc?
# ex. /home/conx/Thesis/
DIR_TO_INSTALL=`pwd`

# This variable should be set to trunk
# or to stable.
VERSION=""

# This variable should take one of
# the following values depending
# to your system: linux, cygwin, freebsd
ENV=""

# !!! DO NOT EDIT BELLOW THIS LINE !!!
# ===================================

# ===== SCRIPT ======
# ===================


# Debug ?
export DEBUG=0;
. beautify.sh

function testtool
{
    #    is_missing=`which $1 2>&1 | grep no`
    is_missing=`whereis -b $1 2>&1 | grep :$`
    if [ -z "$is_missing" ]
    then
        cecho "$1 is installed, pass"
    else
        errormsg "$1 is not installed, install it and re-run this installation script."
    fi
}

# User check!
if [ `whoami` = "root" ];
then
    errormsg "You shouldn't be root for this script to run.";
fi;

# Wizard
if [ -z "${ALTDIR}" ]
then
    cnecho "Give full path (ex. /home/foo/) for installation directory or leave empty for "${DIR_TO_INSTALL}": ";
    read ALTDIR;
    if [ ! -z "${ALTDIR}" ]
    then
        DIR_TO_INSTALL=${ALTDIR}
    fi
    cecho "${DIR_TO_INSTALL} selected";
fi

# Directory exists?
if [ ! -d ${DIR_TO_INSTALL} ]
then
    errormsg "Directory doesn't exist. Please create it";	
fi;

cd ${DIR_TO_INSTALL}


#setting environment
ENV=`uname -o`
if [ "$ENV" != "GNU/Linux" ] && [ "$ENV" != "Cygwin" ]
then
    errormsg "Environment $ENV not supported by this script."
fi
cecho "Building tools for ${ENV} system"


# Testing necessary tools
cecho "Testing if necessary tools are installed, program "whereis" is required."
testtool wget
testtool svn
testtool tar
testtool sed
testtool patch
testtool gcc
testtool make
testtool libncurses
testtool flex
testtool bison
if [ "$ENV" == "Cygwin" ]
then
    testtool ioperm
    testtool libusb
fi


# Which Version?
if [ -z ${VERSION} ]
then
    while [ "$VERSION" != "trunk" -a   "$VERSION" != "stable" ]
    do
        cnecho "Select MinSOC Version [stable/trunk]: "
        read VERSION;
    done
fi


# Checkout MinSOC
if [ "${VERSION}" = "trunk" ]
then
    execcmd "Download minsoc" "svn co -q http://opencores.org/ocsvn/minsoc/minsoc/trunk/ minsoc"
    execcmd "cd minsoc/backend/std"
    execcmd "Selecting standard configuration (not synthesizable)" "./configure"
    execcmd "cd ${DIR_TO_INSTALL}"
else
    execcmd "Download minsoc" "svn co -q http://opencores.org/ocsvn/minsoc/minsoc/tags/release-0.9/ minsoc"
    execcmd "cd minsoc/rtl/verilog"

    execcmd "Checkout adv_jtag_bridge" "svn co -q http://opencores.org/ocsvn/adv_debug_sys/adv_debug_sys/trunk adv_debug_sys"
    execcmd "Checkout ethmac" "svn co -q http://opencores.org/ocsvn/ethmac/ethmac/trunk ethmac"
    execcmd "Checkout openrisc" "svn co -q  http://opencores.org/ocsvn/openrisc/openrisc/trunk/or1200 or1200"
    execcmd "Checkout uart" "svn co -q http://opencores.org/ocsvn/uart16550/uart16550/trunk uart16550"
fi


#Tools directory
if [ ! -d ${DIR_TO_INSTALL}/tools ]
then
    execcmd "mkdir tools"
fi;


#Installing GDB
execcmd "cd ${DIR_TO_INSTALL}/tools"
execcmd "Downloading GDB sources" "wget ftp://anonymous:anonymous@ftp.gnu.org/gnu/gdb/gdb-6.8.tar.bz2"
execcmd "Downloading GDB OpenRISC patch" "wget ftp://ocuser:ocuser@openrisc.opencores.org/toolchain/or32-gdb-6.8-patch-2.4.bz2"
execcmd "Downloading GDB Advanced Debug System patch" "svn export -q http://opencores.org/ocsvn/adv_debug_sys/adv_debug_sys/trunk/Patches/GDB6.8/gdb-6.8-bz436037-reg-no-longer-active.patch"

execcmd "Uncompressing GDB" "tar -jxf gdb-6.8.tar.bz2"
execcmd "bzip2 -d or32-gdb-6.8-patch-2.4.bz2"
execcmd "cd gdb-6.8"
execcmd "Patching GDB" "patch -p1 < ../or32-gdb-6.8-patch-2.4"
execcmd "patch -p1 < ../gdb-6.8-bz436037-reg-no-longer-active.patch"

execcmd "Compiling GDB" "mkdir b-gdb"
execcmd "cd b-gdb"
execcmd "../configure --target=or32-elf --disable-werror --prefix=$DIR_TO_INSTALL/tools"
execcmd "make"
make install    #avoid Fedora failing due to missing Makeinfo
PATH=$PATH:$DIR_TO_INSTALL/tools/bin


# Installing the GNU Toolchain
cecho "Installing the GNU Toolchain"

is_arch64=`uname -m | grep 64`
if [ -z $is_arch64 ]
then
    KERNEL_ARCH="32"
else
    KERNEL_ARCH="64"
fi

cd $DIR_TO_INSTALL/tools;

if [ "$ENV" == "Cygwin" ]
then
    execcmd "Download toolchain (it may take a while)" "wget ftp://ocuser:ocuser@openrisc.opencores.org/toolchain/or32-elf-cygwin-1.7.tar.bz2";
    execcmd "Un-tar" "tar xf or32-elf-cygwin-1.7.tar.bz2";
else
    if [ $KERNEL_ARCH == "32" ];
    then
        execcmd "Download toolchain (it may take a while)" "wget ftp://ocuser:ocuser@openrisc.opencores.org/toolchain/or32-elf-linux-x86.tar.bz2";
        execcmd "Un-tar" "tar xf or32-elf-linux-x86.tar.bz2";
    elif [ $KERNEL_ARCH == "64" ];
    then
        execcmd "Download toolchain (it may take a while)" "wget ftp://ocuser:ocuser@openrisc.opencores.org/toolchain/or32-elf-linux-x86_64.tar.bz2";
        execcmd "Un-tar" "tar xf or32-elf-linux-x86_64.tar.bz2";
    else
        errormsg "Not a correct architecture, $KERNEL_ARCH. Check Configurations";
    fi
fi

PATH=$PATH:$DIR_TO_INSTALL/tools/or32-elf/bin


# Preparing MinSoC Specifics
cecho "I will now start to compile everything that's needed";

execcmd "cd ${DIR_TO_INSTALL}/minsoc/sw/utils"
execcmd "Make utils" "make"

execcmd "cd ../support"
execcmd "Make support tools" "make"

execcmd "cd ../drivers"
execcmd "Make drivers" "make"

execcmd "cd ../uart"
execcmd "Make UART" "make"


# adv_jtag_bridge install
if [ "$ENV" != "Cygwin" ]
then
    execcmd "cd ${DIR_TO_INSTALL}/tools"
    execcmd "Acquiring libusb-0.1 for Advanced Debug System" "wget http://sourceforge.net/projects/libusb/files/libusb-0.1%20%28LEGACY%29/0.1.12/libusb-0.1.12.tar.gz"
    execcmd "tar zxf libusb-0.1.12.tar.gz"
    execcmd "cd libusb-0.1.12"
    execcmd "./configure --prefix=${DIR_TO_INSTALL}/tools"
    execcmd "make"
    execcmd "make install"
fi

execcmd "cd ${DIR_TO_INSTALL}/tools"
execcmd "Acquiring libftdi for Advanced Debug System" "wget http://www.intra2net.com/en/developer/libftdi/download/libftdi-0.19.tar.gz"
execcmd "tar zxf libftdi-0.19.tar.gz"
execcmd "cd libftdi-0.19"
execcmd "./configure --prefix=${DIR_TO_INSTALL}/tools"
execcmd "make"
execcmd "make install"

execcmd "Compiling Advanced JTAG Bridge" "cd ${DIR_TO_INSTALL}/minsoc/rtl/verilog/adv_debug_sys/Software/adv_jtag_bridge"

if [ `grep "INCLUDE_JSP_SERVER=true" Makefile` != "" ]
then
    cecho "Switching off the adv_jtag_bridge JSP_SERVER option";
    sed 's/INCLUDE_JSP_SERVER=true/INCLUDE_JSP_SERVER=false/' Makefile > TMPFILE && mv TMPFILE Makefile
fi

if [ "${ENV}" == "GNU/Linux" ] 
then
    cecho "Setting the right build environment";
    sed 's/BUILD_ENVIRONMENT=cygwin/BUILD_ENVIRONMENT=linux/' Makefile > TMPFILE && mv TMPFILE Makefile
fi

sed "s%prefix = /usr/local%prefix = ${DIR_TO_INSTALL}/tools%" Makefile > TMPFILE && mv TMPFILE Makefile
sed "s%\$(CC) \$(CFLAGS)%\$(CC) \$(CFLAGS) \$(INCLUDEDIRS)%" Makefile > TMPFILE && mv TMPFILE Makefile
sed "s%INCLUDEDIRS =%INCLUDEDIRS = -I${DIR_TO_INSTALL}/tools/include%" Makefile > TMPFILE && mv TMPFILE Makefile
sed "s%LIBS =%LIBS = -L${DIR_TO_INSTALL}/tools/lib%" Makefile > TMPFILE && mv TMPFILE Makefile

execcmd "Make adv_jtag_bridge" "make"
execcmd "Installing adv_jtag_bridge" "make install"


#install extra tools
execcmd "cd ${DIR_TO_INSTALL}/tools"

execcmd "Acquiring Icarus Verilog Tool" "wget ftp://icarus.com/pub/eda/verilog/v0.9/verilog-0.9.4.tar.gz"
execcmd "tar zxf verilog-0.9.4.tar.gz"
execcmd "cd verilog-0.9.4"
execcmd "./configure --prefix=${DIR_TO_INSTALL}/tools"
execcmd "make"
execcmd "make install"


#Configuring Advanced Debug System to work with MinSoC
cecho "Configuring Advanced Debug System to work with MinSoC"
execcmd "cd ${DIR_TO_INSTALL}/minsoc/rtl/verilog/adv_debug_sys/Hardware/adv_dbg_if/rtl/verilog"
sed "s%\`define DBG_JSP_SUPPORTED%//\`define DBG_JSP_SUPPORTED%" adbg_defines.v > TMPFILE && mv TMPFILE adbg_defines.v

cecho "Compiling and moving adv_jtag_bridge debug modules for simulation"
execcmd "cd ${DIR_TO_INSTALL}/minsoc/rtl/verilog/adv_debug_sys/Software/adv_jtag_bridge/sim_lib/icarus"
execcmd "make"
execcmd "cp jp-io-vpi.vpi ${DIR_TO_INSTALL}/minsoc/bench/verilog/vpi"


#trying to set-up new variables
execcmd "Adding MinSoC tools to PATH" "echo \"PATH=\\\$PATH:$DIR_TO_INSTALL/tools/bin\" >> /home/$(whoami)/.bashrc;";
execcmd "Adding OpenRISC toolchain to PATH" "echo \"PATH=\\\$PATH:$DIR_TO_INSTALL/tools/or32-elf/bin/\" >> /home/$(whoami)/.bashrc;";
cecho "Installation Finished"
cecho "Before using the system, load the new environment variables doing this: source /home/$(whoami)/.bashrc"
