;**************************************************************************************
;* PS 5 Main [includes LibV2.2]                                                       *
;**************************************************************************************
;* Summary:                                                                           *
;*   -                                                                                *
;*                                                                                    *
;* Author: Julia Fay                                                                  *
;*   Cal Poly University                                                              *
;*   Fall 2023                                                                        *
;*                                                                                    *
;* Revision History:                                                                  *
;*   -                                                                                *
;*                                                                                    *
;* ToDo:                                                                              *
;*   -                                                                                *
;**************************************************************************************

;/------------------------------------------------------------------------------------\
;| Include all associated files                                                       |
;\------------------------------------------------------------------------------------/
; The following are external files to be included during assembly


;/------------------------------------------------------------------------------------\
;| External Definitions                                                               |
;\------------------------------------------------------------------------------------/
; All labels that are referenced by the linker need an external definition

              XDEF  main

;/------------------------------------------------------------------------------------\
;| External References                                                                |
;\------------------------------------------------------------------------------------/
; All labels from other files must have an external reference

              XREF  ENABLE_MOTOR, DISABLE_MOTOR
              XREF  STARTUP_MOTOR, UPDATE_MOTOR, CURRENT_MOTOR
              XREF  STARTUP_PWM, STARTUP_ATD0, STARTUP_ATD1
              XREF  OUTDACA, OUTDACB
              XREF  STARTUP_ENCODER, READ_ENCODER
              XREF  INITLCD, SETADDR, GETADDR, CURSOR_ON, CURSOR_OFF, DISP_OFF
              XREF  OUTCHAR, OUTCHAR_AT, OUTSTRING, OUTSTRING_AT
              XREF  INITKEY, LKEY_FLG, GETCHAR
              XREF  LCDTEMPLATE, UPDATELCD_L1, UPDATELCD_L2
              XREF  LVREF_BUF, LVACT_BUF, LERR_BUF,LEFF_BUF, LKP_BUF, LKI_BUF
              XREF  Entry, ISR_KEYPAD
            
;/------------------------------------------------------------------------------------\
;| Assembler Equates                                                                  |
;\------------------------------------------------------------------------------------/
; Constant values can be equated here



;/------------------------------------------------------------------------------------\
;| Variables in RAM                                                                   |
;\------------------------------------------------------------------------------------/
; The following variables are located in unpaged ram

DEFAULT_RAM:  SECTION

TMP DS.B 1


;/------------------------------------------------------------------------------------\
;|  Main Program Code                                                                 |
;\------------------------------------------------------------------------------------/
; Your code goes here

MyCode:       SECTION
main:   
        
        
       ldd #$9C40
       ldy #$9C40
loop: 
       bgnd 
       jsr sat_add 
        
        
        
        
        
spin:   bra   loop                    ; endless horizontal loop


;/------------------------------------------------------------------------------------\
;| Subroutines                                                                        |
;\------------------------------------------------------------------------------------/
; General purpose subroutines go here

 sat_add: 
 
 ;push registers to the stack to maintain them
 
       pshx 
       
 ;add the contents of d and y 
 
       sty TMP
       addd TMP 
       
 ;check if there is an overflow  and if its negative or positive 
 ;if there is, saturate d with either -32,768 or 32,767 
 ;if not, keep the results     
 
       bvc skip_overflow 
       bpl skip_negative 
       ldd #$8000        
        
 skip_negative: 
             
       ldd #$7FFF  

 ;restore the registers from the stack 
 
 skip_overflow: 
 
        pulx  
        rts 



;/------------------------------------------------------------------------------------\
;| ASCII Messages and Constant Data                                                   |
;\------------------------------------------------------------------------------------/
; Any constants can be defined here


;/------------------------------------------------------------------------------------\
;| Vectors                                                                            |
;\------------------------------------------------------------------------------------/
; Add interrupt and reset vectors here

        ORG   $FFFE                    ; reset vector address
        DC.W  Entry

