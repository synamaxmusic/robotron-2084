# Robotron: 2084
A source code retarget to the 1982 arcade game.

## Credits
* Programmed by Eugene Jarvis and Larry Demar
* Original source code rewrite by mwenge https://github.com/mwenge/robotron
* 2008 Pause Mod by [Coinoplove.com](http://coinoplove.com/romhack/romhack.htm)
* Source code re-targeted to Macroassembler {AS} by SynaMax
* Tie-Die Pause Mod implementation by SynaMax
* Special thanks to braedel

## Build instructions

First, place all the files in the repository alongside with Macroassembler {AS}'s asl, pbind, and p2bin executables.

### Batch files

Two batch files are included to make it easy to build the game from scratch.  

Open ```BURN.BAT``` to build the final original version of the game (known as the "blue label" ROM set).  

Use ```TIEDIE_BURN.BAT``` to build the 2015 "Tie-Die" ROM set which introduces several new features added by the original developers.

### Terminal commands

If you can't use the batch files then type this into a terminal:

```
asl robomake.asm -o robotron1.p
asl robomake2.asm -o robotron2.p
asl robomake3.asm -o robotron3.p
asl robomake4.asm -o robotron4.p

pbind robotron1.p robotron2.p robotron3.p robotron4.p robotron_final.p
```

This takes the four make files and generates four .p code files.  We then combine all four code files into a "final" .p code file.

Then, use the following commands to generate all the ROM files from the final code file:
```
p2bin robotron_final.p 2084_rom_1b_3005-13.e4 -r $0000-$0FFF
p2bin robotron_final.p 2084_rom_2b_3005-14.c4 -r $1000-$1FFF
p2bin robotron_final.p 2084_rom_3b_3005-15.a4 -r $2000-$2FFF
p2bin robotron_final.p 2084_rom_4b_3005-16.e5 -r $3000-$3FFF
p2bin robotron_final.p 2084_rom_5b_3005-17.c5 -r $4000-$4FFF
p2bin robotron_final.p 2084_rom_6b_3005-18.a5 -r $5000-$5FFF
p2bin robotron_final.p 2084_rom_7b_3005-19.e6 -r $6000-$6FFF
p2bin robotron_final.p 2084_rom_8b_3005-20.c6 -r $7000-$7FFF
p2bin robotron_final.p 2084_rom_9b_3005-21.a6 -r $8000-$8FFF
p2bin robotron_final.p 2084_rom_10b_3005-22.a7 -r $D000-$DFFF
p2bin robotron_final.p 2084_rom_11b_3005-23.c7 -r $E000-$EFFF
p2bin robotron_final.p 2084_rom_12b_3005-24.e7 -r $F000-$FFFF
```

### Terminal commands (Tie-Die)

The process is pretty much the same for building the Tie-Die ROM set but we need to use ```robomake4_tiedie.asm``` instead.

```
asl robomake.asm -o robotron1.p
asl robomake2.asm -o robotron2.p
asl robomake3.asm -o robotron3.p
asl robomake4_tiedie.asm -o robotron4.p

pbind robotron1.p robotron2.p robotron3.p robotron4.p robotron_tiedie_final.p
```

MAME's ROM set filenames are slightly different as well:

```
p2bin robotron_tiedie_final.p 2084_rom_1b_3005-13.e4 -r $0000-$0FFF
p2bin robotron_tiedie_final.p 2084_rom_2b_3005-14.c4 -r $1000-$1FFF
p2bin robotron_tiedie_final.p 2084_rom_3b_3005-15.a4 -r $2000-$2FFF
p2bin robotron_tiedie_final.p tiedie_rom_4b.e5 -r $3000-$3FFF
p2bin robotron_tiedie_final.p fixrobo_rom_5b.c5 -r $4000-$4FFF
p2bin robotron_tiedie_final.p 2084_rom_6b_3005-18.a5 -r $5000-$5FFF
p2bin robotron_tiedie_final.p tiedie_rom_7b.e6 -r $6000-$6FFF
p2bin robotron_tiedie_final.p tiedie_rom_8b.c6 -r $7000-$7FFF
p2bin robotron_tiedie_final.p 2084_rom_9b_3005-21.a6 -r $8000-$8FFF
p2bin robotron_tiedie_final.p tiedie_rom_10b.a7 -r $D000-$DFFF
p2bin robotron_tiedie_final.p tiedie_rom_11b.c7 -r $E000-$EFFF
p2bin robotron_tiedie_final.p 2084_rom_12b_3005-24.e7 -r $F000-$FFFF
```

## Pause Mod

A Pause Mod has been added for the Tie-Die ROM set!  This mod is originally from 2008 and is taken from Coinoplove.com.  

Because the Tie-Die ROM set came out in 2015, the 2008 pause mod only works on the blue label ROM set.  To get pause functionality working on Tie-Die, the "Cross Hatch" diagnostic screen test was removed in ROM 12 to make room.

To build Tie-Die with Pause, simply edit ```robomake4_tiedie.asm``` and make sure to uncomment ```PAUSEMOD EQU 1``` by removing the semi-colon(```;```).  

Finally, use ```TIEDIE_BURN.BAT``` or manually type in the [terminal commands for building the Tie-Die set](#terminal-commands-tie-die).

## Why four makefiles?

The file ```RRX7.ASM``` introduces an "EXPLOSION DATA STRUCTURE" that features symbols that get reused over and over again.  Unfortunately, these duplicate symbols causes errors for {AS} so it was decided to split the makefile into several to avoid this.

It's possible to rewrite the code so that the game can be built from one .p code file instead of four, but I want to avoid modifying the original source code as much as possible and using the four "robomake" files helps us workaround this issue.  Why try fixing something that's not broken, amirite?
