;        OPT   NOL
;        LIB   "src/RRF.ASM"
;        OPT   LIS
;        STTL  T A N K ........
        ORG   RTKORG
;*
;*VECTORS
;*
        JMP   TNKSTV
        JMP   SQSTV
        FDB   SQP0
        FDB   MTNKP1
        FDB   TNKP1
;*
;*SOUNDS
;*
TNKSND  FCB   $D0,$01,$08,$11,0 ;TANK KILL
TKFSND  FCB   $C8,$01,$08,$04,0 ;TANK FIRE
SRBSND  FCB   $C8,$01,$04,$14,$01,$01,$13,0 ;SHELL REBOUND
SHKSND  FCB   $D0,$01,$03,$01,$01,$04,$15,$01,$04,$13,0 ;SHELL KILL
SQKSND  FCB   $D0,$01,$04,$15,$01,$08,$11,0 ;SQUARE KILL
TKDSND  FCB   $D0,$01,$08,$19,0 ;TANK DROP
;*
;*START SQUARES
;*PD=OBJ,PD2=TIME TO DROP,PD3=#,PD7=ND TIM
;*
SQSTV   LDA   SQCNT
        PSHS  A
        BEQ   SQSTX
SQST1   MKPROB SQUARE,SQP1,SQKIL
        BEQ   SQSTX            ;NONE LEFT
        LDB   #YMIN+2
        JSR   RAND
        BPL   SQST2
        LDB   #YMAX-14
SQST2   LDA   #XMAX-XMIN-10
        JSR   RANDU
        ADDA  #XMIN-1
        STD   OBJX,X
        STA   OX16,X
        STB   OY16,X
        LDA   TDPTIM           ;TIME TO DROP TANKS
        JSR   RMAX
        STA   PD2,U
        LDA   ENFNUM
        JSR   RMAX             ;# TO DROP
        LSRA 
        ADCA  #0
        STA   PD3,U
        LDD   #SQP4
        STD   FONIPC,X
        STX   OPTR
        JSR   SQVEL
        DEC   ,S
        BNE   SQST1
SQSTX   PULS  A,PC
;*
;*GET A NEW SQUARE VELOCITY
;*
SQVEL   LDA   SQSPD
        JSR   RMAX
        LDB   OX16,X
        CMPB  #XMIN+5
        BLS   SQV1
        CMPB  #XMAX-12
        BHS   SQV1N
        LDB   LSEED
        BPL   SQV1
SQV1N   NEGA 
SQV1    TFR   A,B
        SEX  
        ASLB 
        ROLA 
        ASLB 
        ROLA 
        STD   OXV,X
        LDA   SQSPD
        JSR   RMAX
        LDB   OY16,X
        CMPB  #YMIN+5
        BLS   SQV2
        CMPB  #YMAX-20
        BHS   SQV2N
        LDB   HSEED
        BMI   SQV2
SQV2N   NEGA 
SQV2    TFR   A,B
        SEX  
        ASLB 
        ROLA 
        ASLB 
        ROLA 
        ASLB 
        ROLA 
        STD   OYV,X
        LDA   SEED
        ANDA  #$1F
        INCA 
        STA   PD7,U            ;ND TIMR
        RTS  
;*
;*KILL A SQUARE
;*
SQKIL   LDA   PCFLG
        BNE   SQKX
        JSR   KILOFP
        LDU   OFREE            ;GET BACK YOUR OBJ GUY
        LDD   ,U
        STD   OFREE
        MAKP  CIRKV
        STU   PD,X
        LDD   #SQP1
        STD   OPICT,U
        LDD   #$DDDD           ;COLORS
        STD   PD4,X
        LDA   #8
        STA   PD6,X
        LDD   #SQKSND
        JSR   SNDLD
        LDD   #$0210
        JSR   SCORE
        DEC   SQCNT
SQKX    RTS  
;*
;*SQUARE PROCESS
;*PD=OBJ,PD2=TIME TO DROP,PD3=#,PD7=ND TIMR
;*
SQUARE  LDX   PD,U
        LDD   OPICT,X
        ADDD  #4
        CMPD  #SQP4
        BLS   SQ1
        LDD   #SQP0
        TST   STATUS
        BNE   SQ1              ;IDLE
        DEC   PD2,U
        BEQ   SQ2
