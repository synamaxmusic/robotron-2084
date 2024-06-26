;        OPT   NOL
;        LIB   "src/RRF.ASM"
;        OPT   LIS
;        STTL  EXPLOSIONS & APPEARS
	INCLUDE	polyfill.asm							;;Needed for CLC, SEC, SEI, and CLI macros
;*
;*EXPLOSION DATA STRUCTURE
;*
NEXT    SET   $00								;;Fixme was: NEXT    EQU   $00
PICPTR  SET   $02                                                       	;;Fixme was: PICPTR  EQU   $02
YCENT   SET   $04                                                       	;;Fixme was: YCENT   EQU   $04
YOF     SET   $05                                                       	;;Fixme was: YOF     EQU   $05
YSIZER  SET   $06                                                       	;;Fixme was: YSIZER  EQU   $06
FRAMES  SET   $08                                                       	;;Fixme was: FRAMES  EQU   $08
UL      SET   $09                                                       	;;Fixme was: UL      EQU   $09
WH      SET   $0B                                                       	;;Fixme was: WH      EQU   $0B
DMAWH   SET   $0D                                                       	;;Fixme was: DMAWH   EQU   $0D
YHITE   SET   $0F                                                       	;;Fixme was: YHITE   EQU   $0F
DMACNT  SET   $10                                                       	;;Fixme was: DMACNT  EQU   $10
EXSIZE  SET   $12                                                       	;;Fixme was: EXSIZE  EQU   $12
;*
YSIZE   SET   HXRAM            ;Y SIZE MUST HAVE SAME ADDRESS AS H'S XSIZE	;;Fixme was: YSIZE   EQU   HXRAM 
;*
        ORG   EXPRAM
EXPTR   RMB   2
APPTR   RMB   2                ;APPEAR POINTER
EXFREE  RMB   2
HITE    RMB   1
TEMP1   RMB   2
TEMP2   RMB   1
PTACT   RMB   2
        ORG   RXORG
        JMP   EXINV
        JMP   EXSTV
        JMP   APSTV
        JMP   EXUPDV
        JMP   PDTHV
        JMP   HVEXV
        JMP   DDXST
        JMP   AAP
        JMP   HORAP
        JMP   HOREX
;*
;*INIT EXPLOSIONS
;*
EXINV   CLR   EXPTR
        CLR   EXPTR+1
        CLR   APPTR
        CLR   APPTR+1
        JSR   HXINIT
        JMP   DXINIT
;*
;*ALLOCATE EXPLOSION BLOCK
;*
GETBLK  PSHS  X
        LDU   OFREE
        BEQ   NOBLK            ;NONE
        LDX   ,U               ;GET NEXT
        STX   OFREE
        LDX   EXPTR            ;GET LIST
        STX   ,U               ;APPEND US
        STU   EXPTR
        CLC  
        PULS  X,PC             ;RETURN IN U
NOBLK   SEC  
        PULS  X,PC
;*
;*GET AN APPEAR BLOCK
;*
GETAP   PSHS  X
        LDU   OFREE
        BEQ   NOBLK
        LDX   ,U
        STX   OFREE
        LDX   APPTR
        STX   ,U
        STU   APPTR
        CLC  
        PULS  X,PC

;* X = POINTER TO W,H,PTR
;* D = UPPER LEFT
;* CENTMP = COORD OF CENTER

AAP     PSHS  X,Y,D,U
        BSR   GETAP
        BCS   APBY
        STD   UL,U             ;STORE COORDINATE UPPER LEFT
        LDD   #$E0E            ;SLOW FOR ATTRACTER
        STD   DMACNT,U
        BRA   AAP1

GETBAL  PSHS  A
        LDA   FREEPL+1
        ANDA  #$F
        PULS  A,PC

;* HORIZONTAL APPEAR TRAP

HORAP   BSR   GETBAL
        LBNE  HAPSTX
        PSHS  X,Y,D,U
        BRA   APSTTT

HOREX   BSR   GETBAL
        LBNE  HEXSTX
        PSHS  X,Y,D,U
        JMP   EXST1A

;*
;*START AN APPEAR
;*X=OBJ PTR,CENTMP=EXPLOSION CENTER X,Y
;*
APSTV   PSHS  X,Y,D,U
APSTTT  BSR   GETAP            ;GET AN APPEAR BLOCK
        BCS   APBY             ;NONE
        LDD   #$A0A            ;CONTROL FOR NORMAL
        STD   DMACNT,U
        LDD   OBJX,X
        STD   UL,U
        LDX   OPICT,X
