;        OPT   NOL
;        LIB   "src/RRF.ASM"
;        OPT   LIS
;        STTL  C I R C L E S AND E N F O R C E R S
;*
;*VECTORS
;*
        ORG   RCORG
        JMP   CIRST
        JMP   CIRKKV
        FDB   CIRP0
        FDB   ENGP1
        FDB   ENFP0
;*
;*MISC SOUNDS
;*
ENDSND  FCB   $D8,$01,$08,$18,0 ;ENFORCER DROP OFF
CRKSND  FCB   $D1,$01,$08,$08,0 ;CIRCLE KILL
ENFSND  FCB   $D0,$01,$08,$1D,0 ;ENFORCER SHOOT
ENKSND  FCB   $D0,$03,$04,$17,0 ;ENFORCER KILL
SPKSND  FCB   $D0,$01,$04,$15,$01,$08,$14,0 ;SPARK KILL
;*
;*CIRCLE START
;*PD=OBJ,PD2=TIME TO DROP,PD3=#OF ENFORCERS
;*A=#
CIRST   LDA   CIRCNT
        PSHS  A
        BEQ   CIRCSX
CIRSTL  MKPROB CIRCLE,CIRP4,CIRKIL
        BEQ   CIRCSX           ;NONE LEFT
        JSR   RANDXY
        LDA   #XMIN+2
        TST   SEED
        BMI   CIRCS1
        LDA   #XMAX-8
CIRCS1  STD   OBJX,X           ;INIT COORDS
        STA   OX16,X
        STB   OY16,X
        LDA   CDPTIM
        JSR   RMAX
        STA   PD2,U            ;TIME TO DROP
        LDA   ENFNUM
        JSR   RMAX
        LSRA 
        ADCA  #0
        STA   PD3,U            ;# TO DROP
        JSR   CIRNAC           ;RANDOM CIRCLE ACCEL
        LDD   #CIRP4           ;PHONY PICTURE TO HIT
        STD   FONIPC,X
        STX   OPTR
        DEC   ,S
        BNE   CIRSTL
CIRCSX  PULS  A,PC
;*
;*CIRCLE PROCESS
;*PD=OBJ,PD2=TIME TO DROP,PD3=# ENF,PD5=X ACC,PD6=Y ACC
;*PD7=ACC TIME
;*
CIRCLE  LDX   PD,U
        LDD   OPICT,X
        ADDD  #4
        CMPD  #CIRP4
        BLS   CIRC1
        LDD   #CIRP0
        TST   STATUS           ;DONT START EARLY GUYS
        BNE   CIRC1
        DEC   PD2,U            ;GO CRITICAL??
        BEQ   CIRC2            ;YIP
CIRC1   STD   OPICT,X
        DEC   PD7,U            ;NEW ACCEL?
        BNE   CIRC1A           ;NO
        JSR   CIRNAC
CIRC1A  JSR   CIRGO            ;ACCELERATE+DAMP
        NAP   2,CIRCLE
;*GO GET THE MO'FO'
CIRC2   LDA   CDPTIM
        LSRA 
        LSRA 
        JSR   RMAX
        STA   PD2,U            ;TIME TO DROP
CIRC2L  LDX   PD,U
        LDD   OPICT,X
        ADDD  #4
        CMPD  #CIRP7
        BLS   CIRC2A
        DEC   PD2,U
        BNE   CIR2A
        LDA   ENFCNT           ;MAXXED OUT??
        CMPA  #8
        BHS   CIRC2            ;TOO MANY
        LDA   OVCNT            ;OUT OF REAL TIME ??
        CMPA  #17
        BHS   CIRC2
        JSR   ENFDRP
        DEC   PD3,U
        BEQ   CIRC3            ;ALL DONJE
        BRA   CIRC2            ;GET NEW DROP TIME
CIR2A   LDD   #CIRP0
CIRC2A  STD   OPICT,X
        DEC   PD7,U
        BNE   CIRC2B
        JSR   CIRNAC
CIRC2B  JSR   CIRGO
        NAP   2,CIRC2L
;*ESCAPE PHASE
CIRC3   LDD   #0
        STD   OYV,X
        LDD   #$100
        TST   SEED
        BPL   CIRC3A
        NEGA 
CIRC3A  STD   OXV,X
CIRC3L  LDX   PD,U
        LDD   OPICT,X
        ADDD  #4
        CMPD  #CIRP4
        BLS   CIRC3B
        LDA   OX16,X           ;DONE?
        CMPA  #XMIN+3
        BLS   CIRC4            ;YES
        CMPA  #XMAX-10
        BHS   CIRC4            ;YES
        LDD   #CIRP0
