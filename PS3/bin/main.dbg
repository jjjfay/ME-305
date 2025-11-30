;**************************************************************************************
;* Blank Project Main [includes LibV2.2]                                              *
;**************************************************************************************
;* Summary:  PS 3                                                                     *
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

COUNT DS.B 1 
BUFFER DS.B 5  
RESULT DS.W 1 
TMP DS.B 1 

;/------------------------------------------------------------------------------------\
;|  Main Program Code                                                                 |
;\------------------------------------------------------------------------------------/
; Your code goes here

MyCode:       SECTION
main:   
       
       ldx #BUFFER
	   	 movb #$31, 0,x     ;loading ASCII into the the BUFFER
	     movb #$32, 1,x
		   movb #$33, 2,x
		   movb #$34, 3,x
		   movb #$35, 4,x

       movb #$05, COUNT   ;sets COUNT to 5  
       
spin:		
		
		   bgnd               ;bgnd for debugging
		
	     jsr convert     ;calls conversion	  
	  
       bra spin           ;loops 
       

;-------------------------------------------------------------------------------------

convert:

;push all registers and accumulators to the stack so they remain unchanged after the 
;subroutine is complete

        pshb
        pshd
        pshy
        pshc

;initialize variables 

        clrw RESULT              ;sets RESULT to zero
        clr TMP                  ;sets TMP to zero
                                 
        ldx #BUFFER              ;load index register x with the contents of BUFFER                       
                       
                       
convert_loop:
       
;check status of loop
       
        ldaa COUNT             ;load accumulator a with the value of COUNT
        beq convert_error      ;if count is 0 then we are done and set error codes
       
;multiply current result value by 10

        ldy RESULT             ;load index register y with the contents of RESULT
        ldd #$000A             ;load accumulator d with the hex value for 10
        emul                   ;multiply the contents of d with the contents of y
        std RESULT             ;store the contents of accumulator d in result
       
;get the next number to be added

  
        ldaa TMP               ;load index register A with the position value TMP
        ldab a,x               ;load accumulator b with the contents of buffer at position a
        subb #$30              ;subtract #$30 to get the digital value of the numnber
               
;add the number to the multiplied result value and store the result
 
        clra                   ;clear the contents of accumulator a
        addd RESULT            ;add the contents of accumulator d to result
        bcs too_large          ;if an overflow is triggered, go to the error code section 
        std RESULT             ;store the contents of accumulator d in result
        inc TMP                ;increment so the next position can be reached
        dec COUNT              ;decrement count to keep tack of the loop
        bra convert_loop       ;loop back to the top  
 
convert_error:
 
 
;set error code 


        tstw RESULT 
        bne skip_zero                ;branch if result is not equal to zero
        
        ldaa #$02             ;load accumulator a with zero error 
        
        bra convert_exit      ;exit after error code has been set 

skip_zero: 
        
        clra                  ;clear a to set it to 0 indicating no error 
        
        bra convert_exit      ;exit after error code has been set

too_large: 
 
        ldaa #$01             ;load accumulator a with magnitude too large error 
        
        bra convert_exit      ;exit after error code has been set
        
convert_exit:

        bgnd
 
;restore all accumulators and registers from the stack 
 
        pshc
        puly
        puld
        pulb
     
        rts ; return to main         
        

;/------------------------------------------------------------------------------------\
;| Subroutines                                                                        |
;\------------------------------------------------------------------------------------/
; General purpose subroutines go here


;/------------------------------------------------------------------------------------\
;| ASCII Messages and Constant Data                                                   |
;\------------------------------------------------------------------------------------/
; Any constants can be defined here

 MESSAGE: DC.B  'please enter a number: ', $00
 RESPONSE: DC.B 'that was a great choice' , $00
 BACKSPACE: DC.B ' ' , $00 
 
;/------------------------------------------------------------------------------------\
;| Vectors                                                                            |
;\------------------------------------------------------------------------------------/
; Add interrupt and reset vectors here

        ORG   $FFFE                    ; reset vector address
        DC.W  Entry

