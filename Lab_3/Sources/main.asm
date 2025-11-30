;**************************************************************************************
;* Lab 3 Main [includes LibV2.2]                                                      *
;**************************************************************************************
;* Summary:                                                                           *
;*   Main For Lab 3, DUE 11/02/2023                                                                                *
;*                                                                                    *
;* Author: Aiden Taylor & Julia Fay                                                   *
;*   Cal Poly University                                                              *
;*   Fall 2023                                                                        *
;*                                                                                    *
;* Revision History:                                                                  *
;*   -                                                                                *
;*                                                                                    *
;* ToDo:                                                                              *
;*    -DONE!
;* 
;* 
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

PORTP EQU $0258         ; output port for LEDs
DDRP EQU $025A
G_LED_1 EQU %00010000   ; green LED output pin for LED pair_1
R_LED_1 EQU %00100000   ; red LED output pin for LED pair_1
LED_MSK_1 EQU %00110000 ; LED pair_1
G_LED_2 EQU %01000000   ; green LED output pin for LED pair_2
R_LED_2 EQU %10000000   ; red LED output pin for LED pair_2
LED_MSK_2 EQU %11000000 ; LED pair_2



;/------------------------------------------------------------------------------------\
;| Variables in RAM                                                                   |
;\------------------------------------------------------------------------------------/
; The following variables are located in unpaged ram

DEFAULT_RAM:  SECTION

;params for t1 

COUNT DS.B 1
F1_FLG  DS.B 1
F2_FLG  DS.B 1
ON1     DS.B 1 
ON2     DS.B 1 
MM_ERR  DS.B 1 

;params for t2 
KEY_FLG DS.B 1
KEY_BUFF DS.B 1

;params for t3
MSG_NUM DS.B 1
LNUM DS.B 1


;params for t4

DONE_1 DS.B 1

;params for t5

TICKS_1 DS.W 1
COUNT_1 DS.W 1

;params for t6

DONE_2 DS.B 1

;params for t7

TICKS_2 DS.W 1
COUNT_2 DS.W 1

;state vars
t1state DS.B 1
t2state DS.B 1
t3state DS.B 1
t4state DS.B 1
t5state DS.B 1
t6state DS.B 1
t7state DS.B 1
t8state DS.B 1

;subroutines ---------

;convert
RESULT DS.W 1 
BUFFER DS.B 5
TMP DS.B 1
ERR DS.B 1 

;input
INPUT DS.B 1
DPTR DS.W 1
FIRSTCH DS.B 1

;display
COUNT_ERR DS.W 1
TICKS_ERR DS.W 1

;/------------------------------------------------------------------------------------\
;|  Main Program Code                                                                 |
;\------------------------------------------------------------------------------------/
; Your code goes here

MyCode:       SECTION
main:  
        clr t1state ; initialize all tasks to state 0
        clr t2state
        clr t3state
        clr t4state
        clr t5state
        clr t6state
        clr t7state
        clr t8state
       
Top:
        ;bgnd
        jsr TASK_1 ; execute tasks endlessly
        jsr TASK_2
        jsr TASK_3
        jsr TASK_4
        jsr TASK_5
        jsr TASK_6
        jsr TASK_7
        jsr TASK_8
        bra Top       
       
spin:   bra spin

;-------------TASK_1 MASTERMIND ---------------------------------------------------------

TASK_1: 
        ;bgnd
        ldaa t1state ; get current t1state and branch accordingly
        beq t1s0
        deca
        beq t1s1
        deca
        lbeq t1s2
        deca
        lbeq t1s3
        deca
        lbeq t1s4
        deca
        lbeq t1s5
        deca
        lbeq t1s6
        deca
        lbeq t1s7
        rts          ; undefined state - do nothing but return
;__________________________________________________________________________________
t1s0: ; init TASK_1

;clear all of the flags and relevant ITCVs 
        clr TICKS_1
        clr TICKS_2
        clr F1_FLG 
        clr F2_FLG 
        clr KEY_FLG 
        clr COUNT
        jsr clearbuffer                             ;clear buffer
        movb #$01, t1state                          ;set next state
        lbra exit1                                  ;exit
;__________________________________________________________________________________
t1s1: ;

        tst KEY_FLG                                 ;first test if there is a key to be checked
        lbeq exit1                                  ;if there is no key exit


;check if its F1
 
        ;bgnd
        ldaa KEY_BUFF                               ;load accumulator A with the current char
        tst F1_FLG                                  ;test if F1_FLG has already been pressed 
        bne skipF1                                  ;skip if it has already been pressed
        tst F2_FLG                                  ;test if F2_FLG has already been pressed
        bne skipF1                                  ;skip if F2 has already been pressed
        cmpa #$F1                                   ;if not pressed compare whats in A to F1 
        bne skipF1                                  ;if its not F1, skip settting the state
        movb #$05 , t1state                         ;set the state to the appropriate number  
        lbra exit1                                  ;exit