CIRC3B  STD   OPICT,X
        NAP   2,CIRC3L
;*ALL DONE
CIRC4   JSR   KILLOF
        DEC   CIRCNT
        JMP   SUCIDE
;*
;*CIRCLE NEW ACCEL
;*X=OBJ,PD5=X ACC,PD6=Y ACC,PD7=ACC TIME
;*
CIRNAC  LDA   HSEED
        ANDA  #$1F
        ADDA  #-$10
        STA   PD5,U            ;X ACC
        LDA   LSEED
        EORA  SEED
        ANDA  #$3F
        ADDA  #-$20
        STA   PD6,U            ;Y ACC
        LDA   #15
        JSR   RANDU
        STA   PD7,U
        RTS  
;*
;*CIRCLE ACCELERATE
;*X=OBJ
CIRGO   LDB   PD5,U            ;X ACCEL
        SEX  
        ADDD  OXV,X
        CMPD  #$0100           ;CHECK YOUR LIMITS
        BLT   CIRG1
        LDD   #$0100
CIRG1   CMPD  #$FF00
        BGT   CIRG2
        LDD   #$FF00
CIRG2   STD   OXV,X
        COMA 
        COMB 
        ASLB 
        ROLA 
        ASLB 
        ROLA 
        TFR   A,B
        SEX  
        ADDD  OXV,X
        STD   OXV,X
        LDB   PD6,U            ;Y ACCEL
        SEX  
        ADDD  OYV,X
        CMPD  #$0200
        BLT   CIRG3
        LDD   #$0200
CIRG3   CMPD  #$FE00
        BGT   CIRG4
        LDD   #$FE00
CIRG4   STD   OYV,X
        COMA 
        COMB 
        ASLB 
        ROLA 
        TFR   A,B
        SEX  
        ADDD  OYV,X
        STD   OYV,X
        RTS  
;*
;*KILL A CIRCLE
;*X=OBJECT
CIRKIL  LDA   PCFLG
        BNE   CIRKX            ;DONT BLOW IF PLAYER HITS YOU
        JSR   KILOFP           ;KILL, OFF OBJ; KILL PROC
        LDU   OFREE
        LDD   ,U               ;GET OBJ BACK
        STD   OFREE
        MAKP  CIRKP            ;CIRCLE KILL PROC
        STU   PD,X
        LDD   #CIRP1
        STD   OPICT,U
        DEC   CIRCNT
        LDD   #$0210           ;SCORE 1K
        JSR   SCORE
        LDD   #CRKSND
        JMP   SNDLD
CIRKX   RTS  
;*
;*CIRCLE KILL PROCESS BUBBLE BURST
;*PD=OBJ.
CIRKP   LDD   #$FFAA
        STD   PD4,U            ;COLORS..
        LDA   #7
        STA   PD6,U            ;COUNT
CIRKKV  EQU   *
CIRKPL  LDX   PD,U
        LDY   OPICT,X
        LDD   OBJX,X
        JSR   PCTOFF
        LEAY  4,Y
        STY   OPICT,X
        DEC   PD6,U
        BEQ   CIRKPX
        LDA   PD5,U
        STA   XTEMP2
        LDD   OBJX,X
        JSR   MPCTON
        NAP   2,CIRKPL
CIRKPX  EQU   *
        LDD   OBJX,X           ;DISPLAY 1000 MESSAGE
        ADDD  #$0105
        STD   OBJX,X
        LDA   #30
        STA   PD2,U
        LDD   P1KD
        STD   OPICT,X
CIRKX1  LDX   PD,U
        LDA   PD4,U
        STA   XTEMP2           ;COLOR
        LDY   OPICT,X
        LDD   OBJX,X
        JSR   MPCTON
        DEC   PD2,U
        BEQ   CIRKX2
        NAP   2,CIRKX1
CIRKX2  JSR   PCTOFF
        LDD   OFREE            ;DUMP
        STD   ,X
        STX   OFREE
        JMP   SUCIDE           ;CROAK NOW PLEASE!!
;*
;*DROP OFF AN ENFORCER
;*X=CIRCLE OBJECT
ENFDRP  PSHS  X,Y,D,U
        TFR   X,Y
        MKPROB ENFRCE,ENGP1,ENFKIL
        BEQ   ENFDX            ;NONE LEFT
        LDA   OX16,Y
        LDB   OY16,Y
        STA   OX16,X
        STB   OY16,X
        STD   OBJX,X
        LDA   ENSTIM
        JSR   RMAX
        STA   PD6,U            ;SHOT TIMER
        STX   OPTR             ;LINK EM IN
        LDD   #ENDSND
        JSR   SNDLD
        INC   ENFCNT
