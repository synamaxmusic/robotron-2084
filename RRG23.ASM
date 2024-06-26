;        STTL  ROBOT GAME
;        OPT   NOL
;        LIB   "src/RRF.ASM"
;        OPT   LIS
        ORG   RGORG
        JMP   PLAYRV
        JMP   RNDXYV
        JMP   CKOBSV
        JMP   MANDSV
        JMP   START1
        JMP   START2
        JMP   TDISP
        FDB   MANLP1
        FDB   LLPIC
;*
;*SOUNDS
;*
PDSND   FCB   $EE,$02,$08,$11,$01,$20,$17,0 ;PLAYER DEATH
ST1SND  FCB   $F0,$01,$10,$28,0 ;START 1
ST2SND  FCB   $F0,$01,$10,$25,0 ;START 2
WVSND   FCB   $E0,$1D,$04,$0E,0 ;WAVE END
LASSND  FCB   $D0,$01,$08,1,0  ;LASER SOUND
;*
;*GAME START
;*
START2  LDA   #2
        BRA   SST0
STRTX   JMP   SUCIDE
START1  LDA   #1
SST0    LDY   #HCK2+1345
        TST   STATUS
        BPL   STRTX
        LDB   COINSL+1         ;CHECK FREEBY
        ANDB  #$F
        CMPB  #9
        BNE   SST00            ;NO FREE PLAY
        STA   CREDIT
SST00   CMPA  CREDIT
        BHI   STRTX            ;INSUFFICIENT FUNDS
        STA   PLRCNT           ;MAKE APPROPRIATE SOUND
        CLR   BUNITS
        CLR   CUNITS
        LDB   #8
        JSR   AUD              ;GAMES PLAYED
        LDU   #$D015
        NEGA 
        ADDA  #$9A
        ADDA  CREDIT
        DAA  
        STA   CREDIT
        LDX   #CREDST
        JSR   WCMOSA
        LDA   PLRCNT
        SUBA  #2
        LDD   #ST1SND
        BCS   SST01
        LDD   #ST2SND
SST01   JSR   SNDLD
        CLRA 
CKS11   ADDA  ,U               ;ADD NEXT BYTE
        LEAU  $8,U             ;NEXT ONE
        CMPU  #$EAB1
        BLO   CKS11
        STA   -1345,Y          ;STORE
        LDA   #$7F
        STA   STATUS
        JSR   SCRCLR
        LDX   #PLDATA
SST1    CLR   ,X+
        CMPX  #PLDEND
        BNE   SST1
        LDX   #NSHIP           ;GET # OF SHIPS
        JSR   RCMOSA
        JSR   NEWBCH           ;IN BINARY PLEASE
        STA   ZP1LAS
        LDA   #1
        STA   CURPLR
        LDA   #1
        STA   ZP1WAV
        STA   PCFLG
        LDX   #REPLAY
        JSR   RCMOSA
        CLRB 
        LSRA 
        RORB 
        LSRA 
        RORB 
        LSRA 
        RORB 
        LSRA 
        RORB 
        STD   REPLA
        STD   ZP1RP+1
        JSR   GETWV
        LDX   #PLDATA
SSTRAN  LDA   ,X+
        STA   PLDLEN-1,X
        CMPX  #ZP1END
        BNE   SSTRAN
        LDA   PLRCNT
        DECA 
        BNE   PLSTRT
        CLR   ZP2LAS           ;NO PLAYER 2
PLSTRT  LDA   #$7F
        STA   STATUS
        JSR   PLINDX
        DEC   PLAS,X
        JSR   SCRCLR
        JSR   GNCIDE
        LDX   [ACTIVE]         ;REINIT PROC STRUCT IF NO COINS
        BNE   PLS0
        JSR   PINIT
        MAKP  PLS0
        JMP   EXECV
PLS0    JSR   CRINIT
        JSR   EXINIT
        JSR   OINIT
        JSR   GTWCOL           ;GET WALL COLOR
        JSR   P1SW
        LDA   PIA3             ;COCKTAIL??
        BPL   PLS000           ;NO
        LDA   CURPLR           ;PLAYER 2?
        DECA 
        BEQ   PLS000           ;NO
        JSR   P2SW
PLS000  JSR   TDISP
        JSR   COLST
        CLR   RIPFLG
        LDA   PCFLG
        BNE   PLS00C
        JSR   WVMESS
        BRA   PLS0A            ;NO DEATH.. NO MESSIE POOH
PLS00C  LDD   ZP1SCR+1
        BNE   PLS0C            ;NOT GAME START
        LDA   #$11
        STA   TEXCOL
        LDA   #113
        JSR   WRD5V            ;COPYRIGHT MESSAGE
        BRA   PLS0D
PLS0C   JSR   WVMESS
PLS0D   CLR   PCFLG
        LDA   PLRCNT
        DECA 
        BEQ   PLS0A            ;1 PLAYER GAME
        LDA   PSTCOL
        STA   TEXCOL
        LDB   CURPLR
        LDA   #103
        JSR   WRD7V
        NAP   115,PLS0B        ;PLAYER UP MESSAGE
PLS0B   CLR   TEXCOL
        LDB   CURPLR
        LDA   #103
        JSR   WRD7V            ;ERASE MESSAGE
PLS0A   JSR   PLRES
        JSR   PLINIT
        CLR   PCRAM+6
        CLR   CRAM+6
        JSR   HULKST
        JSR   BRNST
        JSR   TANKST
        JSR   HUMST
        JSR   PSINIT
        JSR   RINIT
        JSR   ROBOFF
        LDA   #8
        STA   PSTREF           ;DOUBLE REFRESH RATE
        MAKP  PSTRPC           ;REFRESH POSTS
        JSR   PSTON
        JSR   CRINIT
        JSR   CIRCST
        JSR   SQST
        LDA   #$19
        STA   STATUS
        LDA   BRNCNT           ;BRAIN WAVE???
        BEQ   PLS00            ;NO
        MAKP  TRANST           ;TRANSPORT EM
        NAP   150,PLS1
PLS00   JMP   APPEAR
PLS1    JSR   PAPPR            ;PLAYER APPEAR
        JSR   PSTON            ;ON POSTS
        NAP   06,PLS1A
PLS1A   JSR   PDAPPR           ;DIAG PLAYER APPEAR
        NAP   4,PLS2
PLS2    JSR   ROBON
        MAKP  LSPROC
        MAKP  COLCHK
        CLR   STATUS
        NAP   12,PLS3
PLS3    JSR   ROBON            ;TURN THEM ON
        JSR   PSTON
        NAP   10,PLS4
