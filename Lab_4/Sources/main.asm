;**************************************************************************************
;* Blank Project Main [includes LibV2.2]                                              *
;**************************************************************************************
;* Summary: Lab 4                                                                     *
;*   -                                                                                *
;*                                                                                    *
;* Author: Julia Fay & Aiden Taylor                                                   *
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

;params for t1 interrupt 
Chan0 EQU $01
TIOS  EQU $0040
TCTL2 EQU $0049
TFLG1 EQU $004E
TMSK1 EQU $004C
TSCR  EQU $0046
TCNTH EQU $0044
TC0   EQU $0050
INTERVAL DS.W 1

;params for t2 

SELECT_FLG DS.B 1 
COUNT DS.B 1 
MM_ERR  DS.B 1
NINT DS.W 1
WAVE_NUM DS.B 1 

;params for t3 
KEY_FLG DS.B 1
KEY_BUFF DS.B 1

;params for t4
MSG_NUM DS.B 1

;params for t5
RUN DS.B 1
CINT DS.W 1 
NEWBTI DS.B 1  
WAVEPTR DS.W 1  
CSEG DS.B 1 
LSEG DS.B 1  
SEGPTR DS.W 1  
SEGINC DS.W 1  
VALUE DS.W 1 
DWAVE DS.B 1 
DPRMPT DS.B 1
NINTOK DS.B 1 

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
BUFFER DS.B 3
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
        
top:
       
        jsr TASK_1  ; execute tasks endlessly
        jsr TASK_2
        jsr TASK_3
        jsr TASK_4
        ;bgnd
        jsr TASK_5
        ;movb #$01, NEWBTI
        bra top       
         
spin:   bra   spin                     ; endless horizontal loop


;-------------TASK_1 TC0 SETUP ---------------------------------------------------------

TASK_1:

        ldaa t1state ;get state
        beq t1s0
        deca
        beq t1s1

t1s0: 

;Step 1: Pre-initialization
		   
		   movw #1000, INTERVAL ; Determine the number of bus clock counts that corresponds to 0.1 msec.
		   
;Step 2: Timer Initialization
		   
		   bset TIOS, Chan0     ; Set timer channel 0 for output compare
		   bset TCTL2,Chan0     ; Set timer channel 0 to toggle its output pin
		   bset TFLG1, Chan0    ; Clear timer channel flag by writing a 1 to it 
		   cli                  ; Clear I bit 
		   bset TMSK1, Chan0    ; enable maskable interrupts 
		   

		   bset TSCR, %10100000 ; enable timer channel output compare intuerrupts 
		                        ; sets TEN = 1  (enable timer bit)
		                        ; sets TSBCK = 1 (timer stop in background mode) 

;Step 3: Generating the first interrupt		   
		  
		   ldd TCNTH            ; read current timer count 
		   addd INTERVAL        ; add interval to count 
		   std TC0              ; load result into TC0
		   
		   movb #$01, t1state   ;set t1state to 1 

t1s1:  

 rts 



 ;-------------TASK_2 MASTERMIND ---------------------------------------------------------

 TASK_2: 
 
        ldaa t2state ;get state
        beq t2s0
        deca
        beq t2s1
        deca
        lbeq t2s2
        deca  
        lbeq t2s3
        deca 
        lbeq t2s4 
        deca 
        lbeq t2s5 
        deca 
        lbeq t2s6
        rts

;__________________________________________________________________________________

t2s0: ; init TASK_2

;clear all of the flags and relevant ITCVs
 
        clr SELECT_FLG 
        clr KEY_FLG 
        clr COUNT
        clr WAVE_NUM
        jsr clearbuffer                             ;clear buffer
        movb #$01, t2state                          ;set next state
        lbra exit2                                  ;exit
        
 ;__________________________________________________________________________________
       
