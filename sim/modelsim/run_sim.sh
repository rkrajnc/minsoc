#!/bin/bash

vsim -lib minsoc minsoc_bench_clock -pli ../../bench/verilog/vpi/jp-io-vpi.so +file_name=$1