SQ1     STD   OPICT,X
        DEC   PD7,U
        BNE   SQ1A
        JSR   SQVEL
SQ1A    NAP   3,SQUARE
;*DROP MODE
SQ2     LDA   TDPTIM           ;INTER DROP TIME CALC
        LSRA 
        INCA 
        JSR   RMAX
        STA   PD2,U
SQ2L    LDX   PD,U
        DEC   PD2,U
        BNE   SQ2B
        LDA   OVCNT
        CMPA  #17
        BHS   SQ2
        LDA   FREE             ;ANY RESOURCES
        ORA   OFREE
        BEQ   SQ2              ;NADA
        LDA   TNKCNT
        CMPA  #20              ;MAX TANKS
        BHS   SQ2              ;YES
        JSR   TNKDRP
        DEC   PD3,U
        BEQ   SQ3              ;DONE!!
        BRA   SQ2
SQ2B    LDD   OPICT,X
        ADDD  #4
        CMPD  #SQP8
        BLS   SQ2C
        LDD   #SQP0
SQ2C    STD   OPICT,X
        DEC   PD7,U
        BNE   SQ2D
        JSR   SQVEL
SQ2D    NAP   3,SQ2L
;*FLEE MODE....
SQ3     LDD   #0
        STD   OXV,X
        LDD   #$0200
        TST   SEED
        BPL   SQ3A
        NEGA 
SQ3A    STD   OYV,X
SQ3L    LDX   PD,U
        LDD   OPICT,X
        SUBD  #4
        CMPD  #SQP0
        BHS   SQ3B
        LDA   OY16,X
        CMPA  #YMIN+2
        BLS   SQ4
        CMPA  #YMAX-16
        BHS   SQ4
        LDD   #SQP8
SQ3B    STD   OPICT,X
        NAP   3,SQ3L
;*ALL DONE..
SQ4     JSR   KILLOF
        DEC   SQCNT
        JMP   SUCIDE
;*
;*DROP OFF A TANK
;*X=SQUARE OBJ
TNKDRP  PSHS  X,Y,D,U
        LEAY  ,X
        MAKP  MTANKS
        LEAU  ,X
        JSR   GETROB
        INC   TNKCNT
        LDD   #MTNKP1
        STD   OPICT,X
        STD   OLDPIC,X
        STU   OBJID,X
        STX   PD,U
        LDD   #TNKIL
        STD   OCVECT,X
        LDD   #TKDSND          ;MAKE A SOUND
        JSR   SNDLD
        LDD   OBJX,Y
        CMPB  #YMIN
        BEQ   TNKDP1
        DECB 
TNKDP1  ADDD  #$0206           ;OFFSET
        STD   OBJX,X
        STA   OX16,X
        STB   OY16,X
        JSR   TNKND
        LDA   TNKSHT
        STA   PD6,U
        JSR   DMAON            ;ON YOUR TANKS
        PULS  X,Y,D,U,PC

        FCC   " (C) WILLIAMS ELECTRONICS INC. "
;*
;*START A TANK
;*PD=OBJ,PD4=DX,DY,PD6=SHOT TIMR,PD7=ND TIMR
;*
TNKSTV  LDA   TNKCNT
        PSHS  A
        BEQ   TNKSTX
TNKSTL  MAKP  TANK
        LEAU  ,X
        JSR   GETROB
        LDD   #TNKP1
        STD   OPICT,X
        STD   OLDPIC,X
        STU   OBJID,X
        STX   PD,U
        LDD   #TNKIL
        STD   OCVECT,X
        JSR   SAFTY
TNKST0  JSR   RANDXY
        CMPB  XTEMP            ;CHECK SAFETY BOX
        BLS   TNKST1
        CMPB  XTEMP+1
        BHS   TNKST1
        CMPA  XTEMP2
        BLS   TNKST1
        CMPA  XTEMP2+1
        BLS   TNKST0
TNKST1  STD   OBJX,X
        STA   OX16,X
        STB   OY16,X
        JSR   TNKND            ;GET NEW DIR
        LDA   SEED
        ANDA  #$1F
        ADDA  TNKSHT
        STA   PD6,U
        JSR   OPON1
        DEC   ,S
        BNE   TNKSTL