ENFDX   PULS  X,Y,D,U,PC
;*
;*ENFORCER PROCESS
;*PD=OBJECT,PD6=SHOT TIMER, PD7=UPDATE TIMER
;*
ENFR0   LDX   PD,U             ;GROW UP
        LDD   OPICT,X
        ADDD  #4
        CMPD  #ENFP0
        BHS   ENFR10           ;ALL GROWN UP
        STD   OPICT,X
ENFRCE  NAP   8,ENFR0
;*GO GIT IM
ENFR10  STD   OPICT,X          ;SAVE THE PICT
        JSR   ENFNV            ;GET A VELOCITY
ENFR1   LDX   PD,U
        DEC   PD7,U
        BNE   ENFR1A
        JSR   ENFNV
ENFR1A  DEC   PD6,U
        BNE   ENFR1B
        JSR   ENFSHT           ;TAKE A SHOT AT THE JAGOFF
ENFR1B  NAP   3,ENFR1
;*
;*GET A NEW ENFORCER VELOCITY
;*PD7=UPDATE TIMER, X=OBJ
;*
ENFNV   JSR   RAND16
        ANDA  #$1F
        STA   PD7,U
        CLRA 
        ASRB 
        ASRB 
        ASRB 
        ADDB  PX
        CMPB  #XMIN
        BHS   ENFNV1
        LDB   #XMIN
ENFNV1  CMPA  #XMAX
        BLS   ENFNV4
        CMPB  #XMAX+$40
        BHS   ENFNV2
        LDB   #XMAX
        BRA   ENFNV4
ENFNV2  LDB   #XMIN
ENFNV4  SUBB  OX16,X
        SBCA  #0               ;GET THE SIGN GUYS
        ASLB 
        ROLA 
        STD   OXV,X
        CLRA 
        LDB   HSEED
        ASRB 
        ASRB 
        ASRB 
        ADDB  PX+1
        CMPB  #YMAX
        BLS   ENFNV5
        LDB   #YMAX
ENFNV5  CMPB  #YMIN
        BHS   ENFNV7
        CMPB  #YMIN>>1
        BHS   ENFNV6
        LDB   #YMAX
        BRA   ENFNV7
ENFNV6  LDB   #YMIN
ENFNV7  SUBB  OY16,X
        SBCA  #0               ;GET THE SIGN
        ASLB 
        ROLA 
        STD   OYV,X
        RTS  
;*
;*ENFORCER SHOOT
;*X=OBJ
ENFSHT  PSHS  U,X
        TFR   X,Y
        LDA   ENSTIM           ;SHOT TIMER
        JSR   RMAX
        STA   PD6,U
        LDA   SPKCNT           ;TOO MANY??
        CMPA  #20
        BHS   ENFSX
        LDA   OVCNT            ;NO TIME LEFT??
        CMPA  #17
        BHS   ENFSX
        MKPROB SPARK,SPKP0,SPKIL
        BEQ   ENFSX            ;NONE LEFT
        INC   SPKCNT
        LDD   OBJX,Y
        STA   OX16,X
        STB   OY16,X
        STD   OBJX,X
        LDB   SEED
        ANDB  #$1F
        ADDB  #-$10
        LDA   PX
        CMPA  #XMIN+$10
        BHS   ENFS2
        CLRB 
ENFS2   ADDB  PX
        CLRA 
        SUBB  OBJX,X
        SBCA  #0               ;GET SIGN
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
        ASLB 
        ROLA 
        ASLB 
        ROLA 
        STD   OYV,X
        LDB   LSEED
        ANDB  #$1F
        ADDB  #-$10
        SEX  
        STD   PD2,U            ;X ACC
        LDB   HSEED
        ANDB  #$1F
        ADDB  #-$10
        SEX  
        STD   PD4,U            ;Y ACC
        STX   OPTR
        LDA   HSEED
        ANDA  #$F
        ADDA  #$14
        STA   PD7,U            ;LIFETIME
        LDD   #ENFSND
        JSR   SNDLD
ENFSX   PULS  U,X,PC
;*
;*KILL AN ENFORCER
;*X=OBJECT
ENFKIL  LDA   PCFLG
        BNE   ENFKX
        JSR   KILOFP
        LDX   OFREE
        LDD   ,X
        STD   OFREE            ;GET OBJ BACK
        JSR   EXST
        LDD   OFREE
        STD   ,X
        STX   OFREE            ;FREE HIM
        DEC   ENFCNT
        LDD   #$0115
        JSR   SCORE
        LDD   #ENKSND
        JMP   SNDLD