skipF1:  

;check if its F2
                          
        tst F2_FLG                                  ;test F2_FLG to see if it has been pressed
        bne skipF2                                  ;skip if F1 has already been pressed
        tst F1_FLG                                  ;test F1_FLG to see if it has been pressed
        bne skipF2                                  ;skip if either have been pressed
        cmpa #$F2                                   ;compare whats in A to F2
        bne skipF2                                  ;if its not F2, skip settting the state
        movb #$06 , t1state                         ;set the state to the appropriate number 
        lbra exit1                                  ;exit

skipF2:

;check if its a BS 
       
        cmpa #$08                                   ;compare whats in A to BS 
        bne skipBS                                  ;if its not BS, skip settting the state 
        movb #$04 , t1state                         ;set the state to the appropriate number 
        lbra exit1                                  ;exit

skipBS: 

;check if its a ENT  

        cmpa #$0A                                   ;compare whats in A to ENT 
        bne skipENT                                 ;if its not BS, skip settting the state 
        movb #$03 , t1state                         ;set the state to the appropriate number 
        lbra exit1                                  ;exit
        
skipENT: 

;check if its a digit
 
;load contents of a into b to ensure + signed arithmetic is occuring to avoid errors with F1 and F2 

        psha                                        ;push whats in a to the stack 
        pulb                                        ;pul what was in a into b 
        ldaa #$00                                   ;put zeros in a to make it a positive num
        
        cpd #$39                                    ;check if what in A is a number 
        bgt skipDIGIT                               ;if its not a number, disregard the input
        pshb                                        ;restore the stack 
        pula
         
        movb #$02 , t1state                         ;set the state to digit handler 
        lbra exit1                                  ;exit

skipDIGIT: 

        clr KEY_FLG
        lbra exit1                                  ;exit

;___________________________________________________________________________________

t1s2: ;Digit Handler 

;checks if we should proceed with the digit handler state 

        ldab COUNT                                  ;load b with count 
        cmpb #$05                                   ;check if count is 5
        beq toomany                                 ;if count is 5 stop taking inputs and leave
        tst F1_FLG                                  ;test F1 flag 
        bne skip_e                                  ;if not equal to 0, skip exiting 
        tst F2_FLG                                  ;test the F2 flag 
        bne skip_e                                  ;if not equal to 0, skip exiting 
        clr KEY_FLG                                 ;clear keyflag 
        movb #$01 , t1state                         ;set the state back to 1
        lbra exit1                                  ;exit  

toomany:
        movb #$01, t1state                          ;set the state back to 1 
        clr KEY_FLG                                 ;clear keyflag 
        lbra exit1                                  ;exit
skip_e:

;now proceed with the digit handler
   
        ldy #BUFFER                                 ;load index register y with buffer 
        ldaa COUNT                                  ;load A with the current value of COUNT 
        ldab KEY_BUFF                               ;load b with KEY_BUFF 
        stab a,y                                    ;store the contents of b at the position of COUNT in BUFFER
       
        inc COUNT                                   ;increment count 
        movb #$00, KEY_FLG                          ;set key flag to 0 to acknowledge KEYPAD
        movb #$01 , t1state                         ;set the state back to 1
        clr KEY_FLG                                 ;clear key flag
         
        movb #$0C, t3state                          ;set state in display task to echo the char
        lbra exit1                                  ;exit 
;________________________________________________________________________________________
t1s3: ;ENT 
 

;before jsr to conversion, check if any digits have been entered into buffer      
      
       jsr clrcurs                                 ;turn off the cursor when enter is hit   
       tst COUNT                                   ;test the current value of count 
       bne skip_NO_DIGITS                          ;if the count is not zero, branch 
       ldaa #$03                                   ;if the count is zero, put an error code into A 
       bra skip_F2                                 ;branch to the set error state below 
       

skip_NO_DIGITS: 

;send to conversion to get a BCD form of the input 
    
       jsr conversion                              ;convert the contents of buffer to binary 
       clr COUNT                                   ;set count back to zero 
       clr BUFFER                                  ;clear the contents of the BUFFER
       
;check which ON flag to set 
 
       tst F1_FLG                                  ;test the F1 flag
       beq skip_F1_a                               ;if the flag is zero, skip the next steps 
       movb #01, ON1                               ;if the flag is 1, set ON1 to be true
       stx TICKS_1                                 ;store the results of the conversion 
         
skip_F1_a:  
 
       tst F2_FLG                                  ;test the F2 flag
       beq skip_F2                                 ;if the flag is zero, skip the next steps 
       movb #$01, ON2                              ;if the flag is 1, set ON2 to be true
       stx TICKS_2                                 ;store the results of the conversion

