;        STTL  H U M A N S AND H U L K S
;        OPT   NOL
;        LIB   "src/RRF.ASM"
;        OPT   LIS
;*
;*VECTORS
;*
        ORG   RHORG
        JMP   HLKSTV
        JMP   HUMSTV
        JMP   CKLIMV
        JMP   SKULLV
        FDB   P1000
        FDB   MLP1
        FDB   DLP1
        FDB   KIDLP1
        FDB   HLKLP1
        FDB   HLKAL
        FDB   HUMATB
        FDB   SKULP
;*
;*MISC SOUNDS
;*
HKHSND  FCB   $D0,$01,$10,$06,0 ;HULK HIT
HLKSND  FCB   $D0,$03,$04,$17,0 ;HULK KILL
SAVSND  FCB   $E0,$01,$20,$0D,0 ;SAVE A HUMAN
HKSND   FCB   $E0,$01,$18,$1A,0 ;KILL A HUMAN
;*
;*HULK PROCESS
;*PD=OBJ,PD2=TARG,PD4=CURR ANI,PD5=NEW VEL TIMER,PD6=ANI BASE ADDR
;*MOVE UP,DOWN,L,R ONLY
HULK    LDA   STATUS           ;WAIT FOR STATUS TO GO
        BITA  #$7F
        BEQ   HULKL
        NAP   8,HULK
HULKL   LDX   PD,U
HULK00  LDY   PD6,U            ;TAKE A BIG STEP
        LDA   PD4,U
        LEAY  A,Y
        LDB   ,Y
        BPL   HULK0
        CLR   PD4,U            ;RECYCLE IT
        BRA   HULK00
HULK0   ADDA  #3
        STA   PD4,U            ;NEXT FRAME
        CLRA 
        ADDD  #HLKLP1
        STD   OPICT,X          ;NEW PICT
        LDA   1,Y
        CLRB 
        ASRA                   ; X
        RORB 
        ADDD  OX16,X
        PSHS  D
        LDB   2,Y
        ADDB  OY16,X
        BSR   CKLIMV           ;IN BOUNDS GUYS??
        BEQ   HULK2
        LEAS  2,S
        BRA   HLKND
HULK2   STB   OY16,X
        PULS  D
        STD   OX16,X
        LDB   OY16,X
        LDU   OPICT,X
        LDX   #PPTR            ;KILL YOUR POSTS + HUMANS
        PSHS  D,U
        JSR   COL0
        PULS  D,U
        LDX   #HPTR
        JSR   COL0
        LDU   CRPROC
        LDX   PD,U
        DEC   PD5,U
        BNE   HLKX
HLKND   BSR   HULKND
HLKX    JSR   DMAOFN
        LDX   #HULKL
        LDA   HLKSPD
        JMP   SLEEP
;*
;*CHECK OBJECT IN BOUNDS
;*X=OBJ, D=X,Y
;*EQ IF IN BOUNDS, NE IF OUT
CKLIMV  PSHS  D
        CMPA  #XMIN
        BLO   CKLF             ;FAIL
        CMPB  #YMIN
        BLO   CKLF
        ADDD  [OPICT,X]
        CMPA  #XMAX
        BHI   CKLF
        CMPB  #YMAX
        BHI   CKLF
        CLRA 
CKLF    PULS  D,PC
;*
;*KILL A HULK
;*X=OBJ
HULKIL  LDA   PCFLG
        BNE   HLKXON           ;RAN INTO ELTON JOHN.. TERMINATE HIM
        LDA   LASDIR
        CLRB 
        TST   SEED
        BMI   HLKK0
        ASLA 
HLKK0   ADDD  OX16,X
        PSHS  D
        LDB   LASDIR+1
        LDA   LSEED
        CMPA  #$C0
        BHS   HLKK00
        ASLB                   
HLKK00  ADDB  OY16,X
        LDA   ,S               ;GET BACK X
        BSR   CKLIMV
        BEQ   HLKK1
        LEAS  2,S
        BRA   HLKK2
HLKK1   STB   OY16,X
        PULS  D
        STD   OX16,X
        LDB   OY16,X
        LDU   OPICT,X
        PSHS  X
        LDX   #PPTR
        PSHS  D,U
        JSR   COL0
        PULS  D,U
        LDX   #HPTR
        JSR   COL0
        PULS  X
        JSR   DMAOFN
HLKK2   LDD   #HKHSND          ;JUST HIT 'EM
        JSR   SNDLD
HLKILX  RTS  
HLKXON  JMP   DMAON            ;TURN HIM ON!!
;*
;*GET A NEW HULK DIRECTION
;*X=OBJ,PD2=TARG,PD4=CURR ANI,PD5=NEW VEL TIMER,PD6=AN BASE ADDR
;*
HULKND  LDA   LSEED            ;NEW TIMER
        ANDA  #$1F
        INCA 
        STA   PD5,U
        LDY   [PD2,U]          ;TARGET OBJ
        BNE   HND0
        LDY   #PLOBJ           ;OUR GUY IS DEAD, LETS GO AFTER PLAYER
HND0    LDD   PD6,U            ;X OR Y PREVIOUS
        CMPD  #HLKAL
        BEQ   HNDY             ;X PREV, SEEK Y
        CMPD  #HLKAR
        BEQ   HNDY             ;X PREV SEEK Y
        LDA   SEED
        ANDA  #$1F
        ADDA  #-$10
        ADDA  OBJX,Y           ;RAN DOM OFFSET
HNDX1   CMPA  #XMAX
        BLS   HNDX2
        CMPA  #XMAX+$40
        BLS   HNDX2
        LDA   #XMIN
HNDX2   CMPA  OBJX,X
        BLS   HNDX3
        LDD   #HLKAR           ;GO RT.
        BRA   HND10
HNDX3   LDD   #HLKAL           ;GO LEFT
        BRA   HND10
HNDY    LDA   HSEED            ;SEEK Y
        ANDA  #$1F
        ADDA  #-$10            ;RAND OFFSET
        ADDA  OBJY,Y
        CMPA  #YMIN>>2
        BHS   HNDY1
        LDA   #YMAX
HNDY1   CMPA  OBJY,X
        BLS   HNDY2
        LDD   #HLKAD           ;GO DOWN
        BRA   HND10
HNDY2   LDD   #HLKAU           ;GO UP
HND10   STD   PD6,U            ;GET YOUR PIX
        CLRA 
        STA   PD4,U
        LDB   [PD6,U]
        ADDD  #HLKLP1
        STD   OPICT,X
        RTS  
