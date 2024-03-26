start /wait asl robomake.asm -o robotron1.p
start /wait asl robomake2.asm -o robotron2.p
start /wait asl robomake3.asm -o robotron3.p
start /wait asl robomake4.asm -o robotron4.p
start /wait pbind robotron1.p robotron2.p robotron3.p robotron4.p robotron_final.p
start /wait p2bin robotron_final.p 2084_rom_1b_3005-13.e4 -r $0000-$0FFF
start /wait p2bin robotron_final.p 2084_rom_2b_3005-14.c4 -r $1000-$1FFF
start /wait p2bin robotron_final.p 2084_rom_3b_3005-15.a4 -r $2000-$2FFF
start /wait p2bin robotron_final.p 2084_rom_4b_3005-16.e5 -r $3000-$3FFF
start /wait p2bin robotron_final.p 2084_rom_5b_3005-17.c5 -r $4000-$4FFF
start /wait p2bin robotron_final.p 2084_rom_6b_3005-18.a5 -r $5000-$5FFF
start /wait p2bin robotron_final.p 2084_rom_7b_3005-19.e6 -r $6000-$6FFF
start /wait p2bin robotron_final.p 2084_rom_8b_3005-20.c6 -r $7000-$7FFF
start /wait p2bin robotron_final.p 2084_rom_9b_3005-21.a6 -r $8000-$8FFF
start /wait p2bin robotron_final.p 2084_rom_10b_3005-22.a7 -r $D000-$DFFF
start /wait p2bin robotron_final.p 2084_rom_11b_3005-23.c7 -r $E000-$EFFF
start /wait p2bin robotron_final.p 2084_rom_12b_3005-24.e7 -r $F000-$FFFF