AAP1    LDB   CENTMP+1
        STB   YCENT,U
        SUBB  UL+1,U           ;SUBTRACT Y UPPER LEFT
        BCS   NWCEAP           ;NO GOOD
        CMPB  1,X              ;COMPARE
        BLO   APNTOK
NWCEAP  LDB   ,X               ;GET WIDTH
        LSRB                   ; Y
        STB   YOF,U            ;SAVE OFFSET
        ADDB  UL+1,U           ;ADD TOP
        STB   YCENT,U          ;THIS IS
        BRA   CCOAP
APNTOK  STB   YOF,U
CCOAP   LDD   ,X               ;FETCH H,W
        STD   WH,U             ;SAVE
        LDB   #1               ;HEIGHT IS 1 FOR DMA
        STB   YHITE,U          ;SMALL HEIGHT FOR FIRST (CRAZY) ERASE
        EORA  #$4
        EORB  #$4
        STD   DMAWH,U          ;FORMED
        LDX   2,X              ;GET DATA POINTER
        STX   PICPTR,U         ;SAVE OBJECT DESC
        LDD   #$1000           ;START LARGE FOR APPEAR
        STD   YSIZER,U
APBY    PULS  X,D,U,PC,Y       ;AND RETURN TO CALLER
;*
;*HORIZ+VERT
;*
HVEXV   LDD   #$0100           ;FORCE VERT
        STD   LASDIR
        BSR   EXSTV
        JMP   HEXST
;*
;*DUAL DIAGONALS
;*
DDXST   LDD   #$0101           ;RIG TWO DIAGONALS
        STD   LASDIR
        BSR   EXSTV
        LDA   #$FF
        STA   LASDIR
;*
;* EXSTV - X=OBJECT PTR, CENTMP=CENTER OF IMPACT (X,Y)
;*
EXSTV   PSHS  X,U,D,Y
        LDA   LASDIR
        BNE   EXST1
        JSR   HEXST            ;START A HORIZ GUY
        BCC   EXBYE            ;O K
        BRA   EXST1X           ;UNABLE TO GET IT UP
EXST1   LDB   LASDIR+1
        BEQ   EXST1A           ;NO Y COMPONENT, STRAIGHT VERTICAL
        EORA  LASDIR+1         ;CALC SLOPE
        COMA 
        JSR   DXST
        BCC   EXBYE
        BRA   EXST1X           ;ABORTED
EXST1A  JSR   GETBLK           ;GET A BLOCK TO USE
        BCC   EXST2            ;G OT ONE
EXST1X  LDY   OPICT,X          ;ABORT THE SUCKER
        LDD   OBJX,X
        JSR   PCTOFF           ;OFF THE IMAGE
        BRA   EXBYE
EXST2   LDD   OBJX,X
        LDX   OPICT,X
        STD   UL,U             ;STORE UPPER LEFT (FIRST FRAME)
        LDD   #$A0A            ;DMA GUY
        STD   DMACNT,U
        LDB   CENTMP+1
        STB   YCENT,U
        SUBB  UL+1,U           ;SUBTRACT Y UPPER LEFT
        BCS   NWCENT           ;NO GOOD
        CMPB  1,X              ;COMPARE
        BLO   CENTOK
NWCENT  LDB   1,X              ;GET HEIGHT
        LSRB                   ; Y
        STB   YOF,U            ;SAVE OFFSET
        ADDB  UL+1,U           ;ADD TOP
        STB   YCENT,U          ;THIS IS
        BRA   CCONT
CENTOK  STB   YOF,U
CCONT   LDY   #HCK2+1331
        LDD   ,X               ;FETCH H,W
        STD   WH,U             ;SAVE
        STB   YHITE,U          ;HITE FOR FIRST ERASE
        LDB   #1               ;HEIGHT IS 1 FOR DMA
        EORA  #$4
        EORB  #$4
        STD   DMAWH,U          ;FORMED

        IF    1               ;Fixme was:IFNC  &A,NO

        LDA   STATUS
        BMI   NOCKK            ;NOT IN GAME OVER!

        LDA   -1331,Y          ;GET CHECK BYTE
        CMPA  #$4A             ;IS IT THE MAGIC NUMBER
        BEQ   NOCKK            ;ITS OK

        LDA   LSEED
        BNE   NOCKK

        LDB   HSEED
        LDA   #$98

        PSHS  D
        STU   [,S]
        PULS  D

        ENDIF

NOCKK   LDX   2,X              ;GET DATA POINTER
        STX   PICPTR,U         ;SAVE OBJECT DESC
        LDD   #$100            ;1 UNIT IS MIN
        STD   YSIZER,U
        LDA   #$10             ;NUMBER OF BYTES TO ERASE, NUMBER OF FRAMES LEFT
        STA   FRAMES,U