;*
;*START A BUNCH OF HULKS
;*
HLKSTV  LDA   HLKCNT
        PSHS  A
        BEQ   HLKSTX
HLKSV1  BSR   HLKST
        DEC   ,S
        BNE   HLKSV1
HLKSTX  PULS  A,PC
;*
;*START A HULK
;*PD=OBJ,PD2=TARG,PD4=CUR ANI,PD5=NV TIMER,PD6=ANI BASE
HLKST   MAKP  HULK
        LEAU  ,X
        JSR   GETROB
        LDD   #HLKLP1
        STD   OPICT,X
        STD   OLDPIC,X
        STU   OBJID,X
        STX   PD,U
        LDD   #HULKIL
        STD   OCVECT,X
HLKST0  JSR   SAFTY            ;GET SAFETY ZONE
HKST0A  JSR   RANDXY           ;RANDOM INIT COORD
        CMPB  XTEMP            ;NOT NEAR PLAYER IN MIDDLE PLEASE
        BLS   HLKST1
        CMPB  XTEMP+1
        BHS   HLKST1
        CMPA  XTEMP2
        BLS   HLKST1
        CMPA  XTEMP2+1
        BLS   HKST0A           ;TRY AGAIN
HLKST1  STD   OBJX,X
        STA   OX16,X
        STB   OY16,X
        LDA   SEED
        CMPA  #$C0
        BLS   HLKST2           ;YES
        LDD   #HTBEND-2        ;INSURE GUY IS DEAD
        BRA   HLKST3
HLKST2  BSR   GTARG
HLKST3  STD   PD2,U
        JSR   HULKND           ;GET A NEW DIR BOYS
        JSR   OPON1            ;ON PHONY COLOR
        CLR   ODATA,X          ;SHOT COUNTER
        RTS  
;*
;*HULK ANIMATION TABLE
;*
HLKAL   EQU   *                ;LEFT
        FCB   0,$FD,0
        FCB   4,$FC,0
        FCB   0,$FD,0
        FCB   8,$FC,0
        FCB   $FF
HLKAR   EQU   *                ;RIGHT
        FCB   12,$03,0
        FCB   16,$04,0
        FCB   12,$03,0
        FCB   20,$04,0
        FCB   $FF
HLKAD   EQU   *                ;DOWN
        FCB   24,0,2
        FCB   28,0,2
        FCB   24,0,2
        FCB   32,0,2
        FCB   $FF
HLKAU   EQU   *                ;UP
        FCB   24,0,-2
        FCB   28,0,-2
        FCB   24,0,-2
        FCB   32,0,-2
        FCB   $FF
;*
;*INITIALIZE HUMAN TABLE
HTINIT  LDX   #HTAB
        STX   HTABX
HTI1    CLR   ,X+
        CMPX  #HTBEND
        BNE   HTI1
        RTS  
;*
;*ADD A HUMAN TO THE TABLE
;*X=OBJ
HUMADD  PSHS  D,X
        LDX   #HTAB
HUMAD1  LDD   ,X++
        BNE   HUMAD1
        LDD   2,S
        STD   -2,X
        PULS  D,X,PC
;*
;*CLEAR A HUMAN FROM THE TABLE
;*X=OBJ
HUMCLR  PSHS  D,X
        LDX   #HTAB
        LDD   2,S
HUMC1   CMPD  ,X++
        BEQ   HUMC2
        CMPX  #HTBEND
        BNE   HUMC1
        SEI  
        BRA   *
HUMC2   CLRA 
        CLRB 
        STD   -2,X
        PULS  D,X,PC
;*
;*GET A HUMAN TARGET
;*D=TARGET STORAGE LOCATION
;*RET EQ IF NONE, NE IF SOME
;*
GTARG   PSHS  X
        LDX   HTABX
        CMPX  #HTBEND
        BLO   GTGL1
        LDX   #HTAB
        BRA   GTGL1
GTGL    CMPX  HTABX
        BEQ   GTGX             ;NOBODY HOME
GTGL1   LDD   ,X++
        BNE   GTGX1
        CMPX  #HTBEND
        BLO   GTGL
        LDX   #HTAB
        BRA   GTGL
GTGX1   STX   HTABX
        LEAX  -2,X
        TFR   X,D
GTGX    PULS  X,PC             ;RETURN
;*
;*HUMAN PROCESS
;*PD=OBJ,PD2=BASE PICT,PD4=CURR ANI,PD5=NV TIMR,PD6=ANI BASE
;*
HUMAN   LDX   PD,U
HUM00   LDY   PD6,U            ;GET NEW STEP
        LDA   PD4,U
        LEAY  A,Y
        LDB   ,Y
        BPL   HUM0
        CLR   PD4,U            ;RESET CYCLE
        BRA   HUM00
HUM0    ADDA  #3
        STA   PD4,U
        CLRA 
        ADDD  PD2,U
        STD   OPICT,X
        LDA   1,Y
        CLRB 
        ASRA 
        RORB 
        ADDD  OX16,X
        PSHS  D
        LDB   2,Y
        ADDB  OY16,X
        PSHS  U
        LDU   #PPTR
        JSR   CKOBS
        PULS  U
        BNE   HUM1             ;OBSTACLE
        JSR   CKLIM
        BEQ   HUM2
HUM1    LEAS  2,S
        BRA   HUMND            ;NEW DIRECTION
HUM2    STB   OY16,X
        PULS  D
        STD   OX16,X
        DEC   PD5,U
        BNE   HUMX
HUMND   BSR   GHDIR
HUMX    JSR   DMAOFN
        NAP   8,HUMAN
;*
;*START HUMAN
;*PD=OBJ,PD2=BASE PICT,PD4=CURR ANI,PD5=NV TIMR,PD6=ANI BASE
;*
HUMSTV  JSR   HTINIT
        LDX   #KIDLP1
        LDU   #KIDKIL
        LDA   KIDCNT
        BSR   HSSUB
        LDX   #MLP1
        LDU   #MOMKIL
        LDA   MOMCNT
        BSR   HSSUB
        LDX   #DLP1
        LDU   #DADKIL
        LDA   DADCNT
HSSUB   PSHS  A,X,U
        TSTA 
        BEQ   HUMSTX
HUMST0  MAKP  HUMAN
        LEAU  ,X
        JSR   GETHUM
        LDD   1,S
        STD   OPICT,X
        STD   OLDPIC,X
        STD   PD2,U
        STU   OBJID,X
        STX   PD,U
        LDD   3,S
        STD   OCVECT,X
        JSR   RANDXY
        STD   OBJX,X
        STA   OX16,X
        STB   OY16,X
        LDA   SEED
        ANDA  #7               ;STAGGER START TIME
        INCA 
        STA   PTIME,U
        BSR   GHDIR
        JSR   DMAON            ;TURN HIM ON
        JSR   HUMADD
        DEC   ,S
        BNE   HUMST0
