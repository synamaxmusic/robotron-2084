;        OPT   NOL
;        LIB   "src/RRFRED.ASM"
;        OPT   LIS
;*
        ORG   RAMALS
SW0ST   RMB   1
SW0SCN  RMB   1
SW2ST   RMB   1
SW2SCN  RMB   1
SW3ST   RMB   1
SW3SCN  RMB   1
SW2STI  RMB   1
SW2SCI  RMB   1
SW3STI  RMB   1
SW3SCI  RMB   1

;* PSEUDO DMA
RCONT   RMB   1                ;THESE ARE THE PASSED REGISTERS
RCONST  RMB   1
RORIG   RMB   2
RDEST   RMB   2
RHORIZ  RMB   2

DHORIZ  RMB   1                ;THESE ARE THE DYNAMICALLY CHANGING
DVERT   RMB   1                ;REGISTERS
DORIG   RMB   2
DDEST   RMB   2

DFL     RMB   1                ;FLAVOR SAVOR
NEWROW  RMB   1                ;NEW ROW FLAG
DMATMP  RMB   2

DIV     RMB   6                ;6 BYTES OF DIVIDEND
DIVTMP  RMB   6
DIVSOR  RMB   6                ;6 BYTES OF DIVISOR
QUO     RMB   4
DVTEMP  RMB   2

;****************************** STUFF FOR HORIZ EXPLOSION

;*
;* EXPLODING OBJECT DATA STRUCTURE
;*
        ORG   HXTAB            ;PLACE FOR DATA

EX      EQU   *
NEXTZ   RMB   2                ;LIST POINTER
PICPTZ  RMB   2                ;POINTER TO DATA
XCENTZ  RMB   1                ;SCREEN Y CENTER
XOFZ    RMB   1                ;OFFSET IN Y TO OBJECT CENTER (PIXELS) (0-HEIGHT)
XSIZEZ  RMB   2                ;CURRENT Y POINT SPACING
FRAMEZ  RMB   1                ;FRAMES TO RUN IN EFFECT
ULZ     RMB   2                ;UPPER LEFT
WHZ     RMB   2                ;WIDTH,HEIGHT
DMAWHZ  RMB   2                ;DMA HEIGHT WIDTH
DMACNZ  RMB   2                ;DMA CONTROL RET
XHITEZ  RMB   1
DATAZ   RMB   7*16*2           ;RESERVE FOR DATA IN VERTICAL FORMAT
ESIZEZ  EQU   *

NEXT    EQU   NEXTZ-EX
PICPTR  EQU   PICPTZ-EX
XCENT   EQU   XCENTZ-EX
XOF     EQU   XOFZ-EX
XSIZER  EQU   XSIZEZ-EX
FRAMES  EQU   FRAMEZ-EX
UL      EQU   ULZ-EX
WH      EQU   WHZ-EX
DMAWH   EQU   DMAWHZ-EX
DMACNT  EQU   DMACNZ-EX
XHITE   EQU   XHITEZ-EX
DATA    EQU   DATAZ-EX
EXSIZE  EQU   ESIZEZ-EX

        RMB   ((8-1)*EXSIZE)   ;NUMBER OF BLOCKS

EXEND   EQU   *

        ORG   HXRAM            ;(BASE PAGE)

XSIZE   RMB   1                ;DISTANCE BETWEEN Y POINTS THIS FRAME
EXPTR   RMB   2
APPTR   RMB   2
EXFREE  RMB   2
WIDE    RMB   1
TEMP1   RMB   2
TEMP2   RMB   1

;****************************************************************

        ORG   TSTORG
        JMP   PWRUP
        JMP   ADVSWZ
        JMP   AUTCYC
        JMP   HXINV
        JMP   HEXSTV
        JMP   HAPSTV
        JMP   HXUPDV
        FDB   BSLOOP
        FDB   ERLOOP
        FDB   L2V
        FDB   L0V

        INCLUDE	RRHX4.ASM							;;Fixme was: LIB   "src/RRHX4.ASM"

