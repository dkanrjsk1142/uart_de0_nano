# --------------------------------------------------------
# File Name   : gen_cmd_rom.py
# Description : generate command rom
#               commands seperated by 0x20(ASCII-space)
# --------------------------------------------------------
# Ver     Date       Author              Comment
# 0.01    2020.01.05 I.Yang              Create New
# --------------------------------------------------------

FILE_NAME = 'cmd_parser_cmd_table.mif'

header = """-- Copyright (C) 2018  Intel Corporation. All rights reserved.
-- Your use of Intel Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Intel Program License 
-- Subscription Agreement, the Intel Quartus Prime License Agreement,
-- the Intel FPGA IP License Agreement, or other applicable license
-- agreement, including, without limitation, that your use is for
-- the sole purpose of programming logic devices manufactured by
-- Intel and sold by Intel or its authorized distributors.  Please
-- refer to the applicable agreement for further details.

-- Quartus Prime generated Memory Initialization File (.mif)

ADDRESS_RADIX=HEX;
DATA_RADIX=HEX;

"""
footer = "END;\n"

cmd_dir = { 1:"ECHO", 2:"RAW_DIR", 3:"RAW", 4:"", # 4 is placeholder(because of special cmd. - handle by RTL)
            5:"REG_WRITE", 6:"REG_READ"          }
num_cmd = 32

def get_num_word(cmd_dir, num_cmd):
	cntr = 0

	for i in range(0, num_cmd):
		if i in cmd_dir:
			cntr += len(cmd_dir[i]) + 1 # sum # of char + seperator(space)
		else:
			cntr += 1 # seperator(space)

	return cntr

def get_rom_depth(num_need_word):
	import numpy as np
	return int(2**(np.ceil(np.log2(num_need_word))))

num_word = get_num_word(cmd_dir, num_cmd);

rom_width = 8   #ASCII
rom_depth = get_rom_depth(num_word)

with open(FILE_NAME, 'w') as f:
	f.write(header)
	f.write("WIDTH={:d};\n".format(rom_width))
	f.write("DEPTH={:d};\n".format(rom_depth))
	f.write("\nCONTENT BEGIN\n")


	word_cntr = 0
	for i in range(0, num_cmd):
		if i in cmd_dir:
			f.write("\t-- CMD_{0:02d} {1:s}\n".format(i, cmd_dir[i]))
			for j in range(0, len(cmd_dir[i])):
				f.write("\t{0:03X} : {1:02X};\n".format(word_cntr, ord(cmd_dir[i][j])))
				word_cntr += 1

		f.write("\t{0:03X} : {1:02X};\n".format(word_cntr, 0x20)) #seperator
		word_cntr += 1

	#out of valid data
	if word_cntr < rom_depth-1:
		f.write("\t[{0:03X}..{1:03X}] : {2:02X};\n".format(word_cntr, rom_depth-1, 0x00)) 
	elif word_cntr == rom_depth-1:
		f.write("\t{0:03X} : {1:02X};\n".format(word_cntr, 0x00))


	f.write(footer)
