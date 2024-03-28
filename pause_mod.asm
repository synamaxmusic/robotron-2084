;;
;;  To fit this pause mod along with all the Tie-Die patches, we'll have to
;;  overwrite the "Cross Hatch" CRT grid test screen in ROM 12.  It will
;;  give us plenty of room ($F6FE-$F887) to insert the pause mod. 
;;

;;  First let's clear out two JSR instructions at TSTPAT so that we don't 
;;  call the Cross Hatch routine during diagnostics.

	ORG	$F677
	
	NOP			;;TSTPAT  JSR   CROSS            ;DO FANCY HASSLER PAT.
	NOP
	NOP
	
	NOP			;	  JSR   AVWAIT           ;WAIT FOR ADVANCE
	NOP
	NOP
	
;;  Now we can insert the mod data

	ORG	$F6FE

PRINTPA	LDY	#PATXT
	LDX	#$4078		;;X/Y Screen position for text
PADRAW1	LDA	,Y+		;;Go through each letter in PATXT
	BEQ	PADRAW2
	JSR	PRN7FV		;;  and print it as 5X7 font
	LDA	#$00
	BEQ	PADRAW1
PADRAW2	JMP	PAUSE2
PATXT	FCC	"P A U S E D"
	FCB	0
	
PAUCLR	LDX	#$0000
	LDA	#$40
PCLR2	LDB	#$78
PCLR1	EXG	X,D
	STA	,X
	EXG	X,D
	INCB
	CMPB	#$80
	BNE	PCLR1
	INCA
	CMPA	#$5F
	BNE	PCLR2
	JMP	PAUSE4
	

PAUSE	PSHS   U,Y,X,D   
	LDA    PIA2      
	ANDA   #$10      
	BEQ    PAUSEX    
	ORCC   #$10      
	JSR    PAUWAIT   
PAUSE1  JSR    PAWDOG    
	LDA    PIA2      
	ANDA   #$10      
	BNE    PAUSE1    
	JMP    PRINTPA
PAUSE2  JSR    PAWDOG    
	LDA    PIA2      
	ANDA   #$10      
	BEQ    PAUSE2    
	JSR    PAUWAIT   
PAUSE3  JSR    PAWDOG    
	LDA    PIA2      
	ANDA   #$10      
	BNE    PAUSE3    
	JMP    PAUCLR
PAUSE4	JMP    PAUSEX    
PAWDOG  LDB    #$39      
	STB    WDOG      
	RTS              
PAUWAIT LDD    #$0200    
PAUSELP DECB             
	BNE    PAUSELP   
	DECA             
	BNE    PAUSELP   
	RTS              
PAUSEX	PULS   D,X,Y,U   
	ANDCC  #$EF
	LDA    PIA2      	;;restore trashed instruction
	JMP    $31C4		;;Go back to laser processing routine   

	
;;
;;  Change the checksum byte for ROM 12 so that we can pass the ROM test.
;;	
	ORG	$FFD6
	FCB	$A0
	
;;
;;  And finally let's overwrite the joystick scanning in the Laser processing routine
;;  so we can check for pause during gameplay.
;;		
	ORG	$31C1		;LSP0
	JMP	PAUSE		;Overwrite LDA   PIA2

;;
;;  Let's update the checksum fudger byte in ROM 4 so that it matches up with $6C.
;;
	ORG	$3860
	FCB	$18