t2s1: ;hub        
        
        tst KEY_FLG                                 ;first test if there is a key to be checked
        lbeq exit2                                  ;if there is no key exit
        
 ;check if 1-4 have already been pressed for the first time 
 
        ldaa KEY_BUFF                               ;load accumulator A with the current char
        tst SELECT_FLG                              ;test if have already selected a wave 
        bne skip_select                             ;skip setting the t1 state if already pressed once 
 
 ;if 1-4 has not been pushed yet, check if its being pushed for the first time 
 
 ;load accumulator d with the current ascii hex digit to make sure all arithmetic is correct 
       
        psha                                        ;push whats in a to the stack 
        pulb                                        ;pul what was in a into b 
        ldaa #$00                                   ;put zeros in a to make it a positive num
        
        cpd #$34                                    ;check if what in A is 1-4 
        bgt skip_select                             ;if its not 1-4, disregard the input  
        pshb                                        ;restore the stack 
        pula  
        movb #$05 , t2state                         ;set the state to select  
        lbra exit2               

skip_select:
 
;check if its a BS 
       
        cmpa #$08                                   ;compare whats in A to BS 
        bne skipBS                                  ;if its not BS, skip settting the state 
        movb #$04 , t2state                         ;set the state to the appropriate number 
        lbra exit2                                  ;exit

skipBS: 

;check if its a ENT  

        cmpa #$0A                                   ;compare whats in A to ENT 
        bne skipENT                                 ;if its not BS, skip settting the state 
        movb #$03 , t2state                         ;set the state to the appropriate number 
        lbra exit2                                  ;exit
        
skipENT:

;check if its a digit
 
        psha                                        ;push whats in a to the stack 
        pulb                                        ;pul what was in a into b 
        ldaa #$00                                   ;put zeros in a to make it a positive num
        
        cpd #$39                                    ;check if what in A is a number 
        bgt skipDIGIT                               ;if its not a number, disregard the input
        pshb                                        ;restore the stack 
        pula
         
        movb #$02 , t2state                         ;set the state to digit handler 
        lbra exit2                                  ;exit

skipDIGIT: 

        clr KEY_FLG
        lbra exit2                                  ;exit
  
;__________________________________________________________________________________
        
t2s2: ;Digit Handler 

;checks if we should proceed with the digit handler state 

        ldab COUNT                                  ;load b with count 
        cmpb #$03                                   ;check if count is 3
        beq toomany                                 ;if count is 3 stop taking inputs and leave
        tst SELECT_FLG                              ;test SELECT_FLG 
        bne skip_e                                  ;if not equal to 0, skip exiting 

toomany:        
        
        clr KEY_FLG                                 ;clear keyflag 
        movb #$01 , t2state                         ;set the state back to 1
        lbra exit2                                  ;exit  
                                
skip_e:

;now proceed with the digit handler
   
        ldy #BUFFER                                 ;load index register y with buffer 
        ldaa COUNT                                  ;load A with the current value of COUNT 
        ldab KEY_BUFF                               ;load b with KEY_BUFF 
        stab a,y                                    ;store the contents of b at the position of COUNT in BUFFER
       
        inc COUNT                                   ;increment count 
        clr KEY_FLG                                 ;set key flag to 0 to acknowledge KEYPAD
        movb #$01 , t2state                         ;set the state back to 1  
        movb #$0B, MSG_NUM                          ;set state in display task to echo the char
        lbra exit2                                  ;exit 

;__________________________________________________________________________________
        
t2s3: ;ENTER 

         
;before jsr to conversion, check if any digits have been entered into buffer      
       
       jsr clrcurs                                 ;turn off the cursor when enter is hit   
       tst COUNT                                   ;test the current value of count 
       bne skip_NO_DIGITS                          ;if the count is not zero, branch 
       ldaa #$03                                   ;if the count is zero, put an error code into A 
       bra check_error                             ;branch to the set error state below 


 skip_NO_DIGITS: 

