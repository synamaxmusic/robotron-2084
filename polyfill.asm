;; Taken from mwenge's rewrite, these restore missing macros referenced in the code


CLC     MACRO 
        ANDCC #$FE
        ENDM

SEI     MACRO 
        ORCC #$10
        ENDM

CLI     MACRO 
        ANDCC #$EF
        ENDM

SEC     MACRO 
        ORCC #$01
        ENDM