TNKSTX  PULS  A,PC
;*
;*MINI TANK GROW
;*
MTANK   LDX   PD,U
        JSR   DMAOFF
        LDD   OBJX,X
        LDY   OPICT,X
        ADDA  4,Y
        ADDB  5,Y
        STA   OX16,X           ;OFFSET
        STB   OY16,X
        LEAY  6,Y
        STY   OPICT,X
        JSR   DMAON
        CMPY  #TNKP1
        BHS   TANK
MTANKS  NAP   12,MTANK
;*
;*TANK PROCESS
;*PD=OBJ,PD4=DX,DY,PD6=SHOT TIMER,PD7=ND TIMR
;*
TANK    LDA   STATUS
        BITA  #$7F
        BEQ   TANKL
        NAP   15,TANK
TANKL   LDX   PD,U
        DEC   PD6,U            ;SHOT?
        BNE   TANK1
        JSR   TNKFIR
TANK1   LDA   PD4,U
        CLRB 
        ASRA 
        RORB 
        ADDD  OX16,X
        PSHS  D
        LDB   PD5,U
        ADDB  OY16,X
        JSR   CKLIM            ;IN BOUNDS????
        BEQ   TANK3            ;O.K.
        LEAS  2,S              ;OUT OF BOUNDS
        BRA   TANKND           ;GET A NEW DIR ON LIFE
TANK3   STB   OY16,X
        PULS  D
        STD   OX16,X
        LDD   OPICT,X
        TST   PD4,U
        BPL   TANK4            ;POS DIRECTION
        SUBD  #4
        CMPD  #TNKP1
        BHS   TANK5
        LDD   #TNKP4
        BRA   TANK5
TANK4   ADDD  #4
        CMPD  #TNKP4
        BLS   TANK5
        LDD   #TNKP1
TANK5   STD   OPICT,X
        JSR   DMAOFN           ;MAKE YOUR MOVE
        DEC   PD7,U
        BNE   TANK6
TANKND  JSR   TNKND
TANK6   LDA   TNKSPD
        LDX   #TANKL
        JMP   SLEEP
;*
;*KILL TANK
;*X=OBJ
TNKIL   LDA   PCFLG
        BNE   TNKILX
        DEC   TNKCNT
        JSR   HVEXST           ;BLOW HIM
        JSR   KILROB
        LDX   OBJID,X
        JSR   KILL
        LDD   #$0120
        JSR   SCORE
        LDD   #TNKSND
        JSR   SNDLD
TNKILX  RTS  
;*
;*TANK NEW DIRECTION
;*X=OBJ,PD4=DX,DY,PD7=ND TIMER
TNKND   LDA   SEED
        CMPA  #$60
        BLS   TNKND0           ;SEEK PLAYER
        JSR   RANDXY
        BRA   TNKND1
TNKND0  LDD   PX
TNKND1  STD   XTEMP
        SUBB  OBJY,X
        BHS   TNKND2
        NEGB 
TNKND2  CMPB  #16
        BHS   TNDXY
        CLRB 
        BRA   TNDXY1
TNDXY   LDD   XTEMP
        CMPB  OBJY,X
        LDB   #$01
        BCC   TNDXY1
        NEGB 
TNDXY1  CMPA  OBJX,X
        LDA   #1
        BCC   TNKNDX
        NEGA 
TNKNDX  STD   PD4,U
        LDA   SEED
        ANDA  #$1F
        INCA 
        STA   PD7,U
        RTS  
;*
;*TANK FIRE
;*PD6=SHOT TIMR
TNKFIR  PSHS  X,U
        LEAY  ,X
        LDA   TNKSHT
TNKF1   STA   PD6,U            ;SHOT RATE
        LDA   OVCNT
        CMPA  #17
        LBHS  TNKFX            ;OLOAD NO SHOOT
        LDA   SHLCNT
        CMPA  #20
        LBHI  TNKFX
        INC   SHLCNT
        MKPROB SHELL,SHLP1,SHLKIL
        LBEQ  TNKFX
        LDD   OBJX,Y
        ADDD  #$0100           ;CENTER SHOT
        STA   OX16,X
        STB   OY16,X
        STD   OBJX,X
        LDB   #$80
        CMPB  SEED
        BLS   TNKFRB           ;REBOUND SHOT
        LDB   LSEED
        ANDB  #$1F
        ADDB  #-$10
        LDA   PX
        CMPA  #$11
        BHS   TNKF2
        CLRB 