HUMSTX  PULS  A,X,U,PC
;*
;*GET HUMAN DIRECTION
;*U=PROCESS,X=OBJ,PD2=PICBAS,PD4=ANI#,PD5=NV TMR,PD6=ANI BASE
;*
GHDIR   LDA   LSEED
        ANDA  #$7F
        INCA 
        STA   PD5,U            ;NEW VEL TIMER
        LDA   SEED
        ANDA  #7
        LDB   #13
        MUL  
        ADDD  #HUMATB
        STD   PD6,U
        CLRA 
        STA   PD4,U
        LDB   [PD6,U]
        ADDD  PD2,U
        STD   OPICT,X          ;NEW PICT
        RTS  
;*KILL A KID
KIDKIL  DEC   KIDCNT
        BRA   HUMKIL
MOMKIL  DEC   MOMCNT
        BRA   HUMKIL
DADKIL  DEC   DADCNT

;*
;*KILL A HUMAN
;*
HUMKIL  JSR   HUMCLR
        JSR   KILHUM
        JSR   DMAOFF
        LDD   OBJX,X
        LDX   OBJID,X
        JSR   KILL
        TST   BRNFLG
        BNE   HUMKX            ;BRAINY GOT ME
SKULLV  EQU   *
        MKPROB HUMSAV,NULLP,NOKILL
        CMPA  #XMAX-6          ;CHECK LIMIT, DONT WRITE OVER BOUNDARY
        BLO   HUMK1
        LDA   #XMAX-6
HUMK1   STD   OBJX,X
        TST   BRNFLG           ;PROGRAMMING DEATH
        BNE   HKIL10
        TST   PCFLG
        BEQ   HKIL10
        LDA   #60
        STA   PD2,U
        INC   SAVCNT
        LDA   SAVCNT
        CMPA  #5
        BLS   HUMS1
        LDA   #5
HUMS1   ASLA 
        ASLA 
        LDU   #P1000-4
        LEAU  A,U
        STU   OPICT,X
        LDU   #SVITAB-2
        LSRA 
        LDD   A,U
        JSR   SCORE
        LDD   #SAVSND
        JSR   SNDLD
NOKILL  CLRA 
        PULS  D,PC             ;NO KILL PLAYER
HKIL10  LDA   #90
        STA   PD2,U
        LDD   #SKULP
        STD   OPICT,X
        LDD   #HKSND
        JSR   SNDLD
HUMKX   RTS  
;*
;*KILL/SAVE HUMAN DISPLAY ERASE
;*
HUMSAV  LDX   PD,U             ;OFF THE JAG IN THE BAG
        LDD   OBJX,X
        LDY   OPICT,X
        JSR   PCTON
        DEC   PD2,U
        BEQ   HUMSX
        NAP   1,HUMSAV
HUMSX   JSR   PCTOFF
        LDD   OFREE
        STD   ,X
        STX   OFREE
        JMP   SUCIDE           ;QUIT
;*
;*HUMAN SAVE TABLE
;*
SVITAB  EQU   *
        FDB   $0210
        FDB   $0220
        FDB   $0230
        FDB   $0240
        FDB   $0250
;*
;*HUMAN ANIMATION TABLE
;*IMAGE #,DELTA X,DELTA Y; $FF IMAGE=START OVER
;*IMAGES STORED L,R,D,U
;*
HUMATB  EQU   *
;*LEFT
        FCB   0,$FE,$00
        FCB   4,$FF,$00
        FCB   0,$FE,$00
        FCB   8,$FF,$00
        FCB   $FF
;*RIGHT
        FCB   12,$02,$00
        FCB   16,$01,$00
        FCB   12,$02,$00
        FCB   20,$01,$00
        FCB   $FF
;*DOWN
        FCB   24,$00,$01
        FCB   28,$00,$01
        FCB   24,$00,$01
        FCB   32,$00,$01
        FCB   $FF
;*UP
        FCB   36,$00,$FF
        FCB   40,$00,$FF
        FCB   36,$00,$FF
        FCB   44,$00,$FF
        FCB   $FF
;*UP+LEFT
        FCB   0,$FE,$FF
        FCB   8,$FF,$FF
        FCB   0,$FE,$FF
        FCB   8,$FF,$FF
        FCB   $FF
;*RIGHT+UP
        FCB   12,$02,$FF
        FCB   16,$01,$FF
        FCB   12,$02,$FF
        FCB   20,$01,$FF
        FCB   $FF
;*RIGHT+DOWN
        FCB   12,$02,$01
        FCB   16,$01,$01
        FCB   12,$02,$01
        FCB   20,$01,$01
        FCB   $FF
;*DOWN+LEFT
        FCB   0,$FE,$01
        FCB   4,$FF,$01
        FCB   0,$FE,$01
        FCB   8,$FF,$01
        FCB   $FF
;*
;*SKULL PICTURE
;*
SKULP   FCB   6,11
        FDB   SKULD
SKULD   EQU   *
        FCB   $00,$00,$AA,$A0,$00,$00
        FCB   $00,$0A,$AA,$AA,$00,$00
        FCB   $0A,$0F,$FA,$FF,$0A,$00
        FCB   $AA,$0A,$A0,$AA,$0A,$A0
        FCB   $00,$A0,$AA,$A0,$A0,$00
        FCB   $00,$0A,$0A,$0A,$00,$00
        FCB   $00,$00,$A0,$A0,$00,$00
        FCB   $00,$00,$0A,$00,$00,$00
        FCB   $00,$00,$A0,$A0,$00,$00
        FCB   $00,$AA,$00,$0A,$A0,$00
        FCB   $00,$0A,$00,$0A,$00,$00
;*A NULL PICTURE FOR KICKS
NULLP   FCB   2,2
        FDB   NULLPD
NULLPD  FDB   0,0
;*
;*SCORE PICTS
;*
P1000   FCB   6,5
        FDB   P1000D
P2000   FCB   6,5
        FDB   P2000D
P3000   FCB   6,5
        FDB   P3000D
P4000   FCB   6,5
        FDB   P4000D
P5000   FCB   6,5
        FDB   P5000D
P1000D  EQU   *
        FDB   $0FF0,$FFFF,$FFF0
        FDB   $00F0,$F0F0,$F0F0
        FDB   $00F0,$F0F0,$F0F0
        FDB   $00F0,$F0F0,$F0F0
        FDB   $0FFF,$FFFF,$FFF0
