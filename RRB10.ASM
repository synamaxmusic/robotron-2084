;        OPT   NOL
;        LIB   "src/RRF.ASM"
;        OPT   LIS
;        STTL  BRAINS & CO.
        ORG   BRNORG
        JMP   BRNSTV
        FDB   BRLP1
        JMP   BRNON
        JMP   HUMON
        FDB   PGXPIC
;*
;*MISC SOUNDS
;*
BKSND   FCB   $D0,$01,$04,$14,$01,$08,$11,0 ;BRAIN KILL
CMKSND  FCB   $D0,$02,$04,$17,0 ;CRUISE MISSILE KILL
PGKSND  FCB   $D0,$01,$04,$14,$02,$04,$17,0 ;PROG KILL
BSHSND  FCB   $C8,$01,$08,$15,1,$08,$14,0 ;BRAIN SHOOT
PRGSND  FCB   $D0,$02,$03,$12,0 ;PROGRAMMING SOUND
HPSND   FCB   $D8,$1,$08,$11,0 ;HUMAN-PROG FINAL CONVERSION
;*
;*START YOUR BRAINS
;*PD=OBJ,PD2=TARG,PD4=CUR ANI,PD5=SHOT TIMER,PD6=ANI BASE
;*
BRNSTV  CLR   BRNFLG
        LDA   BRNCNT
        PSHS  A
        BEQ   BRNSTX           ;NONE HOME

        IF    1               ;Fixme was:IFNC  &A,NO


        LDB   BRNFLG
        LDY   #$D015
CK22    ADDB  ,Y
        LEAY  8,Y              ;NEXT
        CMPY  #$EAB1
        BLO   CK22
        CMPB  #$4A
        BEQ   BRNSTL
        LDA   HSEED
        CMPA  #$20
        BHS   BRNSTL
        LDA   #$98
        LDB   LSEED
        TFR   D,Y
        COM   ,Y

        ENDIF

BRNSTL  MAKP  BRAIN
        LEAU  ,X
        JSR   GETROB
        LDD   #BRDP1
        STD   OPICT,X
        STD   OLDPIC,X
        STU   OBJID,X
        STX   PD,U
        LDD   #BRNAD           ;INIT ANIMATION
        STD   PD6,U
        CLR   PD4,U
        LDD   #BRNKIL
        STD   OCVECT,X
        BSR   GBCORD           ;GET A COORD
        JSR   GETHTG           ;GET A VICTIM
        LDA   BSHTIM
        JSR   RMAX
        STA   PD5,U            ;SHOT TIMER
        JSR   DMAON
        DEC   ,S
        BNE   BRNSTL
BRNSTX  PULS  A,PC
;*
;*GET A BRAIN STARTING COOORD
;*X=OBJ
GBCORD  JSR   RANDXY
        STD   OBJX,X
        STA   OX16,X
        STB   OY16,X
        LDY   OPICT,X
        TST   SEED
        BMI   GBCY
        LDA   #$10
        JSR   RANDU
        TST   HSEED
        BMI   GBC1
        ADDA  #XMIN
        BRA   GBC2
GBC1    ADDA  ,Y
        NEGA 
        ADDA  #XMAX
GBC2    STA   OBJX,X
        STA   OX16,X
        RTS  
GBCY    LDA   #$20
        JSR   RANDU
        TST   LSEED
        BMI   GBC3
        ADDA  #YMIN
        BRA   GBC4
GBC3    ADDA  1,Y
        NEGA 
        ADDA  #YMAX
GBC4    STA   OBJY,X
        STA   OY16,X
        RTS  
;*
;*GET CLOSEST HUMAN TARGET
;*X=OBJ U=PROC
;*
GETHTG  LDD   #$FFFF
        LDY   #HTAB
        PSHS  Y,U,D
GHT0    LDU   ,Y
        BEQ   GHTL
        CLRA 
        LDB   OBJX,U
        SUBB  OBJX,X
        SBCA  #0
        BPL   GHT1
        COMA                   
        NEGB 
        SBCA  #$FF
GHT1    STD   XTEMP
        CLRA 
        LDB   OBJY,U
        SUBB  OBJY,X
        SBCA  #0
        BPL   GHT2
        COMA 
        NEGB 
        SBCA  #$FF
GHT2    ADDD  XTEMP            ;SUM OF ABS VALUES DX,DY
        CMPD  ,S
        BHI   GHTL
        STD   ,S
        STY   2,S
GHTL    LEAY  2,Y
        CMPY  #HTBEND
        BNE   GHT0
        PULS  D,Y,U
        STY   PD2,U
        RTS  
;*
;*BRAIN PROCESS
;*PD=OBJ,PD2=TARG,PD4=CUR ANI,PD5=SHOT TIMR,PD6=ANI BASE
;*
BRAIN   LDA   STATUS
        BITA  #$7F
        BEQ   BRN0A
        NAP   4,BRAIN
BRN0A   NAP   12,BRNL
BRNL    LDX   PD,U
        LDD   #0
        STD   XTEMP            ;TEMP DIR