TNKF2   ADDB  PX
        CLRA 
        SUBB  OBJX,X
        SBCA  #0
        PSHS  A
        BPL   TNKF3
        NEGB 
TNKF3   LDA   SHLSPD
        MUL  
        TFR   A,B
        LDA   ,S+
        BPL   TNKF4
        COMB 
TNKF4   ASLB 
        ROLA 
        ASLB 
        ROLA 
        ASLB 
        ROLA 
        STD   OXV,X
        LDB   LSEED
        ANDB  #$1F
        ADDB  #-$10
        ADDB  PX+1
        CLRA 
        SUBB  OBJY,X
        SBCA  #0
        PSHS  A
        BPL   TNKF5
        NEGB 
TNKF5   LDA   SHLSPD
        MUL  
        TFR   A,B
        LDA   ,S+
        BPL   TNKF6
        COMB 
TNKF6   ASLB 
        ROLA 
        ASLB 
        ROLA 
        ASLB 
        ROLA 
        STD   OYV,X
        JMP   TNKFX1
;*FIRE A REBOUND
TNKFRB  JSR   RAND
        LSRA 
        BCS   TRBY             ;Y DIRECTION
        CLRA 
        LDB   SEED
        ANDB  #$1F
        ADDB  #-$10
        ADDB  OBJY,X
        ADDB  PX+1
        ADCA  #0
        LSRA 
        RORB 
        LDA   LSEED
        ANDA  #7
        BEQ   TNKFR2
        LDA   PX
        CMPA  #(XMAX+XMIN)/2
        BLO   TNKFR3
TNKFR1  LDA   #XMAX
        BRA   TRBXY
TNKFR2  LDA   PX
        CMPA  #(XMAX+XMIN)/2
        BLS   TNKFR1
TNKFR3  LDA   #XMIN
        BRA   TRBXY
TRBY    CLRA 
        LDB   SEED
        ANDB  #$F
        ADDB  #-8
        ADDB  OBJX,X
        ADDB  PX
        ADCA  #0
        LSRA 
        RORB 
        LDA   LSEED
        ANDA  #7
        BEQ   TRBY02
        LDA   PX+1
        CMPA  #(YMAX+YMIN)/2
        BLO   TRBY03
TRBY01  LDA   #YMAX
        BRA   TRBY1
TRBY02  LDA   PX+1
        CMPA  #(YMAX+YMIN)/2
        BLS   TRBY01
TRBY03  LDA   #YMIN
TRBY1   EXG   A,B
TRBXY   STA   XTEMP
        CLRA 
        SUBB  OBJY,X
        SBCA  #0
        STD   OYV,X
        LDB   XTEMP
        CLRA 
        SUBB  OBJX,X
        SBCA  #0
        STD   OXV,X
        LDB   SHLSPD
        LDA   #$40             ;ADJUST FACTOR
        MUL  
        TFR   A,B
        CLRA 
        ASLB 
        ROLA 
        ASLB 
        ROLA 
        PSHS  D
        COMA 
        COMB 
        PSHS  D
        ASLB 
        ROLA 
        PSHS  D
        COMA 
        COMB 
        PSHS  D
        LDD   OXV,X
TRBXYL  CMPD  4,S
        BLE   TNKFX0
        CMPD  6,S
        BGE   TNKFX0
        LDD   OYV,X
        CMPD  2,S
        BLE   TNKFX0
        CMPD  0,S
        BGE   TNKFX0
        ASLB 
        ROLA 
        STD   OYV,X
        LDD   OXV,X
        ASLB 
        ROLA 
        STD   OXV,X
        BRA   TRBXYL
TNKFX0  LEAS  8,S              ;GET RID OF THE SHIT!!!
TNKFX1  STX   OPTR             ;LINK HIM IN
        LDA   HSEED
        ANDA  #$1F
        ADDA  #$30
        STA   PD7,U            ;HOT LIFETIME
        LDD   #TKFSND
        JSR   SNDLD            ;MAKE A FIRE SOUND