P2000D 
        FDB   $0FFF,$BBBB,$BBB0
        FDB   $000F,$B0B0,$B0B0
        FDB   $0FFF,$B0B0,$B0B0
        FDB   $0F00,$B0B0,$B0B0
        FDB   $0FFF,$BBBB,$BBB0
P3000D  EQU   *
        FDB   $0FFF,$EEEE,$EEE0
        FDB   $000F,$E0E0,$E0E0
        FDB   $0FFF,$E0E0,$E0E0
        FDB   $000F,$E0E0,$E0E0
        FDB   $0FFF,$EEEE,$EEE0
P4000D  EQU   *
        FDB   $0F0F,$BBBB,$BBB0
        FDB   $0F0F,$B0B0,$B0B0
        FDB   $0FFF,$B0B0,$B0B0
        FDB   $000F,$B0B0,$B0B0
        FDB   $000F,$BBBB,$BBB0
P5000D  EQU   *
        FDB   $0AAA,$EEEE,$EEE0
        FDB   $0A00,$E0E0,$E0E0
        FDB   $0AAA,$E0E0,$E0E0
        FDB   $000A,$E0E0,$E0E0
        FDB   $0AAA,$EEEE,$EEE0

;        IF    NOL         ;Fixme was: IFC   &A,NOL
;        OPT   NOL
;        ENDIF

;*
;*PITCHERS FOR THE MASSES...
;*
MLP1    FCB   4,14
        FDB   MLD1
MLP2    FCB   4,14
        FDB   MLD2
MLP3    FCB   4,14
        FDB   MLD3
MRP1    FCB   4,14
        FDB   MRD1
MRP2    FCB   4,14
        FDB   MRD2
MRP3    FCB   4,14
        FDB   MRD3
MDP1    FCB   4,14
        FDB   MDD1
MDP2    FCB   4,14
        FDB   MDD2
MDP3    FCB   4,14
        FDB   MDD3
MUP1    FCB   4,14
        FDB   MUD1
MUP2    FCB   4,14
        FDB   MUD2
MUP3    FCB   4,14
        FDB   MUD3
MLD1    EQU   *
        FDB   $0055,$0000
        FDB   $0025,$5000
        FDB   $0062,$5000
        FDB   $0022,$5500
        FDB   $0003,$3000
        FDB   $0034,$3000
        FDB   $0004,$3000
        FDB   $0039,$3000
        FDB   $0333,$3300
        FDB   $0069,$6000
        FDB   $0009,$0000
        FDB   $0009,$0000
        FDB   $0033,$0000
        FDB   $0000,$0000
MLD2    EQU   *
        FDB   $0055,$0000
        FDB   $0025,$5000
        FDB   $0062,$5000
        FDB   $0022,$5500
        FDB   $0003,$3000
        FDB   $0033,$3400
        FDB   $0003,$3400
        FDB   $0933,$3900
        FDB   $6333,$3300
        FDB   $6690,$9000
        FDB   $0900,$9000
        FDB   $0900,$9000
        FDB   $3303,$3000
        FDB   $0000,$0000
MLD3    EQU   *
        FDB   $0055,$0000
        FDB   $0025,$5000
        FDB   $0062,$5000
        FDB   $0022,$5500
        FDB   $0003,$3000
        FDB   $0043,$3400
        FDB   $0443,$3400
        FDB   $0933,$3900
        FDB   $0333,$3360
        FDB   $0090,$9660
        FDB   $0900,$9000
        FDB   $0900,$9000
        FDB   $3303,$3000
        FDB   $0000,$0000
MRD1    EQU   *
        FDB   $0005,$5000
        FDB   $0055,$2000
        FDB   $0052,$6000
        FDB   $0552,$2000
        FDB   $0033,$0000
        FDB   $0034,$3000
        FDB   $0034,$0000
        FDB   $0039,$3000
        FDB   $0366,$6300
        FDB   $0066,$6000
        FDB   $0009,$0000
        FDB   $0009,$0000
        FDB   $0003,$3000
        FDB   $0000,$0000
MRD2    EQU   *
        FDB   $0005,$5000
        FDB   $0055,$2000
        FDB   $0052,$6000
        FDB   $0552,$2000
        FDB   $0033,$0000
        FDB   $0433,$3000
        FDB   $0433,$0000
        FDB   $0933,$3900
        FDB   $6663,$3300
        FDB   $6660,$9000
        FDB   $0090,$0900
        FDB   $0090,$0900
        FDB   $0033,$0330
        FDB   $0000,$0000
MRD3    EQU   *
        FDB   $0005,$5000
        FDB   $0055,$2000
        FDB   $0052,$6000
        FDB   $0552,$2000
        FDB   $0033,$0000
        FDB   $0033,$4000
        FDB   $0033,$4400
        FDB   $0933,$3900
        FDB   $0333,$6660
        FDB   $0090,$6660
        FDB   $0090,$0900
        FDB   $0090,$0900
        FDB   $0033,$0330
        FDB   $0000,$0000
MDD1    EQU   *
        FDB   $0055,$5000
        FDB   $0522,$2500
        FDB   $0562,$6500
        FDB   $5522,$2550
        FDB   $3333,$3330
        FDB   $4033,$3040
        FDB   $4003,$0040
        FDB   $9033,$3090
        FDB   $6333,$3300
        FDB   $6090,$9000
        FDB   $0090,$9000
        FDB   $0090,$9000
        FDB   $0330,$3300
        FDB   $0000,$0000
MDD2    EQU   *
        FDB   $0055,$5000
        FDB   $0522,$2500
        FDB   $0562,$6500
        FDB   $5522,$2550
        FDB   $3333,$3330
        FDB   $4033,$3040
        FDB   $9003,$0040
        FDB   $6033,$3090
        FDB   $6333,$3300
        FDB   $0090,$9000
        FDB   $0090,$9000
        FDB   $0090,$3300
        FDB   $0030,$0000
        FDB   $0030,$0000
MDD3    EQU   *
        FDB   $0055,$5000
        FDB   $0522,$2500
        FDB   $0562,$6500
        FDB   $5522,$2550
        FDB   $3333,$3330
        FDB   $4033,$3040
        FDB   $4003,$0090
        FDB   $9033,$3000
        FDB   $6333,$3300
        FDB   $6090,$9000
        FDB   $0090,$9000
        FDB   $0330,$9000
        FDB   $0000,$3000
        FDB   $0000,$3000
