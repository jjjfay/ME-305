 
;**************************************************************************************
;* Lab 5 main_ISR                                                                     *
;**************************************************************************************
;* Summary:                                                                           *
;*  This code is designed for use with the 2016 hardware for ME305. This code         *
;* implements a proportional plus integral controller on the velocity of the ME 305   *
;* dc motor with encoder system.  A full user interface is required.                  *
;*                                                                                    *
;*                                                                                    *
;* Author: William R. Murray, E. Espinoza-Wade and Charlie T. Refvem                  *
;*  Cal Poly University                                                               *
;*  Fall 2016                                                                         *
;*                                                                                    *
;* Revision History:                                                                  *
;*  CTR 10/03/16                                                                      *
;*   - Programmed the ISR that implements the controller, but with no user interface. *
;*  WRM 10/09/16                                                                      *
;*   - Began to add user interface as time allowed.                                   *
;*  WRM 11/12/16                                                                      *
;*   - Initial user interface coded, and ready to merge with Charlie's controller.    *
;*  WRM 11/17/16                                                                      *
;*   - User interface has passed moderate testing.                                    *
;*  WRM 12/02/16                                                                      *
;*   - Locked out changes in CL/|OL to prevent active data entry needing an <ENT>     *
;*       terminate when OL/|CL is pressed, and cleaned up unintentional consequences. *
;*  WRM 12/07/16                                                                      *
;*   - Added a signed overflow [OVF] to ERR display.                                  *
;*  WRM 11/16/17                                                                      *
;*   - Changed default gains to reduced values to make headroom for boosting the      *
;*       natural frequency.  This is an issue due to the 2-quadrant limitations       *
;*       of the VNH5019 motor driver. Kp=1 and Ki=0.45.                               *
;*   - Blocked out enabling RUN while entering 1024*Kp or 1024*Ki.                    *
;*  WRM 12/06/18                                                                      *
;*   - Corrected sign issue in SAT_MULDIV                                             *
;*  WRM 01/06/19                                                                      *
;*   - Adapted to run with Library V2.1 [changed PWM period to 625]                   *
;*  WRM 03/10/19                                                                      *
;*   - Changed the default gains for use with Library V2.1                            *
;*        [Kp=0.7; Ki=0.225], that is, [1024*Kp=717; 1024*Ki=230]                     *
;*  WRM 05/14/22                                                                      *
;*   - Tidied up comments and formatting                                              *
;*  WRM 05/14/22                                                                      *
;*   - Stripped out TCOISR for testing Lab 5 library                                  *
;*                                                                                    *
;*  ToDo:                                                                             *
;*   - Could fool around with making EFF based on the motor current;                  *
;*       otherwise, I'm happy ... until more bugs surface.                            *
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
              XDEF  Theta_OLD, RUN, CL, V_ref, KP, KI, UPDATE_FLG1            
;/------------------------------------------------------------------------------------\
;| External References                                                                |
;\------------------------------------------------------------------------------------/
; All labels from other files must have an external reference             
                    
              XREF  ENABLE_MOTOR, DISABLE_MOTOR
              XREF  STARTUP_MOTOR, UPDATE_MOTOR, CURRENT_MOTOR 
              XREF  STARTUP_PWM, STARTUP_ATD0, STARTUP_ATD1   
              XREF  OUTDACA, OUTDACB
              XREF  STARTUP_ENCODER, READ_ENCODER
              XREF  DELAY_MILLI, DELAY_MICRO
              XREF  INITLCD, SETADDR, GETADDR, CURSOR_ON, CURSOR_OFF, DISP_OFF
              XREF  OUTCHAR, OUTCHAR_AT, OUTSTRING, OUTSTRING_AT
              XREF  INITKEY, LKEY_FLG, GETCHAR
              XREF  LCDTEMPLATE, UPDATELCD_L1, UPDATELCD_L2
              XREF  LVREF_BUF, LVACT_BUF, LERR_BUF,LEFF_BUF, LKP_BUF, LKI_BUF
              XREF  Entry, ISR_KEYPAD
            

              XREF  V_act_DISP, ERR_DISP, EFF_DISP, INTERVAL
              XREF  IFENTRY, Kscale
;/------------------------------------------------------------------------------------\
;| Assembler Equates                                                                  |
;\------------------------------------------------------------------------------------/
; Constant values can be equated here


TFLG1         EQU   $004E
TC0           EQU   $0050

C0F           EQU   %00000001          ; timer channel 0 output compare bit
PORTT         EQU   $0240              ; PORTT pin 8 to be used for interrupt timing

LOWER_LIM     EQU   -625               ; number for max reverse duty cycle
UPPER_LIM     EQU   625                ; number for max forward duty cycle

Max_Pos       EQU $7FFF
Max_Neg       EQU $8000


;/------------------------------------------------------------------------------------\
;| Variables in RAM                                                                   |
;\------------------------------------------------------------------------------------/
; The following variables are located in unpaged ram