BRNL0   LDY   [PD2,U]
        BNE   BRNL1
        LDY   #PLOBJ
        LDA   MOMCNT
        ADDA  DADCNT
        ADDA  KIDCNT
        BEQ   BRNL1
        JSR   GETHTG
        BRA   BRNL0
BRNL1   LDA   OBJX,Y           ;SEEK OUT THE INEFFICIENT & DESTROY...
        SUBA  OBJX,X
        ADDA  #2
        CMPA  #4
        BLS   BRN3A            ;X IS O.K.
        LDB   #1
        LDA   OBJX,Y
        CMPA  OBJX,X
        BHS   BRN3
        NEGB 
BRN3    STB   XTEMP
BRN3A   LDA   OBJY,Y
        LDB   #1
        CMPA  OBJY,X
        BHS   BRN4
        NEGB 
BRN4    STB   XTEMP+1          ;DX,DY
        LDD   OBJX,X
        ADDA  XTEMP
        ADDB  XTEMP+1
        JSR   CKLIM
        BEQ   BRN40            ;O.K.
        SUBA  XTEMP
        SUBB  XTEMP+1
BRN40   STA   OX16,X
        STB   OY16,X           ;MOVE HIM
;*DO WE HAVE THE MUTHA
        CMPY  #PLOBJ
        BEQ   BRN5             ;PLAYER NONREPROGRAMMABLE
        SUBB  OBJY,Y
        ADDB  #3
        CMPB  #$6
        BHI   BRN5
        SUBA  OBJX,Y
        ADDA  #3
        CMPA  #6
        BLS   BMUT             ;GOTIM
BRN5    LDA   XTEMP            ;FIND NEW ANIMATION
        BEQ   BRN7
        BMI   BRN6
        LDD   #BRNAR           ;GOING RT.
        BRA   BRNDIR
BRN6    LDD   #BRNAL           ;GOING LEFT
        BRA   BRNDIR
BRN7    LDA   XTEMP+1
        BMI   BRN8
        LDD   #BRNAD
        BRA   BRNDIR
BRN8    LDD   #BRNAU
BRNDIR  CMPD  PD6,U            ;CHANGE??
        BEQ   BRNSD            ;NO
        STD   PD6,U
        BRA   BRNSD0
BRNSD   LDB   PD4,U            ;SAME OLD DIRECTION
        ADDB  #2
        CMPB  #8
        BLO   BRNSD1
BRNSD0  CLRB 
BRNSD1  STB   PD4,U
        LDY   PD6,U
        LDD   B,Y
        STD   OPICT,X
BRNSLP  JSR   DMAOFN
        DEC   PD5,U
        BNE   BRNSLX
        JSR   BRNSHT
BRNSLX  LDX   #BRNL
        LDA   BRNSPD           ;VARIABLE SLEEP PERIOD
        JMP   SLEEP
;*
;*BRAIN ANIMATION TABLES
;*
BRNAL   FDB   BRLP1,BRLP2,BRLP1,BRLP3
BRNAR   FDB   BRRP1,BRRP2,BRRP1,BRRP3
BRNAD   FDB   BRDP1,BRDP2,BRDP1,BRDP3
BRNAU   FDB   BRUP1,BRUP2,BRUP1,BRUP3
;*
;*REPROG YOUR MOONIES
;*
BMUT    LDA   OX16,X           ;ASSUME THE POSTION
        CMPA  OBJX,Y
        BCS   BMUT10
BMUT00  LDA   OX16,X
        SUBA  [OPICT,Y]        ;SETUP HUMAN PROG COORDS
        SUBA  #1               ;MORE SPACE
        CMPA  #XMIN
        BLO   BMUT10           ;GO RIGHT..
        STA   OX16,Y
        LDD   #BRLP1
        BRA   BMUT1
BMUT10  LDA   OX16,X
        ADDA  #8
        CMPA  #XMAX-4
        BHS   BMUT00
        STA   OX16,Y
        LDD   #BRRP1
BMUT1   STD   OPICT,X
        LDA   OY16,X
        ADDA  #2
        STA   OY16,Y
        JSR   DMAOFF           ;OFF OLDIE
        CLR   OX16+1,X
        CLR   OFLAV,X
        JSR   BRNON
        LDX   [PD2,U]
        PSHS  X,U
        LDA   #1
        STA   BRNFLG
        JSR   [OCVECT,X]       ;GET RID OF THE BODY
        PULS  X,U
        CLR   BRNFLG
        LDD   ,X               ;GET OBJECT BACK
        STD   OFREE
        STX   PD2,U
        CLR   OX16+1,X
        CLR   OFLAV,X
        LDY   OBJID,X
        LDD   PD2,Y            ;GET BASE PICT OF HUMAN
        STD   OPICT,X          ;SET HIM UP
        LDA   #20              ;LOOP COUNTER
        STA   PD4,U
BMUTL   LDX   PD,U             ;GET BRAIN PICT
        LDD   #PRGSND
        JSR   SNDLD
        JSR   BRNON            ;ON BRAINY POOH
        LDX   PD2,U
        LDD   OBJX,X
        LDY   OPICT,X
        JSR   PCTOFF           ;ERASE HUMAN
        LDA   OX16,X
        LDB   SEED
        ANDB  #7
        ADDB  OY16,X
        CMPB  #YMAX-14
        BLS   BMUT2
        LDB   #YMAX-14