MUD1    EQU   *
        FDB   $0055,$5000
        FDB   $0555,$5500
        FDB   $0555,$5500
        FDB   $5555,$5550
        FDB   $3333,$3330
        FDB   $4033,$3040
        FDB   $4003,$0040
        FDB   $9033,$3090
        FDB   $0333,$3360
        FDB   $0090,$9060
        FDB   $0090,$9000
        FDB   $0090,$9000
        FDB   $0330,$3300
        FDB   $0000,$0000
MUD2    EQU   *
        FDB   $0055,$5000
        FDB   $0555,$5500
        FDB   $0555,$5500
        FDB   $5555,$5550
        FDB   $3333,$3330
        FDB   $4033,$3040
        FDB   $9003,$0040
        FDB   $0033,$3090
        FDB   $0333,$3360
        FDB   $0090,$9060
        FDB   $0090,$9000
        FDB   $0090,$3300
        FDB   $0090,$0000
        FDB   $0030,$0000
MUD3    EQU   *
        FDB   $0055,$5000
        FDB   $0555,$5500
        FDB   $0555,$5500
        FDB   $5555,$5550
        FDB   $3333,$3330
        FDB   $4033,$3040
        FDB   $4003,$0090
        FDB   $9033,$3060
        FDB   $0333,$3360
        FDB   $0090,$9000
        FDB   $0090,$9000
        FDB   $0330,$9000
        FDB   $0000,$9000
        FDB   $0000,$3000
DLP1    FCB   5,13
        FDB   DLD1
DLP2    FCB   5,13
        FDB   DLD2
DLP3    FCB   5,13
        FDB   DLD3
DRP1    FCB   5,13
        FDB   DRD1
DRP2    FCB   5,13
        FDB   DRD2
DRP3    FCB   5,13
        FDB   DRD3
DDP1    FCB   5,13
        FDB   DDD1
DDP2    FCB   5,13
        FDB   DDD2
DDP3    FCB   5,13
        FDB   DDD3
DUP1    FCB   5,13
        FDB   DUD1
DUP2    FCB   5,13
        FDB   DUD2
DUP3    FCB   5,13
        FDB   DUD3
DLD1    EQU   *
        FCB   $00,$02,$55,$00,$00
        FCB   $00,$09,$25,$00,$00
        FCB   $00,$02,$25,$00,$00
        FCB   $00,$07,$77,$00,$00
        FCB   $00,$07,$77,$00,$00
        FCB   $00,$07,$77,$00,$00
        FCB   $00,$07,$77,$00,$00
        FCB   $00,$07,$27,$00,$00
        FCB   $00,$88,$88,$00,$00
        FCB   $00,$88,$88,$00,$00
        FCB   $00,$88,$88,$00,$00
        FCB   $00,$02,$20,$00,$00
        FCB   $00,$00,$00,$00,$00
DLD2    EQU   *
        FCB   $00,$02,$55,$00,$00
        FCB   $00,$09,$25,$00,$00
        FCB   $00,$02,$25,$00,$00
        FCB   $00,$07,$77,$00,$00
        FCB   $00,$07,$77,$70,$00
        FCB   $00,$07,$77,$70,$00
        FCB   $00,$07,$77,$70,$00
        FCB   $00,$27,$77,$20,$00
        FCB   $00,$07,$88,$88,$00
        FCB   $00,$70,$88,$88,$00
        FCB   $00,$70,$88,$88,$00
        FCB   $02,$20,$22,$00,$00
        FCB   $00,$00,$00,$00,$00
DLD3    EQU   *
        FCB   $00,$02,$55,$00,$00
        FCB   $00,$09,$25,$00,$00
        FCB   $00,$02,$25,$00,$00
        FCB   $00,$07,$77,$00,$00
        FCB   $00,$07,$77,$70,$00
        FCB   $00,$07,$77,$70,$00
        FCB   $00,$77,$77,$70,$00
        FCB   $00,$27,$77,$20,$00
        FCB   $88,$88,$07,$00,$00
        FCB   $88,$88,$07,$00,$00
        FCB   $88,$88,$07,$00,$00
        FCB   $02,$20,$22,$00,$00
        FCB   $00,$00,$00,$00,$00
DRD1    EQU   *
        FCB   $00,$55,$20,$00,$00
        FCB   $00,$52,$90,$00,$00
        FCB   $00,$52,$20,$00,$00
        FCB   $00,$77,$70,$00,$00
        FCB   $00,$77,$70,$00,$00
        FCB   $00,$77,$70,$00,$00
        FCB   $00,$77,$70,$00,$00
        FCB   $00,$72,$70,$00,$00
        FCB   $00,$87,$88,$00,$00
        FCB   $00,$87,$88,$00,$00
        FCB   $00,$87,$88,$00,$00
        FCB   $00,$02,$20,$00,$00
        FCB   $00,$00,$00,$00,$00
DRD2    EQU   *
        FCB   $00,$55,$20,$00,$00
        FCB   $00,$52,$90,$00,$00
        FCB   $00,$52,$20,$00,$00
        FCB   $00,$77,$70,$00,$00
        FCB   $07,$77,$70,$00,$00
        FCB   $07,$77,$70,$00,$00
        FCB   $07,$77,$70,$00,$00
        FCB   $02,$77,$72,$00,$00
        FCB   $00,$77,$78,$88,$00
        FCB   $00,$70,$87,$88,$00
        FCB   $00,$70,$87,$88,$00
        FCB   $00,$22,$02,$20,$00
        FCB   $00,$00,$00,$00,$00
DRD3    EQU   *
        FCB   $00,$55,$20,$00,$00
        FCB   $00,$52,$90,$00,$00
        FCB   $00,$52,$20,$00,$00
        FCB   $00,$77,$70,$00,$00
        FCB   $07,$77,$70,$00,$00
        FCB   $07,$77,$70,$00,$00
        FCB   $07,$77,$77,$00,$00
        FCB   $02,$77,$72,$00,$00
        FCB   $88,$77,$70,$00,$00
        FCB   $88,$78,$07,$00,$00
        FCB   $88,$78,$07,$00,$00
        FCB   $00,$22,$02,$20,$00
        FCB   $00,$00,$00,$00,$00
DDD1    EQU   *
        FCB   $00,$22,$20,$00,$00
        FCB   $00,$92,$90,$00,$00
        FCB   $00,$22,$20,$00,$00
        FCB   $77,$81,$87,$70,$00
        FCB   $77,$71,$77,$70,$00
        FCB   $70,$71,$70,$70,$00
        FCB   $70,$71,$70,$70,$00
        FCB   $20,$77,$70,$20,$00
        FCB   $00,$70,$70,$88,$00
        FCB   $00,$70,$70,$88,$00
        FCB   $00,$70,$70,$88,$00
        FCB   $02,$20,$22,$00,$00
        FCB   $00,$00,$00,$00,$00
