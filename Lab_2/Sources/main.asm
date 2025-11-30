;**************************************************************************************
;* Blank Project Main [includes LibV2.2]                                              *
;**************************************************************************************
;* Summary:                                                                           *
;*   -                                                                                *
;*                                                                                    *
;* Author: YOUR NAME                                                                  *
;*   Cal Poly University                                                              *
;*   Spring 2022                                                                      *
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

              XREF ENABLE_MOTOR, DISABLE_MOTOR
              XREF STARTUP_MOTOR, UPDATE_MOTOR, CURRENT_MOTOR
              XREF STARTUP_PWM, STARTUP_ATD0, STARTUP_ATD1
              XREF OUTDACA, OUTDACB
              XREF STARTUP_ENCODER, READ_ENCODER
              XREF INITLCD, SETADDR, GETADDR, CURSOR_ON, CURSOR_OFF, DISP_OFF
              XREF OUTCHAR, OUTCHAR_AT, OUTSTRING, OUTSTRING_AT
              XREF INITKEY, LKEY_FLG, GETCHAR
              XREF LCDTEMPLATE, UPDATELCD_L1, UPDATELCD_L2
              XREF LVREF_BUF, LVACT_BUF, LERR_BUF,LEFF_BUF, LKP_BUF, LKI_BUF
              XREF Entry, ISR_KEYPAD
            
;/------------------------------------------------------------------------------------\
;| Assembler Equates                                                                  |
;\------------------------------------------------------------------------------------/
; Constant values can be equated here

PORTP EQU $0258 ; output port for LEDs
DDRP EQU $025A
G_LED_1 EQU %00010000 ; green LED output pin for LED pair_1
R_LED_1 EQU %00100000 ; red LED output pin for LED pair_1
LED_MSK_1 EQU %00110000 ; LED pair_1
G_LED_2 EQU %01000000 ; green LED output pin for LED pair_2
R_LED_2 EQU %10000000 ; red LED output pin for LED pair_2
LED_MSK_2 EQU %11000000 ; LED pair_2




;/------------------------------------------------------------------------------------\
;| Variables in RAM                                                                   |
;\------------------------------------------------------------------------------------/
; The following variables are located in unpaged ram

DEFAULT_RAM:  SECTION
DONE_1        DS.B 1

DONE_2        DS.B 1
 
TICKS_1       DS.W 1 
COUNT_1       DS.W 1

TICKS_2       DS.W 1 
COUNT_2       DS.W 1 

t1state       DS.B 1
t2state       DS.B 1
t3state       DS.B 1
t4state       DS.B 1
t5state       DS.B 1




;/------------------------------------------------------------------------------------\
;|  Main Program Code                                                                 |
;\------------------------------------------------------------------------------------/
; Your code goes here

MyCode: SECTION
main:
        clr t1state ; initialize all tasks to state0
        clr t2state
        clr t3state
        clr t4state
        clr t5state
        
; Normally no code other than that to clear the state variables and call the tasks
; repeatedly should be in your main program. However, in this lab we will make a
; one-time exception: the following code will set TICKS_1 and TICKS_2 to default values
; and the BGND will give the user an opportunity to change these values in the debugger.

        movw #100, TICKS_1 ; set default for TICKS_1
        movw #200, TICKS_2 ; set default for TICKS_2
        bgnd ; stop in DEBUGGER to allow user to alter TICKS
Top:
        jsr TASK_1 ; execute tasks endlessly
        jsr TASK_2
        jsr TASK_3
        jsr TASK_4
        jsr TASK_5
        bra Top
        
;-------------TASK_1 Pattern_1---------------------------------------------------------
TASK_1: ldaa t1state ; get current t1state and branch accordingly
        beq t1state0
        deca
        beq t1state1
        deca
        beq t1state2
        deca
        beq t1state3
        deca
        beq t1state4
        deca
        beq t1state5
        deca
        beq t1state6
        rts ; undefined state - do nothing but return