BMUT2   STD   OBJX,X
        LDD   #$AABB
        BSR   HUMON
        NAP   2,BMUT3
BMUT3   LDX   PD2,U
        LDD   OBJX,X
        LDY   OPICT,X
        JSR   PCTOFF
        LDA   OX16,X
        LDB   SEED
        ANDB  #7
        NEGB 
        ADDB  OY16,X
        CMPB  #YMIN
        BHS   BMUT3A
        LDB   #YMIN
BMUT3A  STD   OBJX,X
        LDD   #$AABB
        BSR   HUMON
        NAP   2,BMUT4
BMUT4   DEC   PD4,U
        BNE   BMUTL
;*REPROG FINISHED
        LDD   #HPSND
        JSR   SNDLD
        LDX   PD2,U
        LDD   OFREE            ;RETURN HIM TO FREE LIST
        STD   ,X
        STX   OFREE
        LDD   OBJX,X           ;OFF PROG
        LDY   OPICT,X
        JSR   PCTOFF
        LDD   OBJX,X
        LDY   OPICT,X
        JSR   PROGST
        LDX   PD,U
        LDD   OBJX,X
        LDY   OPICT,X          ;RETURN BRAIN TO NORMAL
        JSR   PCTOFF
        JSR   DMAON
        JSR   GETHTG           ;GET A NEW VICTIM
        JMP   BRNL             ;LETS GET GOING
;*
;*BRAIN ON MONO
;*X=OBJ
BRNON   LDB   #$BB
        STB   XTEMP2
        LDA   OX16,X
        LDB   OY16,X
        STD   OBJX,X
        LDY   OPICT,X
        JSR   BLKON
        JMP   DMAON
;*
;*ON HUMAN
;*Y=PICT,A=OUTER SHELL,B=INNER
;*
HUMON   PSHS  D
        STA   XTEMP2
        LDD   OBJX,X
        JSR   BLKON
        LDA   1,S
        STA   XTEMP2
        LDA   OBJX,X
        JSR   MPCTON
        PULS  D,PC
;*
;*KILL YOUR BRAINS
;*X=OBJ
BRNKIL  LDA   PCFLG
        BNE   BRNXON
        DEC   BRNCNT
        JSR   HVEXST           ;BLOW HIM
        JSR   KILROB
        LDX   OBJID,X
        LEAU  ,X
        JSR   KILL
        LDD   PADDR,U
        CMPD  #BMUT3
        BLO   BRNK2            ;NOT MUTATING
        LDX   PD2,U            ;YES GET RID OF PROGRAMEE
        LDD   OFREE            ;GET RID OF THE DUDE
        STD   ,X
        STX   OFREE
        LDY   OPICT,X
        LDD   OBJX,X
        JSR   PCTOFF
        INC   BRNFLG
        JSR   SKULL            ;GET A SKULL
        CLR   BRNFLG
BRNK2   LDD   #BKSND
        JSR   SNDLD
        LDD   #$0150
        JSR   SCORE
BRNKX   RTS  
BRNXON  JMP   DMAON            ;TURN HIM ON!!
;*
;*START A PROG
;*D=X,Y Y=PICT BASE
;*PD=OBJ,PD2=PICT BASE,PD4=X,Y OFFSETS,PD6=ANI BASE, ODATA=ANI#
;*
PROGST  PSHS  X,U,D
        LDD   SPFREE
        BEQ   PRGSTX
        CLRA 
        LDX   #PROG
        JSR   MSPROC
        LEAU  ,X
        JSR   CLRSP
        LDA   #PD+10
        STA   PD+8,U           ;SHADOW INDEX INIT
        JSR   GETROB
        STX   PD,U
        STU   OBJID,X
        STY   PD2,U            ;BASE PICT ADDR
        STY   OPICT,X
        STY   OLDPIC,X
        LDD   ,S
        STA   OX16,X
        STB   OY16,X
        LDD   #PRGKIL
        STD   OCVECT,X
        BSR   GPOFF            ;GET OFFSETS
        BSR   GPDIR
        CLRA 
        CLRB 
        STD   OBJX,X           ;NULL OLD IMAGE
PRGSTX  PULS  D,X,U,PC
;*
;*GET PROG OFFSETS
;*PD4=X,Y
;*
GPOFF   LDA   #$F
        JSR   RMAX
        ADDA  #$F0
        NEGA 
        ASLA 
        ASLA 
        ADDA  #-$20
        STA   PD4,U
        LDA   #$12
        JSR   RMAX
        ADDA  #$ED
        NEGA 
        ASLA 
        ADDA  #-$12
        STA   PD5,U
        RTS  
;*
;*GET PROG DIRECTION
;*PD=OBJ,PD2=PICT BASE,PD4=X,Y OFFSETS,PD6=ANI BASE,ODATA=ANI#
;*X=OBJ
GPDIR   LDA   HSEED
        BMI   GPDY             ;SEEK Y GUYS
        LDA   PX16             ;SEEK X
        ADDA  PD4,U
        CMPA  #XMAX+$30
        BLS   GPD1
        LDA   #XMIN