ENFKX   RTS  
;*
;*SPARK PROCESS
;*PD=OBJ,PD2=X ACC,PD4=Y ACC
;*PD7=LIFE
SPARK   LDX   PD,U
        LDD   OPICT,X
        ADDD  #4
        CMPD  #SPKP3
        BLS   SPK1
        LDD   #SPKP0
SPK1    STD   OPICT,X
        LDD   OXV,X
        ADDD  PD2,U
        STD   OXV,X
        LDD   OYV,X
        ADDD  PD4,U
        STD   OYV,X
        DEC   PD7,U
        BEQ   SPKDIE
        NAP   4,SPARK
SPKDIE  JSR   KILLOF
        DEC   SPKCNT
        JMP   SUCIDE
;*
;*SPARK KILL
;*X=OBJ
SPKIL   LDA   PCFLG
        BNE   SPKX
        JSR   KILOFP
        DEC   SPKCNT
        LDD   #$0025
        JSR   SCORE
        LDD   #SPKSND
        JMP   SNDLD
SPKX    RTS  
;*CIRCLES
CIRP0   FCB   8,15
        FDB   CIRD0
CIRP1   FCB   8,15
        FDB   CIRD1
CIRP2   FCB   8,15
        FDB   CIRD2
CIRP3   FCB   8,15
        FDB   CIRD3
CIRP4   FCB   8,15
        FDB   CIRD4
CIRP5   FCB   8,15
        FDB   CIRD5
CIRP6   FCB   8,15
        FDB   CIRD6
CIRP7   FCB   8,15
        FDB   CIRD7

;        IF    NOL         ;Fixme was: IFC   &A,NOL
;        OPT   NOL
;        ENDIF

CIRD0   EQU   *
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$000F,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
CIRD1   EQU   *
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$000F,$0000,$0000
        FDB   $0000,$00FF,$F000,$0000
        FDB   $0000,$000F,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
CIRD2   EQU   *
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$00FF,$F000,$0000
        FDB   $0000,$0FFF,$FF00,$0000
        FDB   $0000,$0FF0,$FF00,$0000
        FDB   $0000,$0FFF,$FF00,$0000
        FDB   $0000,$00FF,$F000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
CIRD3   EQU   *
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$00FF,$F000,$0000
        FDB   $0000,$0FFF,$FF00,$0000
        FDB   $0000,$FFF0,$FFF0,$0000
        FDB   $0000,$FF00,$0FF0,$0000
        FDB   $0000,$FFF0,$FFF0,$0000
        FDB   $0000,$0FFF,$FF00,$0000
        FDB   $0000,$00FF,$F000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
CIRD4   EQU   *
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0FFF,$FF00,$0000
        FDB   $0000,$FFFF,$FFF0,$0000
        FDB   $000F,$FF00,$0FFF,$0000
        FDB   $000F,$F000,$00FF,$0000
        FDB   $000F,$F000,$00FF,$0000
        FDB   $000F,$F000,$00FF,$0000
        FDB   $000F,$FF00,$0FFF,$0000
        FDB   $0000,$FFFF,$FFF0,$0000
        FDB   $0000,$0FFF,$FF00,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
CIRD5   EQU   *
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0FFF,$FF00,$0000
        FDB   $000F,$FFFF,$FFFF,$0000
        FDB   $000F,$F000,$00FF,$0000
        FDB   $00FF,$0000,$000F,$F000
        FDB   $00FF,$0000,$000F,$F000
        FDB   $00FF,$0000,$000F,$F000
        FDB   $00FF,$0000,$000F,$F000
        FDB   $00FF,$0000,$000F,$F000
        FDB   $000F,$F000,$00FF,$0000
        FDB   $000F,$FFFF,$FFFF,$0000
        FDB   $0000,$0FFF,$FF00,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
CIRD6   EQU   *
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$00FF,$F000,$0000
        FDB   $0000,$FFFF,$FFF0,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $00F0,$0000,$0000,$F000
        FDB   $00F0,$0000,$0000,$F000
        FDB   $0FF0,$0000,$0000,$FF00
        FDB   $0FF0,$0000,$0000,$FF00
        FDB   $0FF0,$0000,$0000,$FF00
        FDB   $00F0,$0000,$0000,$F000
        FDB   $00F0,$0000,$0000,$F000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$FFFF,$FFF0,$0000
        FDB   $0000,$00FF,$F000,$0000
        FDB   $0000,$0000,$0000,$0000