skip_F2:

;automatically set the state back to 1 for all cases  

       movb #$01, t1state                          ;set the state back to 1 
       
;check for error and set variables and state accordingly so that user has to start over 

       ;bgnd
       cmpa #$00                                   ;check whats in A 
       beq skipERROR                               ;check if an error was generated from conversion
       movb #$07, t1state                          ;if there is an error code set the state to the 
                                                   ;error state
       staa MM_ERR                                 ;store the error code of accumulator A into a variable 
                                                   ;so it is not affected by other code before it gets to 
                                                   ;the error state                                              
                                                     
;check which ON variable needs to be cleared if there is an error 
      
      tst F1_FLG                                   ;test the F1 flag
      beq skip_F1_b                                ;if the flag is zero, skip the next steps 
      clr ON1                                      ;clear ON1
      clr TICKS_1                                  ;clear TICKS_1
      lbra exit1                                   ;exit
      
skip_F1_b: 
 
      tst F2_FLG                                   ;test the F2 flag
      beq skipERROR                                ;if the flag is zero, skip the next steps
      clr ON2                                      ;clear ON2 
      clr TICKS_2                                  ;clear TICKS_2
      clr KEY_FLG                                  ;clear key flag
      jsr clearbuffer
      jsr CURSOR_OFF   
      lbra exit1                                   ;exit without clearing F1 and F2 flags 
                  
skipERROR:

;if there are no errors, clear the F1 and F2 flags and exit     
      
      jsr clearbuffer
      jsr CURSOR_OFF 
      clr KEY_FLG 
      clr F1_FLG 
      clr F2_FLG
      movb #$01, DONE_1
      movb #$01, DONE_2  
      lbra exit1                                    ;exit
 ;________________________________________________________________________________________
t1s4: ;BS
 
       movb #$02 , t3state                         ;set the state in task 3 to the BS state   
       movb #$01 , t1state                         ;set the state back to 1
       clr KEY_FLG 
       lbra exit1                                   ;exit
 ;________________________________________________________________________________________
t1s5: ;F1 state 
 
       
       movb #$01, F1_FLG                           ;set the F1_FLG to be true
       movb #$01 , t1state                         ;set the state back to 1
       clr ON1 
       clr KEY_FLG
       ldaa #$08
       jsr SETADDR
       jsr CURSOR_ON
       movb #$03, MSG_NUM
       bra exit1                                   ;exit
       
 ;________________________________________________________________________________________
t1s6: ;F2 state 
 
       movb #$01, F2_FLG                           ;set the F2_FLG to be true
       movb #$01 , t1state                         ;set the state back to 1
       clr ON2
       clr KEY_FLG
       ldaa #$48
       jsr SETADDR
       jsr CURSOR_ON
       movb #$04, MSG_NUM 
       bra exit1                                   ;exit

;________________________________________________________________________________________
t1s7: ;Error state 


;checks the error code in accumulator A and which F flag is set to set the appropiate fixed 
;message state to be displayed through task 3 

;split the code into two sections. the F1 and F2 sections 
  
;fist test the F1 flag 
       ;bgnd
       ldaa MM_ERR
       tst F1_FLG                                   ;test the F1 flag
       beq skip_F1_e                                ;if the flag is zero, skip the next steps    
 
;now check the error number and set the message number for task 3 
 
                                         ;put the error number back into accumulator a 
       cmpa #01                                     ;check if the error code is mag to large 
       bne skip_F1_toolarge                         ;skip setting the message num
       movb #$09, MSG_NUM                           ;set the appropiate message num 

skip_F1_toolarge: 

       cmpa #02                                     ;check if the error code is zero magnitude 
       bne skip_F1_zeromag                          ;skip setting the message num
       movb #$07, MSG_NUM                           ;set the appropiate message num 

skip_F1_zeromag: 

       cmpa #03                                     ;check if the error code is zero digits
       bne skip_F1_e                                ;skip setting the message num
       movb #$05, MSG_NUM                           ;set the appropiate message num    
   
skip_F1_e: 
 
;now test the F2 flag 
 
       tst F2_FLG                                   ;test the F1 flag
       beq skip_F2_e                                ;if the flag is zero, skip the next steps    
 
;now check the error number and set the message number for task 3 
 
       cmpa #01                                     ;check if the error code is mag to large 
       bne skip_F2_toolarge                         ;skip setting the message num
       movb #$0A, MSG_NUM                           ;set the appropiate message num 

skip_F2_toolarge: 

       cmpa #02                                     ;check if the error code is zero magnitude 
       bne skip_F2_zeromag                          ;skip setting the message num
       movb #$08, MSG_NUM                           ;set the appropiate message num 