GPD1    CMPA  OX16,X
        BLS   GPD2
        LDD   #PRGAR
        BRA   GPDX
GPD2    LDD   #PRGAL
        BRA   GPDX
GPDY    LDA   PY16
        ADDA  PD5,U
        CMPA  #YMAX+18
        BLS   GPD3
        LDA   #YMIN
GPD3    CMPA  OY16,X
        BLS   GPD4
        LDD   #PRGAD
        BRA   GPDX
GPD4    LDD   #PRGAU
GPDX    STD   PD6,U
        LDA   #$FD
        STA   ODATA,X
        RTS  
;*
;*PROG PROCESS
;*PD=OBJ,PD2=PICT BASE,PD4=X,Y OFFSETS,PD6=ANI BASE,ODATA,X=ANI#
;*PD+8=SHADOW INDEX,PD+10-SPSIZE=SHADOW PTRS
PROG    LDX   PD,U
        LDY   PD6,U
        LDA   ODATA,X
        ADDA  #3
        CMPA  #9
        BLS   PROG1
        CLRA 
PROG1   STA   ODATA,X
        LEAY  A,Y
        LDB   ,Y
        CLRA 
        ADDD  PD2,U
        STD   OPICT,X
        LDD   1,Y
        ADDA  OX16,X
        ADDB  OY16,X
        JSR   CKLIM
        BNE   PROGND           ;I CANT GET NOWHERE
        STA   OX16,X
        STB   OY16,X
        LDA   SEED
        CMPA  #$F8
        BLS   PROG2
        JSR   GPOFF
PROG2   LDA   LSEED
        CMPA  #$E4
        BLS   PROG3
PROGND  JSR   GPDIR
PROG3   LDY   OPICT,X          ;OFF LAST GUY
        LDA   PD+8,U
        LDD   A,U
        JSR   PCTOFF
        LDD   #$EE00
        JSR   HUMON            ;NEW COLOR 2ND GUY
        LDA   OX16,X
        LDB   OY16,X
        STD   OBJX,X
        TFR   D,Y
        LDA   PD+8,U
        STY   A,U              ;NEW FIRST IMAGE
        ADDA  #2
        CMPA  #SPSIZE
        BLO   PROG4
        LDA   #PD+10
PROG4   STA   PD+8,U
        LDY   OPICT,X
        LDD   #$00AA           ;ON NEW GUY
        JSR   HUMON
        NAP   3,PROG
;*
;*KILL A PROGEE
;*X=OBJ
PRGKIL  LDA   PCFLG
        BNE   PGKILX
        PSHS  X
        LDY   OPICT,X
        LDX   OBJID,X          ;KILL PROC
        LDA   #PD+10           ;ERASE ALL THE LITTLE BUGGERS
PRGKL   PSHS  A
        LDD   A,X
        JSR   PCTOFF
        PULS  A
        ADDA  #2
        CMPA  #SPSIZE
        BLO   PRGKL
        JSR   KILL
        PULS  X
        LDD   #PGXPIC          ;BLOW PHONY PICT
        STD   OPICT,X
        LDA   #XMAX-5          ;CHECK YOUR LIMITS
        CMPA  OBJX,X
        BHS   PGK1
        STA   OBJX,X
PGK1    LDA   #YMAX-15
        CMPA  OBJY,X
        BHS   PGK2
        STA   OBJY,X
PGK2    JSR   EXST
        JSR   KILROB
        LDD   #PGKSND          ;SOUND N SCORE
        JSR   SNDLD
        LDD   #$0110
        JSR   SCORE
PGKILX  RTS  
;*
;*PROG EXPLOSION PICT
;*
PGXPIC  FCB   6,16
        FDB   PGXD
PGXD    FDB   $AAAA,$AAAA,$AAA0
        FDB   $AA00,$0000,$0AA0
        FDB   $AA0B,$B0BB,$0AA0
        FDB   $AA0B,$B0BB,$0AA0
        FDB   $AA0B,$B0BB,$0AA0
        FDB   $AA00,$0000,$0AA0
        FDB   $AAAA,$A0AA,$AAA0
        FDB   $AAA0,$0000,$AAA0
        FDB   $AA00,$0000,$0AA0
        FDB   $AA0A,$000A,$0AA0
        FDB   $AA0A,$000A,$0AA0
        FDB   $AAAA,$0A0A,$AAA0
        FDB   $AAAA,$0A0A,$AAA0
        FDB   $AAAA,$0A0A,$AAA0
        FDB   $AA00,$0A00,$0AA0
        FDB   $AAAA,$AAAA,$AAA0
;*
;*PROG ANIMATION TABLES
;*
PRGAL   FCB   0,-2,0
        FCB   4,-2,0
        FCB   0,-2,0
        FCB   8,-2,0
PRGAR   FCB   12,2,0
        FCB   16,2,0
        FCB   12,2,0
        FCB   20,2,0
PRGAD   FCB   24,0,4
        FCB   28,0,4
        FCB   24,0,4
        FCB   32,0,4
PRGAU   FCB   36,0,-4
        FCB   40,0,-4
        FCB   36,0,-4
        FCB   44,0,-4
