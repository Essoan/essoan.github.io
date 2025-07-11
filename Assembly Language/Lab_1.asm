;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file

;-------------------------------------------------------------------------------
            .def    RESET                  ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------

RESET      mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------

;				Port configuration for RGB led and buttons
;_______________________________________________________________________________

				bis.b	#BIT1,P8DIR												;	Port 8.1 set to output
				bis.b	#BIT1,P8OUT												;	Port set to "High"

				bis.b	#BIT3,P2DIR												;	Port 2.3 set to output
				bis.b	#BIT3,P2OUT												;	Port set to "High"

				bis.b	#BIT6,P2DIR												;	Port 2.6 set to output
				bis.b	#BIT6,P2OUT												;	Port 2.6 set to "High"

				bic.b	#BIT2,P8DIR												;	Port 8.2: input with pull-up resistor (blue light button)
				bis.b	#BIT2,P8REN
				bis.b	#BIT2,P8OUT

				bic.b	#BIT1,P1DIR												;	Port 1.1: input with pull-up resistor (red light button)
				bis.b	#BIT1,P1REN
				bis.b	#BIT1,P1OUT

				bic.b	#BIT1,P2DIR												;	Port 2.1: input with pull-up resistor (green light button)
				bis.b	#BIT1,P2REN
				bis.b	#BIT1,P2OUT

; Ports and settings for tilt-switch and 7-segment display
; All connections to the 7-segment display are set through port 3.0-7 and one 3.3V connection
;_______________________________________________________________________________
;
;					______________
;			 g,P3.0 |	___a__	 | a,P3.7
;		     f,P3.1 |	|    |	 | b,P3.6
;				    |  f|	 |b  |
;		   Cat,3v3  |	|__g_|	 | Cat, noCon
;					|	|	 |	 |
;			 e,P3.2 |  e|   c| DP| DP,P3.5
;		     d,P3.3 |	|____| o | c,P3.4
;					|_____d______|
;
;_______________________________________________________________________________


				bis.b	#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3DIR			;	Output to 7-segment display


				bis.b	#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT			;	Clearing the 7 segment display.


				bic.b	#BIT5,P2DIR												;	Port 2.5: Input with pull-up resistor (T-Sw)
				bis.b	#BIT5,P2REN
				bis.b	#BIT5,P2OUT


; Timer configuration for delay purposes
;_______________________________________________________________________________

				bis.w	#TASSEL_2+ID_3+MC_2,TA0CTL
				mov.w	#0xFFFF,TA0CCR0

; Main routine
;_______________________________________________________________________________



initiate		bis.b	#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT			;	Clear 7-seg display
				bic.b	#BIT0+BIT3+BIT7,P3OUT									;	Three lines on display for initiate
				call 	#delay													;	Delay call
				call	#buttonCheck											;	Button press check
				jnz		countDown											;	Tilt check "count up"
				jz		countUp											;	Tilt check "count down"
				jmp		initiate												;	Jump back to initiate

