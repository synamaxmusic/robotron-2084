;        OPT   NOL
;        LIB   "src/RRF.ASM"
;        OPT   LIS
;        STTL  ROBOTS AND POSTS
        ORG   RPORG
        JMP   RINITV
        JMP   PSINV
        FDB   PSTP1V
        JMP   OPONV
        JMP   OPON1V
        JMP   SAFTYV
        FDB   RWDP1
        FDB   PSTP1V
        JMP   PKPROC
;*
;*SOUND TABLE
;*
RBSND   FCB   $D0,$01,$0C,$14,$01,$08,$17,0 ;ROBOT HIT
RMVSND  FCB   $C0,$01,$0A,$06,0 ;ROBOT MOVE
PSKSND  FCB   $D0,$01,$08,$17,0 ;POST KILL
;*
;*INITIALIZE ROBOTS
;*
RINITV  LDA   ROBCNT
        PSHS  A
        BEQ   RINX
RINL    JSR   GETROB
        LDD   #RWDP1
        STD   OPICT,X
        STD   OLDPIC,X
        BSR   SAFTY
RINL0   JSR   RANDXY
        CMPB  XTEMP
        BLS   RINL1
        CMPB  XTEMP+1
        BHS   RINL1
        CMPA  XTEMP2
        BLS   RINL1
        CMPA  XTEMP2+1
        BLO   RINL0
RINL1   STD   OBJX,X
        STA   OX16,X
        STB   OY16,X
        TFR   D,U
        LDD   [OPICT,X]
        JSR   ASCAN
        BNE   RINL0
        LDA   ROBSPD
        JSR   RANDU
        STA   ODATA,X
        LDD   #ROBKIL
        STD   OCVECT,X
        BSR   OPON1            ;TURN HIM ON WITH PHONY COLOR
        DEC   ,S
        BNE   RINL
        STX   ROBST            ;SAVE START OF LIST
        MAKP  ROBOT
RINX    PULS  A,PC
;*
;*GRUNT SAFTY MARGIN
;*
SAFTYV  PSHS  X,U,D
        JSR   PLINDX
        LDA   PWAV,X
        CMPA  #10
        BLO   SAF0
        LDA   #6
        BRA   SAF1
SAF0    CMPA  #5
        BLS   SAF1
        LDA   #5
SAF1    LDX   #SAFTAB-4
        ASLA 
        ASLA 
        LEAX  A,X
        LDD   ,X
        STD   XTEMP            ;SET UP LIMITS
        LDD   2,X
        STD   XTEMP2
        PULS  D,X,U,PC
SAFTAB  FCB   $40,$B0,$1A,$7A
        FCB   $48,$A8,$1A,$7A
        FCB   $50,$A0,$2A,$6A
        FCB   $54,$9D,$30,$60
        FCB   $5D,$96,$35,$59
        FCB   $62,$94,$38,$5C
;*
;*ON PICTURE OF OBJECT
;*X=OBJ, A=COL
OPON1V  PSHS  D,Y
        LDA   #FONCOL
        BRA   OPON2
OPONV   PSHS  D,Y
OPON2   STA   XTEMP2
        LDD   OBJX,X
        LDY   OPICT,X
        JSR   MPCTON
        PULS  D,Y,PC
;*
;*INITIALIZE POSTS
;*
PSINV   PSHS  X,Y,U
        LDX   #PSLIST
        STX   PSTIN
        LEAY  ,X
PSI00   CLR   ,X+
        CMPX  #PSLEND
        BLO   PSI00
        LDA   PSTCNT
        PSHS  A
        BEQ   PSIX
PSIL    JSR   GETPST
        LDD   PSTANI
        STD   OPICT,X
        STD   OLDPIC,X
        BSR   SAFTYV
        LDD   XTEMP
        ADDD  #$03FC           ;ADJUST BOUNDS
        STD   XTEMP
        LDD   XTEMP2
        ADDD  #$02FD
        STD   XTEMP2
PSI0    JSR   RANDXY
        CMPB  XTEMP
        BLS   PSI1
        CMPB  XTEMP+1
        BHS   PSI1
        CMPA  XTEMP2
        BLS   PSI1
        CMPA  XTEMP2+1
        BLO   PSI0