skip_F2_zeromag: 

       cmpa #03                                     ;check if the error code is zero digits
       bne skip_F2_e                                ;skip setting the message num
       movb #$06, MSG_NUM                           ;set the appropiate message num 
 
skip_F2_e: 

 ;clear the F1 and F2 flags and fall through to the exit 

        clr F1_FLG 
        clr F2_FLG
        movb #$01 , t1state                         ;set the state back to 1
        jsr clearbuffer
        clr KEY_FLG

exit1:
        ;clr KEY_FLG
        rts
;----------------------TASK 2 - KEYPAD -------------------------------------------; 
 
TASK_2:
 
        ldaa t2state ;get state
        beq t2s0
        deca
        beq t2s1
        deca
        beq t2s2
        rts

t2s0:   ;init
        
        jsr INITKEY       ;initialize keypad
        movb #$01, t2state
        rts
        
t2s1:   ;Wait for Key   
   
        tst LKEY_FLG             ;check if there is a digit in the buffer 
        beq exit2                ;if no key then exit 
        jsr GETCHAR              ;get the character 
        stab KEY_BUFF            ;stores the input char into key buffer
        movb #$01, KEY_FLG       ;set ITCV keyflag to notifiy MM of key input
        movb #$02, t2state       ;set the state to state 2 
        bra exit2                ;exit
        
t2s2:   ;Wait for Acknowledgement 

        tst KEY_FLG              ;test the ITCV KEY_FLG 
        bne exit2                ;if it is still 1 then do not change state 
        movb #$01, t2state       ;if it is 0, set state back to 1 
        

exit2: rts                       ;exit 
        
        
;---------------------TASK 3 - DISPLAY ---------------------------------------------;

TASK_3:

        ldaa t3state
        beq t3s0
        deca
        beq t3s1
        deca
        beq t3s2
        deca
        beq t3s3
        deca
        beq t3s4
        deca
        lbeq t3s5
        deca
        lbeq t3s6
        deca
        lbeq t3s7
        deca
        lbeq t3s8
        deca
        lbeq t3s9
        deca
        lbeq t3s10
        deca
        lbeq t3s11
       deca 
       lbeq t3s12
        rts
        
t3s0:   ;init    
        
        jsr INITLCD             ;initialize LCD
        movb #$01, FIRSTCH      ;set first char to be true 
        ldaa #$00               ;set LCD position to 0
        jsr SETADDR             ;set the address 
        movw #$07D0, TICKS_ERR  ;set the ticks error to be ___
        movb #$0B, t3state      ;automatically go to state 11  
        rts                     ;exit 
        
t3s1:   ;hub
             
        movb #$01, FIRSTCH      ;set first char to be true  
        ldab MSG_NUM            ;load message number into b 
        stab t3state            ;store message number in state 
        movb #$01, MSG_NUM      ;reset message num       
        rts                     ;exit


t3s2:   ;backspace 

        jsr backspace           ;go to backspace subroutine 
        movb #$01, t3state      ;reset to state 1 
        rts                     ;exit

        
t3s3:   ;full time1 message     
        
        clr LNUM                ;clear LCD line number variable to set line number to the top 
        ldaa #$00               ;set the address in accumulator a  
        ldx #TIME1              ;load the time1 message into x 
        tst FIRSTCH             ;check if its first character 
        lbne char1              ;branch to the char1 line where you jump to char1 subroutine 
        jsr PUTCHAR             ;otherwise jsr to the regular putchar subroutine 
        rts                     ;exit
        
        
t3s4:   ;full time2 message
       
        movb #$01, LNUM         ;load a 1 into LNUM to set line number to the bottom 
        ldaa #$40               ;set the LCD address in accumulator a 
        ldx #TIME2              ;load time 2 message into x 
        tst FIRSTCH             ;check if its first character 
        lbne char1              ;branch to the char1 line where you jump to char1 subroutine
        jsr PUTCHAR             ;otherwise jsr to the regular putchar subroutine 
        rts                     ;exit


t3s5:   ;no digit 1 message
       
        clr LNUM                ;clear LCD line number variable to set line number to the top
        ldaa #$00               ;set the LCD address in accumulator a
        ldx #NODIG1             ;load message into x 
        tst FIRSTCH             ;check if its first character
        bne char1               ;branch to the char1 line where you jump to char1 subroutine
        jsr PUTCHAR             ;otherwise jsr to the regular putchar subroutine
        rts                     ;exit


t3s6:   ;no digit 2 message
       
        movb #$01, LNUM         ;load a 1 into LNUM to set line number to the bottom 
        ldaa #$40               ;set the LCD address in accumulator a 
        ldx #NODIG2             ;load message into x 
        tst FIRSTCH             ;check if its first character
        bne char1               ;branch to the char1 line where you jump to char1 subroutine
        jsr PUTCHAR             ;otherwise jsr to the regular putchar subroutine
        rts                     ;exit
        