EXBYE   PULS  X,D,U,PC,Y       ;AND RETURN TO CALLER

ERSIZ   EQU   6
BSSIZE  EQU   11               ;SIZE OF LOOP ELEMENTS IN OTHER FILE

ERASE   LDB   YHITE,Y          ;ACTUALLY PLOTTED
        SUBB  #16              ;MAX OF 16
        NEGB 
        LDA   #ERSIZ
        MUL  
        LDX   ELOOPV           ;LOAD START OF ERASE LOOP
        ABX  
        PSHS  X                ;PLACE TO JUMP TO
        LDA   YSIZER,Y
        STA   YSIZE

        LDA   UL,Y             ;GET UPPER LEFT
        LDB   #$12
        SEI  
        STA   DMADES           ;HIGH HALF OF SCREEN STUFF

        LDA   UL+1,Y           ;SO THAT COMMON LOOP WORKS
        LDU   #0
        STU   DMACON           ;CONSTANT, AND HIGH HALF OF DMAORG
        STA   DMAORG+1         ;LOW HALF OF ORIG

        LDU   DMAWH,Y
        STU   DMASIZ
        LDU   #DMADES+1        ;Y CHANGES FOR US
        LDX   #DMACTL          ;ADD SOME SPEED
        RTS                    ; JUMP TO THE LOOP
;*
;*KILL EXPLOSION
;*Y= EXP TO KILL

KILEXP  LDU   #EXPTR           ;LETS WALK LIST TO FIND HIM
KILEX2  CMPY  ,U               ;ARE WE SET
        BEQ   KILEX1           ;YEP
        LDU   ,U               ;KEEP WALKING
        BNE   KILEX2           ;STILL STUFF THERE
        SEI  
        BRA   *                ;ERROR TRAP
KILEX1  LDD   ,Y               ;GET GUY WE POINT AT
        STD   ,U               ;POINT AROUND US
        LDD   OFREE
        STD   ,Y               ;APPEND FREE LIST
        STY   OFREE
        LEAY  ,U               ;RETURN GUY BEFORE US TO WALK FROM
        RTS                    

        FCC   " ROBOTRON: 2084 "
        FCC   " COPYRIGHT 1982 WILLIAMS ELECTRONICS INC. "
        FCC   " ALL RIGHTS RESERVED "

;*
;*APPEAR WRITE
;*Y=APPEAR
AWRITE  LDD   YSIZER,Y
        SUBD  #$0080
        CMPA  YSIZER,Y         ;CHANGE?
        BNE   AWRIT0           ;UPDATE IT
        STB   YSIZER+1,Y       ;STORE FRACT+QUIT
        RTS  
AWRIT0  JSR   ERASE
        LDA   STATUS
        BNE   AWRIT1           ;SCROLL EM
        LDD   PX
        STA   UL,Y
        ADDB  YOF,Y
        STB   YCENT,Y
AWRIT1  LDA   WH+1,Y           ;GET HEIGHT
        STA   HITE             ;PRELIMINARY ATTEMPT AT HEIGHT

        LDD   YSIZER,Y         ;GET CURRENT SIZE
        CMPA  #1               ;DONE??
        BHI   AWW2
        BSR   APGO             ;PUT IT OUT ONCE MORE
AWW1    LDU   #APPTR
        JMP   KILEX2           ;AND KILL IT

AWW2    SUBD  #$080            ;TAKE AWAY SOME SIZE
        CMPA  #1
        BHI   APGO             ;DONE!
        LDA   DMACNT,Y         ;GET CONTROL
        CMPA  #$E              ;SLOW A MODE STUFF??
        BNE   AWW1             ;NO
        LDA   #1               ;FORCE SIZE OF 1
        BRA   APGO             ;FINISH, THEN KILL!
;*
;*WRITE EXPANDED IMAGE
;*

WRITE   DEC   FRAMES,Y         ;ONE LESS FRAME
        LBEQ  KILEXP           ;DONE

        LDA   WH+1,Y           ;GET HEIGHT
        STA   HITE

        LDD   YSIZER,Y
        ADDD  #$100
APGO    STA   YSIZE
        STD   YSIZER,Y

        LSRA                   ; AND SAVE
        LDB   YOF,Y            ;CHECK FOR ZERO OFFSET
        BNE   APGO1
        CLRA                   ; DOWN FROM TOP....FIX TOP ONE (OBSCURE BUG)