PLS4    JSR   ROBON
        JSR   PSTON
        LDA   #4
        STA   PSTREF           ;STD REFRESH RATE
        CLR   TEXCOL           ;OFF CPM
        LDA   #113
        JSR   WRD5V
        JSR   WVMESS           ;ON WAVE #
        LDX   #$20FB           ;COPIERS TAKE NOTE:
        LDU   #HIDTAB          ;HIDDEN COPY RIGHT HERE
HIDLP   LDA   ,U+
        EORA  #$5A
        BEQ   HIDEND
        JSR   PR35V
        BRA   HIDLP
HIDEND  JMP   GEXEC

        FCC   " (C) 1982 WILLIAMS ELECTRONICS INC. "
;*
;*MAKE YOUR ROBOTS APPEAR
;*PD=CNT,PD2=PTR,PD4=REFPTR,PD6=REF LIM
;*
APPEAR  LDU   CRPROC
        CLR   PD,U
        LDX   #RPTR
        STX   PD2,U
        LDX   RPTR
        STX   PD4,U
        STX   PD6,U
APL     LDA   #1
        PSHS  A                ;1/FRAME
APL1    LDX   PD2,U            ;GET INDEX
        LDX   ,X
        BEQ   AP3              ;ALL DONE
        JSR   APCENT           ;GET CENTER
        LDA   PD,U
        ANDA  #3
        CMPA  #3
        BNE   AP1
        JSR   HAPST
        BRA   AP2
AP1     JSR   APST
AP2     STX   PD2,U
AP3     INC   PD,U
        LDA   PD,U
        CMPA  #32
        BLS   AP4
        LDY   PD6,U            ;EXPAND REFRESH LIST
        BEQ   APX1
        LDY   ,Y
        BEQ   APX1             ;DONE
        STY   PD6,U
AP4     DEC   ,S
        BNE   APL1
        PULS  A
        BSR   APREF
        NAP   1,APL
APX1    PULS  A
        NAP   2,APX2           ;LET EVERYONE FINISH
APX2    BSR   ROBON            ;TURN EVERYONE ON
        NAP   10,PLS1
;*
;*REFRESH APEAREES
;*
APREF   PSHS  X
        LDA   #4               ;4 PER FRAME
        STA   XTEMP
        LDX   PD4,U
APRL    CMPX  PD6,U
        BNE   APR1
        LDX   #RPTR
        BRA   APRX
APR1    JSR   DMAON
APRX    LDX   ,X
        DEC   XTEMP
        BNE   APRL
        STX   PD4,U
        PULS  X,PC
;*
;*ON ROBOTS
;*
ROBON   LDX   RPTR
        BEQ   ROBONX
ROBON1  JSR   DMAON
        LDX   ,X
        BNE   ROBON1
ROBONX  RTS  
;*
;*ON POSTS
;*
PSTON   LDX   PPTR
        BEQ   PSTONX
PSTON1  LDA   PSTCOL
        JSR   OPON
        STX   [OBJID,X]
PSTONL  LDX   ,X
        BNE   PSTON1
PSTONX  RTS  
;*
;*OFF POSTS
;*
PSTOFF  LDX   PPTR
        BRA   ROBOF0
;*
;*OFF ROBOTS
;*
ROBOFF  LDX   RPTR
ROBOF0  BEQ   ROBOFX
ROBOF1  LDD   OBJX,X
        LDY   OPICT,X
        JSR   PCTOFF
        LDX   ,X
        BNE   ROBOF1
ROBOFX  RTS  
;*
;*APPEAR CENTER CALCULATE
;*X=OBJ, STORES CENT-CENTMP
APCENT  PSHS  D,U
        LDU   OPICT,X          ;X CENTER
        LDB   OBJW,U
        LDA   OBJX,X
        ASLA 
        BCC   APC1
        LDA   #$FF
APC1    MUL  
        ADDA  OBJX,X
        STA   CENTMP
        LDB   OBJH,U
        LDA   OBJY,X
        MUL  
        ADDA  OBJY,X
        STA   CENTMP+1
        PULS  D,U,PC
;*
;*PLAYER DIAGONAL APPEAR
;*
PDAPPR  LDX   #PLOBJ
        LDY   OPICT,X
        LDA   OBJH,Y
        PSHS  A
DPAPP1  LDA   ,S
        ADDA  PX+1
        DECA 
        STA   CENTMP+1
        CLRA 
        JSR   DAPST
        COMA 
        JSR   DAPST
        LDA   ,S
        SUBA  #3
        STA   ,S
        BPL   DPAPP1
        PULS  A,PC
;*
;*SUPER PLAYER APPEAR
;*
PAPPR   LDX   #PLOBJ
        LDY   OPICT,X
        LDA   OBJH,Y
        PSHS  A
PAPPR1  LDA   ,S
        ADDA  PX+1
        DECA 
        STA   CENTMP+1
        JSR   APST             ;VERTS
        DEC   ,S
        BNE   PAPPR1
        LDA   OBJW,Y
        STA   ,S
PAPPR2  LDA   ,S
        ADDA  PX
        DECA 
        STA   CENTMP
        JSR   HAPST
        DEC   ,S
        BNE   PAPPR2
        PULS  A,PC
;*
;*GET WALL COLOR
;*
GTWCOL  JSR   PLINDX
        LDU   #WCTAB
        LDA   PWAV,X
        DECA 
GTWL    CMPA  #9
        BLS   GTW1
        SUBA  #10
        BRA   GTWL
GTW1    LEAU  A,U
        LDA   ,U
        STA   WALCOL
        LDA   10,U
        STA   PSTCOL
        LDB   20,U
        LDX   PSTP1
        ABX  
        STX   PSTANI           ;POST IMAGE
        LDA   30,U
        STA   LASCOL
        RTS  
;*WAVE COLOR TABLES
WCTAB   EQU   *
        FCB   $22,$55,$11,$EE,$77,$33,$44,$88,$00,$CC
;*POST COLOR TABLES
        FCB   $FF,$EE,$BB,$DD,$EE,$FF,$11,$BB,$DD,$AA
;*POST IMAGES
        FCB   $00,$10,$20,$30,$40,$50,$70,$80,$00,$60
;*LASER COLOR
        FCB   $99,$00,$99,$66,$99,$99,$99,$11,$AA,$99
;*CHECK END OF WAVE
WVCHEK  LDA   ROBCNT
        ADDA  CIRCNT
        ADDA  ENFCNT
        ADDA  BRNCNT
        ADDA  TNKCNT
        ADDA  SQCNT
        RTS  
;*
;*GAME EXEC
;*
GEXEC   LDU   CRPROC
        LDA   #18
        STA   PD,U
        CLR   SCRFLG
GEXEC0  BSR   WVCHEK
        BNE   GEXEC1
        JSR   PLINDX
GEXX    INC   PWAV,X
        BNE   GEXX1
        INC   PWAV,X