;send to conversion to get a BCD form of the input 
    
       jsr conversion                              ;convert the contents of buffer to binary 
       stx NINT                                    ;store the result of conversion in NINT 
       clr COUNT                                   ;set count back to zero 
       clr BUFFER                                  ;clear the contents of the BUFFER
       
            
check_error: 
       
;automatically set the state back to 1 for all cases  

       movb #$01, t2state                          ;set the state back to 1 
       
;check for error and set variables and state accordingly so that user has to start over 

       cmpa #$00                                   ;check whats in A 
       beq skipERROR                               ;check if an error was generated from conversion
       movb #$06, t2state                          ;if there is an error code set the state to the 
                                                   ;error state
       staa MM_ERR                                 ;store the error code of accumulator A into a variable 
                                                   ;so it is not affected by other code before it gets to 
                                                   ;the error state 
       clr NINT                                    ;clear NINT 
       clr KEY_FLG                                 ;clear key flag
       jsr clearbuffer
       jsr CURSOR_OFF   
       lbra exit2                                   

skipERROR: 

;if there are no errors, clear the select and key flags and buffer and exit     
      
      jsr clearbuffer                               ;set run to be true if there are no errors 
      jsr CURSOR_OFF 
      clr KEY_FLG 
      clr SELECT_FLG  
      clr DWAVE 
      movb #$01, NINTOK 
      lbra exit2                                    ;exit

;________________________________________________________________________________________

t2s4: ;BS
 
       movb #$03 , t4state                         ;set the state in task 4 to the BS state   
       movb #$01 , t2state                         ;set the state back to 1
       clr KEY_FLG 
       lbra exit2                                   ;exit

;________________________________________________________________________________________

t2s5: ;SELECT state 
 
         
       movb #$01, SELECT_FLG                       ;set the SELECT_FLG to be true
       movb #$01, DWAVE                                   ;clear the display wave flag 
       clr NINTOK                                  ;clear NINTOK 
       clr RUN                                     ;clear run 
       ldaa KEY_BUFF                               ;load a with whats in KEY_BUFF 
       suba #$30	  	                             ;subtract $30 to get the decimal value of the ascii code
       staa WAVE_NUM                               ;store the wave number 
       
      ;set the display state in task 4 
      
       adda #$03               ;add 3 to get the corresponding task 4 state
       staa t4state            ;store message number in state 
       
      ;set the state back to one, clear key flag, and exit 
      
       movb #$01 , t2state                         ;set the state back to 1 
       clr KEY_FLG                                 ;clear the key flag  
       bra exit2                                   ;exit
       
     
;________________________________________________________________________________________

t2s6: ;Error state 


;checks the error code in accumulator A to set the appropiate fixed 
;message state to be displayed through task 4 


;now check the error number and set the message number for task 4 
 
       ldaa MM_ERR                                  ;put the error number back into accumulator a 
       cmpa #01                                     ;check if the error code is mag to large 
       bne skip_toolarge                            ;skip setting the message num
       movb #$08, MSG_NUM                           ;set the appropiate message num 

skip_toolarge: 

       cmpa #02                                     ;check if the error code is zero magnitude 
       bne skip_zeromag                             ;skip setting the message num
       movb #$09, MSG_NUM                           ;set the appropiate message num 

skip_zeromag: 

       cmpa #03                                     ;check if the error code is zero digits
       bne skip_zerodigits                          ;skip setting the message num
       movb #$0A, MSG_NUM                           ;set the appropiate message num    

skip_zerodigits: 
   
       movb #$01 , t2state                         ;set the state back to 1
       jsr clearbuffer
       clr KEY_FLG
       
       
;might be missing the clearing of some variables here 

exit2: 
 
       rts                                         

 ;-------------TASK_3 KEYPAD ---------------------------------------------------------

 TASK_3:
 
        ldaa t3state ;get state
        beq t3s0
        deca
        beq t3s1
        deca
        beq t3s2
        rts

t3s0:   ;init
        
        jsr INITKEY       ;initialize keypad
        clr KEY_BUFF
        movb #$01, t3state
        rts
        
