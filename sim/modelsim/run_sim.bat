@echo off
set /p filename=Input the target firmware hex file along with its path. Ex: "..\..\sw\uart\uart-nocache.hex": 
vsim -lib minsoc minsoc_bench -pli ../../bench/verilog/vpi/jp-io-vpi.dll +file_name=%filename%