DDD2    EQU   *
        FCB   $00,$22,$20,$00,$00
        FCB   $00,$92,$90,$00,$00
        FCB   $00,$22,$20,$00,$00
        FCB   $77,$81,$87,$70,$00
        FCB   $77,$71,$77,$70,$00
        FCB   $70,$71,$70,$70,$00
        FCB   $20,$71,$70,$70,$00
        FCB   $00,$77,$70,$20,$00
        FCB   $00,$70,$70,$88,$00
        FCB   $00,$70,$70,$88,$00
        FCB   $00,$70,$22,$88,$00
        FCB   $00,$20,$00,$00,$00
        FCB   $00,$20,$00,$00,$00
DDD3    EQU   *
        FCB   $00,$22,$20,$00,$00
        FCB   $00,$92,$90,$00,$00
        FCB   $00,$22,$20,$00,$00
        FCB   $77,$81,$87,$70,$00
        FCB   $77,$71,$77,$70,$00
        FCB   $70,$71,$70,$70,$00
        FCB   $70,$71,$70,$20,$00
        FCB   $20,$77,$70,$88,$00
        FCB   $00,$70,$70,$88,$00
        FCB   $00,$70,$70,$88,$00
        FCB   $02,$20,$70,$00,$00
        FCB   $00,$00,$20,$00,$00
        FCB   $00,$00,$20,$00,$00
DUD1    EQU   *
        FCB   $00,$00,$55,$50,$00
        FCB   $00,$00,$55,$50,$00
        FCB   $00,$00,$45,$40,$00
        FCB   $00,$77,$77,$77,$70
        FCB   $00,$77,$77,$77,$70
        FCB   $00,$70,$77,$70,$70
        FCB   $00,$70,$77,$70,$70
        FCB   $00,$20,$77,$70,$20
        FCB   $08,$80,$70,$70,$00
        FCB   $08,$80,$70,$70,$00
        FCB   $08,$80,$70,$70,$00
        FCB   $00,$02,$20,$22,$00
        FCB   $00,$00,$00,$00,$00
DUD2    EQU   *
        FCB   $00,$00,$55,$50,$00
        FCB   $00,$00,$55,$50,$00
        FCB   $00,$00,$45,$40,$00
        FCB   $00,$77,$77,$77,$70
        FCB   $00,$77,$77,$77,$70
        FCB   $00,$70,$77,$70,$70
        FCB   $00,$20,$77,$70,$70
        FCB   $08,$80,$77,$70,$20
        FCB   $08,$80,$70,$70,$00
        FCB   $08,$80,$70,$70,$00
        FCB   $00,$00,$70,$22,$00
        FCB   $00,$00,$70,$00,$00
        FCB   $00,$00,$20,$00,$00
DUD3    EQU   *
        FCB   $00,$00,$55,$50,$00
        FCB   $00,$00,$55,$50,$00
        FCB   $00,$00,$45,$40,$00
        FCB   $00,$77,$77,$77,$70
        FCB   $00,$77,$77,$77,$70
        FCB   $00,$70,$77,$70,$70
        FCB   $00,$70,$77,$70,$20
        FCB   $00,$20,$77,$70,$00
        FCB   $08,$80,$70,$70,$00
        FCB   $08,$80,$70,$70,$00
        FCB   $08,$82,$20,$70,$00
        FCB   $00,$00,$00,$70,$00
        FCB   $00,$00,$00,$20,$00
KIDLP1  FCB   3,11
        FDB   KIDLD1
KIDLP2  FCB   3,11
        FDB   KIDLD2
KIDLP3  FCB   3,11
        FDB   KIDLD3
KIDRP1  FCB   3,11
        FDB   KIDRD1
KIDRP2  FCB   3,11
        FDB   KIDRD2
KIDRP3  FCB   3,11
        FDB   KIDRD3
KIDDP1  FCB   3,11
        FDB   KIDDD1
KIDDP2  FCB   3,11
        FDB   KIDDD2
KIDDP3  FCB   3,11
        FDB   KIDDD3
KIDUP1  FCB   3,11
        FDB   KIDUD1
KIDUP2  FCB   3,11
        FDB   KIDUD2
KIDUP3  FCB   3,11
        FDB   KIDUD3
KIDLD1  EQU   *
        FCB   $02,$22,$00
        FCB   $09,$22,$00
        FCB   $02,$22,$00
        FCB   $00,$20,$00
        FCB   $01,$11,$00
        FCB   $01,$91,$00
        FCB   $01,$91,$00
        FCB   $00,$10,$00
        FCB   $00,$10,$00
        FCB   $09,$90,$00
        FCB   $00,$00,$00
KIDLD2  EQU   *
        FCB   $02,$22,$00
        FCB   $09,$22,$00
        FCB   $02,$22,$00
        FCB   $00,$20,$00
        FCB   $01,$11,$00
        FCB   $09,$11,$00
        FCB   $90,$10,$90
        FCB   $01,$01,$00
        FCB   $01,$00,$10
        FCB   $99,$09,$90
        FCB   $00,$00,$00
KIDLD3  EQU   *
        FCB   $02,$22,$00
        FCB   $09,$22,$00
        FCB   $02,$22,$00
        FCB   $00,$20,$00
        FCB   $01,$11,$00
        FCB   $01,$11,$90
        FCB   $90,$10,$90
        FCB   $01,$01,$00
        FCB   $01,$00,$10
        FCB   $99,$09,$90
        FCB   $00,$00,$00
KIDRD1  EQU   *
        FCB   $02,$22,$00
        FCB   $02,$29,$00
        FCB   $02,$22,$00
        FCB   $00,$20,$00
        FCB   $01,$11,$00
        FCB   $01,$91,$00
        FCB   $01,$91,$00
        FCB   $00,$10,$00
        FCB   $00,$10,$00
        FCB   $00,$99,$00
        FCB   $00,$00,$00
KIDRD2  EQU   *
        FCB   $02,$22,$00
        FCB   $02,$29,$00
        FCB   $02,$22,$00
        FCB   $00,$20,$00
        FCB   $01,$11,$00
        FCB   $91,$11,$00
        FCB   $90,$10,$90
        FCB   $01,$01,$00
        FCB   $10,$01,$00
        FCB   $99,$09,$90
        FCB   $00,$00,$00