GEXX1   INC   PLAS,X
        LDD   #WVSND
        JSR   SNDLD
        JSR   GETWV
        JSR   GNCIDE
        LDA   #$7F
        STA   STATUS           ;TURN EVERYTHING OFF
        JSR   SCRCLR
        JSR   RMST             ;DO MARQUEE EFFECT
        JMP   PLSTRT
GEXEC1  LDA   PIA2
        CMPA  #$58
        BNE   NORIPP
        JSR   RIPV
NORIPP  DEC   PD,U
        BNE   GEXECX
        LDA   #15
        STA   PD,U
        LDA   ROBCNT           ;TOO MANY ROBOTS
        CMPA  #30
        BHS   GEXECX
        LDD   #$FFFE
        TST   SCRFLG
        BNE   GEXEC2
        LDD   #$FEFC           ;BONE HIM FOR STALLING
GEXEC2  ADDA  RMXSPD
        CLR   SCRFLG
        CMPA  #1
        BGE   GEXEC3
        LDA   #1
GEXEC3  STA   RMXSPD
        ADDB  ROBSPD
        CMPB  RMXSPD
        BGE   GEXEC4
        LDB   RMXSPD
GEXEC4  STB   ROBSPD
GEXECX  LDA   GAMTIM
        INCA 
        CMPA  #150             ;1/4 SEC. CTS
        BLO   GEXX2
        LDB   #6               ;HIT THE TIMER
        JSR   AUD1
        CLRA 
GEXX2   STA   GAMTIM
        NAP   15,GEXEC0
;*
;*PLAYER RESTORE
;*
PLRES   JSR   PLINDX
        LEAX  PENEMY,X
        LDU   #ELIST
PLRES1  LDA   ,X+
        STA   ,U+
        CMPU  #ELEND
        BNE   PLRES1
        JSR   PLINDX
        LDA   PWAV,X
        CMPA  #4
        BHI   PLRESX           ;NO BOZO
        LDB   PLAS,X
        STD   XTEMP            ;SAVE WAVE,SHIPS
        TSTB 
        BEQ   BOZO             ;LAST SHIP
        CMPA  #2
        BHI   PLRESX           ;NOT WAVE 1,2
        LDX   #NSHIP
        JSR   RCMOSA
        JSR   NEWBCH
        DECA 
        CMPA  XTEMP+1
        BLS   PLRESX           ;NOT DOWN SHIPS
BOZO    LDA   XTEMP
        LDX   #BOZOTB-4
        ASLA 
        ASLA 
        LEAX  A,X
        LDD   ,X++
        STA   CDPTIM
        STB   ENSTIM
        LDD   ,X
        STA   ROBSPD
        STB   RMXSPD
PLRESX  RTS  
;*
;*BOZO TABLE: FOR ALL YOU BOZOS OUT THERE
;*
BOZOTB  EQU   *
        FCB   38,96,30,15      ;WAVE 1
        FCB   38,96,25,12      ;2
        FCB   36,48,20,10      ;3
        FCB   30,30,15,7       ;4
;*
;*SAVE PLAYER STATE
;*
PLSAV   JSR   PLINDX
        LEAX  PENEMY,X
        LDU   #ELIST
PLSAV1  LDA   ,U+
        STA   ,X+
        CMPU  #ELEND
        BNE   PLSAV1
        RTS  
;*
;*GET NEXT WAVE
;*
GETWV   LDX   #GA1             ;GET DIFFICULTY
        JSR   RCMOSB
        JSR   BCDBIN
        JSR   PLINDX
        CMPB  #5               ;EASY SET UP??
        BHS   GTWV0X           ;NO
        LDA   PWAV,X
        CMPA  #14              ;WAVE 14 OR GREATER
        BLO   GTWV01           ;NO
        LDB   #5
GTWV01  CMPA  #5               ;WAVE 5 OR GT?
        BLO   GTWV0X           ;NO
        LDA   PLAS,X           ;4 OR MORE LASERS LEFT?
        CMPA  #3
        BLO   GTWV0X           ;NO
        LDB   #5               ;YES SCREW HIM
GTWV0X  SUBB  #5
        STB   XTEMP+1          ;SAVE SIGN
        BPL   GETWV0
        NEGB 
GETWV0  STB   XTEMP            ;MAGNITUDE
        LDB   PWAV,X
        LDU   #WVTAB+2
        LEAX  PENEMY,X
GETWV1  CMPB  #40
        BLS   GETWV2
        SUBB  #20
        BRA   GETWV1
GETWV2  EQU   *
        CMPU  #WVCNT
        BLO   GETWV3
        LEAU  -3,U             ;NO MAX/MINS
        LDA   B,U
        BRA   GETWV9
GETWV3  LDA   B,U
        PSHS  D
        LDB   -2,U             ;GET FRACTION
        ANDB  #$1F
        LDA   XTEMP
        MUL                    ; BY MAGNITUDE
        PULS  A
        MUL  
        ADCA  #0               ;ROUND
        LDB   XTEMP+1
        EORB  -2,U             ;PLUS OR MINUS ????
        PULS  B
        BPL   GETWV4
        NEGA 
        BEQ   GETWV4           ;ZERO CASE
        ADDA  B,U
        BCS   GETWV5           ;O.K.
        BRA   GETWV6           ;UNDERFLOW GET MIN
GETWV4  ADDA  B,U
        BCS   GETWV8           ;OVERFLOW GET MAX
GETWV5  CMPA  -1,U             ;CHECK MIN
        BHS   GETWV7
GETWV6  LDA   -1,U
GETWV7  CMPA  ,U
        BLS   GETWV9
GETWV8  LDA   ,U
GETWV9  STA   ,X+
        LEAU  43,U
        CMPU  #WVTEND-1
        BLO   GETWV2
        CLR   ,X+              ;GET TANK COUNT
        RTS  
HIDTAB  FCB   $01,$19,$06,$7A,$6B,$63,$62,$68,$7A,$0D,$13,$16,$16,$13,$1B
        FCB   $17,$09,$7A,$1F,$16,$1F,$19,$67,$7A,$13,$14,$19,$67,$5A