;*
;*** POWER UP ROUTINE
;*
PWRUP   ORCC  #$FF             ;NO INTERRUPTS ETC.
        LDS   #HSTK            ;IF AND WHEN WE DECIDE TO USE THE STACK
        CLR   PIA0+1
        CLR   PIA0
        LDA   #$3C             ;SET LED 3 TO 1 (WE'RE MAKING AN F TO BLANK)
        STA   PIA0+1
        CLR   PIA1+1
        LDA   #$C0             ;BITS 6,7 TO OUTPUTS (LEDS)
        STA   PIA1
        LDA   #$3C             ;SET BIT 2 TO 1
        STA   PIA1+1           ;CLEAR CB2 (LED)
        LDA   #$C0             ;CLEAR LEDS
        STA   PIA1             ;SET BITS 0,1
        LDA   #1
        STA   RWCNTL           ;MAKE SURE WE COPY FROM ROM!
        LDX   #CRTAB
        LDY   #CRAM
PWRUP0  LDD   ,X++
        STD   ,Y++
        CMPX  #CRTAB+16
        BLO   PWRUP0
        LDA   #2
        LDY   #PWRUP1
        LDX   #0
        JMP   RAMTST           ;DO A RAM TEST.
PWRUP1  LDY   #PWRUP4
        JMP   ROMTST
PWRUP4  LDA   #$34             ;PUT A ZERO IN THE LED.
        STA   PIA0+1
        STA   PIA1+1
        CLR   PIA1
        LDA   #RAM>>8
        TFR   A,DP
        LDS   #HSTK
        JSR   SCRCLR
        LDA   #OKM
        JSR   WRD7V            ;INDICATE OK
        LDY   #INIT            ;DELAY TO JUMP INTO GAME.
        LDA   #7
        JMP   DELA1

;*
;* ADVANCE SWITCH
;*

ADVSWZ  LDA   #STYPE
        STA   PTYPE,U
        LDA   INDIAG           ;ALREADY HERE??
        BNE   SUCDV
        NAP   2,ADVSW2         ;MAKE SURE THAT ITS NOT NOISE
ADVSW2  LDA   PIA0             ;IS IT STILL PRESSED??
        BITA  #$02             ;WELL??
        BNE   ADVSW3           ;YEP
SUCDV   JMP   SUCIDE           ;NOPE...DIE
ADVSW3  JSR   GNCIDE           ;CAN EVERYBODY
        JSR   P1SW             ;MAKE SURE PROPER DIRECTION FACED
        LDA   #$FF
        STA   INDIAG
        STA   STATUS           ;KEEP EM ALL OUT
        JSR   INITCM           ;INITIALIZE COLOR MATRIX
        JSR   SCRCLR
        LDA   PIA0             ;CHECK WHICH TYPE OF TEST
        RORA                   ; UP??
        LBCS  BOOK             ;YEP...GO TO BOOKKEEPING
        ORCC  #$BF             ;FIRQ ENABLED INDICATES NORMAL AGNOSTICS RUNNING
        LDY   #DAG999
        JMP   BLKLED           ;BLANK THE LEDS
DAG999  LDA   #WDATA
        STA   WDOG
        LDA   PIA0             ;WAIT FOR ADVANCE SWITCH LET GO
        BITA  #2
        BNE   DAG999
        LDY   #DIAG0
        JMP   ROMTST           ;DO THE ROM TEST
DIAG0   LDA   #RAM>>8
        TFR   A,DP
        JSR   SCRCLR           ;CLEAR FOR ROMS MESSAGE.
        LDA   #ROMOK
        JSR   WRD7V            ;PRINT THE MESSAGE
        LDB   #3
DIG111  LDX   #$7000
DIAG1   LDA   #WDATA
        STA   WDOG
        LDA   PIA0
        BITA  #2
        BNE   DIAG2            ;CONTINUE IF ADVANCE PRESSED.
        LEAX  -1,X
        CMPX  #0
        BNE   DIAG1
        DECB 
        BNE   DIG111
DIG11Z  LDY   #DIAG2
        LDX   #0
        LDA   #$FF             ;INDICATE FRONT DOOR
        JMP   RAMTST           ;DO THE RAM TEST.
DIAG2   LDA   #1
        STA   RWCNTL
        LDA   #RAM>>8
        TFR   A,DP
        JSR   SCRCLR
        LDA   #RAMOK
        JSR   WRD7V            ;PRINT RAM OK MESSAGE
DIAG22  LDA   #WDATA
        STA   WDOG
        LDA   PIA0
        BITA  #2
        BNE   DIAG22           ;HOLD CONTROL UNTIL LET GO.