t3s7:   ;zero magnitude 1 message
      
        clr LNUM                ;clear LCD line number variable to set line number to the top
        ldaa #$00               ;set the LCD address in accumulator a
        ldx #ZMAG1              ;load message into x 
        tst FIRSTCH             ;check if its first character
        bne char1               ;branch to the char1 line where you jump to char1 subroutine
        jsr PUTCHAR             ;otherwise jsr to the regular putchar subroutine
        rts               ;exit

t3s8:   ;zero magnitude 2 message
       
        movb #$01, LNUM         ;load a 1 into LNUM to set line number to the bottom 
        ldaa #$40               ;set the LCD address in accumulator a 
        ldx #ZMAG2              ;load message into x 
        tst FIRSTCH             ;check if its first character
        bne char1               ;branch to the char1 line where you jump to char1 subroutine
        jsr PUTCHAR             ;otherwise jsr to the regular putchar subroutine
        rts               ;exit

t3s9:   ;magnitude too large 1 message
       
        clr LNUM                ;clear LCD line number variable to set line number to the top
        ldaa #$00               ;set the LCD address in accumulator a
        ldx #MAGTL1             ;load message into x 
        tst FIRSTCH             ;check if its first character
        bne char1               ;branch to the char1 line where you jump to char1 subroutine
        jsr PUTCHAR             ;otherwise jsr to the regular putchar subroutine
        rts                     ;exit


t3s10:  ;magnitude too large 2 message
        
        movb #$01, LNUM         ;load a 1 into LNUM to set line number to the bottom 
        ldaa #$40               ;set the LCD address in accumulator a 
        ldx #MAGTL2
       tst FIRSTCH              ;check if its first character
        bne char1               ;branch to the char1 line where you jump to char1 subroutine
        jsr PUTCHAR             ;otherwise jsr to the regular putchar subroutine
        rts                     ;exit

t3s11:  ;display full screen (init message)

        ldx #INITMSG            ;load the F1 and F2 starting screen 
        tst FIRSTCH             ;check if its the first character 
        bne initmsg             ;if first char, go to the char1 subroutine 
        jsr ICHAR               ;if not go to regular subroutine 
        rts                     ;exit                     
       
initmsg: ;first char of init message
       
        jsr ICHAR1              ;go to starting message first char subroutine 
        rts                     ;exit
       
char1:  ;first char of any message

        jsr PUTCHAR1            ;go to general first char subroutine 
        rts                     ;exit

t3s12:  ;echo 

        ldab KEY_BUFF           ;load accumulator b with whats in KEY_BUFF 
        jsr OUTCHAR             ;display the inputted digit 
        movb #$01, t3state      ;reset to state 1
        
exit3:

        rts
       
;------------------TASK 4--------------------------------------------------
;pattern 1

TASK_4: 

        ldaa t4state ; get current t4state and branch accordingly
        beq t4state0
        deca
        
        tst ON1
        beq turnofft4
        
        ldaa t4state ; get current t4state and branch accordingly
        beq t4state0
        deca
        beq t4state1
        deca
        beq t4state2
        deca
        beq t4state3
        deca
        beq t4state4
        deca
        beq t4state5
        deca
        beq t4state6
        deca
        beq t4state7
        rts ; undefined state - do nothing but return
        
turnofft4:
        ;changes lights to off
        bclr PORTP, LED_MSK_1
        movb #$07, t4state
        rts
        
        
t4state0: ; init TASK_1 (not G, not R)
        clr ON1
        bclr PORTP, LED_MSK_1 ; ensure that LEDs are off when initialized
        bset DDRP, LED_MSK_1 ; set LED_MSK_1 pins as PORTS outputs
        movb #$01, t4state ; set next state
        rts
        
t4state1: ; G, not R
        bset PORTP, G_LED_1 ; set state1 pattern on LEDs
        tst DONE_1 ; check TASK_4 done flag
        beq exit_t4s1 ; if not done, return
        movb #$02, t4state ; otherwise if done, set next state
exit_t4s1:
        rts
        
t4state2: ; not G, not R
        bclr PORTP, G_LED_1 ; set state2 pattern on LEDs
        tst DONE_1 ; check TASK_4 done flag
        beq exit_t4s2 ; if not done, return
        movb #$03, t4state ; otherwise if done, set next state
exit_t4s2:
        rts
        
t4state3: ; not G, R
        bset PORTP, R_LED_1 ; set state3 pattern on LEDs
        tst DONE_1 ; check TASK_4 done flag
        beq exit_t4s3 ; if not done, return
        movb #$04, t4state ; otherwise if done, set next state