t3s1:   ;Wait for Key   
   
        tst LKEY_FLG             ;check if there is a digit in the buffer 
        beq exit3                ;if no key then exit 
        jsr GETCHAR              ;get the character 
        stab KEY_BUFF            ;stores the input char into key buffer
        movb #$01, KEY_FLG       ;set ITCV keyflag to notifiy MM of key input
        movb #$02, t3state       ;set the state to state 2 
        bra exit2                ;exit
        
t3s2:   ;Wait for Acknowledgement 

        tst KEY_FLG              ;test the ITCV KEY_FLG 
        bne exit3                ;if it is still 1 then do not change state 
        movb #$01, t3state       ;if it is 0, set state back to 1         

exit3: rts                       ;exit 
        
        
        
;-------------TASK_4 DISPLAY ---------------------------------------------------------


TASK_4:

        ldaa t4state
        beq t4s0
        deca
        beq t4s1
        deca
        lbeq t4s2
        deca
        lbeq t4s3
        deca
        lbeq t4s4
        deca
        lbeq t4s5
        deca
        lbeq t4s6
        deca
        lbeq t4s7
        deca
        lbeq t4s8
        deca
        lbeq t4s9
        deca
        lbeq t4s10
        deca
        lbeq t4s11
        rts
;________________________________________________________________________________________

t4s0:   ;init    
        
        jsr INITLCD             ;initialize LCD
        movb #$01, FIRSTCH      ;set first char to be true 
        ldaa #$00               ;set LCD position to 0
        jsr SETADDR             ;set the address 
        movw #$5000, TICKS_ERR  ;set the ticks error to be ___
        movb #$02, t4state      ;automatically go to state 2 to display the initial message   
        rts                     ;exit 

;________________________________________________________________________________________
t4s1:  ;hub
             
        movb #$01, FIRSTCH      ;set first char to be true  
        ldab MSG_NUM            ;load message number into b 
        stab t4state            ;store message number in state 
        movb #$01, MSG_NUM      ;reset message num       
        rts                     ;exit 
 
;________________________________________________________________________________________
t4s2:  ;set screen 

        ldx #TOP
        ldaa #$00               ;set LCD position to 0
        tst FIRSTCH 
        lbne char1
        jsr PUTCHAR           
        rts 
  
;________________________________________________________________________________________
t4s3:   ;backspace 

        ldaa COUNT 
        adda #$5B
        jsr SETADDR 
        jsr backspace           ;go to backspace subroutine 
        movb #$01, t4state      ;reset to state 1 
        rts                     ;exit      
        