RAMERJ  LDX   #$9800           ;RAM ERROR MESSAGE COMES HERE.
        CLRA 
DIAG3   STA   ,X+              ;CLR USABLE MEMORY
        LDB   #WDATA
        STB   WDOG
        CMPX  #HSTK+1								;;Fixme was: CPX   #HSTK+1
        BLO   DIAG3
        JSR   INITCM           ;COLOR MATRIX BACK
        LDD   #$A55A
        STD   HSEED
        STA   INDIAG           ;INDICATE THAT WE'RE AGNOSTICS
        JSR   PINIT            ;TIME TO LET THE SYSTEM TAKE OVER
        JSR   INT20V           ;GET OTHER STUFF IN PROPER SHAPE
        JSR   P1SW
        LDA   #$FF
        STA   STATUS
        MAKP  DIAG4            ;START A PROCESS TO CONTINUE
        BSR   ZLED             ;ZERO IN LED
        ANDCC #0               ;LET THE INTERRUPTS IN
        JMP   EXECV            ;GO!
DIAG4   JSR   AVWAIT           ;WAIT FOR ADVANCE SWITCH.
        JSR   CMTEST           ;TEST CMOS.
        ANDCC #1               ;INTERRUPTS BACK ON LEAVE CARRY
        LDA   #CMOK
        BCC   DIAG66
        LDB   #$2F             ;INDICATE THAT ITS IN R/W HALF
        CMPX  #CMOS+$100
        BHI   DIAG5            ;IT WAS IN WRITABLE HALF
        LDB   #$1F
DIAG5   ORCC  #$10             ;LOCK OUT THE INTERRUPTS
        LDS   #DIAG55
        LDA   #$3
        JMP   PULSE
DIAG55  LDS   #HSTK
        BSR   ZLED
        LDA   #RAM>>8
        TFR   A,DP
        ANDCC #$EF             ;LET THE INTERRUPTS BACK
        LDA   #CMERR
        CMPB  #$1F
        BHI   DIAG66
        LDA   #CMDOOR
DIAG66  JSR   SCRCLR
        JSR   WRD7V            ;PRINT ONE OF THE TWO MESSAGES.
;* LDA #CMFD TELL HIM WHATS GOING ON
;* JSR WRD7V
;* NAP $C0,DMAP1
;*MAP1 JSR SCRCLR CLEAR OUT HOSER
;*MAP5 LDB #10
;* LDA #$3F
;* STA SOUND
;* LDA #5
;*MAP2 JSR DMASRT DO THE TEST
;* BCS DMAP3 ERROR
;* JSR AVCHK
;* BCS DMAP4 ADVANCE PRESSED
;* DECB
;* BNE DMAP2
;* LDA #$19 MAKE SOME SOUND DURING THIS
;* STA SOUND
;* LDB #30
;*MPA1 LDA #WDATA
;* STA WDOG
;* DECB
;* BNE DMPA1
;* BRA DMAP5
;*
;*MAP3 JSR SCRCLR
;* JSR INITCM
;* LDA #DMFAIL BAD BYTES
;* JSR WRD7V PRINT IT
;* BRA DMAP7
;*
;*MAP4 JSR SCRCLR
;* JSR INITCM
;* LDA #DMPASS
;* JSR WRD7V
;*MAP99 JSR AVCHK WAIT FOR RELEASE OF GUY THAT GOT US HERE
;* BCS DMAP99
;*
;*MAP7 JSR AVWAIT MOVE ON TO NEXT IMAGE
;*
        JSR   AVWAIT
        LDU   CRPROC
        CLR   PD+2,U           ;INDICATE FRONT DOOR TEST CALLING
        JSR   SNDSRT           ;START THE SOUND TEST
DIAG6   JSR   SNDCYC           ;CYCLE ONE SOUND
        JSR   AVCHK            ;CHECK ADVANCE SWITCH.
        BCC   DIAG6            ;NOT PRESSED, DO ANOTHER SOUND
        LDA   #$3F
        STA   SOUND
        NAP   1,DIAG77