countUp			call 	#delay													;	Delay call
				call	#buttonCheck											;	Check RGB buttons
				bit.b	#BIT5,P2IN												;	Testing Tilt-Switch for changed position
				jnz		countDown												;	If changed, jump to count down

				bis.b	#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT			;	Clear 7-seg display
				bic.b	#BIT1+BIT7+BIT5+BIT6+BIT4+BIT3+BIT2,P3OUT				;	0 out

				call	#delay													;	Delay call
				call	#buttonCheck											;	Check RGB buttons
				bit.b	#BIT5,P2IN												;	Testing Tilt-Switch for changed position
				jnz		countDown												;	If changed, jump to count down

				bis.b	#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT			;	Clear 7-seg display
				bic.b	#BIT4+BIT5+BIT6,P3OUT									; 	1 out

				call	#delay													;	Delay call
				call	#buttonCheck											;	Check RGB buttons
				bit.b	#BIT5,P2IN												;	Testing Tilt-Switch for changed position
				jnz		countDown												;	If changed, jump to count down

				bis.b	#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT			;	Clear 7-seg display
				bic.b	#BIT6+BIT7+BIT0+BIT2+BIT3+BIT5,P3OUT					;	2 out

				call	#delay													;	Delay call
				call	#buttonCheck											;	Check RGB buttons
				bit.b	#BIT5,P2IN												;	Testing Tilt-Switch for changed position
				jnz		countDown												;	If changed, jump to count down

				bis.b	#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT			;	Clear 7-seg display
				bic.b	#BIT7+BIT6+BIT0+BIT4+BIT3+BIT5,P3OUT					; 	3 out

				call	#delay													;	Delay call
				call	#buttonCheck											;	Check RGB buttons
				bit.b	#BIT5,P2IN												;	Testing Tilt-Switch for changed position
				jnz		countDown												;	If changed, jump to count down

				bis.b	#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT			;	Clear 7-seg display
				bic.b	#BIT1+BIT6+BIT0+BIT4+BIT5,P3OUT							; 	4 out

				call	#delay													;	Delay call
				call	#buttonCheck											;	Check RGB buttons
				bit.b	#BIT5,P2IN												;	Testing Tilt-Switch for changed position
				jnz		countDown												;	If changed, jump to count down

				bis.b	#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT			;	Clear 7-seg display
				bic.b	#BIT7+BIT1+BIT0+BIT4+BIT3+BIT5,P3OUT					; 	5 out

				call	#delay													;	Delay call
				call	#buttonCheck											;	Check RGB buttons
				bit.b	#BIT5,P2IN												;	Testing Tilt-Switch for changed position
				jnz		countDown												;	If changed, jump to count down

				bis.b	#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT			;	Clear 7-seg display
				bic.b	#BIT7+BIT1+BIT0+BIT4+BIT3+BIT2+BIT5,P3OUT				; 	6 out

				call	#delay													;	Delay call
				call	#buttonCheck
				bit.b	#BIT5,P2IN												;	Testing Tilt-Switch for changed position
				jnz		countDown												;	If changed, jump to count down

				bis.b	#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT			;	Clear 7-seg display
				bic.b	#BIT7+BIT6+BIT4+BIT5,P3OUT								;	7 out

				call	#delay													;	Delay call
				call	#buttonCheck											;	Check RGB buttons
				bit.b	#BIT5,P2IN												;	Testing Tilt-Switch for changed position
				jnz		countDown												;	If changed, jump to count down

				bis.b	#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT			;	Clear 7-seg display
				bic.b	#BIT1+BIT2+BIT3+BIT4+BIT0+BIT6+BIT7+BIT5,P3OUT			; 	8 out

				call	#delay													;	Delay call
				call	#buttonCheck											;	Check RGB buttons
				bit.b	#BIT5,P2IN												;	Testing Tilt-Switch for changed position
				jnz		countDown												;	If changed, jump to count down

				bis.b	#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT			;	Clear 7-seg display
				bic.b	#BIT1+BIT7+BIT6+BIT0+BIT4+BIT3+BIT5,P3OUT				; 	9 out

				call	#delay													;	Delay call
				call	#buttonCheck											;	Check RGB buttons|
				bit.b	#BIT5,P2IN												;	Testing Tilt-Switch for changed position
				jnz		countDown												;	If changed, jump to count down

				jmp		countUp													;	Continue counting up


