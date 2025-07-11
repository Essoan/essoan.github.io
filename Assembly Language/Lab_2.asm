;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------
; Setting ports
				bis.b		#BIT2,P1DIR						;	Activating port 1.2 as output
				bis.b		#BIT2,P1SEL						
				bic.b		#BIT1,P2DIR						;	Activating port 2.1 as input with pull-up resistor
				bis.b		#BIT1,P2REN
				bis.b		#BIT1,P2OUT

; Timer 1
				bis.w 		#TASSEL_2+MC_1+ID_2,TA1CTL		;	Setting timer 1
                mov.w 		#0xFFFF, TA1CCR0

; Timer 2
				bis.w 		#TASSEL_2+MC_1+ID_0,TA0CTL		;	Setting timer 2
                bis.w 		#OUTMOD_2,TA0CCTL1


initiate		bit.b		#BIT1,P2IN						;	Checking for pushbutton action
				jz			melody							;	Play melody if button is pushed
				jnz			initiate						;	Check again if button was not pushed


; Starting the melody
; The entirety of the melody segment calls functions from further down.
; As such the comments would be the same throughout the segment.
; The segments of tones are listed as showed in the lab assignment.
;--------------------------------------------------------

melody				call	#pause
					call	#pause
;------------------ Segment 1 ----------------------------
					call 	#Hz523
					call	#ms500
					call	#Hz587
					call	#ms500
					call	#Hz659
					call	#ms500
					call	#Hz698
					call	#ms500
					call	#Hz784
					call	#ms900
					call	#pause
					call	#Hz784
					call	#ms900
;------------------ Segment 2 ----------------------------
					call	#pause
					call	#Hz880
					call	#ms400
					call	#pause
					call	#Hz880
					call	#ms400
					call	#pause
					call	#Hz880
					call	#ms400
					call	#pause
;------------------ Segment 3 ----------------------------
					call	#Hz880
					call	#ms500
					call	#Hz784
					call	#ms1900
					call	#pause
					call	#Hz698
					call	#ms400
					call	#pause
					call	#Hz698
					call	#ms400
					call	#pause
;------------------ Segment 4 ----------------------------
					call	#Hz698
					call	#ms400
					call	#pause
					call	#Hz698
					call	#ms500
					call	#Hz659
					call	#ms900
					call	#pause
;------------------ Segment 5 ----------------------------
					call	#Hz659
					call	#ms900
					call	#pause
					call	#Hz587
					call	#ms400
					call	#pause
					call	#Hz587
					call	#ms400
;------------------ Segment 6 ----------------------------
					call	#pause
					call	#Hz587
					call	#ms400
					call	#pause
					call	#Hz587
					call	#ms500
					call	#Hz523
					call 	#ms2000
;------------------ End ----------------------------------
					call	#pause							;	Ends with a pause to avoid sound in the buzzer after finish.
					jmp		initiate						;	Jump to iniate, to wait for new pushbutton event.


; Setting pause to 100ms
;---------------------------------------------------------
pause				mov.w #0, TA0CCR0     					;	No sound, 0 Hz
                   	mov.w #0, TA0CCR1						;	No sound, 0 Hz

           			bic.w	#BIT0+BIT1+BIT2, TA1EX0			;	Clearing TA1EX0 Bits
					bis.w	#TAIDEX_0, TA1EX0				;	Setting TAIDEX_0
           			mov.w 	#26214, TA1CCR0   				;	100ms pause
                   	bic.w 	#TAIFG,TA1CTL					;	Clearing timer
waitPause           bit.w 	#TAIFG,TA1CTL					;	Checking timer
                   	jz      waitPause						; 	Has timer reached zero? If not, check again.
                   	ret										;	Return to call


; Setting the different tone intervalls (length of tone)
;---------------------------------------------------------