DIAG77  LDA   #$2C             ;SILENCE
        STA   SOUND
        JSR   AVWAIT           ;NOW WAIT FOR RELEASE.
        JSR   SWTEST           ;DO A SWITCH TEST.
        JSR   AVWAIT           ;WAIT FOR RELESE
        JSR   CRTEST           ;DO THE COLOR MATRIX TEST
        JSR   AVCHK            ;HOLDING BUTTON??
        BCC   DIAG78           ;NOPE...CONTINUE
        JSR   AVWAIT           ;WAIT FOR LET GO TIME.
DIAG78  JMP   TSTPAT           ;DO SOME TEST PATTERNS THEN GO TO BOOK.

ZLED    CLR   PIA1             ;ZERO IN LED INDICATES ON LAST TEST OR DUN
        LDA   #$34
        STA   PIA0+1
        INCA 
        STA   PIA1+1
        RTS  
;*
INITCM  LDX   #CRTAB
        LDY   #PCRAM
        LDU   #CRAM
ADVS90  LDD   ,X++
        STD   ,Y++
        STD   ,U++
        CMPX  #CRTAB+16
        BLO   ADVS90
        RTS  

CRTAB   FCB   $00,$07,$17,$C7,$1F,$3F,$38,$C0
        FCB   $A4,$FF,$38,$17,$CC,$81,$81,$07 ;STARGATE COLOR TABLE
;*
;*** AUTO CYCLE
;*
AUTCYC  LDA   #$3F             ;MAKE LOOK LIKE FRONT DOOR TEST THANX TO MOTOROLA
        TFR   A,CC             ;SET TO AUTOCYCLE NO INTS PLEASE ETC.
        BSR   INITCM           ;COLOR MATRIX OK.....OK?
        LDA   #$85             ;FIVE RAM PASSES, IN AUTOCYCLE
        LDX   RAMALS+$600      ;TAKE A BYTE FORM THE RAM TEST
        LEAX  $1234,X          ;ADD A STUPID NUMBER TO VARY TEST
        LDY   #AUTO1
        JMP   RAMTST           ;TEST THE RAM
AUTO1   LDY   #AUTO2
        JMP   ROMTST
AUTO2   LDA   #RAM>>8
        TFR   A,DP
        LDS   #HSTK            ;JUST IN CASE
        JSR   CMTEST
        BCC   AUTO4
        LDA   #3               ;CMOS ERROR IN LED NOW
        BSR   LEDME            ;PUT IT OUT
        LDA   #CMDOOR
        CMPX  #CMOS+$100       ;WRITE PROTECT??
        BLS   AUTO8
        LDA   #CMERR
AUTO8   LDB   #WDATA
        STB   WDOG             ;ARF
        JSR   SCRCLR
        JSR   WRD7V            ;PRINT THE ERROR
AUTO5   LDA   #WDATA
        STA   WDOG
        BRA   AUTO5
AUTO4   BSR   BARS
        LDY   #AUTCYC
        LDA   #4
        JMP   DELA1

LEDME   LDY   #LEDME1          ;RETURN ADDRESS
        JSR   PSSUB            ;PUT OUT THE LOW HALF OF A
LEDME1  RTS                   ;AND RETURN

;*
;*** TEST PATTERNS
;*
TSTPAT  JSR   CROSS            ;DO FANCY HASSLER PAT.
        JSR   AVWAIT           ;WAIT FOR ADVANCE
        JSR   SCRCLR
        LDA   #$7              ;RED
        STA   PCRAM
        JSR   AVWAIT
        LDA   #$38             ;GREEN
        STA   PCRAM
        JSR   AVWAIT
        LDA   #$C0
        STA   PCRAM            ;BLUE
        JSR   AVWAIT
        BSR   BARS
        JSR   AVWAIT
        JMP   BOOK

HASSUB  STX   XTEMP
        LEAX  $1000,X
COL221  LEAX  -$100,X
        CMPX  #RAM             ;INTO SCRATCHPAD??
        BHI   COL221
        RTS  

BARS    LDX   #PCRAM
        LDY   #CBARCL
        LDU   #CRAM
BARS0   LDD   ,Y++             ;GET A COLOR
        STD   ,X++
        STD   ,U++             ;IN CASE INTERRUPTS OFF
        LDA   #WDATA
        STA   WDOG
        CMPX  #PCRAM+16
        BLO   BARS0
        LDD   #0
        LDX   #0

COLOR1  BSR   HASSUB

