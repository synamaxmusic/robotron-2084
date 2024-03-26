
	CPU	6809

	INCLUDE RRTABLE.ASM
	INCLUDE RRX7.ASM
	INCLUDE RRG23.ASM
	INCLUDE RRB10.ASM
	INCLUDE RRC11.ASM
	
;	RRDX2.ASM
;	RRLOG.ASM
;	RRH11.ASM

;	RRTEST1.ASM
;	RRM1.ASM
;	RRP8.ASM
;	RRS22.ASM
;	RRSET.ASM

;	RRT2.ASM
;	RRTESTB.ASM 
;	RRTESTC.ASM
;	RRTEXT.ASM
;	RRTK4.ASM
;	RRELESE6.ASM

;;  RRRR    OOO   BBBB    OOO   TTTTT  RRRR    OOO   N   N       222    OOO    888      4
;;  R   R  O   O  B   B  O   O    T    R   R  O   O  NN  N  ::  2   2  O   O  8   8    44
;;  RRRR   O   O  BBBB   O   O    T    RRRR   O   O  N N N         2   O   O   888    4 4
;;  R   R  O   O  B   B  O   O    T    R   R  O   O  N  NN  ::   2     O   O  8   8  44444
;;  R   R   OOO   BBBB    OOO     T    R   R   OOO   N   N      22222   OOO    888      4
;;  
;;  Originally re-written by Rob Hogan aka "mwenge", re-targeted to Macroassembler {AS} by SynaMax
;;  
;;  {AS} retarget took just one day to finish, started on March 24th, 2024 and a perfect matching binary
;;  was built on March 25th, at 10:14 PM.
;;  
;;  RRX7 introduces an "EXPLOSION DATA STRUCTURE" that features symbols that get reused over and over again.
;;  It's possible to rewrite the code so that the game can be built from one .p code file instead of four, 
;;  but that might be too much work and could potentially introduce more troubleshooting and headaches.
;;  So for now, there are four "robomake" files that generate four code files.  Combine the code files
;;  together and use that final code file to build the "blue label" ROM set.
;;  
;;  Place these .ASM files alongside with {AS}'s asl, pbind, and p2bin.  Type the following into a terminal:
;;
;;  	asl robomake.asm -o robotron1.p
;;  	asl robomake2.asm -o robotron2.p
;;  	asl robomake3.asm -o robotron3.p
;;  	asl robomake4.asm -o robotron4.p
;;
;;	pbind robotron1.p robotron2.p robotron3.p robotron4.p robotron_final.p
;;
;;	p2bin robotron_final.p robotron.bin -r $0000-$FFFF
;;	p2bin robotron_final.p 2084_rom_1b_3005-13.e4 -r $0000-$0FFF
;;	p2bin robotron_final.p 2084_rom_2b_3005-14.c4 -r $1000-$1FFF
;;	p2bin robotron_final.p 2084_rom_3b_3005-15.a4 -r $2000-$2FFF
;;	p2bin robotron_final.p 2084_rom_4b_3005-16.e5 -r $3000-$3FFF
;;	p2bin robotron_final.p 2084_rom_5b_3005-17.c5 -r $4000-$4FFF
;;	p2bin robotron_final.p 2084_rom_6b_3005-18.a5 -r $5000-$5FFF
;;	p2bin robotron_final.p 2084_rom_7b_3005-19.e6 -r $6000-$6FFF
;;	p2bin robotron_final.p 2084_rom_8b_3005-20.c6 -r $7000-$7FFF
;;	p2bin robotron_final.p 2084_rom_9b_3005-21.a6 -r $8000-$8FFF
;;	p2bin robotron_final.p 2084_rom_10b_3005-22.a7 -r $D000-$DFFF
;;	p2bin robotron_final.p 2084_rom_11b_3005-23.c7 -r $E000-$EFFF
;;	p2bin robotron_final.p 2084_rom_12b_3005-24.e7 -r $F000-$FFFF
;;
;;  You can also run the BURN.BAT batch file to build a ROM set automatically.
;;
;;  Tie-Die disassembly is up next!