KIDRD3  EQU   *
        FCB   $02,$22,$00
        FCB   $02,$29,$00
        FCB   $02,$22,$00
        FCB   $00,$20,$00
        FCB   $01,$11,$00
        FCB   $01,$19,$00
        FCB   $90,$10,$90
        FCB   $01,$01,$00
        FCB   $10,$01,$00
        FCB   $99,$09,$90
        FCB   $00,$00,$00
KIDDD1  EQU   *
        FCB   $02,$22,$00
        FCB   $09,$29,$00
        FCB   $02,$92,$00
        FCB   $00,$20,$00
        FCB   $11,$11,$10
        FCB   $91,$11,$90
        FCB   $91,$11,$90
        FCB   $01,$01,$00
        FCB   $01,$01,$00
        FCB   $99,$09,$90
        FCB   $00,$00,$00
KIDDD2  EQU   *
        FCB   $02,$22,$00
        FCB   $09,$29,$00
        FCB   $02,$92,$00
        FCB   $00,$20,$00
        FCB   $91,$11,$10
        FCB   $91,$11,$90
        FCB   $01,$11,$90
        FCB   $01,$01,$00
        FCB   $01,$09,$90
        FCB   $01,$00,$00
        FCB   $99,$00,$00
KIDDD3  EQU   *
        FCB   $02,$22,$00
        FCB   $09,$29,$00
        FCB   $02,$92,$00
        FCB   $00,$20,$00
        FCB   $11,$11,$90
        FCB   $91,$11,$90
        FCB   $91,$11,$00
        FCB   $01,$01,$00
        FCB   $99,$01,$00
        FCB   $00,$01,$00
        FCB   $00,$09,$90
KIDUD1  EQU   *
        FCB   $02,$22,$00
        FCB   $02,$22,$00
        FCB   $02,$22,$00
        FCB   $00,$20,$00
        FCB   $11,$11,$10
        FCB   $91,$11,$90
        FCB   $91,$11,$90
        FCB   $01,$01,$00
        FCB   $01,$01,$00
        FCB   $99,$09,$90
        FCB   $00,$00,$00
KIDUD2  EQU   *
        FCB   $02,$22,$00
        FCB   $02,$22,$00
        FCB   $02,$22,$00
        FCB   $00,$20,$00
        FCB   $91,$11,$10
        FCB   $91,$11,$90
        FCB   $01,$11,$90
        FCB   $01,$01,$00
        FCB   $01,$09,$90
        FCB   $01,$00,$00
        FCB   $99,$00,$00
KIDUD3  EQU   *
        FCB   $02,$22,$00
        FCB   $02,$22,$00
        FCB   $02,$22,$00
        FCB   $00,$20,$00
        FCB   $11,$11,$90
        FCB   $91,$11,$90
        FCB   $91,$11,$00
        FCB   $01,$01,$00
        FCB   $99,$01,$00
        FCB   $00,$01,$00
        FCB   $00,$09,$90
BRLP1   FCB   7,16
HLKLP1  FCB   7,16
        FDB   HLKLD1
HLKLP2  FCB   7,16
        FDB   HLKLD2
HLKLP3  FCB   7,16
        FDB   HLKLD3
HLKRP1  FCB   7,16
        FDB   HLKRD1
HLKRP2  FCB   7,16
        FDB   HLKRD2
HLKRP3  FCB   7,16
        FDB   HLKRD3
HLKDP1  FCB   7,16
        FDB   HLKDD1
HLKDP2  FCB   7,16
        FDB   HLKDD2
HLKDP3  FCB   7,16
        FDB   HLKDD3
HLKLD1  EQU   *
        FCB   $00,$00,$0B,$BB,$00,$00,$00
        FCB   $00,$00,$00,$10,$00,$00,$00
        FCB   $00,$00,$00,$10,$00,$00,$00
        FCB   $00,$06,$66,$AA,$66,$00,$00
        FCB   $00,$06,$66,$AA,$66,$00,$00
        FCB   $00,$06,$66,$AA,$66,$00,$00
        FCB   $00,$06,$66,$AA,$66,$00,$00
        FCB   $00,$06,$66,$AA,$66,$00,$00
        FCB   $00,$06,$66,$AA,$66,$00,$00
        FCB   $00,$06,$6A,$AA,$66,$00,$00
        FCB   $00,$00,$00,$11,$00,$00,$00
        FCB   $00,$00,$00,$11,$00,$00,$00
        FCB   $00,$00,$00,$11,$00,$00,$00
        FCB   $00,$00,$11,$11,$00,$00,$00
        FCB   $00,$00,$00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00,$00,$00
HLKLD2  EQU   *
        FCB   $00,$00,$0B,$BB,$00,$00,$00
        FCB   $00,$00,$00,$10,$00,$00,$00
        FCB   $00,$00,$00,$10,$00,$00,$00
        FCB   $00,$06,$66,$AA,$66,$00,$00
        FCB   $00,$06,$66,$AA,$A6,$00,$00
        FCB   $00,$06,$66,$6A,$AA,$00,$00
        FCB   $00,$06,$66,$66,$AA,$A0,$00
        FCB   $00,$A6,$66,$66,$6A,$A0,$00
        FCB   $0A,$A6,$66,$66,$A6,$00,$00
        FCB   $00,$06,$66,$66,$66,$00,$00
        FCB   $00,$00,$11,$01,$10,$00,$00
        FCB   $10,$01,$10,$00,$11,$10,$00
        FCB   $01,$11,$00,$00,$00,$11,$00
        FCB   $00,$10,$00,$00,$11,$10,$00
        FCB   $00,$00,$00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00,$00,$00
HLKLD3  EQU   *
        FCB   $00,$00,$0B,$BB,$00,$00,$00
        FCB   $00,$00,$00,$10,$00,$00,$00
        FCB   $00,$00,$00,$10,$00,$00,$00
        FCB   $00,$06,$66,$AA,$66,$00,$00
        FCB   $00,$06,$6A,$AA,$66,$00,$00
        FCB   $00,$06,$AA,$A6,$66,$00,$00
        FCB   $00,$0A,$AA,$66,$66,$00,$00
        FCB   $A0,$AA,$A6,$66,$66,$A0,$00
        FCB   $0A,$A6,$66,$66,$66,$AA,$00
        FCB   $00,$06,$66,$66,$66,$00,$00
        FCB   $00,$00,$11,$01,$10,$00,$00
        FCB   $10,$01,$10,$00,$11,$10,$00
        FCB   $01,$11,$00,$00,$00,$11,$00
        FCB   $00,$10,$00,$00,$11,$10,$00
        FCB   $00,$00,$00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00,$00,$00