WVTAB   EQU   *
        FCB   $8E,10,20        ;SIGN/DELTA,MIN,MAX
        FCB   20,15,15,15,15,15,15,15,15,15,14,14,14,14,14,13,13,13,13,13 ;ROBSPD
        FCB   14,14,14,14,14,14,13,13,13,13,13,13,12,12,12,12,12,12,15,12
        FCB   $8E,03,10
        FCB   09,07,06,05,05,05,05,04,04,04,04,04,04,04,04,04,04,04,04,04 ;RMXSPD
        FCB   04,04,04,04,04,04,03,03,04,03,03,03,03,03,03,03,03,03,04,03
        FCB   $0E,$08,12
        FCB   10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10 ;ENFNUM
        FCB   11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11
        FCB   $8E,13,40
        FCB   30,28,26,24,22,20,18,18,16,14,14,14,14,14,14,14,14,14,14,14 ;ENSTIM
        FCB   15,15,15,15,15,15,15,15,15,14,14,14,14,14,14,14,14,14,14,14
        FCB   $8E,12,40
        FCB   30,28,26,24,30,20,18,16,18,25,12,12,12,25,25,12,12,12,18,20 ;CDPTIM
        FCB   14,14,14,14,14,25,14,14,18,25,12,12,12,12,25,12,12,12,18,20
        FCB   $8E,05,09
        FCB   08,08,07,07,07,07,07,06,06,06,06,05,05,05,05,05,05,05,05,05 ;HLKSPD
        FCB   05,05,05,05,05,05,05,05,05,05,05,05,05,05,05,05,05,05,05,05
        FCB   $8E,25,80
        FCB   64,64,64,64,64,40,40,38,38,38,38,38,38,38,38,38,36,36,36,36 ;BSHTIM
        FCB   32,32,32,32,32,32,32,30,30,30,30,30,25,25,25,25,25,25,25,25
        FCB   $8E,6,10
        FCB   08,08,08,08,08,07,07,07,07,07,07,07,07,07,07,06,06,06,06,06 ;BRNSPD
        FCB   06,06,06,06,06,06,06,06,06,06,06,06,06,06,06,06,06,06,06,06
        FCB   $8E,20,40
        FCB   32,32,32,32,32,32,32,30,30,30,30,30,30,28,28,28,28,28,28,28 ;THKSHT
        FCB   30,30,30,30,30,30,28,28,28,28,28,26,26,26,26,26,24,24,24,24
        FCB   $0E,$A0,$FF
        FDB   $B0B0,$B0B0,$B0B0,$B0B0,$B0B0,$B0B0,$B0B0,$B0B0,$B0B0,$B0B0 ;SHLSPD
        FDB   $B8B8,$B8B8,$B8B8,$B8B8,$B8B8,$C0C0,$C0C0,$C0C0,$C0C0,$C0C0
        FCB   $8E,$0C,$30
        FDB   $1010,$1010,$1010,$1010,$1010,$1010,$1010,$0F0F,$0F0F,$0F0F ;TDPTIM
        FDB   $0E0E,$0E0E,$0E0E,$0E0E,$0E0E,$0E0E,$0E0E,$0E0E,$0E0E,$0E0E
        FCB   $0E,$28,$44
        FDB   $3232,$3232,$3232,$3232,$3232,$3232,$3838,$3838,$3838,$3838 ;SQSPD
        FDB   $3838,$3838,$3838,$3838,$3C3C,$3C3C,$3C3C,$3C3C,$3C3C,$3C3C
WVCNT   EQU   *
        FCB   15,17,22,34,20,32,00,35,60,25,35,00,35,27,25,35,00,35,70,25 ;ROBCNT
        FCB   35,00,35,00,25,35,00,35,75,25,35,00,35,30,27,35,00,35,80,30
        FCB   05,15,25,25,20,25,00,25,00,20,25,00,25,05,20,25,00,25,00,20 ;PSTCNT
        FCB   25,00,25,00,20,25,00,25,00,20,25,00,25,00,15,25,00,25,00,15
        FCB   01,01,02,02,15,03,04,03,03,00,03,03,03,05,00,03,03,03,03,08 ;MOMCNT
        FCB   03,03,03,03,25,03,03,03,03,00,03,03,03,03,00,03,03,03,03,10
        FCB   01,01,02,02,00,03,04,03,03,22,03,03,03,05,00,03,03,03,03,08 ;DADCNT
        FCB   03,03,03,03,00,03,03,03,03,25,03,03,03,03,00,03,03,03,03,10
        FCB   00,01,02,02,01,03,04,03,03,00,03,03,03,05,22,03,03,03,03,08 ;KIDCNT
        FCB   03,03,03,03,01,03,03,03,03,00,03,03,03,03,25,03,03,03,03,10
        FCB   00,05,06,07,00,07,12,08,04,00,08,13,08,20,02,03,14,08,03,02 ;HLKCNT
        FCB   08,15,08,13,01,08,16,08,04,01,08,16,08,25,02,08,16,08,06,02
        FCB   00,00,00,00,15,00,00,00,00,20,00,00,00,00,20,00,00,00,00,20 ;BRNCNT
        FCB   00,00,00,00,21,00,00,00,00,22,00,00,00,00,23,00,00,00,00,25
        FCB   00,01,03,04,01,04,00,05,05,01,05,00,05,02,01,05,00,05,05,02 ;CIRCNT
        FCB   05,00,05,06,01,05,00,05,05,01,05,00,05,02,01,05,00,05,05,01
        FCB   00,00,00,00,00,00,10,00,00,00,00,12,00,00,00,00,12,00,00,00 ;SQCNT
        FCB   00,12,00,07,00,00,12,01,01,01,01,13,01,02,02,02,14,02,01,01
WVTEND  EQU   *
;*
;*PLAYER INITIALIZE
;*
PLINIT  LDX   #PLOBJ
        LDD   #MANDP1
        STD   OPICT,X
        STD   OLDPIC,X
        CLR   PLAIMC           ;ANI COUNT+NUM
        CLR   PLAIMN
        LDD   #PISD
        STD   PLAIMB           ;ANI BASE
        LDD   #PCOORD
        STD   OBJX,X
        STA   OX16,X
        CLR   OX16+1,X
        STB   OY16,X
        CLR   OY16+1,X
        CLR   LCNT
        CLR   PCFLG
        CLR   SAVCNT           ;MAN SAVED COUNTER
        CLR   BCMCNT
        CLR   SPKCNT
        CLR   BRNFLG
        CLR   ENFCNT
        LDA   #2
        STA   TNKSPD
        CLR   SHLCNT
        RTS  
;*
;*PLAYER MOTION+OUTPUT
;*
PLAYRV  LDA   STATUS
        BITA  #$01
        BEQ   PL00
        RTS  
PL00    TSTA 
        BPL   PL01
        LDA   ATRSW2           ;FONY SWITCH
        BRA   PL02
PL01    LDA   PIA2
PL02    LDX   #PLOBJ
        LDU   #PITAB
        ANDA  #$F
        ASLA 
        ASLA 
        LEAU  A,U
        LDD   ,U               ;GET YOUR TABLE ENTRY FOR SWITCH POSITION
        ADDB  PY16
        CMPB  #YMIN
        BLO   PL1
        CMPB  #YMAX-11
        BHI   PL1
        STB   PY16
PL1     CLRB 
        ASRA 
        RORB 
        ADDD  PX16
        CMPA  #XMIN
        BLO   PL2
        CMPA  #XMAX-3
        BHI   PL2
        STD   PX16