TNKFX   PULS  X,U,PC
;*
;*TANK SHELL PROCESS
;*PD=OBJ,PD7=LIFETIME
SHELL   LDX   PD,U
        LDD   OX16,X
        ADDD  OXV,X
        CMPA  #XMIN
        BLO   XVNEG
        CMPA  #XMAX-4
        BHI   XVNEG
        LDD   OY16,X
        ADDD  OYV,X
        CMPA  #YMIN
        BLO   YVNEG
        CMPA  #YMAX-7
        BHI   YVNEG
        DEC   PD7,U
        BEQ   SHLDIE           ;LIFETIME OVER
SHELLP  NAP   2,SHELL
SHLDIE  JSR   KILLOF
        JMP   SUCIDE
XVNEG   COM   OXV,X
        COM   OXV+1,X
        BRA   SHNEG
YVNEG   COM   OYV,X
        COM   OYV+1,X
SHNEG   LDD   #SRBSND          ;MAKE REBOUND SOUND
        JSR   SNDLD
        BRA   SHELLP
;*
;*KILL A SHELL
;*X=OBJ
SHLKIL  LDA   PCFLG
        BNE   SHLKX
        DEC   SHLCNT
        JSR   EXST
        JSR   KILOFP
        LDD   #$0025
        JSR   SCORE
        LDD   #SHKSND
        JMP   SNDLD
SHLKX   RTS  
;*
;*PURTY PITCHERS
;*
SHLP1   FCB   4,7
        FDB   SHLD1
SHLD1   EQU   *
        FDB   $000A,$0000
        FDB   $0ACC,$CA00
        FDB   $0C0B,$0CA0
        FDB   $ACBB,$BCA0
        FDB   $0C0B,$0CA0
        FDB   $0ACC,$CA00
        FDB   $000A,$0000
MTNKP1  FCB   2,4              ;W,H
        FDB   MTNKD1           ;DATA PTR
        FCB   $FF,$FF          ;DELTA X,Y
MTNKP2  FCB   4,7
        FDB   MTNKD2
        FCB   0,$FF
MTNKP3  FCB   4,8
        FDB   MTNKD3
        FCB   $FF,$FE
MTNKP4  FCB   6,12
        FDB   MTNKD4
        FCB   $00,$FE
TNKP1   FCB   7,16
        FDB   TNKD1
TNKP2   FCB   7,16
        FDB   TNKD2
TNKP3   FCB   7,16
        FDB   TNKD3
TNKP4   FCB   7,16
        FDB   TNKD4
MTNKD1  EQU   *
        FDB   $0100
        FDB   $1110
        FDB   $1110
        FDB   $9790
MTNKD2  EQU   *
        FDB   $0011,$0000
        FDB   $0011,$0000
        FDB   $1111,$1100
        FDB   $1666,$6100
        FDB   $1111,$1100
        FDB   $7979,$7900
        FDB   $0797,$9000
MTNKD3  EQU   *
        FDB   $0011,$1000
        FDB   $0019,$1000
        FDB   $1111,$1110
        FDB   $1660,$6610
        FDB   $1606,$0610
        FDB   $1111,$1110
        FDB   $9779,$7790
        FDB   $0797,$7900
MTNKD4  EQU   *
        FDB   $0000,$1111,$0000
        FDB   $0000,$1991,$0000
        FDB   $0000,$1111,$0000
        FDB   $0000,$0110,$0000
        FDB   $0011,$1111,$1100
        FDB   $0010,$6006,$0100
        FDB   $0016,$0660,$6100
        FDB   $0010,$6006,$0100
        FDB   $0011,$1111,$1100
        FDB   $0097,$7977,$9700
        FDB   $0700,$0000,$0070
        FDB   $0079,$7797,$7900
SQP0    FCB   8,15
        FDB   SQD0
SQP1    FCB   8,15
        FDB   SQD1
SQP2    FCB   8,15
        FDB   SQD2
SQP3    FCB   8,15
        FDB   SQD3
SQP4    FCB   8,15
        FDB   SQD4
SQP5    FCB   8,15
        FDB   SQD5