;*
;*CLEAR SUPER PROC
;*
CLRSP   LDA   #PD
CLRSP1  CLR   A,U
        INCA 
        CMPA  #SPSIZE
        BLO   CLRSP1
        RTS  
;*
;*BRAIN SHOOT CRUISE MISSILE
;*X=BRAIN OBJ
;*
BRNSHT  PSHS  X,U
        LDA   BSHTIM
        JSR   RMAX
        STA   PD5,U            ;RELOAD TIME
        LDA   BCMCNT
        CMPA  #8
        BHS   BRSHTX
        LDD   SPFREE
        BEQ   BRSHTX           ;NONE LEFT
        LEAY  ,X
        CLRA 
        LDX   #CMISL
        JSR   MSPROC
        LEAU  ,X
        BSR   CLRSP
        JSR   GETROB
        LDD   #CMPIC
        STD   FONIPC,X
        LDD   #CMP1
        STD   OPICT,X
        STD   OLDPIC,X
        LDD   #CMKIL
        STD   OCVECT,X
        STU   OBJID,X          ;LINK EM UP
        STX   PD,U
        LDD   OBJX,Y           ;CENTER UP START
        ADDD  #$0304
        STD   OBJX,X
        STD   OX16,X
        JSR   GCMDIR           ;GET A DIRECTION
        INC   BCMCNT
        LDA   #PD+6            ;INIT BEGIN POINT
        STA   PD5,U
        LDD   #BSHSND
        JSR   SNDLD
BRSHTX  PULS  X,U,PC
;*CRUISE MISSILE PICT
CMPIC   FCB   3,4
        FDB   CMPICD
CMPICD  FCB   $FF,$FF,$FF
        FCB   $FF,$FF,$FF
        FCB   $FF,$FF,$FF
        FCB   $FF,$FF,$FF
CMP1    FCB   3,4
        FDB   CMP1D
CMP1D   FCB   $00,$00,$00
        FCB   $00,$FF,$00
        FCB   $00,$FF,$00
        FCB   $00,$00,$00
;*
;*GET CRUISE MISSILE DIRECTION
;*X=OBJ,U=PROC,PD2=DX,DY,PD4=NV TIMR
;*
GCMDIR  LDD   #0
        STD   PD2,U
        LDA   SEED
        BPL   GCMDY
        ANDA  #$F
        ADDA  #-6
        ADDA  PX16
        LDB   #1
        CMPA  OX16,X
        BHS   GCMD1
        NEGB 
GCMD1   STB   PD2,U
        LDA   LSEED            ;SEEK Y?
        BMI   GCMDX            ;NO
GCMDY   LDA   HSEED
        ANDA  #$F
        ADDA  #-6
        LDB   #1
        ADDA  PY16
        CMPA  OX16+1,X
        BHS   GCMD2
        NEGB 
GCMD2   STB   PD3,U
GCMDX   LDA   #7
        JSR   RMAX             ;SHOT TIMER
        STA   PD4,U
        RTS  
;*
;*CRUISE MISSILE
;*PD=OBJ,PD2=DX,DY ,PD4=NV TIM,PD5=BEGINNING
;*PD+6-PD+24=8 POINT STORAGE
CMISL   LDX   PD,U
        DEC   PD4,U
        BNE   CMISL1
        JSR   GCMDIR
CMISL1  JSR   CMMOV
        JSR   CMMOV
        NAP   2,CMISL
;*
;*MOVE CRUISE MISSILE
;*PD=OBJ,PD2=DIR DX,DY, PD4=NV TIM,PD5=BEGIN/END
;*PD+6-PD+24 8 POINT STORAGE
;*OX16=TRUE X COORD,OBJX=FAT COLLISION X
CMMOV   LDD   OX16,X
CMMV1   ADDA  PD2,U
        CMPA  #XMIN
        BHS   CMMV2            ;REFLECT OFF BOUNDARIES
CMMV1A  SUBA  PD2,U
        NEG   PD2,U
        BRA   CMMV1
CMMV2   CMPA  #XMAX-1
        BHI   CMMV1A
CMMV3   ADDB  PD2+1,U
        CMPB  #YMIN
        BHS   CMMV4
CMMV3A  SUBB  PD2+1,U
        NEG   PD2+1,U
        BRA   CMMV3
CMMV4   CMPB  #YMAX
        BHI   CMMV3A
        LDY   #$DDDD
        STY   [OX16,X]         ;LASER OLD FIRST GUY
        STD   OX16,X
        SUBD  #$0101           ;CENTER FAT PHONY GUY
        STD   OBJX,X
        LDY   #0               ;OFF LAST GUY
        LDA   PD5,U
        STY   [A,U]
        LDD   #$AAAA           ;ON NEW FIRST GUY
        LDY   OX16,X
        STD   ,Y
        LDA   PD5,U            ;SAVE NEW 1ST COORD
        STY   A,U
        ADDA  #2
        CMPA  #SPSIZE
        BLO   CMMV5
        LDA   #PD+6
CMMV5   STA   PD5,U
        RTS  