exit_t4s3:
        rts
        
t4state4 ; not G, not R
        bclr PORTP, R_LED_1 ; set state4 pattern on LEDs
        tst DONE_1 ; check TASK_4 done flag
        beq exit_t4s4 ; if not done, return
        movb #$05, t4state ; otherwise if done, set next state
exit_t4s4:
        rts
        
t4state5: ; G, R
        bset PORTP, LED_MSK_1 ; set state5 pattern on LEDs
        tst DONE_1 ; check TASK_4 done flag
        beq exit_t4s5 ; if not done, return
        movb #$06, t4state ; otherwise if done, set next state
exit_t4s5:
        rts
        
t4state6: ; not G, not R
        bclr PORTP, LED_MSK_1 ; set state6 pattern on LEDs
        tst DONE_1 ; check TASK_4 done flag
        beq exit_t4s6 ; if not done, return
        movb #$01, t4state ; otherwise if done, set next state
exit_t4s6:
        rts ; exit TASK_4
        
t4state7: 
        
        bclr PORTP, LED_MSK_1
        movb #$01, t4state
        rts         
 


;------------------TASK 5--------------------------------------------------
;timing 1

TASK_5: ldaa t5state ; get current t5state and branch accordingly
        beq t5state0
        deca
        beq t5state1
        rts ; undefined state - do nothing but return
        
t5state0: ; initialization for TASK_5
        movw #$00FF, TICKS_1
        movw TICKS_1, COUNT_1 ; init COUNT_1
        clr DONE_1 ; init DONE_1 to FALSE
        movb #$01, t5state ; set next state
        rts
        
t5state1: ; Countdown_1
        ldaa DONE_1   ;load accumulator A with DONE_1 
        cmpa #$01     ;check if DONE_1 - 1 = 0 
        bne t5s1a ; skip reinitialization if DONE_1 is not = 1
        
        ;reinitialize if DONE_1 = 1 
        
        movw TICKS_1, COUNT_1 ; init COUNT_1
        clr DONE_1 ; init DONE_1 to FALSE
        
       ;after reinitialization, you still decrement
        
t5s1a:  decw COUNT_1    ;decrement COUNT_1
        bne exit_t5s2   ;if COUNT_1 is not equal to zero, exit 
        movb #$01, DONE_1     ;if COUNT_1 is zero, set DONE_1 to 1
     
        
exit_t5s2:
        rts ; exit TASK_5






;------------------TASK 6--------------------------------------------------
;pattern 2

TASK_6: 
         
        tst ON2
        beq turnofft6

        ldaa t6state ; get current t1state and branch accordingly
        beq t6state0
        deca
        beq t6state1
        deca
        beq t6state2
        deca
        beq t6state3
        deca
        beq t6state4
        deca
        beq t6state5
        deca
        beq t6state6
        deca
        beq t6state7
        rts ; undefined state - do nothing but return
        
turnofft6:
        ;changes lights to off
        bclr PORTP, LED_MSK_2
        movb #$07, t6state
        rts    
        
t6state0: ; init TASK_1 (not G, not R)
        clr ON2
        bclr PORTP, LED_MSK_2 ; ensure that LEDs are off when initialized
        bset DDRP, LED_MSK_2 ; set LED_MSK_1 pins as PORTS outputs
        movb #$01, t6state ; set next state
        rts
        
t6state1: ; G, not R
        bset PORTP, G_LED_2 ; set state1 pattern on LEDs
        tst DONE_2 ; check TASK_4 done flag
        beq exit_t6s1 ; if not done, return
        movb #$02, t6state ; otherwise if done, set next state
exit_t6s1:
        rts
        
t6state2: ; not G, not R
        bclr PORTP, G_LED_2 ; set state2 pattern on LEDs
        tst DONE_2 ; check TASK_1 done flag
        beq exit_t6s2 ; if not done, return
        movb #$03, t6state ; otherwise if done, set next state
exit_t6s2:
        rts
        
t6state3: ; not G, R
        bset PORTP, R_LED_2 ; set state3 pattern on LEDs
        tst DONE_2 ; check TASK_2 done flag
        beq exit_t6s3 ; if not done, return
        movb #$04, t6state ; otherwise if done, set next state
exit_t6s3:
        rts
        
t6state4 ; not G, not R
        bclr PORTP, R_LED_2 ; set state4 pattern on LEDs
        tst DONE_2 ; check TASK_2 done flag
        beq exit_t6s4 ; if not done, return
        movb #$05, t6state ; otherwise if done, set next state
exit_t6s4:
        rts
        