t1state0: ; init TASK_1 (not G, not R)
        bclr PORTP, LED_MSK_1 ; ensure that LEDs are off when initialized
        bset DDRP, LED_MSK_1 ; set LED_MSK_1 pins as PORTS outputs
        movb #$01, t1state ; set next state
        rts
t1state1: ; G, not R
        bset PORTP, G_LED_1 ; set state1 pattern on LEDs
        tst DONE_1 ; check TASK_1 done flag
        beq exit_t1s1 ; if not done, return
        movb #$02, t1state ; otherwise if done, set next state
        exit_t1s1:
        rts
t1state2: ; not G, not R
        bclr PORTP, G_LED_1 ; set state2 pattern on LEDs
        tst DONE_1 ; check TASK_1 done flag
        beq exit_t1s2 ; if not done, return
        movb #$03, t1state ; otherwise if done, set next state
        exit_t1s2:
        rts
t1state3: ; not G, R
        bset PORTP, R_LED_1 ; set state3 pattern on LEDs
        tst DONE_1 ; check TASK_1 done flag
        beq exit_t1s3 ; if not done, return
        movb #$04, t1state ; otherwise if done, set next state
        exit_t1s3:
        rts
t1state4 ; not G, not R
        bclr PORTP, R_LED_1 ; set state4 pattern on LEDs
        tst DONE_1 ; check TASK_1 done flag
        beq exit_t1s4 ; if not done, return
        movb #$05, t1state ; otherwise if done, set next state
        exit_t1s4:
        rts
t1state5: ; G, R
        bset PORTP, LED_MSK_1 ; set state5 pattern on LEDs
        tst DONE_1 ; check TASK_1 done flag
        beq exit_t1s5 ; if not done, return
        movb #$06, t1state ; otherwise if done, set next state
        exit_t1s5:
        rts
t1state6: ; not G, not R
        bclr PORTP, LED_MSK_1 ; set state6 pattern on LEDs
        tst DONE_1 ; check TASK_1 done flag
        beq exit_t1s6 ; if not done, return
        movb #$01, t1state ; otherwise if done, set next state
        exit_t1s6:
        rts ; exit TASK_1
        
;-------------TASK_2 Timing_1----------------------------------------------------------
TASK_2: ldaa t2state ; get current t2state and branch accordingly
        beq t2state0
        deca
        beq t2state1
        rts ; undefined state - do nothing but return
        
t2state0: ; initialization for TASK_2
        movw TICKS_1, COUNT_1 ; init COUNT_1
        clr DONE_1 ; init DONE_1 to FALSE
        movb #$01, t2state ; set next state
        rts
        
t2state1: ; Countdown_1
        ldaa DONE_1   ;load accumulator A with DONE_1 
        cmpa #$01     ;check if DONE_1 - 1 = 0 
        bne t2s1a ; skip reinitialization if DONE_1 is not = 1
        
        ;reinitialize if DONE_1 = 1 
        
        movw TICKS_1, COUNT_1 ; init COUNT_1
        clr DONE_1 ; init DONE_1 to FALSE
        
       ;after reinitialization, you still decrement
        
t2s1a:  decw COUNT_1    ;decrement COUNT_1
        bne exit_t2s2   ;if COUNT_1 is not equal to zero, exit 
        movb #$01, DONE_1     ;if COUNT_1 is zero, set DONE_1 to 1
     
        
exit_t2s2:
        rts ; exit TASK_2
        
;-------------TASK_3 Delay 1ms---------------------------------------------------------
TASK_3: ldaa t3state ; get current t3state and branch accordingly
        beq t3state0
        deca
        beq t3state1
        rts ; undefined state - do nothing but return
t3state0: ; initialization for TASK_3
        ; no initialization required
        movb #$01, t3state ; set next state
        rts
        t3state1:
        jsr DELAY_1ms
        rts ; exit TASK_3
        
;-------------TASK_4 Pattern_2---------------------------------------------------------
TASK_4: ldaa t4state ; get current t1state and branch accordingly
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
        rts ; undefined state - do nothing but return