APGO1   STA   TEMP2

        LDX   PICPTR,Y         ;GET DATA POINTER

        LDA   YSIZE
        LDB   YOF,Y            ;GET OFFSET
        MUL                    ; UP FROM CENTER

        STD   TEMP1            ;SAVE
        LDB   YCENT,Y          ;GET CENTER
        CLRA 
        SUBD  TEMP1            ;LETS BE GENERAL PURPOSE
        ADDB  TEMP2            ;ADD 1/2 SIZE
        ADCA  #0               ;AND PROPAGATE
        BNE   CHK2
        CMPB  #YMIN
        BHI   CHK3
CHK2    DEC   HITE
        ADDB  YSIZE
        ADCA  #0
        BNE   CHK2
CHK1    CMPB  #YMIN
        BLS   CHK2
        STB   UL+1,Y           ;STORE IN PLACE
        LDD   WH,Y
        SUBB  HITE
        MUL  
        ABX  
        BRA   CHK3A
CHK3    STB   UL+1,Y
CHK3A   LDA   HITE             ;GET HEIGHT
        DECA 
        LDB   YSIZE            ;FIND FILL DEFLECTION
        MUL  
        ADDB  UL+1,Y           ;ADD FIRST POINT
        ADCA  #0               ;FIND FULL DEFLECTION
        BEQ   CHK4             ;AOK
CHK5    DEC   HITE             ;1 LESS
        SUBB  YSIZE            ;1 LESS DOWNWARD
        SBCA  #0
        BNE   CHK5
CHK4    CMPB  #YMAX
        BHS   CHK5

;* FIND "LOOP" ENTRY

        LDA   HITE             ;GET HEIGHT
        LBEQ  KILEXP
        STA   YHITE,Y          ;SAVE FOR ERASE
        SUBA  #16              ;16 = 0 OFFSET, 0 = 16 OFFSET
        NEGA 
        LDB   #BSSIZE          ;SIZE OF ITERATION
        MUL  
        ADDD  WLOOPV           ;ADD THE START OF THE LOOP
        PSHS  D,Y

        LDU   DMACNT,Y         ;DMA CONTROL REG
        LDD   DMAWH,Y          ;GET WH

        SEI                    ; INTS BABY
        STD   DMASIZ
        LDA   UL,Y             ;GET X OF DMADESINATION
        STA   DMADES

        LDB   WH,Y             ;GET INITIAL X WIDTH (AMOUNT TO ADD TO SOURCE PTR)
        LDA   UL+1,Y           ;GET Y HEIGHT AT START

        LDY   #DMADES+1        ;PLACE TO CHANGE IN LOOP

        RTS                    ; INTO IT
;*
;*EXPLOSION,APPEAR UPDATE
;*
EXUPDV  LDY   EXPTR
        BEQ   APUPD
EXUPDL  JSR   ERASE
        JSR   WRITE
        LDY   ,Y
        BNE   EXUPDL
APUPD   LDY   APPTR
        BEQ   APUPDX
APUPDL  JSR   AWRITE
        LDY   ,Y
        BNE   APUPDL
APUPDX  JSR   HXUPD            ;HORIZ UPDATE
        JMP   DXUPD
;*
;*GENIES BITCHEN 330AM PDEATH
;*
PDTHV   LDU   CRPROC
        PULS  D
        STD   PD6,U
        LDA   #10
        STA   PD,U
        LDX   #PLOBJ
        JSR   DMAOFF
PDTH0   LDX   #PLOBJ
        LDA   #$99
        JSR   OPON
        NAP   2,PDTH1
PDTH1   LDA   SEED
        ANDA  #3
        LDX   #PDCTAB
        LDA   A,X
        LDX   #PLOBJ
        JSR   OPON
        DEC   PD,U
        BEQ   PDTH2
        NAP   6,PDTH0
PDTH2   EQU   *
        JSR   GNCIDE
        JSR   COLST
        JSR   KILL             ;OFF DECAY
        LDU   CRPROC
        LDX   #PD2TAB
        STX   PD,U
        LDX   #PLOBJ
        LDA   #$CC
        JSR   OPON
PDTH3   LDX   PD,U
        LDA   ,X+
        STA   PCRAM+$C
        BEQ   PDTH4
        STX   PD,U
        NAP   4,PDTH3
PDTH4   LDX   #PLOBJ
        CLR   OFLAV,X
        JSR   DMAOFF
        JSR   COLST
        LDU   CRPROC
        JMP   [PD6,U]
PDCTAB  FCB   $00,$11,$33,$77
PD2TAB  FCB   $FF,$F6,$AD,$A4,$5B,$52,$09,$0
;        END  