COLOR2  STD   ,--X
        PSHS  A
        LDA   #WDATA
        STA   WDOG
        PULS  A
        CMPX  XTEMP
        BNE   COLOR2
        LEAX  $900,X
        TSTA 
        BNE   COLOR3
        LDX   #$D00
COLOR3  ADDD  #$1111
        BCC   COLOR1
        RTS  
;*
CBARCL  FCB   $5,$5,$28,$28,$80,$80,$0,$0
        FCB   $AD,$AD,$2D,$2D,$A8,$A8,$85,$85
;*
;* DON HASSLER CROSSHATCH
;*
;* RAM0 = BLACK - 00
;* RAM1 = WHITE - FF
;* RAM2 = BLUE - C0
;* RAM3 = GREEN - 38
;* RAM4 = RED - 07
;*
CROSS   JSR   SCRCLR           ;CLEAR SCREEN
        CLRA 
        JSR   SETPCR           ;ZERO COLOR MATRIX
        LDA   #$FF
        STA   PCRAM+1
        LDA   #$C0
        STA   PCRAM+2
        LDA   #$38
        STA   PCRAM+3
        LDA   #$7
        STA   PCRAM+4
        LDY   #WVERT           ;MOVE WHITE VERTICALS
        LDD   #$0101
CROSS4  LDX   0,Y              ;GET START PTR
CROSS5  STD   0,X++            ;MOVE IN WHITE
        CMPX  2,Y              ;CK IF LINE DONE
        BNE   CROSS5           ;NO, KEEP GOING
        LEAY  4,Y              ;INCR Y BY 4
        CMPY  #WVERTX          ;CK IF ALL DONE
        BNE   CROSS4           ;NO, DO NEXT LINE
        LDA   #$11             ;MOVE WHITE HORIZ
        LDY   #WHORZ
CROSS2  LDX   0,Y              ;GET START PTR
        STX   XTEMP
CROSS3  STA   0,X              ;MOVE IN WHITE
        INC   XTEMP            ;UPDATE PTR
        LDX   XTEMP
        CMPX  2,Y              ;CK IF DONE
        BNE   CROSS3           ;NO, KEEP GOING
        LEAY  4,Y              ;INCR Y BY 4
        CMPY  #WHORZX          ;CK IF ALL DONE
        BNE   CROSS2           ;NO, DO NEXT LINE
        LDY   #HORZZ           ;MOVE IN COLOR HORIZ.
CROSS6  LDX   0,Y              ;GET START PTR
        STX   XTEMP
        LDA   4,Y              ;GET COLOR
CROSS7  STA   0,X              ;MOVE IN COLOR
        INC   XTEMP
        LDX   XTEMP
        CMPX  2,Y              ;CK IF LINE DONE
        BNE   CROSS7           ;NO, KEEP GOING
        LEAY  5,Y              ;INCR Y BY 5
        CMPY  #HORIZX          ;CK IF ALL DONE
        BNE   CROSS6           ;NO, DO NEXT LINE
        LDY   #VERT            ;MOVE IN COLOR VERTICAL
CROSS8  LDX   0,Y              ;GET START PTR
        LDA   4,Y              ;GET COLOR
CROSS9  STA   0,X+             ;MOVE IN COLOR
        CMPX  2,Y              ;CK IF LINE DONE
        BNE   CROSS9           ;NO, KEEP GOING
        LEAY  5,Y              ;INCR Y BY 5
        CMPY  #VERTX           ;CK IF ALL DONE
        BNE   CROSS8           ;NO, DO NEXT LINE
        LDA   #$21             ;BLUE TOUCH UP
        STA   $437E
        LDA   #$20
        STA   $937E
        LDX   #$4B0A
CROSSA  SEI  
        CLR   RWCNTL
        LDA   0,X
        LDB   #1
        STB   RWCNTL
        CLI  
        ANDA  #$F0
        ORA   #$02
        STA   0,X+
        CMPX  #$4B6D
        BNE   CROSSA
        LDX   #$4B90
CROSSB  SEI  
        CLR   RWCNTL
        LDA   0,X
        LDB   #1
        STB   RWCNTL
        CLI  
        ANDA  #$F0
        ORA   #$02
        STA   0,X+
        CMPX  #$4BF3
        BNE   CROSSB
        LDX   #$0B18
        STX   XTEMP            ;MOVE IN DOTS
