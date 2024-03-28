;;=========================================================================================
;;
;;  Tie-Die ROM 4
;;

	ORG	$34C0
;*
;*DISPLAY WAVE # MESSAGE
;*
	JMP	TDPAT5		;;Overwrite WVMESS  LDA   ZP1WAV  (ZP1WAV is WAVE # IN HEX)
	
	ORG	$3860
	
	FCB	$44

;;=========================================================================================
;;
;;  Tie-Die ROM 5
;;	
;;	ROM 5 features the 1987 enforcer fix by Christian Gingras (see RRCHRIS.ASM)
;;

;;=========================================================================================
;;
;;  Tie-Die ROM 7
;;

; This single byte edit is taken from RRELESE6.ASM
	ORG    $6D2E
        FCB    $21
	
;; Pointer to copyright message patch located at $D4A8 (RRS22.ASM)	
	ORG	$6361
	FDB	LIVESP		;;Overwrite FDB   WAVEP            ;WAVE NUMBER 104
	
	ORG	$6375
	FDB	WAVEM22		;;Overwrite FDB   WAVEM2           ;114
	
	ORG	$6EFF
	FCB	$C5		;;Checksum fudger byte, I think
	
	ORG	ADJTBL		;;($6FD5)
	FCB	0,$75		;;Overwrite ADJTBL  FCB   0,$50            ;REPLAY LEVEL

;;=========================================================================================	
;;
;;  Tie-Die ROM 8
;;

;;  Extra Lives changes

	ORG	$7043
	FCB   	$10		;;Overwrite FCB   $20,REPMM1	(Change from 20 to 10 as default value)
	
;;  Replace "REPLAY ADJUSTMENT TABLE" with new RVTAB at $DF29
	
	ORG	FINDME+1	;;($71CC)
	FDB	RVTAB2		;;Overwrite LDX   #RVTAB	($DF29 is blank space)
	
	ORG	$71D5
	FDB	RVEND2		;;Overwrite CMPX  #RVEND
	
	ORG	$779F
	FCB	$91		;;Checksum fudger byte, I think

;;=========================================================================================	
;;
;;  Tie-Die ROM 10
;;	

	ORG	$D4A8
LIVESP  FCB   CURSAB,$22,$EE,0,COLOR,$55
	FCC   "LIVES "
        FCB   ZBLANK,COLOR,$AA,NUMY

;;Modified WAVEP
WAVEP2  FCB   CURSAB,$3E,$EE,0,SBLANK				;;Missing "COLOR,$AA"
        FCB   NUMB,CURSOR,3,0,0,COLOR,$BB
        FCC   " WAVE"
        FCB   0

WAVEM22 FCB   CURSOR,$04,$00,0,ZBLANK,COLOR,$AA
        FCB   NUMB
	
LIVENOZ FCB   CURSAB,$64,$EE,0,COLOR,$55
	FCC   "LIVES "
        FCB   COLOR,$AA,NUMY					;;No ZBLANK
	FCB   0
	

	ORG	$DC04
	JSR	TDMAND						;;Insert hook to new patch for displaying extra lives
	
	ORG	$DC22
	LDX  	#$150E						;;Replace #P1DISP ($180E) in SCORE TRANSFER function
	
	ORG	$DC2A
	LDX	#$550E						;;Replace #P2DISP ($580E)
	
	ORG	$DC30
	LDD     #$1806						;;Replace LDD   #$1506
	
	ORG	$DC36
	JMP	$DC3A						;;Replace LEAX  -$300,X          ;7 NOT 8 DIGITS

	ORG	$DC3E
	BRA	$DC40						;;Overwrite ANDA  #$F and just keep on movin' along
	
;; Number of Lives shown at bottom of screen for each player (they still wrap at 256)	
	
	ORG	$DE8A
TDPAT	PSHS	B
	TFR	A,B
	CLRA
	LDY	#$0000
TDPAT1	CMPB	#$0A
	BCS	TDPAT2
	ADDA	#$0A
	DAA
	BCC	TDPAT3
	LEAY	$0100,Y
TDPAT3	SUBB	#$0A
	BRA	TDPAT1
TDPAT2	PSHS	B
	ADDA	,S+
	DAA
	BCC	DEAF
	LEAY	$0100,Y
DEAF	TSTA							;;Calling this "DEAF" because it's at $DEAF
	BPL	TDPAT4
	LEAY	$0080,Y
	SUBA	#$80
TDPAT4	LEAY	A,Y
	PULS	B,PC
TDMAND	JSR	MANDSP						;;DISPLAY MEN LEFT 


TDPAT5  PSHS	U,Y,X,D						;;($DEBF)
	JSR	TDPAT8
	BNE	TDPAT6
	LDD	ZP1SCR
	ADDD	ZP1SCR+2
	BNE	TDPAT6
	LDA	ZP1WAV
	DECA
	BNE	TDPAT6
	LDA	#$99
	STA	ZP1SCR
	STA	ZP1RP
	LDA	#$90
	STA	ZP1SCR+1
	ORA	REPLA
	STA	ZP1RP+1
	
TDPAT6	LDX	#$22EE
	LDD	#EXMANN
	JSR	BLKCLR
	LDA	ZP1LAS						;;# OF LASERS
	JSR	TDPAT
	LDA	ZP1WAV
	JSR	HEXBCD
	TFR	A,B
	LDA	#$68
	JSR	WRD5FV						;;Go to WORD35 vector
	LDA	PLRCNT
	DECA
	BEQ	TDPAT7
	LDA	ZP2LAS
	JSR	TDPAT
	LDA	ZP2WAV
	JSR	HEXBCD
	TFR	A,B
	LDA	#$72
	JSR	WRD5FV
TDPAT7	PULS	D,X,Y,U,PC
TDPAT8	PSHS	X,A
	LDX	#GA2						;;Number of letters allowed to GOD (10)
	JSR	RCMOSA
	CMPA	#$04
	PULS	A,X,PC
	FCB	0
	
	ORG	$DF3F
	FCB	$4F						;;Checksum fudger

;; NEW REPLAY ADJUSTMENT TABLE
;;
;; Extra Lives now settable at 10-15-20-25-30-40-50-60-70-75K


	ORG	$DF29
RVTAB2  FCB	0
        FCB	$10		;;New	
        FCB	$15		;;New
        FCB	$20
        FCB	$25
        FCB	$30
        FCB	$40		;;New
	FCB	$50
        FCB	$60		;;New
        FCB	$70		;;New
RVEND2  FCB	$75		;;New
        FCB	$75		;;New

;;=========================================================================================	
;;
;;  Tie-Die ROM 11
;;

; This is taken from RRELESE6.ASM
       ORG    $E3B0
       FCB    $26,$26,$26,$26,$26,$26,$26,$26,$26
       ORG    $E398
       FCB    $A6
       
; Huh?
	ORG	$E3C5
	FDB	$132A
	
; Editing the High Score Initials

	ORG	$E4A3
	FCC	"SGJ"		;;Overwrite "EPJ"
	
	ORG	$E4AA
	FCC	"DDD"		;;Overwrite "JER"
	
	ORG	$E4B1
	FCC	"RTD"		;;Overwrite "KID"
	
; Modify High Score Entry

	ORG	$E730
	JMP	TDPAT9		;;Replace STX   PLRX             ;SAVE PARAMS
	
	ORG	GETHM1		;;($E7B2)
	JSR	$E977
	
	ORG	$E7D2
	JMP	TDPAT12		;;Replace JSR   GETLT

;; RRTESTC.ASM has code that was commented out that appears in Tie-Die ($E955)

;; Start of new code

	ORG	$E97C
TDPAT9
	PSHS	D
	JSR	TDPAT8
	BNE	TDPAT10
	JMP	$E79F		;;Back to JMP   [EGRAM] in EGSUB1 routine (no GOD high score name)
TDPAT10	LDD	,X
	BITA	#$F0
	BEQ	TDPAT11
	LDD	#$0999
	STD	ZP1RP
	LDA	#$99
	STD	ZP1RP+2
	LDX	#ZP1RP
TDPAT11	PULS	D
	STX	PLRX
	JMP	$E733		;;Back to EGSUB routine
TDPAT12	JSR	GETLT		;;GETLT = Routine to get letters from control panel
	TST	EGRAM2
	BNE	TDPDONE
	LDD	ALTBL		;;ALTBL = PLACE FOR 20 CHAR HIGH SCORE 
	CMPA	#$3A
	BNE	TDPDONE
	CMPB	#$3A
	BNE	TDPDONE
	LDA	YSTOR
	CMPA	#$3A
	BNE	TDPDONE	
	JMP	$E79F		;;Back to JMP   [EGRAM] in EGSUB1 routine (no GOD high score name)
TDPDONE	JMP	GET333
	