SQP6    FCB   8,15
        FDB   SQD6
SQP7    FCB   8,15
        FDB   SQD7
SQP8    FCB   8,15
        FDB   SQD8

;        IF    NOL         ;Fixme was: IFC   &A,NOL
;        OPT   NOL
;        ENDIF

SQD0    EQU   *
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$00EE,$E000,$0000
        FDB   $0000,$00EA,$E000,$0000
        FDB   $0000,$00EE,$E000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
SQD1    EQU   *
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$00EE,$E000,$0000
        FDB   $0000,$00EA,$E000,$0000
        FDB   $0000,$00EE,$E000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
SQD2    EQU   *
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0EEE,$EE00,$0000
        FDB   $0000,$0EA0,$AE00,$0000
        FDB   $0000,$0E0A,$0E00,$0000
        FDB   $0000,$0EA0,$AE00,$0000
        FDB   $0000,$0EEE,$EE00,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
SQD3    EQU   *
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$EEEE,$EEE0,$0000
        FDB   $0000,$EA00,$0AE0,$0000
        FDB   $0000,$E0A0,$A0E0,$0000
        FDB   $0000,$E00A,$00E0,$0000
        FDB   $0000,$E0A0,$A0E0,$0000
        FDB   $0000,$EA00,$0AE0,$0000
        FDB   $0000,$EEEE,$EEE0,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
SQD4    EQU   *
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $000E,$EEEE,$EEEE,$0000
        FDB   $000E,$A000,$00AE,$0000
        FDB   $000E,$0A00,$0A0E,$0000
        FDB   $000E,$00A0,$A00E,$0000
        FDB   $000E,$0000,$000E,$0000
        FDB   $000E,$00A0,$A00E,$0000
        FDB   $000E,$0A00,$0A0E,$0000
        FDB   $000E,$A000,$00AE,$0000
        FDB   $000E,$EEEE,$EEEE,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
SQD5    EQU   *
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $00EE,$00EE,$E00E,$E000
        FDB   $00EA,$0000,$000A,$E000
        FDB   $0000,$A000,$00A0,$0000
        FDB   $0000,$0A00,$0A00,$0000
        FDB   $00E0,$00E0,$E000,$E000
        FDB   $00E0,$0000,$0000,$E000
        FDB   $00E0,$00E0,$E000,$E000
        FDB   $0000,$0A00,$0A00,$0000
        FDB   $0000,$A000,$00A0,$0000
        FDB   $00EA,$0000,$000A,$E000
        FDB   $00EE,$00EE,$E00E,$E000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
SQD6    EQU   *
        FDB   $0000,$0000,$0000,$0000
        FDB   $0EE0,$00EE,$E000,$EE00
        FDB   $0EA0,$0000,$0000,$AE00
        FDB   $000A,$0000,$000A,$0000
        FDB   $0000,$A000,$00A0,$0000
        FDB   $0000,$0E00,$0E00,$0000
        FDB   $0E00,$0000,$0000,$0E00
        FDB   $0E00,$0000,$0000,$0E00
        FDB   $0E00,$0000,$0000,$0E00
        FDB   $0000,$0E00,$0E00,$0000
        FDB   $0000,$A000,$00A0,$0000
        FDB   $000A,$0000,$000A,$0000
        FDB   $0EA0,$0000,$0000,$AE00
        FDB   $0EE0,$00EE,$E000,$EE00
        FDB   $0000,$0000,$0000,$0000
SQD7    EQU   *
        FDB   $E000,$000E,$0000,$00E0
        FDB   $0A00,$000E,$0000,$0A00
        FDB   $00A0,$0000,$0000,$A000
        FDB   $000A,$0000,$000A,$0000
        FDB   $0000,$E000,$00E0,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $EE00,$0000,$0000,$0EE0
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$E000,$00E0,$0000
        FDB   $000A,$0000,$000A,$0000
        FDB   $00A0,$0000,$0000,$A000
        FDB   $0A00,$000E,$0000,$0A00
        FDB   $E000,$000E,$0000,$00E0