CROSSC  LDX   XTEMP
        SEI  
        CLR   RWCNTL
        LDA   0,X              ;OR IN DOT
        LDB   #1
        STB   RWCNTL
        CLI  
        ANDA  #$F0
        ORA   #$01
        STA   0,X              ;STORE DOT
        LDB   XTEMP+1          ;UPDATE VERTICAL PTR
        ADDB  #$22
        BCS   CROSSD
        STB   XTEMP+1
        BRA   CROSSC
CROSSD  LDB   #$18
        STB   XTEMP+1          ;RE-INIT VERT. PTR
        LDB   XTEMP
        ADDB  #$10             ;UPDATE HORIZ PTR
        STB   XTEMP
        CMPB  #$9B             ;CK IF DONE
        BNE   CROSSC           ;NO, KEEP GOING
        RTS  
;*
;* CROSS HATCH DATA
;*
WHORZ   FDB   $0407
        FDB   $9407
        FDB   $0429
        FDB   $9429
        FDB   $044B
        FDB   $944B
        FDB   $046D
        FDB   $946D
        FDB   $048F
        FDB   $948F
        FDB   $04B1
        FDB   $94B1
        FDB   $04D3
        FDB   $94D3
        FDB   $04F5
        FDB   $94F5
WHORZX  EQU   *
WVERT   FDB   $0307
        FDB   $03F5
        FDB   $1307
        FDB   $13F5
        FDB   $2307
        FDB   $23F5
        FDB   $3307
        FDB   $33F5
        FDB   $4307
        FDB   $43F5
        FDB   $5307
        FDB   $53F5
        FDB   $6307
        FDB   $63F5
        FDB   $7307
        FDB   $73F5
        FDB   $8307
        FDB   $83F5
        FDB   $9307
        FDB   $93F5
WVERTX  EQU   *
HORZZ   FDB   $4505
        FDB   $5205
        FCB   $44
        FDB   $4506
        FDB   $5206
        FCB   $44
        FDB   $4507
        FDB   $5207
        FCB   $00
        FDB   $4508
        FDB   $5208
        FCB   $33
        FDB   $4509
        FDB   $5209
        FCB   $33
        FDB   $45F3
        FDB   $52F3
        FCB   $33
        FDB   $45F4
        FDB   $52F4
        FCB   $33
        FDB   $45F5
        FDB   $52F5
        FCB   $00
        FDB   $45F6
        FDB   $52F6
        FCB   $44
        FDB   $45F7
        FDB   $52F7
        FCB   $44
        FDB   $047E
        FDB   $437E
        FCB   $22
        FDB   $547E
        FDB   $937E
        FCB   $22
HORIZX  EQU   *
VERT    FDB   $026F
        FDB   $028E
        FCB   $04
        FDB   $036F
        FDB   $038E
        FCB   $30
        FDB   $936F
        FDB   $938E
        FCB   $00
        FDB   $946F
        FDB   $948E
        FCB   $34
VERTX   EQU   *
;*
;*** COLOR MATRIX TEST
;*
CRTEST  PULS  D                ;GET RETURN
        LDU   CRPROC
        STD   PD+6,U           ;SAVE
        JSR   SCRCLR           ;CLEAR OUT BABY
        LDA   #CMTSTM          ;PRINT THE MESSAGE
        JSR   WRD7V
        LDA   #$80
        STA   PD,U
CRTST1  NAP   1,CRTST2
CRTST2  JSR   AVCHK            ;PRESS??
        BCS   CMTBYE           ;NOPE
        DEC   PD,U             ;DONE WITH DELAY??
        BNE   CRTST1
        LDA   COLRMT           ;GET FIRST COLOR.
        BSR   SETPCR           ;STORE IT DOWN
        BSR   RAMBAR           ;SET UP MEMORY.
CRTTZZ  LDX   #COLRMT          ;TABLE TO STORE
CRTST3  LDA   ,X+              ;GET A COLOR
        LDU   CRPROC
        STX   PD+2,U
        BSR   SETPCR           ;STORE IT THROUGH
        LDA   #$80
        STA   PD,U
CRTST4  NAP   1,CRTST5
CRTST5  JSR   AVCHK            ;ADVANCE??
        BCS   CMTBYE           ;YEP
        DEC   PD,U
        BNE   CRTST4
        LDX   PD+2,U           ;RESTORE POINTER
        CMPX  #COLRMT+8
        BLO   CRTST3
        BRA   CRTTZZ           ;CONTINUE THROUGH