t6state5: ; G, R
        bset PORTP, LED_MSK_2 ; set state5 pattern on LEDs
        tst DONE_2 ; check TASK_2 done flag
        beq exit_t6s5 ; if not done, return
        movb #$06, t6state ; otherwise if done, set next state
exit_t6s5:
        rts
        
t6state6: ; not G, not R
        bclr PORTP, LED_MSK_2 ; set state6 pattern on LEDs
        tst DONE_2 ; check TASK_2 done flag
        beq exit_t6s6 ; if not done, return
        movb #$01, t6state ; otherwise if done, set next state
exit_t6s6:
        rts ; exit TASK_4
        
t6state7: 
        
        bclr PORTP, LED_MSK_2
        movb #$01, t6state
        rts 
        

;------------------TASK 7--------------------------------------------------
;timing 2

TASK_7: ldaa t7state ; get current t2state and branch accordingly
        beq t7state0
        deca
        beq t7state1
        rts ; undefined state - do nothing but return
        
t7state0: ; initialization for TASK_7
        movw #$00FF, TICKS_2
        movw TICKS_2, COUNT_2 ; init COUNT_2
        clr DONE_2 ; init DONE_2 to FALSE
        movb #$01, t7state ; set next state
        rts
        
t7state1: ; Countdown_1
        ldaa DONE_2   ;load accumulator A with DONE_2 
        cmpa #$01     ;check if DONE_2 - 1 = 0 
        bne t7s1a ; skip reinitialization if DONE_2 is not = 1
        
        ;reinitialize if DONE_2 = 1 
        
        movw TICKS_2, COUNT_2 ; init COUNT_2
        clr DONE_2 ; init DONE_2 to FALSE
        
       ;after reinitialization, you still decrement
        
t7s1a:  decw COUNT_2    ;decrement COUNT_2
        bne exit_t7s2   ;if COUNT_2 is not equal to zero, exit 
        ;bgnd
        movb #$01, DONE_2     ;if COUNT_1 is zero, set DONE_2 to 1
     
        
exit_t7s2:
        rts ; exit TASK_7


;------------------TASK 8--------------------------------------------------
          ;delay
          
TASK_8: ldaa t8state ; get current t3state and branch accordingly
        beq t8state0
        deca
        beq t8state1
        rts ; undefined state - do nothing but return

t8state0: ; initialization for TASK_8
        ; no initialization required
        movb #$01, t8state ; set next state
        rts

t8state1:
        jsr DELAY_1ms
        rts ; exit TASK_8
        
         
;/------------------------------------------------------------------------------------\
;| Subroutines                                                                        |
;\------------------------------------------------------------------------------------/
; General purpose subroutines go here

 ;---------------------------------------------------------------------------------------     
         
  backspace:
  
        tst COUNT                     ;test if count is zero
        beq bkspexit                  ;if the count is zero, dont allow backspace to occur 
        jsr GETADDR                   ;get current position of LCR
        deca                          ;decrement one
        jsr SETADDR                   ;set address to new position
        ldx #BACKSPACE                ;load a blank space 
        jsr OUTSTRING                 ;output a blank space
        jsr GETADDR                   ;get current position of LCR
        deca                          ;decrement one
        jsr SETADDR                   ;set address to new position
        dec COUNT                     ;reset the value of count
  
bkspexit:

       rts
       
  
  ;------CONVERSIONS---------------------------------------------------------------------------;

conversion:
		
;clear all variables 

	    	clrw RESULT
	    	clr TMP
	     	clr ERR
	    	ldx #BUFFER
	    	
;pushes registers to stack so that they remain unchanged by the subroutine 
	  
  	   	pshy		
  	  	pshb
  	  	pshc
		
		
convloop:

	
	    	ldaa COUNT		;check if COUNT has finished for loop
	    	beq loopfin		;branch to exit if COUNT is done
		
		
	     	ldy RESULT		;load current value of RESULT into register y for use
	    	ldd #$000A		;load hex 10 into accumulator for use
    		emul			    ;multiply register y and acc d
	    	tsty          ;sets flag for y
	    	bne ERR1      ;checks if the multiplication overflowed to y
	    	std RESULT		;keep the bottom 2 bytes of the emul since we are never dealing with 4 bit nums
		
		
		
	    	ldaa TMP	  	;TMP is used for index addressing
	    	ldab a,x	  	;reference the correct digit in the BUFFER using TMP
	    	subb #$30	  	;subtract $30 to get the decimal value of the ascii code
	    	
		
	    	clra
	    	addd RESULT		;add RESULT and acc d 
	    	bcs ERR1      ;branch if the addition triggers an overflow, causing error 1
	    	std RESULT		;store addition in RESULT
	    	inc TMP		  	;inc TMP so that BUFFER digits are correctly referenced
	    	dec COUNT		  ;dec COUNT to track how long the loop has operated for
	    	bra convloop
			