PSI1    STD   OBJX,X
        STA   OX16,X
        STB   OY16,X
        LDU   OBJX,X
        LDD   [OPICT,X]
        JSR   ASCAN
        BNE   PSI0
        LDD   #PSTKIL
        STD   OCVECT,X
        STY   OBJID,X          ;SAVE REF POINTER FOR KILL
        LEAY  2,Y
        JSR   OPON1            ;ON MONO PHONY
        DEC   ,S
        BNE   PSIL
PSIX    PULS  A,X,Y,U,PC
;*
;*ROBOT PROCESS
;*
ROBOT   LDA   STATUS
        BITA  #$7F
        BEQ   ROB0A
        NAP   2,ROBOT
ROB0A   NAP   10,ROB0
ROB0    CLRB 
        LDA   ROBCNT
        PSHS  D
        BEQ   ROBXXX
        LDX   ROBST
        BRA   ROB1A
ROB1    LDX   ,X
ROB1A   DEC   ODATA,X          ;TIME TO MOVE?
        BEQ   ROB1B
        DEC   ,S
        BNE   ROB1
ROBXXX  BRA   ROBX             ;ALL DONE
ROB1B   LDA   ROBSPD
        JSR   RANDU
        STA   ODATA,X
        LDB   OY16,X
        SUBB  PY16             ;SEEK PLAYER
        BHI   ROB2
        CMPB  #$FE
        BHI   ROB3
        LDB   #4
        BRA   ROB2A
ROB2    CMPB  #2
        BLO   ROB3
        LDB   #-4
ROB2A   ADDB  OY16,X
        CMPB  #YMAX-12
        BHI   ROB3
        CMPB  #YMIN
        BLO   ROB3
        STB   OY16,X
ROB3    LDB   OX16,X
        SUBB  PX16
        BHI   ROB4
        LDB   #2
        BRA   ROB4A
ROB4    CMPB  #1
        BLO   ROB5
        LDB   #-2
ROB4A   ADDB  OX16,X
        CMPB  #XMAX-5
        BHI   ROB5
        CMPB  #XMIN
        BLO   ROB5
        STB   OX16,X
ROB5    LDD   OPICT,X
        ADDD  #4
        CMPD  #RWDP4
        BLS   ROB11
        LDD   #RWDP1
ROB11   STD   OPICT,X
        JSR   DMAOFN
        INC   1,S              ;MAKE A SOUND
        LDU   OPICT,X
        LDD   OBJX,X
        PSHS  X
        LDX   #PPTR
        JSR   COL0
        PULS  X
        BEQ   ROBLP
        LDY   ,X
        BSR   ROBKIL
        DEC   ,S
        BEQ   ROBX             ;ALL DONE
        LEAX  ,Y
        JMP   ROB1A
ROBLP   DEC   ,S
        LBNE  ROB1
ROBX    LDD   ,S++
        BEQ   ROBXX            ;NO SOUND NEEDED
        LDD   #RMVSND
        JSR   SNDLD
ROBXX   NAP   4,ROB0
;*KILL ROBOT
ROBKIL  LDA   PCFLG            ;DONT BLOW ON PLAYER
        BNE   ROBKON
        JSR   EXST             ;BLOW HIM UP!!!!
        CMPX  ROBST            ;CHECK FOR START CHANGE
        BNE   ROBK0
        LDD   ,X
        STD   ROBST
ROBK0   JSR   KILROB
        LDD   #$0110
        JSR   SCORE
        LDD   #RBSND
        JSR   SNDLD
        LDB   #$E0             ;SPEED EM UP
        LDA   ROBSPD
        MUL  
        CMPA  RMXSPD
        BLO   ROBK1
        STA   ROBSPD
ROBK1   DEC   ROBCNT
ROBKX   RTS  
ROBKON  JMP   DMAON            ;ON GRUNT...SEE WHAT YOU HIT
;*KILL POST
PSTKIL  LDA   PCFLG
        BNE   PSTKON
        JSR   KILPST
        LDD   #0
        STD   [OBJID,X]        ;WIPE OUT REFRESH
        JSR   DMAOFF
        DEC   PSTCNT
        LDD   FREE
        BEQ   PSTKX            ;OUT OF PROCS
        LEAU  ,X
        LDX   ,X
        STX   OFREE
        MAKP  PKPROC
        STU   PD,X
        LDD   #PSKSND
        JMP   SNDLD