CMTBYE  LDU   CRPROC
        JMP   [PD+6,U]

RAMBAR  LDX   #$0
        LDY   #COLRMD          ;NUMBERS TO PUT IN BARS
RAMBA1  JSR   HASSUB           ;SAVE OUR X
        LDA   ,Y+
        TFR   A,B
RAMBA2  STD   ,--X
        CMPX  XTEMP
        BNE   RAMBA2
        LEAX  $900,X
        TSTA 
        BNE   RAMBA3
        LDX   #$D00
RAMBA3  CMPY  #COLRMD+16
        BNE   RAMBA1
        RTS  

COLRMT  FCB   $02,$03,$04,$10,$18,$20,$40,$80
COLRMD  FCB   $00,$FF,$11,$EE,$22,$DD,$33,$CC
        FCB   $44,$BB,$55,$AA,$66,$99,$77,$88

SETPCR  LDX   #PCRAM
SETPC1  STA   ,X+
        CMPX  #PCRAM+16
        BLO   SETPC1
        RTS  
;*
;*** SWITCH TEST
;*

SWMH    EQU   44               ;HEIGHT OF FIRST MESSAGE

SWTEST  PULS  D                ;GET RETURN ADDR
        LDU   CRPROC
        STD   PD+6,U
        LDA   #10
        STA   PD+4,U           ;DELAY COUNTER FOR EXIT
        JSR   SCRCLR           ;CLEAR IT PLEASE
        LDA   #SWTESM          ;SWITCH TEST MESSAGE.
        JSR   WRD7V
        LDU   #RAMALS
SWTES0  CLR   ,U+
        CMPU  #SW3SCI+1
        BLS   SWTES0
SWTES2  LDU   #STABP
        BSR   SWSCN0
SWTES1  LDA   #$34
        STA   PIA3+1
        BSR   SWSCN0           ;SCAN THE COCKTAIL SIDE
        LDA   #$3C
        STA   PIA3+1
        BSR   SWDISP
        JSR   AVCHK            ;ADVANCE PRESSED?
        BCC   SWT999           ;NOPE.
        LDU   CRPROC
        DEC   PD+4,U
        BEQ   SWTBYE
SWT999  NAP   1,SWTES2

SWTBYE  LDU   CRPROC
        JMP   [PD+6,U]         ;"RETURN"

SWSCN0  LDX   ,U++             ;GET ADDRESS OF PORT
        BEQ   SWSCN5           ;DONE
        LDY   ,U++             ;GET ADDRESS TO STORE STATE
        LDA   ,X               ;GET NEW STATE
        EORA  ,Y               ;SEE WHERE DIFFERENT
        STA   1,Y              ;AND SAVE AS DIFFERENCE BYTE.
        BRA   SWSCN0
SWSCN5  RTS  

SWDISP  LDU   #SPHTAB          ;WE'LL WALK THROUGH SWITCH PHRASE TABLE
        LDY   #RAMALS          ;WALK THROUGH THE SCANNED STUFF.
SWDIS4  LDB   #1               ;WALK FROM LSB
SWDIS0  BITB  1,Y              ;SEE IF THIS BIT CHANGED.
        BEQ   SWDIS2
        BSR   SWACT            ;TAKE SOME ACTION
SWDIS2  LEAU  3,U              ;MOVE TO NEXT ENTRY
        ASLB                   ; ONE DOWN
        BCC   SWDIS0
        LEAY  2,Y              ;TO NEXT BYTE
        CMPY  #SW3SCI          ;PAST TABLE
        BHI   SWDIS9           ;YEP..DONE
        LDA   PIA3             ;COCKTAIL
        BMI   SWDIS4           ;YEP...FULL SCAN
        CMPY  #SW3SCN          ;NOPE..DONE WITH NORMAL SWITCHES??
        BLS   SWDIS4           ;NOT DONE
SWDIS9  RTS                   ;RETURN BABY.