ERR1:		

	    	movb #$01, ERR ;set ERR for MAGNITUDE TOO LARGE
    		bra cnvexit
	
loopfin:
		
	    	ldx RESULT     ;load x with result 
	    	bne cnvexit	   ;if the result is zero, fall through and set error state
		
ERR2:

	    	movb #$02, ERR  ;set ERR for ZERO MAGNITUDE INAPPROPRIATE

cnvexit:

	    	ldaa ERR		;load ERRor into accumulator a
	    	
;pulls registers from stack to restore them to pre-subroutine states

	    	pulc        
	    	pulb
    		puly
    		rts         ;return
        

;-------------------Cooperative Fixed Messaging-------------------------------------------;        

PUTCHAR1:
    
        stx DPTR                      ;store the contents of x into DPTR 
        jsr SETADDR                   ;set the address on the LCD 
        clr FIRSTCH                   ;clear first char  
        movw TICKS_ERR, COUNT_ERR     ;initialize the amount of ticks an error will disply for
          
PUTCHAR:  
        
        ldx DPTR                      ;put whats in DPTR into x 
        ldab 0,x                      ;input the current char to be displayed in b 
        beq ERR_DELAY                 
        incw DPTR                     ;increment the position of DPTR to get next character 
        jsr OUTCHAR                   ;output the current charater 
        rts                           ;exit 

mess_exit:

        movb #$01, t3state
        movb #$01, MSG_NUM
        jsr clrcurs
        tst F1_FLG
        bne F1addressset
        tst F2_FLG
        bne F2addressset
        rts
        
        
ERR_DELAY:
       
        jsr clrcurs
        ldaa t3state
        cmpa #$04
        ble mess_exit
        tst COUNT_ERR
        beq err_exit
        decw COUNT_ERR
        rts
            
err_exit:
        
        tst LNUM
        bne F2errexit
        movb #$03, MSG_NUM
        movb #$01, t3state
        rts
            
F2errexit:  

        movb #$04, MSG_NUM
        movb #$01, t3state
        rts
         
F1addressset:

        ldaa #$08
        jsr SETADDR
        rts
          
F2addressset:

        ldaa #$48
        jsr SETADDR 
        rts 

clrcurs: ;resets the cursor address 

        psha
        ldaa #$30
        jsr SETADDR
        pula
        rts
        
;-------------------Cooperative Fixed init message-----------------------

ICHAR1: 
         
        stx DPTR
        jsr SETADDR
        clr FIRSTCH
          
ICHAR:        
       
        ldx DPTR
        ldab 0,x
        beq mess_exit
        incw DPTR
        jsr OUTCHAR
        jsr GETADDR
        cmpa #$28
        beq changeline
        rts

changeline: 

        ldaa #$40
        jsr SETADDR
        rts


;----------------------Delay----------------------------

DELAY_1ms:
        ldy #$0584
        INNER: ; inside loop
        cpy #0
        beq EXIT
        dey
        bra INNER
        EXIT:
        rts ; exit DELAY_1ms
        
        
        
;-----------------clearbuffer----------------------   

clearbuffer:

;reset the buffer so it is full of zeros 

        ldx #BUFFER
        ldaa #$00
        clr a, x
        inca
        clr a, x
        inca
        clr a, x
        inca
        clr a, x
        inca
        clr a, x
        rts


;/------------------------------------------------------------------------------------\
;| ASCII Messages and Constant Data                                                   |
;\------------------------------------------------------------------------------------/
; Any constants can be defined here

 INITMSG: DC.B 'TIME1 =       <F1> to update LED1 periodTIME2 =       <F2> to update LED1 period', $00
 TIME1:  DC.B 'TIME1 =       <F1> to update LED1 period', $00
 TIME2:  DC.B 'TIME2 =       <F2> to update LED1 period', $00
 NODIG1: DC.B 'TIME1 = NO DIGITS ENTERED               ', $00
 NODIG2: DC.B 'TIME2 = NO DIGITS ENTERED               ', $00
 ZMAG1:  DC.B 'TIME1 = ZERO MAGNITUDE INAPPROPRIATE    ', $00
 ZMAG2:  DC.B 'TIME2 = ZERO MAGNITUDE INAPPROPRIATE    ', $00
 MAGTL1: DC.B 'TIME1 = MAGNITUDE TOO LARGE             ', $00
 MAGTL2: DC.B 'TIME2 = MAGNITUDE TOO LARGE             ', $00
 BACKSPACE: DC.B ' ' , $00 
 
 
;/------------------------------------------------------------------------------------\
;| Vectors                                                                            |
;\------------------------------------------------------------------------------------/
; Add interrupt and reset vectors here

        ORG   $FFFE                    ; reset vector address
        DC.W  Entry