PSTKX   RTS  
PSTKON  LDA   PSTCOL
        JMP   OPON             ;TURN HIM ON
;*
;*POST KILL PROCESS
;*
PKPROC  LDX   PD,U
        LDY   OPICT,X
        BRA   PKPR2
PKPR1   LDX   PD,U
        LDY   OPICT,X
        LEAY  5,Y
        LDA   ,Y
        BNE   PKPR2
        JSR   DMAOFF           ;ITS ALL OVER....
        LDD   OFREE
        STD   ,X
        STX   OFREE
        JMP   SUCIDE
PKPR2   STY   OPICT,X
        JSR   DMAOFN
        LDA   4,Y              ;SLEEP TIME VARIABLE SLEEP
        LDX   #PKPR1
        JMP   SLEEP
;*
;*POST IMAGES
;*
PSTP1V  EQU   *
;*STAR
PSP1A   FCB   5,9              ;W,H
        FDB   PSD1A            ;DATA ADDR
        FCB   6                ;SLEEP TIME
PSP2A   FCB   5,9
        FDB   PSD2A
        FCB   3
PSP3A   FCB   5,9
        FDB   PSD3A
        FCB   2,0              ;END OF SEQUENCE
;*SNOWFLAKE
PSP1B   FCB   5,9              ;W,H
        FDB   PSD1B            ;DATA ADDR
        FCB   6                ;SLEEP TIME
PSP2B   FCB   5,9
        FDB   PSD2B
        FCB   3
PSP3B   FCB   5,9
        FDB   PSD3B
        FCB   2,0              ;END OF SEQUENCE
;*SQUARE
PSP1C   FCB   5,9              ;W,H
        FDB   PSD1C            ;DATA ADDR
        FCB   6                ;SLEEP TIME
PSP2C   FCB   5,9
        FDB   PSD2C
        FCB   3
PSP3C   FCB   5,9
        FDB   PSD3C
        FCB   2,0              ;END OF SEQUENCE
;*TRIANGLE
PSP1D   FCB   5,9              ;W,H
        FDB   PSD1D            ;DATA ADDR
        FCB   6                ;SLEEP TIME
PSP2D   FCB   5,9
        FDB   PSD2D
        FCB   3
PSP3D   FCB   5,9
        FDB   PSD3D
        FCB   2,0              ;END OF SEQUENCE
;*VERT. BAR
PSP1E   FCB   3,9              ;W,H
        FDB   PSD1E            ;DATA ADDR
        FCB   6                ;SLEEP TIME
PSP2E   FCB   3,9
        FDB   PSD2E
        FCB   3
PSP3E   FCB   3,9
        FDB   PSD3E
        FCB   2,0              ;END OF SEQUENCE
;*DIAMOND
PSP1F   FCB   5,9              ;W,H
        FDB   PSD1F            ;DATA ADDR
        FCB   6                ;SLEEP TIME
PSP2F   FCB   5,9
        FDB   PSD2F
        FCB   3
PSP3F   FCB   5,9
        FDB   PSD3F
        FCB   2,0              ;END OF SEQUENCE
;*2084 POST
PSP1G   FCB   9,7
        FDB   PSD1G
        FCB   6
PSP2G   FCB   9,7
        FDB   PSD2G
        FCB   3
PSP3G   FCB   9,7
        FDB   PSD3G
        FCB   2,0
;*SPIKE
PSP1H   FCB   5,9
        FDB   PSD1H
        FCB   6
PSP2H   FCB   5,9
        FDB   PSD2H
        FCB   3
PSP3H   FCB   5,9
        FDB   PSD3H
        FCB   2,0
;*SPIRAL
PSP1I   FCB   5,10
        FDB   PSD1I
        FCB   6
PSP2I   FCB   5,10
        FDB   PSD2I
        FCB   3
PSP3I   FCB   5,10
        FDB   PSD3I
        FCB   2,0