PL2     LDD   2,U
        BEQ   PLXX             ;NO IMAGE CHANGE
        CMPD  PLAIMB           ;BASE CHANGE?
        BEQ   PL3
        STD   PLAIMB
        CLR   PLAIMN
        CLR   PLAIMC
PL3     LDB   PLAIMC           ;COUNT READY?
        BNE   PL10
        LDU   PLAIMB
        LDA   PLAIMN
        LDB   A,U
        BNE   PL4
        CLR   PLAIMN           ;END OF SEQUENCE
        LDB   ,U
PL4     INC   PLAIMN
        DECB 
        ASLB 
        ASLB 
        CLRA 
        ADDD  #MANLP1
        STD   PPICT
PL10    LDA   PLAIMC
        INCA 
        CMPA  #2
        BLO   PL11
        CLRA 
PL11    STA   PLAIMC
PLXX    RTS  
;*
;*PLAYER IMAGE TABLE
;*DX,DY,IMAGE SEQ
;*B0=U,B1=D,B2=L,B3=R
PITAB   FDB   0,0              ;0000
        FDB   $00FF,PISU       ;0001 U
        FDB   $0001,PISD       ;0010 D
        FDB   $0,0             ;0011
        FDB   $FF00,PISL       ;0100 L
        FDB   $FFFF,PISL       ;0101 U+L
        FDB   $FF01,PISL       ;0110 D+L
        FDB   0,0              ;0111
        FDB   $0100,PISR       ;1000 R
        FDB   $01FF,PISR       ;1001 U+R
        FDB   $0101,PISR       ;1010 D+R
        FDB   0,0              ;1011
        FDB   0,0              ;1100
        FDB   0,0              ;1101
        FDB   0,0              ;1110
        FDB   0,0              ;1111
;*
;*PLAYER ANIMATION TABLE
;*
PISL    FCB   1,2,1,3,0
PISR    FCB   4,5,4,6,0
PISD    FCB   7,8,7,9,0
PISU    FCB   10,11,10,12,0
;*
;*CHECK FOR OBSTACLE
;*CARDBOARD BOX
;*D= SCREEN ADDR X,Y
;*X=OBJ,U=LIST TO CHECK AGAINST
;*RET NE IF BLOCKED, EQ OTHERWISE
CKOBSV  PSHS  U,D
        PSHS  D
        ADDD  [OPICT,X]
        PSHS  D
        BRA   CKOBLP
CKOB1   LDD   OBJX,U
        CMPA  ,S
        BHS   CKOBLP
        CMPB  1,S
        BHS   CKOBLP
        ADDD  [OPICT,U]
        CMPA  2,S
        BLS   CKOBLP
        CMPB  3,S
        BLS   CKOBLP
        PSHS  U                ;IS IT ITSELF??
        CMPX  ,S++
        BNE   CKOBX            ;NOPE
CKOBLP  LDU   ,U
        BNE   CKOB1
CKOBX   LEAS  4,S              ;CLEAN UP YOUR MESS
        PULS  U,D,PC
;*
;*CHECK PLAYER COLLISION
;*
COLCHK  LDA   #1
        STA   PCFLG
        LDD   PX               ;PLAYER
        LDU   POLDPC
        LDX   #RPTR            ;ROBOTS
        JSR   COL0
        BNE   PLEND            ;DIE
        LDD   PX
        LDU   POLDPC
        LDX   #PPTR            ;POSTS (FATAL OBSTACLES)
        JSR   COL0
        BNE   PLEND
        LDD   PX
        LDU   POLDPC
        LDX   #OPTR            ;MOTION OBJECTS
        JSR   COL0
        BNE   PLEND
        LDD   PX               ;HUMANS
        LDU   POLDPC
        LDX   #HPTR
        JSR   COL0
        CLR   PCFLG
        NAP   1,COLCHK
;*
;*PLAYER DEAD
;*
PLEND   LDD   #PDSND
        JSR   SNDLD
        LDA   #$1B
        STA   STATUS
        JSR   GNCIDE
        LDB   #7
        JSR   AUD1             ;MEN PLAYED
        JSR   COLST            ;START YOUR COLORS
        JSR   PDEATH           ;GO FOR IT...
        JSR   PLINDX
        LDA   ZP1LAS
        ORA   ZP2LAS
        BNE   PLEND1
        LDA   #$FF
        STA   STATUS
        LDD   #$1C0A           ;GAME OVER MESSAGE
        LDX   #$3C7E
        JSR   BLKCLR
        LDA   #40
        LDB   #$AA
        STB   TEXCOL
        JSR   WRD7V
        NAP   120,ENDPRC
PLEND1  JSR   PLINDX
        LDA   RMXSPD-ELIST+PENEMY,X ;RESTORE MAX SPEED
        STA   RMXSPD
        CMPA  ROBSPD
        BLS   PLEND2
        STA   ROBSPD
PLEND2  CLRA 
        LDB   ENFCNT           ;CONVERT LEFTOVER ENFORCERS INTO CIRCLES
        BEQ   PLE2C
PLE0A   SUBB  #4
        BMI   PLE1A
        INCA 
        BRA   PLE0A
PLE1A   TSTA 
        BNE   PLE2A
        TST   CIRCNT
        BNE   PLE2A
        INCA 
PLE2A   ADDA  CIRCNT
        CMPA  CIRCNT-ELIST+PENEMY,X ;NO MORE THAN YOU STARTED WITH
        BLS   PLE2B
        LDA   CIRCNT-ELIST+PENEMY,X
PLE2B   STA   CIRCNT
PLE2C   JSR   PLSAV
PLEND3  JSR   PLINDX
        LDB   PLAS,X
        BNE   PLE1B
        LDD   #$1C20           ;PLAYER N GAME OVER MESSAGE
        LDX   #$3C77
        JSR   BLKCLR
        LDA   #75
        LDB   #$AA
        STB   TEXCOL
        LDB   CURPLR
        JSR   WRD7V
        NAP   $60,PLE1B
PLE1B   LDA   CURPLR
PLE1    EORA  #3
        JSR   PLDX
        LDB   PLAS,X
        BEQ   PLE1
        STA   CURPLR
        JMP   PLSTRT
;*
;*RANDOM X,Y->D ON PLAYFIELD FOR OBJECT X
;*
RNDXYV  EQU   *
        LDD   [OPICT,X]
        PSHS  D
        LDA   #XMAX-XMIN
        SUBA  ,S+
        JSR   RANDU
        ADDA  #XMIN-1
        TFR   A,B
        LDA   #YMAX-YMIN
        SUBA  ,S+
        JSR   RANDU
        ADDA  #YMIN-1
        EXG   A,B
        RTS  
;*LASER START
LSPROC  CLR   PD,U             ;PREV STATE
        CLR   PD1,U            ;TIMECOUNT