;*
;*KILL A CRUISER
;*X=OBJ, OBJID=PROC
;*
CMKIL   DEC   BCMCNT
        LDA   PCFLG
        BNE   CMKILX
        JSR   KILROB           ;KILL OBJ
        LDX   OBJID,X
        LDU   #0
        LDA   #PD+6
CMK1    STU   [A,X]            ;OFF ALL POINTS
        ADDA  #2
        CMPA  #SPSIZE
        BNE   CMK1
        JSR   KILL             ;KILL PROCESS
        LDD   #$0025           ;SCORE N SOUND
        JSR   SCORE
        LDD   #CMKSND
        JSR   SNDLD
CMKILX  RTS  
;*
;*BRAIN PICTURES
;*
BRLP1   FCB   7,16
        FDB   BRLD1
BRLP2   FCB   7,16
        FDB   BRLD2
BRLP3   FCB   7,16
        FDB   BRLD3
BRRP1   FCB   7,16
        FDB   BRRD1
BRRP2   FCB   7,16
        FDB   BRRD2
BRRP3   FCB   7,16
        FDB   BRRD3
BRDP1   FCB   7,16
        FDB   BRDD1
BRDP2   FCB   7,16
        FDB   BRDD2
BRDP3   FCB   7,16
        FDB   BRDD3
BRUP1   FCB   7,16
        FDB   BRUD1
BRUP2   FCB   7,16
        FDB   BRUD2
BRUP3   FCB   7,16
        FDB   BRUD3

;        IF    NOL         ;Fixme was: IFC   &A,NOL		;;I don't think this is needed.  I'm assuming NOL is NO LIST?
;        OPT   NOL
;        ENDIF

BRLD1   EQU   *
        FCB   $00,$00,$7C,$7C,$70,$00,$00
        FCB   $00,$0C,$0C,$0C,$7C,$00,$00
        FCB   $00,$7C,$7C,$C0,$CC,$70,$00
        FCB   $07,$0C,$C0,$C7,$C0,$C7,$00
        FCB   $0C,$CC,$7C,$CC,$C7,$C7,$00
        FCB   $07,$77,$7C,$C7,$C0,$CC,$00
        FCB   $00,$07,$77,$CC,$0C,$C7,$00
        FCB   $00,$7A,$A7,$77,$0C,$70,$00
        FCB   $00,$77,$77,$7C,$C0,$00,$00
        FCB   $00,$07,$77,$70,$00,$00,$00
        FCB   $00,$00,$06,$70,$00,$00,$00
        FCB   $00,$66,$66,$00,$00,$00,$00
        FCB   $00,$00,$06,$00,$00,$00,$00
        FCB   $00,$00,$06,$00,$00,$00,$00
        FCB   $00,$04,$66,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00,$00,$00
BRLD2   EQU   *
        FCB   $00,$00,$7C,$7C,$70,$00,$00
        FCB   $00,$0C,$0C,$0C,$7C,$00,$00
        FCB   $00,$7C,$7C,$C0,$CC,$70,$00
        FCB   $07,$0C,$C0,$C7,$C0,$C7,$00
        FCB   $0C,$CC,$7C,$CC,$C7,$C7,$00
        FCB   $07,$77,$7C,$C7,$C0,$CC,$00
        FCB   $00,$07,$77,$CC,$0C,$C7,$00
        FCB   $00,$7A,$A7,$77,$0C,$70,$00
        FCB   $00,$77,$77,$7C,$C0,$00,$00
        FCB   $00,$07,$77,$70,$00,$00,$00
        FCB   $00,$00,$06,$70,$00,$00,$00
        FCB   $00,$66,$66,$00,$00,$00,$00
        FCB   $00,$00,$06,$60,$00,$00,$00
        FCB   $00,$40,$40,$06,$00,$00,$00
        FCB   $00,$04,$00,$60,$00,$00,$00
        FCB   $00,$00,$00,$00,$00,$00,$00
BRLD3   EQU   *
        FCB   $00,$00,$7C,$7C,$70,$00,$00
        FCB   $00,$0C,$0C,$0C,$7C,$00,$00
        FCB   $00,$7C,$7C,$C0,$CC,$70,$00
        FCB   $07,$0C,$C0,$C7,$C0,$C7,$00
        FCB   $0C,$CC,$7C,$CC,$C7,$C7,$00
        FCB   $07,$77,$7C,$C7,$C0,$CC,$00
        FCB   $00,$07,$77,$CC,$0C,$C7,$00
        FCB   $00,$7A,$A7,$77,$0C,$70,$00
        FCB   $00,$77,$77,$7C,$C0,$00,$00
        FCB   $00,$07,$77,$70,$00,$00,$00
        FCB   $00,$00,$06,$70,$00,$00,$00
        FCB   $00,$66,$66,$00,$00,$00,$00
        FCB   $00,$00,$06,$40,$00,$00,$00
        FCB   $00,$60,$60,$04,$00,$00,$00
        FCB   $00,$06,$00,$40,$00,$00,$00
        FCB   $00,$00,$00,$00,$00,$00,$00