;        IF    NOL         ;Fixme was: IFC   &A,NOL
;        OPT   NOL
;        ENDIF
;*STAR PICTS
PSD1A   EQU   *
        FCB   $00,$00,$90,$00,$00
        FCB   $09,$00,$90,$09,$00
        FCB   $00,$90,$90,$90,$00
        FCB   $00,$09,$99,$00,$00
        FCB   $99,$99,$99,$99,$90
        FCB   $00,$09,$99,$00,$00
        FCB   $00,$90,$90,$90,$00
        FCB   $09,$00,$90,$09,$00
        FCB   $00,$00,$90,$00,$00
PSD2A   EQU   *
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$A0,$00,$00
        FCB   $00,$A0,$A0,$A0,$00
        FCB   $00,$0A,$AA,$00,$00
        FCB   $0A,$AA,$AA,$AA,$00
        FCB   $00,$0A,$AA,$00,$00
        FCB   $00,$A0,$A0,$A0,$00
        FCB   $00,$00,$A0,$00,$00
        FCB   $00,$00,$00,$00,$00
PSD3A   EQU   *
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$A0,$00,$00
        FCB   $00,$0A,$AA,$00,$00
        FCB   $00,$00,$A0,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
;*SNOWFLAKE PICTS
PSD1B   EQU   *
        FCB   $00,$00,$90,$00,$00
        FCB   $09,$09,$09,$09,$00
        FCB   $00,$90,$90,$90,$00
        FCB   $09,$09,$09,$09,$00
        FCB   $90,$90,$00,$90,$90
        FCB   $09,$09,$09,$09,$00
        FCB   $00,$90,$90,$90,$00
        FCB   $09,$09,$09,$09,$00
        FCB   $00,$00,$90,$00,$00
PSD2B   EQU   *
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$A0,$00,$00
        FCB   $00,$0A,$0A,$00,$00
        FCB   $00,$A0,$A0,$A0,$00
        FCB   $0A,$0A,$0A,$0A,$00
        FCB   $00,$A0,$A0,$A0,$00
        FCB   $00,$0A,$0A,$00,$00
        FCB   $00,$00,$A0,$00,$00
        FCB   $00,$00,$00,$00,$00
PSD3B   EQU   *
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$A0,$00,$00
        FCB   $00,$0A,$AA,$00,$00
        FCB   $00,$00,$A0,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
;*SQUARE PICTS
PSD1C   EQU   *
        FCB   $99,$99,$99,$99,$90
        FCB   $99,$99,$99,$99,$90
        FCB   $99,$99,$99,$99,$90
        FCB   $99,$99,$99,$99,$90
        FCB   $99,$99,$99,$99,$90
        FCB   $99,$99,$99,$99,$90
        FCB   $99,$99,$99,$99,$90
        FCB   $99,$99,$99,$99,$90
        FCB   $99,$99,$99,$99,$90
PSD2C   EQU   *
        FCB   $00,$00,$00,$00,$00
        FCB   $0A,$AA,$AA,$AA,$00
        FCB   $0A,$AA,$AA,$AA,$00
        FCB   $0A,$AA,$AA,$AA,$00
        FCB   $0A,$AA,$AA,$AA,$00
        FCB   $0A,$AA,$AA,$AA,$00
        FCB   $0A,$AA,$AA,$AA,$00
        FCB   $0A,$AA,$AA,$AA,$00
        FCB   $00,$00,$00,$00,$00
PSD3C   EQU   *
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$0A,$AA,$00,$00
        FCB   $00,$0A,$AA,$00,$00
        FCB   $00,$0A,$AA,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
;*TRIANGLE PICT
PSD1D   EQU   *
        FCB   $00,$00,$00,$00,$90
        FCB   $00,$00,$00,$09,$90
        FCB   $00,$00,$00,$99,$90
        FCB   $00,$00,$09,$99,$90
        FCB   $00,$00,$99,$99,$90
        FCB   $00,$09,$99,$99,$90
        FCB   $00,$99,$99,$99,$90
        FCB   $09,$99,$99,$99,$90
        FCB   $99,$99,$99,$99,$90
PSD2D   EQU   *
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$0A,$00
        FCB   $00,$00,$00,$AA,$00
        FCB   $00,$00,$0A,$AA,$00
        FCB   $00,$00,$AA,$AA,$00
        FCB   $00,$0A,$AA,$AA,$00
        FCB   $00,$AA,$AA,$AA,$00
        FCB   $00,$00,$00,$00,$00