LSPLP   LDA   STATUS
        BPL   LSP0
        LDD   ATRSW2
        BRA   LSP00
LSP0    LDA   PIA2
        LDB   PIA3
LSP00   LSRB 
        RORA 
        LSRB 
        RORA 
        ANDA  #$F0
        LDB   PD,U
        STA   PD,U
        CMPB  PD,U
        BNE   LSPX
        INC   PD1,U
        LDB   PD1,U
        CMPB  #2
        BEQ   LSP1
        ANDB  #$7
        BNE   LSPNAP
LSP1    LDB   LCNT
        CMPB  #4
        BHS   LSPX1
        TST   FREE
        BEQ   LSPNAP           ;NO MORE PROCS
        LSRA 
        LSRA 
        PSHS  A
        LSRA 
        ADDA  ,S+
        LDY   #LTAB
        LEAY  A,Y
        CMPA  #LTEND-LTAB
        BHS   LSPNAP           ;DUD
        LDX   ,Y
        BEQ   LSPNAP           ;DUD
        CLRA 
        JSR   MKPROC
        TFR   X,U
        JSR   GETOBJ
        STX   PD,U
        LDD   4,Y
        ADDD  #LLPIC
        STD   OPICT,X
        STD   OLDPIC,X
        LDD   PX
        ADDA  2,Y
        STA   OX16,X
        ADDB  3,Y
        STB   OY16,X
        INC   LCNT
        LDD   #LASSND
        JSR   SNDLD
        BRA   LSPNAP
LSPX    CLR   PD1,U
        BRA   LSPNAP
LSPX1   DEC   PD1,U
LSPNAP  NAP   1,LSPLP
;*LASER TABLE: ROUTINE,XY OFFSET,OBJECT
LTAB    EQU   *
        FDB   0,0,0            ;0000 CASE
        FDB   ULASR,$02FF,4    ;0001
        FDB   DLASR,$0204,4    ;0010
        FDB   0,0,0            ;0011
        FDB   LLASR,$0004,0    ;0100
        FDB   ULLASR,$0000,12  ;0101
        FDB   DLLASR,$0004,8   ;0110
        FDB   0,0,0            ;0111
        FDB   RLASR,$0204,0    ;1000
        FDB   URLASR,$0200,8   ;1001
        FDB   DRLASR,$0204,12  ;1010
LTEND   EQU   *
;*RT. LASER
RLASR   LDX   PD,U
        LDA   OX16,X
        ADDA  #3
        CMPA  #XMAX-2
        BHI   RLDIE
        STA   OX16,X
        LDD   #$0100
        JSR   LASOUT
        NAP   1,RLASR
;*LEFT LASER
LLASR   LDX   PD,U
        LDA   OX16,X
        SUBA  #3
        CMPA  #XMIN
        BLO   LLDIE
        STA   OX16,X
        LDD   #$FF00
        JSR   LASOUT
        NAP   1,LLASR
;*UP LASER
ULASR   LDX   PD,U
        LDA   OY16,X
        ADDA  #-6
        CMPA  #YMIN
        BLO   ULDIE
        STA   OY16,X
        LDD   #$00FF
        JSR   LASOUT
        NAP   1,ULASR
;*DOWN LASER
DLASR   LDX   PD,U
        LDA   OY16,X
        ADDA  #6
        CMPA  #YMAX-5
        BHI   DLDIE
        STA   OY16,X
        LDD   #$0001
        JSR   LASOUT
        NAP   1,DLASR
;*
;*LASER OUT OF BOUNDS
;*
RLDIE   LDA   #XMAX+1          ;RT LASER DIE
        BRA   LLDIE1
LLDIE   LDA   #XMIN-1          ;LFT LASER DIE
LLDIE1  LDB   OY16,X
        BRA   LASDIH
ULDIE   LDB   #YMIN-1
        BRA   DLDIE1
DLDIE   LDB   #YMAX+1
DLDIE1  LDA   OX16,X           ;GLOW POINT
        BRA   LASDIV
;*
;*LASER DIE HORIZONTAL
;*
LASDIH  STD   PD2,U
        JSR   LASOFF
        LDX   PD2,U
        LDA   LASCOL
        LDB   LASCOL
        STD   -1,X
        STA   1,X
        NAP   2,LDH1
LDH1    LDA   WALCOL
        LDX   PD2,U
        STA   -1,X
        STA   1,X
        NAP   1,LDH2
LDH2    LDA   WALCOL
        STA   [PD2,U]
        JMP   SUCIDE
;*
;*LASER DIE VERTICAL
;*
LASDIV  CMPB  #YMAX
        BHS   LDV0
        LDB   #YMIN-2
LDV0    CMPA  #XMIN-1
        BHI   LDV00
        INCA 
LDV00   STD   PD2,U
        JSR   LASOFF
        LDA   LASCOL
        LDB   LASCOL
        LDX   PD2,U
        STD   ,X
        LDA   WALCOL
        ANDA  #$F0
        PSHS  A
        LDA   LASCOL
        ANDA  #$0F
        ADDA  ,S+
        TFR   A,B
        STD   -$100,X
        NAP   2,LDV1
LDV1    LDX   PD2,U
        LDA   WALCOL
        LDB   WALCOL
        STD   -$100,X
        ANDA  #$0F
        ANDB  #$0F
        PSHS  D
        LDA   LASCOL
        LDB   LASCOL
        ANDA  #$F0
        ANDB  #$F0
        ADDD  ,S++
        STD   ,X
        NAP   1,LDV2
LDV2    LDA   WALCOL
        LDB   WALCOL
        STD   [PD2,U]
        JMP   SUCIDE           ;DONE!!!
LASDH   JMP   LASDIH
LASDV   BRA   LASDIV
;*
;*LASER DIE SCAN
;*FIND WHERE WE RAN OFF
LDSCAN  STB   XTEMP+1
        CLRB 
        ASRA 
        RORB 
        STD   XTEMP2
        TFR   Y,D
        ADDA  OX16,X
        ADDB  OY16,X
        STA   OX16,X
        STB   OY16,X
LDSCXL  LDD   XTEMP2
        ADDD  OX16,X
        STD   OX16,X
        LDB   OY16,X
        ADDB  XTEMP+1
        STB   OY16,X
        CMPB  #YMAX
        BHI   LASDV
        CMPB  #YMIN
        BLO   LASDV
        CMPA  #XMAX
        BHI   LASDH
        CMPA  #XMIN
        BLO   LASDH
        BRA   LDSCXL
;*
;*DOWN LEFT DIE
DLLDIE  LDY   #$0005
        LDD   #$FF01
        BRA   LDSCAN
;*UP LEFT DIE
ULLDIE  LDY   #$0000
        LDD   #$FFFF
        BRA   LDSCAN