;________________________________________________________________________________________
t4s4:   ;saw message (wave #1)

        ldx #SAWMSG
        ldaa #$40               ;set LCD position to 40
        tst FIRSTCH 
        bne char1
        jsr PUTCHAR
        rts  
          
 ;________________________________________________________________________________________
t4s5:   ;7-seg message  (wave #2)

        ldx #SEG7MSG
        ldaa #$40               ;set LCD position to 40
        tst FIRSTCH 
        bne char1
        jsr PUTCHAR
        rts  
          
;________________________________________________________________________________________
t4s6:   ;square message  (wawve #3)

        ldx #SQUAREMSG 
        ldaa #$40               ;set LCD position to 40
        tst FIRSTCH 
        bne char1
        jsr PUTCHAR
        rts  
         
;________________________________________________________________________________________
t4s7:   ;15-seg message  (wave #4) 

        ldx #SEG15MSG 
        ldaa #$40               ;set LCD position to 40
        tst FIRSTCH 
        bne char1
        jsr PUTCHAR
        rts 
;________________________________________________________________________________________
t4s8:   ;too large error message

 ;can have only three error message states by storing the previous state in a variable and
 ;and setting the task 4 state back to that state 
 
        ldx #E1
        ldaa #$55               ;set LCD position to 61
        tst FIRSTCH 
        bne char1
        jsr PUTCHAR
        rts 

;________________________________________________________________________________________
t4s9:   ;invalid magnitude message
        
        ldx #E2
        ldaa #$55               ;set LCD position to 61
        tst FIRSTCH                       
        bne char1
        jsr PUTCHAR
        rts 

;________________________________________________________________________________________
t4s10:  ;no digits entered message

        ldx #E3
        ldaa #$55               ;set LCD position to 61
        tst FIRSTCH 
        bne char1
        jsr PUTCHAR
        rts 
;________________________________________________________________________________________
t4s11:   ;echo 
        
        ldaa COUNT 
        adda #$5A
        jsr SETADDR 
        jsr CURSOR_ON 
        
        ldab KEY_BUFF           ;load accumulator b with whats in KEY_BUFF 
        jsr OUTCHAR             ;display the inputted digit 
        movb #$01, t4state      ;reset to state 1
        
        rts

char1: 
  
        jsr PUTCHAR1      
        
;-------------TASK_5 FUNCTION GENERATOR -----------------------------------------------
        

 TASK_5:

        ldaa t5state
        beq t5s0
        deca
        beq t5s1
        deca
        beq t5s2
        deca
        lbeq t5s3
        deca
        lbeq t5s4
        rts
        
;________________________________________________________________________________________

t5s0:   ;init    
        
        clr RUN 
        clr CSEG
        clr LSEG 
        clrw SEGINC 
        clrw SEGPTR
        clrw NINT
        clrw CINT  
        clr NINTOK 
        clrw WAVEPTR 
        clrw VALUE  
        movb #$01, t5state                   

;________________________________________________________________________________________

t5s1:  ;wait for wave 
             
;set the corrrect wave address  
       
       ;bgnd
       ldaa WAVE_NUM 
       lbeq exit5 
       deca 
       beq t5w1
       deca 
       beq t5w2 
       deca 
       beq t5w3 
       deca
       beq t5w4 
       rts
       
t5w1:
       ldx #SAWTOOTH
       stx WAVEPTR
       movb #$02, t5state
       rts  

t5w2: 
       ldx #SINE_7
       stx WAVEPTR
       movb #$02, t5state
       rts 
  
      
t5w3:       
       ldx #SQUARE
       stx WAVEPTR
       movb #$02, t5state
       rts 

t5w4: 

       ldx #SINE_15
       stx WAVEPTR
       movb #$02, t5state
       rts  
      
                        
 
;________________________________________________________________________________________

t5s2:  ;new wave 


        tst DWAVE ; wait for display of wave message
        ;bgnd
        bne t5s2a
        ldx WAVEPTR ; point to start of data for wave
        movb 0,X, CSEG ; get number of wave segments
        movw 1,X, VALUE ; get initial value for DAC
        movb 3,X, LSEG ; load segment length
        movw 4,X, SEGINC ; load segment increment
        inx ; inc SEGPTR to next segment
        inx
        inx
        inx
        inx
        inx
        stx SEGPTR ; store incremented SEGPTR for next segment
        ;movb #$01, DPRMPT ; set flag for display of NINT prompt
        movb #$03, t5state ; set next state
        t5s2a: rts

        
        
;________________________________________________________________________________________

t5s3:  ;wait for NINT        
        
     ;set run if correct nint
     ;needs more stuff 
     
        tst NINTOK
        beq exit5 
        movb #$01, RUN 
        movb #$04, t5state 
        rts 
         
;________________________________________________________________________________________

t5s4:  ;Display wave  
        ;bgnd
        tst RUN
        beq t5s4c         ; do not update function generator if RUN=0
        tst NEWBTI
        beq t5s4e         ; do not update function generator if NEWBTI=0
        dec LSEG          ; decrement segment length counter
        bne t5s4b         ; if not at end, simply update DAC output
        dec CSEG          ; if at end, decrement segment counter
        bne t5s4a         ; if not last segment, skip reinit of wave
        ldx WAVEPTR       ; point to start of data for wave
        movb 0,X, CSEG    ; get number of wave segments
        inx               ; inc SEGPTR to start of first segment
        inx
        inx
        stx SEGPTR        ; store incremented SEGPTR
        t5s4a: ldx SEGPTR ; point to start of new segment
        movb 0,X, LSEG    ; initialize segment length counter
        movw 1,X, SEGINC  ; load segment increment
        inx               ; inc SEGPTR to next segment
        inx
        inx
        stx SEGPTR        ; store incremented SEGPTR
        t5s4b: ldd VALUE  ; get current DAC input value
        addd SEGINC       ; add SEGINC to current DAC input value
        std VALUE         ; store incremented DAC input value
        bra t5s4d
        t5s4c: movb #$01, t5state ; set next state
        t5s4d: clr NEWBTI
        t5s4e: rts
 
 exit5: 
 
        rts 

;/------------------------------------------------------------------------------------\
;| Subroutines                                                                        |
;\------------------------------------------------------------------------------------/
; General purpose subroutines go here

;------ISUBROUT-----------------------------------------------------------------------;

isubrout:

;first check run is one 
       ;bgnd
       tst RUN 
       beq NXT_INT

;next check if CINT is zero 
        
       tstw CINT 
       beq NEW_CINT 
       decw CINT  
       bra NXT_INT 
        
NEW_CINT: 

       ldd NINT 
       std CINT 
       movb #$01, NEWBTI 
       ldd VALUE 
       jsr OUTDACA 
       
NXT_INT:
        
        ldd TC0                ; read current timer count  
        addd INTERVAL          ; add interval 
        std TC0                ; store result  
        bset TFLG1, $01        ; clear timer channel 0 flag by writing a 1 to it
       
        
        rti

;------BACKSPACE----------------------------------------------------------------------;   
         
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
       
;------CONVERSION---------------------------------------------------------------------------;

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
	    	std RESULT		;keep the bottom 2 bytes of the emul since we are never dealing with 4 bit nums
		
		
		
	    	ldaa TMP	  	;TMP is used for index addressing
	    	ldab a,x	  	;reference the correct digit in the BUFFER using TMP
	    	subb #$30	  	;subtract $30 to get the decimal value of the ascii code
	    	
		
	    	clra
	    	addd RESULT		;add RESULT and acc d 
	    	tsta          ;test if a is zero 
	    	bne ERR1      ;if it is not zero, it has "overflowed"
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

        movb #$01, t4state
        movb #$01, MSG_NUM
        jsr clrcurs
        rts
        
        
ERR_DELAY:
       
        jsr clrcurs
        ldaa t4state
        cmpa #$07
        ble mess_exit
      
        tst COUNT_ERR
        beq err_exit
        decw COUNT_ERR
        rts
            
err_exit:
        
        ldab WAVE_NUM           ;load wave number into b
        addb #$03               ;add 3 to get the corresponding task 4 state
        stab t4state            ;store message number in state
        movb #$01, FIRSTCH
        rts
            

clrcurs: ;resets the cursor address 

        psha
        ldaa #$30
        jsr SETADDR
        pula
        rts
        
        
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
        rts
       

;/------------------------------------------------------------------------------------\
;| ASCII Messages and Constant Data                                                   |
;\------------------------------------------------------------------------------------/
; Any constants can be defined here

TOP:  		DC.B '1: SAW, 2: SINE-7, 3: SQUARE, 4: SINE-15', $00	;message for the top of the screen

SAWMSG:  		DC.B 'SAWTOOTH WAVE        NINT:     [1-->255]', $00	;message for when SAWTOOTH is chosen

SEG7MSG:	  	DC.B '7-SEGMENT SINE WAVE  NINT:     [1-->255]', $00	;message for when 7 Seg sine is chosen

SQUAREMSG:		DC.B 'SQUARE WAVE          NINT:     [1-->255]', $00	;message for when SQUARE is chosen

SEG15MSG:		DC.B '15-SEGMENT SINE WAVE NINT:     [1-->255]', $00	;message for when 15 seg sine is chosen

BACKSPACE: DC.B ' ' , $00 

E1:	DC.B 'MAGNITUDE TOO LARGE', $00	;message for when MAGNITUDE TOO LARGE
E2:	DC.B 'INVALID MAGNITUDE  ', $00	;message for when INVALID MAGNITUDE  
E3:	DC.B 'NO DIGITS ENTERED  ', $00	;message for when NO DIGITS ENTERED    

SAWTOOTH:	DC.B 2 		; number of segments for SAWTOOTH
      		DC.W 3276	 	; initial DAC input value
      		DC.B 1	 	; length for segment_1
      		DC.W 3276 	; increment for segment_1
      		DC.B 9	 	; length for segment_2
      		DC.W -364 	; increment for segment_2
		
SINE_7:   DC.B 7		; number of segments for SINE_7
      		DC.W 2048	; initial DAC input value
      		DC.B 25		; length for segment_1
      		DC.W 33		; increment for segment_1
      		DC.B 50		; length for segment_2
      		DC.W 8		; increment for segment_2
      		DC.B 50		; length for segment_3
      		DC.W -8		; increment for segment_3
      		DC.B 50		; length for segment_4
      		DC.W -33	; increment for segment_4
      		DC.B 50		; length for segment_5
      		DC.W -8		; increment for segment_5
      		DC.B 50		; length for segment_6
      		DC.W 8		; increment for segment_6
      		DC.B 25		; length for segment_7
      		DC.W 33		; increment for segment_7
  		
SQUARE:	  DC.B 4 		; number of segments for SQUARE
      		DC.W 0	 	; initial DAC input value
      		DC.B 9	 	; length for segment_1
      		DC.W 0 		; increment for segment_1
      		DC.B 1	 	; length for segment_2
      		DC.W 3268 ; increment for segment_2
      		DC.B 9	 	; length for segment_3
      		DC.W 0	 	; increment for segment_3
      		DC.B 1	 	; length for segment_4
      		DC.W -3268 	; increment for segment_4
		
SINE_15:	DC.B 15 	; number of segments for SINE
      		DC.W 2048 ; initial DAC input value
      		DC.B 10		; length for segment_1
      		DC.W 41 	; increment for segment_1
      		DC.B 21 	; length for segment_2
      		DC.W 37 	; increment for segment_2
      		DC.B 21 	; length for segment_3
      		DC.W 25 	; increment for segment_3
      		DC.B 21 	; length for segment_4
      		DC.W 9 		; increment for segment_4
      		DC.B 21 	; length for segment_5
      		DC.W -9 	; increment for segment_5
      		DC.B 21 	; length for segment_6
      		DC.W -25 	; increment for segment_6
      		DC.B 21 	; length for segment_7
      		DC.W -37 	; increment for segment_7
      		DC.B 20 	; length for segment_8
      		DC.W -41 	; increment for segment_8
      		DC.B 21 	; length for segment_9
      		DC.W -37 	; increment for segment_9
      		DC.B 21 	; length for segment_10
      		DC.W -25 	; increment for segment_10
      		DC.B 21 	; length for segment_11
      		DC.W -9 	; increment for segment_11
      		DC.B 21 	; length for segment_12
      		DC.W 9 		; increment for segment_12
      		DC.B 21 	; length for segment_13
      		DC.W 25 	; increment for segment_13
      		DC.B 21 	; length for segment_14
      		DC.W 37 	; increment for segment_14
      		DC.B 10 	; length for segment_15
      		DC.W 41 	; increment for segment_15

;/------------------------------------------------------------------------------------\
;| Vectors                                                                            |
;\------------------------------------------------------------------------------------/
; Add interrupt and reset vectors here

        ORG   $FFFE                    ; reset vector address
        DC.W  Entry

        ORG   $FFEE                    ; chan 0 vector address 
        DC.W  isubrout 