PSD3D   EQU   *
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$A0,$00
        FCB   $00,$00,$0A,$A0,$00
        FCB   $00,$00,$AA,$A0,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
;*VERT. BAR PICT
PSD1E   EQU   *
        FCB   $99,$99,$90
        FCB   $99,$99,$90
        FCB   $99,$99,$90
        FCB   $99,$99,$90
        FCB   $99,$99,$90
        FCB   $99,$99,$90
        FCB   $99,$99,$90
        FCB   $99,$99,$90
        FCB   $99,$99,$90
PSD2E   EQU   *
        FCB   $00,$00,$00
        FCB   $0A,$AA,$00
        FCB   $0A,$AA,$00
        FCB   $0A,$AA,$00
        FCB   $0A,$AA,$00
        FCB   $0A,$AA,$00
        FCB   $0A,$AA,$00
        FCB   $0A,$AA,$00
        FCB   $00,$00,$00
PSD3E   EQU   *
        FCB   $00,$00,$00
        FCB   $00,$00,$00
        FCB   $00,$A0,$00
        FCB   $00,$A0,$00
        FCB   $00,$A0,$00
        FCB   $00,$A0,$00
        FCB   $00,$A0,$00
        FCB   $00,$00,$00
        FCB   $00,$00,$00
;*DIAMOND
PSD1F   EQU   *
        FCB   $00,$00,$90,$00,$00
        FCB   $00,$09,$99,$00,$00
        FCB   $00,$99,$99,$90,$00
        FCB   $09,$99,$99,$99,$00
        FCB   $99,$99,$99,$99,$90
        FCB   $09,$99,$99,$99,$00
        FCB   $00,$99,$99,$90,$00
        FCB   $00,$09,$99,$00,$00
        FCB   $00,$00,$90,$00,$00
PSD2F   EQU   *
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$A0,$00,$00
        FCB   $00,$0A,$AA,$00,$00
        FCB   $00,$AA,$AA,$A0,$00
        FCB   $0A,$AA,$AA,$AA,$00
        FCB   $00,$AA,$AA,$A0,$00
        FCB   $00,$0A,$AA,$00,$00
        FCB   $00,$00,$A0,$00,$00
        FCB   $00,$00,$00,$00,$00
PSD3F   EQU   *
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$A0,$00,$00
        FCB   $00,$0A,$AA,$00,$00
        FCB   $00,$00,$A0,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
;*
;*2084
;*
PSD1G   EQU   *
        FCB   $99,$99,$99,$99,$99,$99,$99,$99,$90
        FCB   $90,$00,$90,$00,$90,$00,$90,$90,$90
        FCB   $99,$90,$90,$90,$90,$90,$90,$90,$90
        FCB   $90,$00,$90,$90,$90,$00,$90,$00,$90
        FCB   $90,$99,$90,$90,$90,$90,$99,$90,$90
        FCB   $90,$00,$90,$00,$90,$00,$99,$90,$90
        FCB   $99,$99,$99,$99,$99,$99,$99,$99,$90
PSD2G   EQU   *
        FCB   $00,$00,$00,$00,$00,$00,$00,$00,$00
        FCB   $0A,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$00
        FCB   $0A,$A0,$A0,$A0,$A0,$A0,$A0,$AA,$00
        FCB   $0A,$00,$A0,$A0,$A0,$00,$00,$0A,$00
        FCB   $0A,$AA,$A0,$A0,$A0,$A0,$AA,$AA,$00
        FCB   $0A,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$00
        FCB   $00,$00,$00,$00,$00,$00,$00,$00,$00
PSD3G   EQU   *
        FCB   $00,$00,$00,$00,$00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00,$00,$00,$00,$00
        FCB   $00,$0A,$AA,$AA,$AA,$AA,$AA,$00,$00
        FCB   $00,$00,$00,$00,$00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00,$00,$00,$00,$00
;*SPIKE
PSD1H   EQU   *
        FCB   $00,$00,$90,$00,$00
        FCB   $09,$99,$99,$99,$00
        FCB   $09,$99,$09,$99,$00
        FCB   $09,$90,$00,$99,$00
        FCB   $99,$00,$00,$09,$90
        FCB   $09,$90,$00,$99,$00
        FCB   $09,$99,$09,$99,$00
        FCB   $09,$99,$99,$99,$00
        FCB   $00,$00,$90,$00,$00
