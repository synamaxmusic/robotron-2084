TIEDIE	EQU	1								;;Use this to build the 2015 tie-die version
	CPU	6809

	INCLUDE	polyfill.asm							;;Needed for CLC, SEC, SEI, and CLI macros
	
	INCLUDE RRFRED.ASM							;;Referenced a lot, also includes RRF.ASM too

;	INCLUDE RRTABLE.ASM
;	INCLUDE RRX7.ASM
;	INCLUDE RRG23.ASM
;	INCLUDE RRB10.ASM
;	INCLUDE RRC11.ASM

;	INCLUDE RRDX2.ASM
;	INCLUDE RRLOG.ASM
;	INCLUDE RRH11.ASM

;	INCLUDE RRTEST1.ASM
;	INCLUDE RRM1.ASM
;	INCLUDE RRP8.ASM
;	INCLUDE RRS22.ASM
;	INCLUDE RRSET.ASM

	INCLUDE RRT2.ASM
	INCLUDE RRTESTB.ASM 
	INCLUDE RRTESTC.ASM
	INCLUDE RRTEXT.ASM
	INCLUDE RRTK4.ASM
	INCLUDE RRELESE6.ASM
	
	
	IFDEF	TIEDIE
	
	INCLUDE tie-die.asm
	INCLUDE RRCHRIS.ASM							;; fixes the enforcer explosion “reset” bug on ROM 5
	
	ENDIF