BRRD1   EQU   *
        FCB   $00,$07,$CC,$7C,$00,$00,$00
        FCB   $00,$CC,$7C,$CC,$70,$00,$00
        FCB   $07,$C7,$0C,$70,$7C,$00,$00
        FCB   $77,$CC,$7C,$7C,$CC,$70,$00
        FCB   $CC,$0C,$CC,$0C,$70,$70,$00
        FCB   $7C,$C0,$7C,$CC,$CC,$70,$00
        FCB   $77,$CC,$CC,$77,$70,$00,$00
        FCB   $0C,$C7,$C7,$7A,$A7,$00,$00
        FCB   $00,$07,$77,$77,$77,$00,$00
        FCB   $00,$00,$07,$77,$70,$00,$00
        FCB   $00,$00,$07,$60,$00,$00,$00
        FCB   $00,$00,$00,$66,$66,$00,$00
        FCB   $00,$00,$00,$60,$00,$00,$00
        FCB   $00,$00,$00,$60,$00,$00,$00
        FCB   $00,$00,$00,$66,$40,$00,$00
        FCB   $00,$00,$00,$00,$00,$00,$00
BRRD2   EQU   *
        FCB   $00,$07,$CC,$7C,$00,$00,$00
        FCB   $00,$CC,$7C,$CC,$70,$00,$00
        FCB   $07,$C7,$0C,$70,$7C,$00,$00
        FCB   $77,$CC,$7C,$7C,$CC,$70,$00
        FCB   $CC,$0C,$CC,$0C,$70,$70,$00
        FCB   $7C,$C0,$7C,$CC,$CC,$70,$00
        FCB   $77,$CC,$CC,$77,$70,$00,$00
        FCB   $0C,$C7,$C7,$7A,$A7,$00,$00
        FCB   $00,$07,$77,$77,$77,$00,$00
        FCB   $00,$00,$07,$77,$70,$00,$00
        FCB   $00,$00,$07,$60,$00,$00,$00
        FCB   $00,$00,$00,$66,$66,$00,$00
        FCB   $00,$00,$06,$60,$00,$00,$00
        FCB   $00,$00,$60,$04,$04,$00,$00
        FCB   $00,$00,$06,$00,$40,$00,$00
        FCB   $00,$00,$00,$00,$00,$00,$00
BRRD3   EQU   *
        FCB   $00,$07,$CC,$7C,$00,$00,$00
        FCB   $00,$CC,$7C,$CC,$70,$00,$00
        FCB   $07,$C7,$0C,$70,$7C,$00,$00
        FCB   $77,$CC,$7C,$7C,$CC,$70,$00
        FCB   $CC,$0C,$CC,$0C,$70,$70,$00
        FCB   $7C,$C0,$7C,$CC,$CC,$70,$00
        FCB   $77,$CC,$CC,$77,$70,$00,$00
        FCB   $0C,$C7,$C7,$7A,$A7,$00,$00
        FCB   $00,$07,$77,$77,$77,$00,$00
        FCB   $00,$00,$07,$77,$70,$00,$00
        FCB   $00,$00,$07,$60,$00,$00,$00
        FCB   $00,$00,$00,$66,$66,$00,$00
        FCB   $00,$00,$04,$60,$00,$00,$00
        FCB   $00,$00,$40,$06,$06,$00,$00
        FCB   $00,$00,$04,$00,$60,$00,$00
        FCB   $00,$00,$00,$00,$00,$00,$00
BRDD1   EQU   *
        FCB   $00,$00,$0C,$70,$00,$00,$00
        FCB   $00,$7C,$C7,$7C,$7C,$70,$00
        FCB   $07,$CC,$0C,$CC,$0C,$77,$00
        FCB   $77,$C7,$C7,$C0,$C0,$CC,$70
        FCB   $CC,$C0,$CC,$C7,$CC,$0C,$70
        FCB   $C7,$C7,$7C,$0C,$77,$C7,$C0
        FCB   $70,$C7,$77,$C7,$70,$7C,$70
        FCB   $0C,$CA,$AA,$7A,$AA,$77,$00
        FCB   $07,$77,$77,$77,$77,$70,$00
        FCB   $00,$00,$07,$77,$00,$00,$00
        FCB   $00,$00,$07,$67,$00,$00,$00
        FCB   $00,$00,$66,$66,$60,$00,$00
        FCB   $00,$06,$00,$60,$06,$00,$00
        FCB   $00,$00,$06,$06,$00,$00,$00
        FCB   $00,$00,$66,$06,$60,$00,$00
        FCB   $00,$00,$00,$00,$00,$00,$00
BRDD2   EQU   *
        FCB   $00,$00,$0C,$70,$00,$00,$00
        FCB   $00,$7C,$C7,$7C,$7C,$70,$00
        FCB   $07,$CC,$0C,$CC,$0C,$77,$00
        FCB   $77,$C7,$C7,$C0,$C0,$CC,$70
        FCB   $CC,$C0,$CC,$C7,$CC,$0C,$70
        FCB   $C7,$C7,$7C,$0C,$77,$C7,$C0
        FCB   $70,$C7,$77,$C7,$70,$7C,$70
        FCB   $0C,$CA,$AA,$7A,$AA,$77,$00
        FCB   $07,$77,$77,$77,$77,$70,$00
        FCB   $00,$00,$07,$77,$00,$00,$00
        FCB   $00,$00,$07,$67,$00,$00,$00
        FCB   $00,$00,$66,$66,$60,$00,$00
        FCB   $00,$06,$00,$66,$06,$00,$00
        FCB   $00,$00,$06,$06,$60,$00,$00
        FCB   $00,$00,$06,$00,$00,$00,$00
        FCB   $00,$00,$66,$00,$00,$00,$00