SWACT   PSHS  B,X              ;SAVE THE MASK
        LDA   #$3F
        STA   SOUND            ;BRING SOUND LINES HIGH IN ANTICIPATION
        EORB  ,Y               ;INVERT THE BIT
        STB   ,Y               ;AND MAKE THAT THE NEW STATE
        LDB   ,S               ;RESTORE MASK
        BITB  ,Y               ;WHICH WAY DID IT GO
        BNE   SWPRNT           ;ON....PRINT A MESSAGE.
        LDB   2,U              ;HEIGHT
        BEQ   SWNOAC
        LDA   #$40             ;X
        TFR   D,X              ;MAKE IT CURSOR
        LDD   #$3006
        JSR   BLKCLR           ;CLEAR THE BLOCK
        PULS  B,X,PC
SWPRNT  LDB   2,U              ;GET HEIGHT
        BEQ   SWNOAC
        LDA   #$40             ;CURSOR
        TFR   D,X
        LDB   #$BB
        STB   TEXCOL
        LDD   ,U               ;GET MESSAGE NUMBER,B (PLAYER NUMBER)
        JSR   WRD5FV           ;AND PRINT IT.
        LDA   #$37
        STA   SOUND            ;MAKE A SOUND
SWNOAC  PULS  B,X,PC           ;AND RETURN.

STABP   FDB   PIA0,SW0ST
        FDB   PIA2,SW2ST
        FDB   PIA3,SW3ST
        FDB   0
        FDB   PIA2,SW2STI
        FDB   PIA3,SW3STI
        FDB   0

SPHTAB  FCB   SWMES1,0,SWMH    ;AUTO UP
        FCB   SWMES1+1,0,SWMH+7 ;ADVANCE
        FCB   SWMES1+2,0,SWMH+14 ;RIGHT COIN
        FCB   SWMES1+3,0,SWMH+21 ;HIGH SCORE RESET
        FCB   SWMES1+4,0,SWMH+28 ;LEFT COIN
        FCB   SWMES1+5,0,SWMH+35 ;CENTER COIN
        FCB   SWMES1+6,0,SWMH+42 ;SLAM SWITCH
        FCB   0,0,0            ;UNUSED (SOUND HANDSHAKE)
;*
        FCB   SWMES1+7,1,SWMH+49 ;FIRE (1)
        FCB   SWMES1+8,1,SWMH+56 ;THRUST (1)
        FCB   SWMES1+9,1,SWMH+63 ;SMARTBOMB (1)
        FCB   SWMES1+10,1,SWMH+70 ;HYPERSPACE (1)
        FCB   SWMES1+11,0,SWMH+77 ;START 2
        FCB   SWMES1+12,0,SWMH+84 ;START 1
        FCB   SWMES1+13,1,SWMH+91 ;REVERSE (1)
        FCB   SWMES1+14,1,SWMH+98 ;DOWN (1)
;*
        FCB   SWMES1+15,1,SWMH+105 ;UP (1)
        FCB   SWMES1+16,1,SWMH+112 ;INVISO (1)
        FCB   0,0,0            ;UNUSED
        FCB   0,0,0            ;UNUSED
        FCB   0,0,0            ;UNUSED
        FCB   0,0,0            ;UNUSED
        FCB   0,0,0            ;UNUSED
        FCB   0,0,0            ;UNUSED
;*
        FCB   SWMES1+7,2,SWMH+119 ;FIRE (2)
        FCB   SWMES1+8,2,SWMH+126 ;THRUST (2)
        FCB   SWMES1+9,2,SWMH+133 ;SMART BOMB(2)
        FCB   SWMES1+10,2,SWMH+140 ;HYPERSPACE (2)
        FCB   0,0,0            ;UNUSED
        FCB   0,0,0            ;UNUSED
        FCB   SWMES1+13,2,SWMH+147 ;REVERSE (2)
        FCB   SWMES1+14,2,SWMH+154 ;DOWN (2)
;*
        FCB   SWMES1+15,2,SWMH+161 ;UP (2)
        FCB   SWMES1+16,2,SWMH+168 ;INVISO (2)
        FCB   0,0,0            ;UNUSED
        FCB   0,0,0            ;UNUSED
        FCB   0,0,0            ;UNUSED
        FCB   0,0,0            ;UNUSED
        FCB   0,0,0            ;UNUSED
        FCB   0,0,0            ;UNUSED

        INCLUDE	RRTEST2.ASM    ;INCLUDE SECOND HALF				;;Fixme was: LIB   "src/RRTEST2.ASM" 