countDown		call 	#delay													;	Delay call
				call	#buttonCheck											;	Check RGB buttons
				bit.b	#BIT5,P2IN												;	Testing Tilt-Switch for changed position
				jz		countUp													;	If changed, jump to count up

				bis.b	#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT			;	Clear 7-seg display
				bic.b	#BIT1+BIT7+BIT6+BIT0+BIT4+BIT3+BIT5,P3OUT				; 	9 out

				call	#delay													;	Delay call
				call	#buttonCheck											;	Check RGB buttons
				bit.b	#BIT5,P2IN												;	Testing Tilt-Switch for changed position
				jz		countUp													;	If changed, jump to count up

				bis.b	#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT			;	Clear 7-seg display
				bic.b	#BIT1+BIT2+BIT3+BIT4+BIT0+BIT6+BIT7+BIT5,P3OUT			; 	8 out

				call	#delay													;	Delay call
				call	#buttonCheck											;	Check RGB buttons
				bit.b	#BIT5,P2IN												;	Testing Tilt-Switch for changed position
				jz		countUp													;	If changed, jump to count up

				bis.b	#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT			;	Clear 7-seg display
				bic.b	#BIT7+BIT6+BIT4+BIT5,P3OUT								; 	7 out

				call	#delay													;	Delay call
				call	#buttonCheck											;	Check RGB buttons
				bit.b	#BIT5,P2IN												;	Testing Tilt-Switch for changed position
				jz		countUp													;	If changed, jump to count up

				bis.b	#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT			;	Clear 7-seg display
				bic.b	#BIT7+BIT1+BIT0+BIT4+BIT5+BIT3+BIT2,P3OUT				; 	6 out

				call	#delay													;	Delay call
				call	#buttonCheck											;	Check RGB buttons
				bit.b	#BIT5,P2IN												;	Testing Tilt-Switch for changed position
				jz		countUp													;	If changed, jump to count up

				bis.b	#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT			;	Clear 7-seg display
				bic.b	#BIT7+BIT1+BIT0+BIT4+BIT3+BIT5,P3OUT					; 	5 out

				call	#delay													;	Delay call
				call	#buttonCheck											;	Check RGB buttons
				bit.b	#BIT5,P2IN												;	Testing Tilt-Switch for changed position
				jz		countUp													;	If changed, jump to count up

				bis.b	#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT			;	Clear 7-seg display
				bic.b	#BIT1+BIT6+BIT0+BIT4+BIT5,P3OUT							; 	4 out

				call	#delay													;	Delay call
				call	#buttonCheck											;	Check RGB buttons
				bit.b	#BIT5,P2IN												;	Testing Tilt-Switch for changed position
				jz		countUp													;	If changed, jump to count up

				bis.b	#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT			;	Clear 7-seg display
				bic.b	#BIT7+BIT6+BIT0+BIT4+BIT3+BIT5,P3OUT					; 	3 out

				call	#delay													;	Delay call
				call	#buttonCheck											;	Check RGB buttons
				bit.b	#BIT5,P2IN												;	Testing Tilt-Switch for changed position
				jz		countUp													;	If changed, jump to count up

				bis.b	#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT			;	Clear 7-seg display
				bic.b	#BIT6+BIT7+BIT0+BIT2+BIT3+BIT5,P3OUT					;	2 out

				call	#delay													;	Delay call
				call	#buttonCheck											;	Check RGB buttons
				bit.b	#BIT5,P2IN												;	Testing Tilt-Switch for changed position
				jz		countUp													;	If changed, jump to count up

				bis.b	#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT			;	Clear 7-seg display
				bic.b	#BIT4+BIT6+BIT5,P3OUT									; 	1 out

				call 	#delay													;	Delay call
				call	#buttonCheck											;	Check RGB buttons
				bit.b	#BIT5,P2IN												;	Testing Tilt-Switch for changed position
				jz		countUp													;	If changed, jump to count up

				bis.b	#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT			;	Clear 7-seg display
				bic.b	#BIT1+BIT7+BIT6+BIT5+BIT4+BIT3+BIT2,P3OUT				;	0 out

				call	#delay													;	Delay call
				call	#buttonCheck											;	Check RGB buttons											;
				bit.b	#BIT5,P2IN												;	Testing Tilt-Switch for changed position
				jz		countUp													;	If changed, jump to count up
				jmp		countDown												;	Continue counting down


buttonCheck
redCheck		bit.b	#BIT1,P1IN												;	Is the button for activating red light pressed?
				jz		redLight												;	If pressed. jump to activation of red light
greenCheck		bit.b	#BIT1,P2IN												;	Is the button for activating green light pressed?
				jz		greenLight												;	If pressed. jump to activation of green light
blueCheck		bit.b	#BIT2,P8IN												;	Is the button for activating blue light pressed?
				jz		blueLight												;	If pressed. jump to activation of blue light
				ret																;	Return from call


redLight		bis.b	#BIT2,P2OUT												;	Resetting green light
				bis.b	#BIT6,P2OUT												; 	Resetting blue light
				bic.b	#BIT1,P8OUT												;	Activating red light
				jmp		redCheck												;	jump back to red check

greenLight		bis.b	#BIT1,P8OUT												;	Resetting red light
				bis.b	#BIT6,P2OUT												;	Resetting blue light
				bic.b	#BIT3,P2OUT												;	Activating green light
				jmp		greenCheck												;	Jump back to green check

blueLight		bis.b	#BIT3,P2OUT												;	Resetting green light
				bis.b	#BIT1,P8OUT												;	Resetting red light
				bic.b	#BIT6,P2OUT												;	Activating blue light
				jmp		blueCheck												;	Jump back to blue check


delay			bic.w	#TACLR+TAIFG,TA0CTL										;	Delay call, reset timer
wait			bit.w	#TAIFG,TA0CTL											;	Check state of timer
				jz		wait													;	If zero, jump to wait
				ret																;	Return to call

				nop																;	No operation
;_______________________________________________________________________________
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