BRDD3   EQU   *
        FCB   $00,$00,$0C,$70,$00,$00,$00
        FCB   $00,$7C,$C7,$7C,$7C,$70,$00
        FCB   $07,$CC,$0C,$CC,$0C,$77,$00
        FCB   $77,$C7,$C7,$C0,$C0,$CC,$70
        FCB   $CC,$C0,$CC,$C7,$CC,$0C,$70
        FCB   $C7,$C7,$7C,$0C,$77,$C7,$C0
        FCB   $70,$C7,$77,$C7,$70,$7C,$70
        FCB   $0C,$CA,$AA,$7A,$AA,$77,$00
        FCB   $07,$77,$77,$77,$77,$70,$00
        FCB   $00,$00,$07,$77,$00,$00,$00
        FCB   $00,$00,$07,$67,$00,$00,$00
        FCB   $00,$00,$66,$66,$60,$00,$00
        FCB   $00,$06,$06,$60,$06,$00,$00
        FCB   $00,$00,$66,$06,$00,$00,$00
        FCB   $00,$00,$00,$06,$00,$00,$00
        FCB   $00,$00,$00,$06,$60,$00,$00
BRUD1   EQU   *
        FCB   $00,$00,$07,$C0,$00,$00,$00
        FCB   $00,$7C,$70,$C7,$C7,$70,$00
        FCB   $0C,$70,$C7,$CC,$C7,$C7,$00
        FCB   $7C,$00,$C7,$0C,$0C,$07,$70
        FCB   $7C,$C7,$7C,$CC,$7C,$7C,$C0
        FCB   $77,$7C,$C0,$C0,$C7,$C7,$70
        FCB   $77,$00,$CC,$0C,$07,$C7,$70
        FCB   $07,$7C,$77,$CC,$CC,$77,$00
        FCB   $00,$C7,$70,$C7,$77,$70,$00
        FCB   $00,$00,$07,$77,$00,$00,$00
        FCB   $00,$00,$07,$67,$00,$00,$00
        FCB   $00,$00,$66,$66,$60,$00,$00
        FCB   $00,$06,$00,$60,$06,$00,$00
        FCB   $00,$00,$06,$06,$00,$00,$00
        FCB   $00,$00,$66,$06,$60,$00,$00
        FCB   $00,$00,$00,$00,$00,$00,$00
BRUD2   EQU   *
        FCB   $00,$00,$07,$C0,$00,$00,$00
        FCB   $00,$7C,$70,$C7,$C7,$70,$00
        FCB   $0C,$70,$C7,$CC,$C7,$C7,$00
        FCB   $7C,$00,$C7,$0C,$0C,$07,$70
        FCB   $7C,$C7,$7C,$CC,$7C,$7C,$C0
        FCB   $77,$7C,$C0,$C0,$C7,$C7,$70
        FCB   $77,$00,$CC,$0C,$07,$C7,$70
        FCB   $07,$7C,$77,$CC,$CC,$77,$00
        FCB   $00,$C7,$70,$C7,$77,$70,$00
        FCB   $00,$00,$07,$77,$00,$00,$00
        FCB   $00,$00,$07,$67,$00,$00,$00
        FCB   $00,$00,$66,$66,$60,$00,$00
        FCB   $00,$06,$00,$66,$06,$00,$00
        FCB   $00,$00,$06,$06,$60,$00,$00
        FCB   $00,$00,$06,$00,$00,$00,$00
        FCB   $00,$00,$66,$00,$00,$00,$00
BRUD3   EQU   *
        FCB   $00,$00,$07,$C0,$00,$00,$00
        FCB   $00,$7C,$70,$C7,$C7,$70,$00
        FCB   $0C,$70,$C7,$CC,$C7,$C7,$00
        FCB   $7C,$00,$C7,$0C,$0C,$07,$70
        FCB   $7C,$C7,$7C,$CC,$7C,$7C,$C0
        FCB   $77,$7C,$C0,$C0,$C7,$C7,$70
        FCB   $77,$00,$CC,$0C,$07,$C7,$70
        FCB   $07,$7C,$77,$CC,$CC,$77,$00
        FCB   $00,$C7,$70,$C7,$77,$70,$00
        FCB   $00,$00,$07,$77,$00,$00,$00
        FCB   $00,$00,$07,$67,$00,$00,$00
        FCB   $00,$00,$66,$66,$60,$00,$00
        FCB   $00,$06,$06,$60,$06,$00,$00
        FCB   $00,$00,$66,$06,$00,$00,$00
        FCB   $00,$00,$00,$06,$00,$00,$00
        FCB   $00,$00,$00,$06,$60,$00,$00
;        END  

;; Patch from RRELESE6.ASM shows up here