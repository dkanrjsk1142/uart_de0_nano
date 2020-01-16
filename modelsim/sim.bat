
echo "Library compile"                               >  comp_lib.log
echo "RTL compile"                                   >  comp_rtl.log

rem --------------------------
rem Library
rem --------------------------
vlib work

mkdir alib

vlib alib\altera_mf

vmap altera_mf     alib\altera_mf

vlog -work altera_mf     ..\modelsim_lib\altera_mf.v >> comp_lib.log    

rem --------------------------
rem Copy .mif data
rem --------------------------
copy ..\source\*.mif .

rem --------------------------
rem Compile
rem --------------------------

rem --RTL
vlog ..\source\uart_if.v                             >> comp_rtl.log
vlog ..\source\buffer.v                              >> comp_rtl.log
vlog ..\source\cmd_parser.v                          >> comp_rtl.log
vlog ..\source\UART_DE0_NANO.v                       >> comp_rtl.log

rem --bench
vlog ..\testbench\TB_UART_DE0_NANO_TOP.v             >> comp_rtl.log
vlog ..\testbench\tb_clk.v                           >> comp_rtl.log
vlog ..\testbench\CMD_TABLE_FOR_SIM.v                >> comp_rtl.log

comp_rtl.log

rem --------------------------
rem Simulation
rem --------------------------

rem MODE = -c | -gui
set MODE="-gui"

vsim TB_UART_DE0_NANO_TOP -t ps -L altera_mf -do sim.ctl %MODE% -GSIM_MODE=1


rem --------------------------
rem Remove TEMP file
rem --------------------------
del .\*.mif
del .\*.ver