t4state0: ; init TASK_1 (not G, not R)
        bclr PORTP, LED_MSK_2 ; ensure that LEDs are off when initialized
        bset DDRP, LED_MSK_2 ; set LED_MSK_1 pins as PORTS outputs
        movb #$01, t4state ; set next state
        rts
t4state1: ; G, not R
        bset PORTP, G_LED_2 ; set state1 pattern on LEDs
        tst DONE_2 ; check TASK_4 done flag
        beq exit_t4s1 ; if not done, return
        movb #$02, t4state ; otherwise if done, set next state
        exit_t4s1:
        rts
t4state2: ; not G, not R
        bclr PORTP, G_LED_2 ; set state2 pattern on LEDs
        tst DONE_2 ; check TASK_1 done flag
        beq exit_t4s2 ; if not done, return
        movb #$03, t4state ; otherwise if done, set next state
        exit_t4s2:
        rts
t4state3: ; not G, R
        bset PORTP, R_LED_2 ; set state3 pattern on LEDs
        tst DONE_2 ; check TASK_2 done flag
        beq exit_t4s3 ; if not done, return
        movb #$04, t4state ; otherwise if done, set next state
        exit_t4s3:
        rts
t4state4 ; not G, not R
        bclr PORTP, R_LED_2 ; set state4 pattern on LEDs
        tst DONE_2 ; check TASK_2 done flag
        beq exit_t4s4 ; if not done, return
        movb #$05, t4state ; otherwise if done, set next state
        exit_t4s4:
        rts
t4state5: ; G, R
        bset PORTP, LED_MSK_2 ; set state5 pattern on LEDs
        tst DONE_2 ; check TASK_2 done flag
        beq exit_t4s5 ; if not done, return
        movb #$06, t4state ; otherwise if done, set next state
        exit_t4s5:
        rts
t4state6: ; not G, not R
        bclr PORTP, LED_MSK_2 ; set state6 pattern on LEDs
        tst DONE_2 ; check TASK_2 done flag
        beq exit_t4s6 ; if not done, return
        movb #$01, t4state ; otherwise if done, set next state
        exit_t4s6:
        rts ; exit TASK_4
        
;-------------TASK_5 Timing_2----------------------------------------------------------
TASK_5: ldaa t5state ; get current t2state and branch accordingly
        beq t5state0
        deca
        beq t5state1
        rts ; undefined state - do nothing but return
        
t5state0: ; initialization for TASK_5
        movw TICKS_2, COUNT_2 ; init COUNT_2
        clr DONE_2 ; init DONE_2 to FALSE
        movb #$01, t5state ; set next state
        rts
        
t5state1: ; Countdown_1
        ldaa DONE_2   ;load accumulator A with DONE_2 
        cmpa #$01     ;check if DONE_2 - 1 = 0 
        bne t5s1a ; skip reinitialization if DONE_2 is not = 1
        
        ;reinitialize if DONE_2 = 1 
        
        movw TICKS_2, COUNT_2 ; init COUNT_2
        clr DONE_2 ; init DONE_2 to FALSE
        
       ;after reinitialization, you still decrement
        
t5s1a:  decw COUNT_2    ;decrement COUNT_2
        bne exit_t5s2   ;if COUNT_2 is not equal to zero, exit 
        movb #$01, DONE_2     ;if COUNT_1 is zero, set DONE_2 to 1
     
        
exit_t5s2:
        rts ; exit TASK_25
        
;/------------------------------------------------------------------------------------\
;| Subroutines |
;/------------------------------------------------------------------------------------/
; Add subroutines here:

DELAY_1ms:
        ldy #$0584
        INNER: ; inside loop
        cpy #0
        beq EXIT
        dey
        bra INNER
        EXIT:
        rts ; exit DELAY_1ms
        
;/------------------------------------------------------------------------------------\
;| Messages |
;/------------------------------------------------------------------------------------/
; Add ASCII messages here:
;/------------------------------------------------------------------------------------\
;| Vectors |
;\------------------------------------------------------------------------------------/
; Add interrupt and reset vectors here:
        ORG $FFFE ; reset vector address
        DC.W Entry