;*UP RIGHT DIE
URLDIE  LDY   #$0200
        LDD   #$01FF
        BRA   LDSCAN
;*DOWN RT DIE
DRLDIE  LDY   #$0205
        LDD   #$0101
        BRA   LDSCAN
;*DOWN LEFT DIAG LASER
DLLASR  LDX   PD,U
        LDA   OX16,X
        SUBA  #3
        LDB   OY16,X
        ADDB  #6
        CMPA  #XMIN
        BLO   DLLDIE
        CMPB  #YMAX-5
        BHI   DLLDIE
        STA   OX16,X
        STB   OY16,X
        LDD   #$FF01
        BSR   LASOUT
        NAP   1,DLLASR
;*UPPER LEFT DIAG
ULLASR  LDX   PD,U
        LDA   OX16,X
        SUBA  #3
        CMPA  #XMIN
        BLO   ULLDIE
        LDB   OY16,X
        SUBB  #6
        CMPB  #YMIN
        BLO   ULLDIE
        STA   OX16,X
        STB   OY16,X
        LDD   #$FFFF
        BSR   LASOUT
        NAP   1,ULLASR
;*UPPER RIGHT DIAG
URLASR  LDX   PD,U
        LDA   OX16,X
        ADDA  #3
        CMPA  #XMAX-2
        BHI   URLDIE
        LDB   OY16,X
        SUBB  #6
        CMPB  #YMIN
        BLO   URLDIE
        STA   OX16,X
        STB   OY16,X
        LDD   #$01FF
        BSR   LASOUT
        NAP   1,URLASR
;*DOWN RT DIAG
DRLASR  LDX   PD,U
        LDA   OX16,X
        ADDA  #3
        CMPA  #XMAX-2
        BHI   DRLDIE
        LDB   OY16,X
        ADDB  #6
        CMPB  #YMAX-5
        BLS   DRL1
        JMP   DRLDIE
DRL1    STA   OX16,X
        STB   OY16,X
        LDD   #$0101
        BSR   LASOUT
        NAP   1,DRLASR
;*OUTPUT LASER
LASOUT  STD   LASDIR           ;SAVE DIRECTION FOR HITS
        JSR   DMAOFN
        PSHS  U,X
        LDU   OPICT,X
        LDD   OBJX,X
        LDX   #PPTR
        JSR   COL0
        BNE   LASDIE
        LDX   ,S
        LDU   OPICT,X
        LDD   OBJX,X
        LDX   #RPTR
        JSR   COL0
        BNE   LASDIE
        LDX   ,S
        LDU   OPICT,X
        LDD   OBJX,X
        LDX   #OPTR
        JSR   COL0
        BNE   LASDIE
        PULS  X,U,PC
;*LASER DIE
LASDIE  PULS  X,U
        BSR   LASOFF
        JMP   SUCIDE
;*LASER OFF
LASOFF  JSR   DMAOFF
        LDD   OFREE            ;RETURN OBJECT TO FREE LIST
        STD   ,X
        STX   OFREE
        DEC   LCNT
        RTS  
;*
;*DISPLAY TOP OF SCREEN
;*
TDISP   PSHS  D,X,Y,U
        LDA   PLRCNT
TD1     JSR   SCRTR0
        DECA 
        BNE   TD1
        BSR   BORDER
        JSR   MANDSP
        PULS  D,X,Y,U,PC
;*
;*DISPLAY WAVE # MESSAGE
;*
WVMESS  LDA   ZP1WAV
        JSR   HEXBCD
        TFR   A,B
        LDA   #104
        JSR   WRD5V
        LDA   PLRCNT
        DECA 
        BEQ   WVMESX
        LDA   ZP2WAV
        JSR   HEXBCD
        TFR   A,B
        LDA   #114
        JSR   WRD5V
WVMESX  RTS  
;*
;*DISPLAY MEN LEFT
;*MAX OF 7
;*
MANDSV  LDX   #P1MAN
        LDD   #$1508
        JSR   BLKCLR           ;CLEAR MAN DISPLAY
        LDX   #P2MAN
        JSR   BLKCLR           ;CLEAR EM OUT
        LDY   #MNPIC
        LDA   ZP1LAS
        BEQ   MAND2
        CMPA  #7
        BLS   MAND1
        LDA   #7
MAND1   STA   XTEMP
        LDD   #P1MAN
MAND1L  JSR   PCTON
        ADDA  #4
        DEC   XTEMP
        BNE   MAND1L
MAND2   LDA   ZP2LAS
        BEQ   MAND3
        CMPA  #7
        BLS   MAND2A
        LDA   #7
MAND2A  STA   XTEMP
        LDD   #P2MAN
MAND2L  JSR   PCTON
        ADDA  #4
        DEC   XTEMP
        BNE   MAND2L
MAND3   RTS  
;*
;*DISPLAY BORDER
;*
BORDER  LDX   #(XMIN-1)*256+YMIN-2
        LDA   WALCOL
BORD1   STA   (XMAX-XMIN)*$100+$200,X
        STA   ,X+
        CMPX  #(XMIN-1)*256+YMAX+2
        BLS   BORD1
        LDX   #XMIN*256+YMIN-2
        LDB   WALCOL
BORD2   STD   ,X
        STD   YMAX-YMIN+3,X
        LEAX  256,X
        CMPX  #XMAX*256+YMIN-2
        BLS   BORD2
        RTS  
;*
;*POST REFRESH PROCESS
;*PSTREF=#TO REF EVERY 2 FRAME
PSTRPC  LDU   PSTIN
        CMPU  #PSLIST+64
        BLO   PSTP0
        LDU   #PSLIST
PSTP0   LDA   PSTREF
        PSHS  A
        LDY   PSTANI
PSTPL   LDX   ,U++
        BEQ   PSTP01
        LDD   ,Y
        EORA  #4
        EORB  #4
        SEI  
        STD   DMASIZ           ;SETUP SIZE
        LDB   PSTCOL
        STB   DMACON
        LDD   OBJDAT,Y
        STD   DMAORG
        LDD   OBJX,X
        STD   DMADES
        LDB   #$1A
        STB   DMACTL
        CLI  
PSTP01  DEC   ,S
        BNE   PSTPL
        LEAS  1,S
        STU   PSTIN
        NAP   2,PSTRPC
;*
;*MINI MAN PICT
;*
MNPIC   FCB   3,8
        FDB   MANPD
MANPD   FCB   $02,$22,$00
        FCB   $BB,$0B,$B0
        FCB   $BB,$0B,$B0
        FCB   $00,$20,$00
        FCB   $88,$08,$80
        FCB   $30,$80,$30
        FCB   $08,$08,$00
        FCB   $88,$08,$80
;*
;*LASER PICT PTRS
;*
LLPIC   FCB   3,1
        FDB   LLPC
ULPIC   FCB   1,6
        FDB   ULPC