PSD2H   EQU   *
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$A0,$00,$00
        FCB   $00,$AA,$AA,$A0,$00
        FCB   $00,$AA,$0A,$A0,$00
        FCB   $0A,$A0,$00,$AA,$00
        FCB   $00,$AA,$0A,$A0,$00
        FCB   $00,$AA,$AA,$A0,$00
        FCB   $00,$00,$A0,$00,$00
        FCB   $00,$00,$00,$00,$00
PSD3H   EQU   *
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$A0,$00,$00
        FCB   $00,$0A,$AA,$00,$00
        FCB   $00,$AA,$0A,$A0,$00
        FCB   $00,$0A,$AA,$00,$00
        FCB   $00,$00,$A0,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
;*SPIRAL DATA
PSD1I   EQU   *
        FCB   $99,$99,$99,$99,$90
        FCB   $90,$00,$00,$00,$90
        FCB   $90,$99,$99,$90,$90
        FCB   $90,$90,$00,$90,$90
        FCB   $90,$90,$90,$90,$90
        FCB   $90,$99,$90,$90,$90
        FCB   $90,$00,$00,$90,$90
        FCB   $99,$99,$99,$90,$90
        FCB   $00,$00,$00,$00,$90
        FCB   $09,$99,$99,$99,$90
PSD2I   EQU   *
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$AA,$AA,$A0,$00
        FCB   $00,$A0,$00,$A0,$00
        FCB   $A0,$A0,$A0,$A0,$00
        FCB   $A0,$AA,$A0,$A0,$00
        FCB   $A0,$00,$00,$A0,$00
        FCB   $AA,$AA,$AA,$A0,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
PSD3I   EQU   *
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$AA,$AA,$A0,$00
        FCB   $00,$A0,$00,$A0,$00
        FCB   $00,$A0,$A0,$A0,$00
        FCB   $00,$AA,$A0,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
;*
;*ROBOT PITCHERS
;*
RWDP1   FCB   5,13
        FDB   RWDD1
RWDP2   FCB   5,13
        FDB   RWDD2
RWDP3   FCB   5,13
        FDB   RWDD1
RWDP4   FCB   5,13
        FDB   RWDD3
RWDD1   FCB   $00,$01,$11,$00,$00
        FCB   $00,$66,$66,$60,$00
        FCB   $00,$CC,$CC,$C0,$00
        FCB   $00,$01,$11,$00,$00
        FCB   $11,$91,$11,$91,$10
        FCB   $51,$19,$99,$11,$50
        FCB   $50,$11,$91,$10,$50
        FCB   $50,$01,$11,$00,$50
        FCB   $00,$01,$11,$00,$00
        FCB   $00,$11,$01,$10,$00
        FCB   $00,$11,$01,$10,$00
        FCB   $05,$55,$05,$55,$00
        FCB   $00,$00,$00,$00,$00
RWDD2   FCB   $00,$01,$11,$00,$00
        FCB   $00,$66,$66,$60,$00
        FCB   $00,$CC,$CC,$C0,$00
        FCB   $00,$01,$11,$00,$00
        FCB   $11,$91,$11,$91,$10
        FCB   $51,$19,$99,$11,$50
        FCB   $50,$11,$91,$10,$50
        FCB   $50,$01,$11,$00,$50
        FCB   $00,$11,$11,$00,$00
        FCB   $00,$11,$01,$10,$00
        FCB   $05,$55,$01,$10,$00
        FCB   $00,$00,$01,$10,$00
        FCB   $00,$00,$05,$55,$00
RWDD3   FCB   $00,$01,$11,$00,$00
        FCB   $00,$66,$66,$60,$00
        FCB   $00,$CC,$CC,$C0,$00
        FCB   $00,$01,$11,$00,$00
        FCB   $11,$91,$11,$91,$10
        FCB   $51,$19,$99,$11,$50
        FCB   $50,$11,$91,$10,$50
        FCB   $50,$01,$11,$00,$50
        FCB   $00,$01,$11,$10,$00
        FCB   $00,$11,$01,$10,$00
        FCB   $00,$11,$05,$55,$00
        FCB   $00,$11,$00,$00,$00
        FCB   $05,$55,$00,$00,$00
;        END  