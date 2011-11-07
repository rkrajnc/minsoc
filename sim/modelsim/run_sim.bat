@echo off
set /p target_firmware=Input the target firmware hex file along with its path. Ex: "..\..\sw\uart\uart-nocache.hex": 
if EXIST %target_firmware% (
set firmware_size=find /c /v "NOTTHISSTRING"
vsim -lib minsoc minsoc_bench -pli ../../bench/verilog/vpi/jp-io-vpi.dll +file_name=%target_firmware% +firmware_size=%firmware_size%
) else (
echo %target_firmware% could not be found. 
set /p exit=Press ENTER to close this window... 
)