CIRD7   EQU   *
        FDB   $0000,$000F,$0000,$0000
        FDB   $0000,$00FF,$F000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0F00,$0000,$0000,$0F00
        FDB   $FF00,$0000,$0000,$0FF0
        FDB   $0F00,$0000,$0000,$0F00
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$0000,$0000,$0000
        FDB   $0000,$00FF,$F000,$0000
        FDB   $0000,$000F,$0000,$0000
;*ENFORCER PICTS
ENGP1   FCB   5,11
        FDB   ENGD1
ENGP2   FCB   5,11
        FDB   ENGD2
ENGP3   FCB   5,11
        FDB   ENGD3
ENGP4   FCB   5,11
        FDB   ENGD4
ENGP5   FCB   5,11
        FDB   ENGD5
ENFP0   FCB   5,11
        FDB   ENFD0
ENFD0   FCB   $00,$00,$80,$00,$00
        FCB   $00,$08,$88,$00,$00
        FCB   $00,$8A,$AA,$80,$00
        FCB   $08,$FF,$FF,$F8,$00
        FCB   $00,$08,$88,$00,$00
        FCB   $90,$88,$78,$80,$90
        FCB   $09,$97,$77,$99,$00
        FCB   $90,$77,$77,$70,$90
        FCB   $00,$00,$80,$00,$00
        FCB   $00,$DD,$DD,$D0,$00
        FCB   $0D,$DD,$DD,$DD,$00
ENGD1   EQU   *
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$80,$00,$00
        FCB   $00,$08,$F8,$00,$00
        FCB   $00,$00,$70,$00,$00
        FCB   $00,$00,$D0,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
ENGD2   EQU   *
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$80,$00,$00
        FCB   $00,$08,$F8,$00,$00
        FCB   $00,$00,$80,$00,$00
        FCB   $00,$09,$79,$00,$00
        FCB   $00,$00,$D0,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
ENGD3   EQU   *
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$88,$00,$00
        FCB   $00,$08,$FF,$80,$00
        FCB   $00,$00,$88,$00,$00
        FCB   $00,$09,$77,$90,$00
        FCB   $00,$00,$77,$00,$00
        FCB   $00,$00,$DD,$00,$00
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$00,$00,$00
ENGD4   EQU   *
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$80,$00,$00
        FCB   $00,$08,$A8,$00,$00
        FCB   $00,$8F,$FF,$80,$00
        FCB   $00,$00,$80,$00,$00
        FCB   $00,$08,$78,$00,$00
        FCB   $09,$97,$77,$99,$00
        FCB   $00,$07,$77,$00,$00
        FCB   $00,$00,$80,$00,$00
        FCB   $00,$0D,$DD,$00,$00
        FCB   $00,$00,$00,$00,$00
ENGD5   EQU   *
        FCB   $00,$00,$00,$00,$00
        FCB   $00,$00,$88,$00,$00
        FCB   $00,$08,$AA,$80,$00
        FCB   $00,$8F,$FF,$F8,$00
        FCB   $00,$00,$88,$00,$00
        FCB   $00,$98,$88,$89,$00
        FCB   $00,$09,$77,$90,$00
        FCB   $00,$97,$77,$79,$00
        FCB   $00,$00,$88,$00,$00
        FCB   $00,$0D,$DD,$D0,$00
        FCB   $00,$00,$00,$00,$00
;*SPARK PICTS
SPKP0   FCB   4,7
        FDB   SPKD0
SPKP1   FCB   4,7
        FDB   SPKD1
SPKP2   FCB   4,7
        FDB   SPKD2
SPKP3   FCB   4,7
        FDB   SPKD3
SPKD0   EQU   *
        FDB   $000B,$0000
        FDB   $000B,$0000
        FDB   $000B,$0000
        FDB   $FFFB,$FFF0
        FDB   $000B,$0000
        FDB   $000B,$0000
        FDB   $000B,$0000
SPKD1   EQU   *
        FDB   $0000,$0000
        FDB   $0F00,$0B00
        FDB   $00F0,$B000
        FDB   $000B,$0000
        FDB   $00B0,$F000
        FDB   $0B00,$0F00
        FDB   $0000,$0000
SPKD2   EQU   *
        FDB   $000F,$0000
        FDB   $000F,$0000
        FDB   $000F,$0000
        FDB   $BBBB,$BBB0
        FDB   $000F,$0000
        FDB   $000F,$0000
        FDB   $000F,$0000
SPKD3   EQU   *
        FDB   $0000,$0000
        FDB   $0B00,$0F00
        FDB   $00B0,$F000
        FDB   $000B,$0000
        FDB   $00F0,$B000
        FDB   $0F00,$0B00
        FDB   $0000,$0000
;        END  