DEFAULT_RAM:  SECTION

RUN:          DS.B  1                  ; Boolean indicating controller is running
CL:           DS.B  1                  ; Boolean for closed-loop active

V_ref:        DS.W  1                  ; reference velocity
V_act:        DS.W  1                  ; actual velocity
Theta_NEW:    DS.W  1                  ; new encoder position
Theta_OLD:    DS.W  1                  ; previous encoder reading
KP:           DS.W  1                  ; proportional gain
KI:           DS.W  1                  ; integral gain
ERR:          DS.W  1                  ; error, where ERR = V_ref - V_act
EFF:          DS.W  1                  ; effort
ESUM:         DS.W  1                  ; accumulated error (area under err vs. t curve)

UPDATE_COUNT: DS.B  1                  ; counter for display update
UPDATE_FLG1   DS.B  1                  ; Boolean for display update for line one

MOTOR_POWER:  DS.W  1                  ; motor actuation value
P_POWER:      DS.W  1                  ; P-term of motor actuation value
I_POWER:      DS.W  1                  ; I-term of motor actuation value

CURRENT:      DS.W  1                  ; motor current in mA
A_star:       DS.W  1                 ; 

;/------------------------------------------------------------------------------------\
;|  Main Program Code                                                                 |
;\------------------------------------------------------------------------------------/
; Your code goes here

MyCode:       SECTION
main:   
        jsr IFENTRY

       

spin:   bra   spin                     ; endless horizontal loop


;/------------------------------------------------------------------------------------\
;| Subroutines                                                                        |
;\------------------------------------------------------------------------------------/
; General purpose subroutines go here

TC0ISR:
        bset PORTT, $80 ; turn on PORTT pin 8 to begin ISR timing
        inc UPDATE_COUNT ; unless UPDATE_COUNT = 0, skip saving
        bne measurements ; display variables
        movw V_act, V_act_DISP ; take a snapshot of variables to enable
        movw ERR, ERR_DISP ; consistent display
        movw EFF, EFF_DISP
        movb #$01, UPDATE_FLG1 ; set UPDATE_FLG1 when appropriate

; Measurements block

measurements:

; Read encoder value

        jsr READ_ENCODER ; read encoder position
        std Theta_NEW ; store it

; Compute 2-point difference to get speed

        subd Theta_OLD ; compute displacement since last reading
        std V_act ; store displacement as actual speed
        movw Theta_NEW, Theta_OLD ; move current reading to previous reading


;begin block diagram calculations here 

;calculate error

       ldd V_ref 
       subd V_act 
       std ERR             

;calculate new ESUM 

       ldy ESUM
       jsr SDBA 
       std ESUM 
       
;multiply ERR and ESUM by Kp and Ki 

      ;ESUM*KI/1024
       ldy KI
       emuls
       ldx #$0400 
       edivs 
       pshy 

      ;E*KP/1024
       ldy KP
       ldd ERR
       emuls
       ldx #$0400 
       edivs 
     
       puld
       jsr SDBA 
       
      ;note, result is in accumulator D 
      
;make sure a is in the range of -625 to 625

       cpd  #$FD8F
       bge  skip_low_threshold
       ldd  #$FD8F
       
skip_low_threshold:

       cpd #$271
       ble skip_high_threshold
       ldd #$0271
       
skip_high_threshold: 

      ;leave D as is. now we have a*
      
       std A_star 
       
      
;update motor  
      
       tst RUN
       beq skip_update 
       jsr UPDATE_MOTOR 
                   
;calculate effort 
       ldd A_star
       ldy #$0064
       emuls 
       ldx #$0271 
       edivs
       sty EFF
       bra end 
       
skip_update:

       ldd #$0000
       std EFF
       jsr UPDATE_MOTOR
        
       clr ESUM 
       
end: 
       
;setup next interrupt 
       
       ldd V_act
       ldy #$000D
       emuls
       addd #$0800
       jsr OUTDACA
       ldd TC0                ; read current timer count  
       addd INTERVAL          ; add interval 
       std TC0                ; store result  
       bset TFLG1, $01        ; clear timer channel 0 flag by writing a 1 to it
               
       rti

SDBA:

        pshy ; push one operand to the stack to enable addd
        addd 0, SP ; add the two numbers
        bvc DONE ; exit if no overflow
        tst 0, SP ; if overflow, determine sign of operands
        bmi NEG ; and saturate accordingly
        ldd #Max_Pos
        bra DONE

NEG:    ldd #Max_Neg

DONE:   

        ins
        ins
        rts


;/------------------------------------------------------------------------------------\  
;| Vectors                                                                            | 
;\------------------------------------------------------------------------------------/

; Add interrupt and reset vectors here:

         ORG  $FFFE                    ; reset vector address
         DC.W Entry
         
         ORG   $FFEE
         DC.W  TC0ISR

