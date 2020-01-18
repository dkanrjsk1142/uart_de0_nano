
echo "Library compile"                               >  comp_lib.log
echo "RTL compile"                                   >  comp_rtl.log

# --------------------------
# Library
# --------------------------
rm -rf work
vlib work

rm -rf alib
mkdir alib

vlib alib/altera_mf

vmap altera_mf     alib/altera_mf

vlog -work altera_mf     ../modelsim_lib/altera_mf.v >> comp_lib.log    

# --------------------------
# Copy .mif data
# --------------------------
cp ../source/*.mif .

# --------------------------
# Compile
# --------------------------

# --RTL
vlog ../source/uart_if.v                             >> comp_rtl.log
vlog ../source/buffer.v                              >> comp_rtl.log
vlog ../source/cmd_parser.v                          >> comp_rtl.log
vlog ../source/UART_DE0_NANO.v                       >> comp_rtl.log

# --bench
vlog ../testbench/TB_UART_DE0_NANO_TOP.v             >> comp_rtl.log
vlog ../testbench/tb_clk.v                           >> comp_rtl.log
vlog ../testbench/CMD_TABLE_FOR_SIM.v                >> comp_rtl.log

# --------------------------
# Simulation
# --------------------------

# MODE = -c | -gui
MODE="-gui"

# test pattern
if [ -z $1 ] ; then
	ctl="0_sim.ctl"
else
	ctl=$1"_sim.ctl"
fi

vsim TB_UART_DE0_NANO_TOP -t ps -L altera_mf -do $ctl $MODE -GSIM_MODE=1


# --------------------------
# Remove TEMP file
# --------------------------
rm ./*.mif
rm ./*.ver