DLLPIC  FCB   3,6
        FDB   DLLPC
ULLPIC  FCB   3,6
        FDB   ULLPC
;*LASER PICTURES
LLPC    FCB   $AA,$AA,$AA
ULPC    FCB   $A0,$A0,$A0,$A0,$A0,$A0
DLLPC   FCB   $00,$00,$0A
        FCB   $00,$00,$A0
        FCB   $00,$0A,$00
        FCB   $00,$A0,$00
        FCB   $0A,$00,$00
        FCB   $A0,$00,$00
ULLPC   FCB   $A0,$00,$00
        FCB   $0A,$00,$00
        FCB   $00,$A0,$00
        FCB   $00,$0A,$00
        FCB   $00,$00,$A0
        FCB   $00,$00,$0A
;*
;*PLAYER IMAGES...
MANLP1  FCB   4,12
        FDB   MANLD1
MANLP2  FCB   4,12
        FDB   MANLD2
MANLP3  FCB   4,12
        FDB   MANLD3
MANRP1  FCB   4,12
        FDB   MANRD1
MANRP2  FCB   4,12
        FDB   MANRD2
MANRP3  FCB   4,12
        FDB   MANRD3
MANDP1  FCB   4,12
        FDB   MANDD1
MANDP2  FCB   4,12
        FDB   MANDD2
MANDP3  FCB   4,12
        FDB   MANDD3
MANUP1  FCB   4,12
        FDB   MANUD1
MANUP2  FCB   4,12
        FDB   MANUD2
MANUP3  FCB   4,12
        FDB   MANUD3
MANLD1  EQU   *
        FDB   $0B22,$2000
        FDB   $0BBB,$BB00
        FDB   $0B22,$2B00
        FDB   $0022,$2000
        FDB   $0009,$0000
        FDB   $0099,$9000
        FDB   $0093,$9000
        FDB   $0093,$9000
        FDB   $0003,$0000
        FDB   $0001,$0000
        FDB   $0099,$0000
        FDB   $0000,$0000
MANLD2  EQU   *
        FDB   $0B22,$2000
        FDB   $0BBB,$BB00
        FDB   $0B22,$2B00
        FDB   $0022,$2000
        FDB   $0009,$0000
        FDB   $0009,$9000
        FDB   $0333,$9300
        FDB   $0009,$9300
        FDB   $0090,$9300
        FDB   $0090,$9000
        FDB   $0990,$9000
        FDB   $0000,$0000
MANLD3  EQU   *
        FDB   $0B22,$2000
        FDB   $0BBB,$BB00
        FDB   $0B22,$2B00
        FDB   $0022,$2000
        FDB   $0009,$0000
        FDB   $0009,$9000
        FDB   $0339,$9300
        FDB   $0009,$9300
        FDB   $0090,$9300
        FDB   $0090,$9000
        FDB   $0990,$9000
        FDB   $0000,$0000
MANRD1  EQU   *
        FDB   $0222,$B000
        FDB   $BBBB,$B000
        FDB   $B222,$B000
        FDB   $0222,$0000
        FDB   $0090,$0000
        FDB   $0999,$0000
        FDB   $0939,$0000
        FDB   $0939,$0000
        FDB   $0030,$0000
        FDB   $0090,$0000
        FDB   $0099,$0000
        FDB   $0000,$0000
MANRD2  EQU   *
        FDB   $0222,$B000
        FDB   $BBBB,$B000
        FDB   $B222,$B000
        FDB   $0222,$0000
        FDB   $0090,$0000
        FDB   $0990,$0000
        FDB   $3993,$3000
        FDB   $3990,$0000
        FDB   $3909,$0000
        FDB   $0909,$0000
        FDB   $0909,$9000
        FDB   $0000,$0000
MANRD3  EQU   *
        FDB   $0222,$B000
        FDB   $BBBB,$B000
        FDB   $B222,$B000
        FDB   $0222,$0000
        FDB   $0090,$0000
        FDB   $0990,$0000
        FDB   $3933,$3000
        FDB   $3990,$0000
        FDB   $3909,$0000
        FDB   $0909,$0000
        FDB   $0909,$9000
        FDB   $0000,$0000
MANDD1  EQU   *
        FDB   $0022,$2000
        FDB   $BBB2,$BBB0
        FDB   $B0B0,$B0B0
        FDB   $0B22,$2B00
        FDB   $0009,$0000
        FDB   $0993,$9900
        FDB   $3993,$9930
        FDB   $3093,$9030
        FDB   $3090,$9030
        FDB   $0090,$9000
        FDB   $0990,$9900
        FDB   $0000,$0000
MANDD2  EQU   *
        FDB   $0022,$2000
        FDB   $BBB2,$BBB0
        FDB   $B0B0,$B0B0
        FDB   $0B22,$2B00
        FDB   $0009,$0000
        FDB   $0993,$9900
        FDB   $3993,$9930
        FDB   $3093,$9030
        FDB   $3090,$9000
        FDB   $0990,$9000
        FDB   $0000,$9000
        FDB   $0000,$9900
MANDD3  EQU   *
        FDB   $0022,$2000
        FDB   $BBB2,$BBB0
        FDB   $B0B0,$B0B0
        FDB   $0B22,$2B00
        FDB   $0009,$0000
        FDB   $0993,$9900
        FDB   $3993,$9930
        FDB   $3093,$9030
        FDB   $0090,$9030
        FDB   $0090,$9900
        FDB   $0090,$0000
        FDB   $0990,$0000
MANUD1  EQU   *
        FDB   $BB22,$2BB0
        FDB   $B222,$22B0
        FDB   $B222,$22B0
        FDB   $0022,$2000
        FDB   $0009,$0000
        FDB   $0999,$9900
        FDB   $3999,$9930
        FDB   $3099,$9030
        FDB   $3090,$9030
        FDB   $0090,$9000
        FDB   $0990,$9900
        FDB   $0000,$0000
MANUD2  EQU   *
        FDB   $BB22,$2BB0
        FDB   $B222,$22B0
        FDB   $B222,$22B0
        FDB   $0022,$2000
        FDB   $0009,$0000
        FDB   $0999,$9900
        FDB   $3999,$9930
        FDB   $3099,$9030
        FDB   $3090,$9000
        FDB   $0990,$9000
        FDB   $0000,$9000
        FDB   $0000,$9900
MANUD3  EQU   *
        FDB   $BB22,$2BB0
        FDB   $B222,$22B0
        FDB   $B222,$22B0
        FDB   $0022,$2000
        FDB   $0009,$0000
        FDB   $0999,$9900
        FDB   $3999,$9930
        FDB   $3099,$9030
        FDB   $0090,$9030
        FDB   $0090,$9900
        FDB   $0090,$0000
        FDB   $0990,$0000
;        END  