ms400				bic.w	#BIT0+BIT1+BIT2, TA1EX0			;	Clearing TA1EX0 Bits
					bis.w	#TAIDEX_1, TA1EX0				;	Setting TAIDEX_1
           			mov.w 	#52429, TA1CCR0   				;	400ms length of tone
                   	bic.w 	#TAIFG,TA1CTL					;	Clearing timer
wait400            	bit.w 	#TAIFG,TA1CTL					;	Checking timer
                   	jz      wait400							; 	Has timer reached zero? If not, check again.
                   	ret										;	Return to call


ms500				bic.w	#BIT0+BIT1+BIT2, TA1EX0			;	Clearing TA1EX0 Bits
					bis.w	#TAIDEX_1, TA1EX0				;	Setting TAIDEX_1
           			mov.w 	#65535, TA1CCR0   				;	500ms length of tone
                   	bic.w 	#TAIFG,TA1CTL					;	Clearing timer
wait500            	bit.w 	#TAIFG,TA1CTL					;	Checking timer
                   	jz      wait500							; 	Has timer reached zero? If not, check again.
					ret										;	Return to call

ms900				bic.w	#BIT0+BIT1+BIT2, TA1EX0			;	Clearing TA1EX0 Bits
					bis.w	#TAIDEX_3, TA1EX0				;	Setting TAIDEX_3
           			mov.w 	#58982, TA1CCR0   				;	900ms length of tone
                   	bic.w 	#TAIFG,TA1CTL					;	Clearing timer
wait900            	bit.w 	#TAIFG,TA1CTL					;	Checking timer
                   	jz      wait900							; 	Has timer reached zero? If not, check again.
					ret										;	Return to call


ms1900				bic.w	#BIT0+BIT1+BIT2,TA1EX0			;	Clearing TA1EX0 Bits
					bis.w	#TAIDEX_7, TA1EX0				;	Setting TAIDEX_7
           			mov.w 	#62259, TA1CCR0   				;	1900ms length of tone
                   	bic.w 	#TAIFG,TA1CTL					;	Clearing timer
wait1900           	bit.w 	#TAIFG,TA1CTL					;	Checking timer
                   	jz      wait1900						; 	Has timer reached zero? If not, check again.
                   	ret										;	Return to call


ms2000				bic.w	#BIT0+BIT1+BIT2,TA1EX0			;	Clearing TA1EX0 Bits
					bis.w	#TAIDEX_7, TA1EX0				;	Setting TAIDEX_7
           			mov.w 	#65535, TA1CCR0   				;	2000ms length of tone
                   	bic.w 	#TAIFG,TA1CTL					;	Clearing timer
wait2000           	bit.w 	#TAIFG,TA1CTL					;	Checking timer
                   	jz      wait2000						; 	Has timer reached zero? If not, check again.
                   	ret										;	Return to call


; Setting the different tone frequencies
;---------------------------------------------------------

Hz523				mov.w 	#2005, 	TA0CCR0					;	523Hz buzzer output
                   	mov.w 	#1002, 	TA0CCR1
                   	ret										;	Return to call

Hz587				mov.w	#1786, 	TA0CCR0					;	587Hz buzzer output
                   	mov.w 	#893, 	TA0CCR1
					ret										;	Return to call

Hz659				mov.w 	#1591, 	TA0CCR0					;	659Hz buzzer output
                   	mov.w 	#796, 	TA0CCR1
					ret										;	Return to call

Hz698				mov.w 	#1502, 	TA0CCR0					;	698Hz buzzer output
                   	mov.w 	#751, 	TA0CCR1
					ret										;	Return to call

Hz784				mov.w 	#1337, 	TA0CCR0					;	784Hz buzzer output
                   	mov.w 	#669, 	TA0CCR1
                   	ret										;	Return to call

Hz880				mov.w 	#1192, 	TA0CCR0					;	880Hz buzzer output
                   	mov.w 	#596, 	TA0CCR1
					ret										;	Return to call


;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
            
