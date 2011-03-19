#!/bin/bash
# Xanthopoulos Constantinos


# ===== CONFIGURATIONS =====
# ==========================

# Where should I put the dir. minsoc?
# ex. /home/conx/Thesis/
DIR_TO_INSTALL="/home/conx/Thesis/tmp/"

# This variable should be set to trunk
# or to stable.
VERSION="trunk"

# This variable should take one of
# the following values depending
# to your system: linux, cygwin, freebsd
ENV="linux"

# !!! DO NOT EDIT BELLOW THIS LINE !!!
# ===================================

# ===== SCRIPT ======
# ===================

# Debug ?
export DEBUG=0;
. beautify.sh
. func.sh

# User check!
if [ `whoami` == "root" ];
then
	errormsg "You shouldn't be root for this script to run.";
fi;

# Wizard
if [ $DIR_TO_INSTALL == "" ]
then
	read $DIR_TO_INSTALL;
fi

# Directory exists?
if [ ! -d $DIR_TO_INSTALL ]
then
	errormsg "Directory doesn't exist. Please create it";	
fi;

cd $DIR_TO_INSTALL


if [ $VERSION == "" ]
then
	while [ $VERSION != "trunk" -a $VERSION != "stable"]
	do
		cecho "Which version you want to install [stable/trunk]?"
		read $VERSION;
	done
fi

if [ $ENV == "" ]
then
	while [ $ENV != "linux" -a $ENV != "cygwin" -a $ENV != "freebsd" ]
	do
		cecho "In which environement are you installing MinSOC [linux/cygwin/freebsd]?"
		read $ENV;
	done
fi


# Checkout MinSOC
if [ $VERSION == "trunk" ]
then
	execcmd "Download minsoc" "svn co -q http://opencores.org/ocsvn/minsoc/minsoc/trunk/ minsoc"
else
	execcmd "Download minsoc" "svn co -q http://opencores.org/ocsvn/minsoc/minsoc/tags/release-0.9/ minsoc"
fi

cd minsoc/rtl/verilog

execcmd "Checkout adv_jtag_bridge" "svn co -q http://opencores.org/ocsvn/adv_debug_sys/adv_debug_sys/trunk adv_debug_sys"
execcmd "Checkout ethmac" "svn co -q http://opencores.org/ocsvn/ethmac/ethmac/trunk ethmac"
execcmd "Checkout openrisc" "svn co -q  http://opencores.org/ocsvn/openrisc/openrisc/trunk/or1200 or1200"
execcmd "Checkout uart" "svn co -q http://opencores.org/ocsvn/uart16550/uart16550/trunk uart16550"

cecho "I will now start to compile everything that's needed";

cd ../../sw/utils

execcmd "Make utils" "make"

cd ../support

execcmd "Make support tools" "make"

cd ../drivers

execcmd "Make drivers" "make"

cd ../gpio

execcmd "Make GPIO" "make"

cd ../uart

execcmd "Make UART" "make"

# adv_jtag_bridge install
cd ${DIR_TO_INSTALL}/minsoc/rtl/verilog/adv_debug_sys/Software/adv_jtag_bridge

#cecho "Installing FTDI headers! You will be asked to give root pass"

#execcmd "Install FTDI headers" "su -c \"aptitude install libftdi-dev\""; #FIXME

if [ `grep "INCLUDE_JSP_SERVER=true" Makefile` != "" ]
then
	cecho "Switching off the adv_jtag_bridge JSP_SERVER option";
	sed 's/INCLUDE_JSP_SERVER=true/INCLUDE_JSP_SERVER=false/' Makefile > TMPFILE && mv TMPFILE Makefile
fi

if [ $ENV != "cygwin" ] 
then
	cecho "Setting the right build environment";
	sed "s/BUILD_ENVIRONMENT=cygwin/BUILD_ENVIRONMENT=${ENV}/" Makefile > TMPFILE && mv TMPFILE Makefile
fi

execcmd "Make adv_jtag_bridge" "make"

cecho "Installation Finised"