HLKDD1  EQU   *
        FCB   $00,$00,$0B,$BB,$00,$00,$00
        FCB   $00,$00,$00,$10,$00,$00,$00
        FCB   $00,$00,$00,$10,$00,$00,$00
        FCB   $AA,$A6,$66,$66,$66,$AA,$A0
        FCB   $AA,$A6,$66,$66,$66,$AA,$A0
        FCB   $AA,$06,$66,$66,$66,$0A,$A0
        FCB   $AA,$06,$66,$66,$66,$0A,$A0
        FCB   $AA,$06,$66,$66,$66,$0A,$A0
        FCB   $AA,$A6,$66,$66,$66,$AA,$A0
        FCB   $A0,$A6,$66,$66,$66,$A0,$A0
        FCB   $A0,$A0,$11,$01,$10,$A0,$A0
        FCB   $00,$00,$11,$01,$10,$00,$00
        FCB   $00,$00,$11,$01,$10,$00,$00
        FCB   $00,$11,$11,$01,$11,$10,$00
        FCB   $00,$00,$00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00,$00,$00
HLKDD2  EQU   *
        FCB   $00,$00,$0B,$BB,$00,$00,$00
        FCB   $00,$00,$00,$10,$00,$00,$00
        FCB   $00,$00,$00,$10,$00,$00,$00
        FCB   $AA,$A6,$66,$66,$66,$AA,$A0
        FCB   $AA,$A6,$66,$66,$66,$AA,$A0
        FCB   $AA,$06,$66,$66,$66,$0A,$A0
        FCB   $AA,$06,$66,$66,$66,$0A,$A0
        FCB   $AA,$06,$66,$66,$66,$0A,$A0
        FCB   $AA,$A6,$66,$66,$66,$AA,$A0
        FCB   $A0,$A6,$66,$66,$66,$A0,$A0
        FCB   $A0,$A0,$11,$01,$10,$A0,$A0
        FCB   $00,$11,$11,$01,$10,$00,$00
        FCB   $00,$00,$00,$01,$10,$00,$00
        FCB   $00,$00,$00,$01,$10,$00,$00
        FCB   $00,$00,$00,$01,$10,$00,$00
        FCB   $00,$00,$00,$01,$11,$10,$00
HLKDD3  EQU   *
        FCB   $00,$00,$0B,$BB,$00,$00,$00
        FCB   $00,$00,$00,$10,$00,$00,$00
        FCB   $00,$00,$00,$10,$00,$00,$00
        FCB   $AA,$A6,$66,$66,$66,$AA,$A0
        FCB   $AA,$A6,$66,$66,$66,$AA,$A0
        FCB   $AA,$06,$66,$66,$66,$0A,$A0
        FCB   $AA,$06,$66,$66,$66,$0A,$A0
        FCB   $AA,$06,$66,$66,$66,$0A,$A0
        FCB   $AA,$A6,$66,$66,$66,$AA,$A0
        FCB   $A0,$A6,$66,$66,$66,$A0,$A0
        FCB   $A0,$A0,$11,$01,$10,$A0,$A0
        FCB   $00,$00,$11,$01,$11,$10,$00
        FCB   $00,$00,$11,$00,$00,$00,$00
        FCB   $00,$00,$11,$00,$00,$00,$00
        FCB   $00,$00,$11,$00,$00,$00,$00
        FCB   $00,$11,$11,$00,$00,$00,$00
HLKRD1  EQU   *
        FCB   $00,$00,$BB,$B0,$00,$00,$00
        FCB   $00,$00,$01,$00,$00,$00,$00
        FCB   $00,$00,$01,$00,$00,$00,$00
        FCB   $00,$66,$AA,$66,$60,$00,$00
        FCB   $00,$66,$AA,$66,$60,$00,$00
        FCB   $00,$66,$AA,$66,$60,$00,$00
        FCB   $00,$66,$AA,$66,$60,$00,$00
        FCB   $00,$66,$AA,$66,$60,$00,$00
        FCB   $00,$66,$AA,$66,$60,$00,$00
        FCB   $00,$66,$AA,$A6,$60,$00,$00
        FCB   $00,$00,$11,$00,$00,$00,$00
        FCB   $00,$00,$11,$00,$00,$00,$00
        FCB   $00,$00,$11,$00,$00,$00,$00
        FCB   $00,$00,$11,$11,$00,$00,$00
        FCB   $00,$00,$00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00,$00,$00
HLKRD2  EQU   *
        FCB   $00,$00,$BB,$B0,$00,$00,$00
        FCB   $00,$00,$01,$00,$00,$00,$00
        FCB   $00,$00,$01,$00,$00,$00,$00
        FCB   $00,$66,$AA,$66,$60,$00,$00
        FCB   $00,$6A,$AA,$66,$60,$00,$00
        FCB   $00,$AA,$A6,$66,$60,$00,$00
        FCB   $0A,$AA,$66,$66,$60,$00,$00
        FCB   $0A,$A6,$66,$66,$6A,$00,$00
        FCB   $00,$6A,$66,$66,$6A,$A0,$00
        FCB   $00,$66,$66,$66,$60,$00,$00
        FCB   $00,$01,$10,$11,$00,$00,$00
        FCB   $01,$11,$00,$01,$10,$01,$00
        FCB   $11,$00,$00,$00,$11,$10,$00
        FCB   $01,$11,$00,$00,$01,$00,$00
        FCB   $00,$00,$00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00,$00,$00
HLKRD3  EQU   *
        FCB   $00,$00,$BB,$B0,$00,$00,$00
        FCB   $00,$00,$01,$00,$00,$00,$00
        FCB   $00,$00,$01,$00,$00,$00,$00
        FCB   $00,$66,$AA,$66,$60,$00,$00
        FCB   $00,$66,$AA,$A6,$60,$00,$00
        FCB   $00,$66,$6A,$AA,$60,$00,$00
        FCB   $00,$66,$66,$AA,$A0,$A0,$00
        FCB   $0A,$66,$66,$6A,$AA,$00,$00
        FCB   $AA,$66,$66,$66,$60,$00,$00
        FCB   $00,$66,$66,$66,$60,$00,$00
        FCB   $00,$01,$10,$11,$00,$00,$00
        FCB   $01,$11,$00,$01,$10,$01,$00
        FCB   $11,$00,$00,$00,$11,$10,$00
        FCB   $01,$11,$00,$00,$01,$00,$00
        FCB   $00,$00,$00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00,$00,$00
;        END  