SQD8    EQU   *
        FDB   $0000,$000E,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $E000,$0000,$0000,$00E0
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$000E,$0000,$0000
;*TANK DATA
TNKD1   FCB   $00,$00,$11,$11,$10,$00,$00
        FCB   $00,$00,$19,$09,$10,$00,$00
        FCB   $00,$00,$10,$00,$10,$00,$00
        FCB   $00,$00,$11,$11,$10,$00,$00
        FCB   $00,$00,$00,$10,$00,$00,$00
        FCB   $01,$11,$11,$11,$11,$11,$00
        FCB   $01,$00,$00,$00,$00,$01,$00
        FCB   $01,$06,$60,$00,$66,$01,$00
        FCB   $01,$06,$06,$06,$06,$01,$00
        FCB   $01,$00,$66,$66,$60,$01,$00
        FCB   $01,$00,$00,$00,$00,$01,$00
        FCB   $01,$11,$11,$11,$11,$11,$00
        FCB   $09,$77,$79,$77,$79,$77,$00
        FCB   $70,$00,$00,$00,$00,$00,$70
        FCB   $07,$00,$00,$00,$00,$09,$00
        FCB   $00,$79,$77,$79,$77,$70,$00

TNKD2   FCB   $00,$00,$11,$11,$10,$00,$00
        FCB   $00,$00,$19,$09,$10,$00,$00
        FCB   $00,$00,$10,$00,$10,$00,$00
        FCB   $00,$00,$11,$11,$10,$00,$00
        FCB   $00,$00,$00,$10,$00,$00,$00
        FCB   $01,$11,$11,$11,$11,$11,$00
        FCB   $01,$00,$00,$00,$00,$01,$00
        FCB   $01,$06,$06,$06,$66,$01,$00
        FCB   $01,$06,$06,$00,$00,$01,$00
        FCB   $01,$06,$06,$66,$66,$01,$00
        FCB   $01,$00,$00,$00,$00,$01,$00
        FCB   $01,$11,$11,$11,$11,$11,$00
        FCB   $07,$97,$77,$97,$77,$97,$00
        FCB   $70,$00,$00,$00,$00,$00,$70
        FCB   $07,$00,$00,$00,$00,$07,$00
        FCB   $00,$97,$77,$97,$77,$90,$00

TNKD3   FCB   $00,$00,$11,$11,$10,$00,$00
        FCB   $00,$00,$10,$00,$10,$00,$00
        FCB   $00,$00,$10,$00,$10,$00,$00
        FCB   $00,$00,$11,$11,$10,$00,$00
        FCB   $00,$00,$00,$10,$00,$00,$00
        FCB   $01,$11,$11,$11,$11,$11,$00
        FCB   $01,$00,$00,$00,$00,$01,$00
        FCB   $01,$00,$66,$06,$60,$01,$00
        FCB   $01,$06,$06,$06,$06,$01,$00
        FCB   $01,$06,$60,$60,$66,$01,$00
        FCB   $01,$00,$00,$00,$00,$01,$00
        FCB   $01,$11,$11,$11,$11,$11,$00
        FCB   $07,$79,$77,$79,$77,$79,$00
        FCB   $70,$00,$00,$00,$00,$00,$70
        FCB   $09,$00,$00,$00,$00,$07,$00
        FCB   $00,$77,$79,$77,$79,$70,$00

TNKD4   FCB   $00,$00,$11,$11,$10,$00,$00
        FCB   $00,$00,$10,$00,$10,$00,$00
        FCB   $00,$00,$10,$00,$10,$00,$00
        FCB   $00,$00,$11,$11,$10,$00,$00
        FCB   $00,$00,$00,$10,$00,$00,$00
        FCB   $01,$11,$11,$11,$11,$11,$00
        FCB   $01,$00,$00,$00,$00,$01,$00
        FCB   $01,$06,$66,$06,$06,$01,$00
        FCB   $01,$00,$00,$06,$06,$01,$00
        FCB   $01,$06,$66,$66,$06,$01,$00
        FCB   $01,$00,$00,$00,$00,$01,$00
        FCB   $01,$11,$11,$11,$11,$11,$00
        FCB   $07,$77,$97,$77,$97,$77,$00
        FCB   $90,$00,$00,$00,$00,$00,$90
        FCB   $07,$00,$00,$00,$00,$07,$00
        FCB   $00,$77,$97,$77,$97,$70,$00

;        END  