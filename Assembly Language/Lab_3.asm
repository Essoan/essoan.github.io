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
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
; The intention of this program is to adjust the color of an RGB-LED unit.
;
; There are three buttons and a potensiometer being used to produce this effect.
;
; Each button controlls a pin on the RGB-LED, and uses an analog reading from the
; potensiometer to adjust  the output colors.
; ______________________________________________________________________________
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
; Setting inputs and outputs
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

; Buttons (input)
; ==============================================================================

			bic.b			#BIT1,P8DIR						;	P8.1 input with pull-up resistor
			bis.b			#BIT1,P8REN
			bis.b			#BIT1,P8OUT

			bic.b			#BIT2,P8DIR						;	P8.2 input with pull-up resistor
			bis.b			#BIT2,P8REN
			bis.b			#BIT2,P8OUT

			bic.b			#BIT7,P3DIR						;	P3.7 input with pull-up resistor
			bis.b			#BIT7,P3REN
			bis.b			#BIT7,P3OUT

; Potensiometer (input)
; ==============================================================================

			bic.b			#BIT0,P6DIR						;	P6.0 A0 input
			bis.b			#BIT0,P6SEL

; RGB-LED (output)
; ==============================================================================

			bis.b			#BIT2,P1DIR						;	P1.2 controlled by peripheral unit
			bis.b			#BIT2,P1SEL						;	Rød - TA0CCR1

			bis.b			#BIT3,P1DIR						;	P1.3 controlled by peripheral unit
			bis.b			#BIT3,P1SEL						;	Grønn - TA0CCR2

			bis.b			#BIT4,P1DIR						;	P1.4 controlled by peripheral unit
			bis.b			#BIT4,P1SEL						;	Blå - TA0CCR3


; ______________________________________________________________________________
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
; Setting timers
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

; RGB-LED output timers
; ==============================================================================

			bis.w			#TASSEL_2+MC_1+ID_0,TA0CTL		;	SMCLK, Up Mode, no divider
			bis.w			#OUTMOD_2,TA0CCTL1				; 	Toggle / Reset mode, P1.2 TA0.1 - Red
			bis.w			#OUTMOD_2,TA0CCTL2				; 	Toggle / Reset mode, P1.3 TA0.2 - Green
			bis.w			#OUTMOD_2,TA0CCTL3				;	Toggle / Reset mode, P1.4 TA0.3 - Blue
			bis.w			#0x0FFF,TA0CCR0					;	Setting TA0CCR0 to max Nadc

; Setting delay timer
; ==============================================================================

			bis.w			#TASSEL_2+ID_2+MC_1,TA1CTL
			bis.w			#65535,TA1CCR0
; ______________________________________________________________________________
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
; Setting AD-converter
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

			bic.w			#ADC12ENC+ADC12SC,ADC12CTL0			;	Clearing bits before applying settings
			bis.w			#ADC12ON+ADC12SHT0_1,ADC12CTL0		;	Sample / hold time in pulse-sample mode (8x cycles)
; ______________________________________________________________________________
; Setting ADC12MEM0 as data conversion storage, Sample-and-hold set to ADC12SC bit,
; SAMPCON signal sourced from sampling timer, SMCLK set as clock source.
; ``````````````````````````````````````````````````````````````````````````````
			bis.w			#ADC12CSTARTADD_0+ADC12SHS_0+ADC12SHP+ADC12SSEL_3,ADC12CTL1

			bis.w			#ADC12RES_2,ADC12CTL2				;	Resolution 12bit

			bis.w			#ADC12SREF_0+ADC12INCH_0,ADC12MCTL0	;	Reference: (Vr+ = AVCC, Vr- = AVSS), Input set to A0

			bis.w			#ADC12ENC,ADC12CTL0					;	Activating AD-Converter
; ______________________________________________________________________________
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
; Main Program
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

buttonCheck	bic.w			#ADC12IFG0,ADC12IFG				; 	Reset flag
			bis.w			#ADC12SC,ADC12CTL0				;	Starting conversion
retry		bit.w			#ADC12IFG0,ADC12IFG				;	Waiting for conversion
			jz				retry							;	Hold for flag
			bit.b			#BIT2,P8IN						;	Testing P8.2 for push-button action
			jz				LED1							;	If button is pressed, jump to LED1
			bit.b			#BIT7,P3IN						;	Testing P3.7 for push-button action
			jz				LED2							;	If button is pressed, jump to LED2
			bit.b			#BIT1,P8IN						;	Testing P8.1 for push-button action
			jz				LED3							;	If button is pressed, jump to LED3
			jmp				buttonCheck						;	Jump back to buttonCheck


LED1		call			#delay							;	Call delay subroutine
			mov.w			ADC12MEM0,TA0CCR1				;	Transfer converted value to output
			jmp 			buttonCheck						;	Jump back to buttonCheck

LED2
			call			#delay							;	Call delay subroutine
			mov.w			ADC12MEM0,TA0CCR2				;	Transfer converted value to output
			jmp 			buttonCheck						;	Jump back to buttonCheck


LED3		call			#delay							;	Call delay subroutine
			mov.w			ADC12MEM0,TA0CCR3				;	Transfer converted value to output
			jmp 			buttonCheck						;	Jump back to buttonCheck
			nop												; 	No operation

delay		bic.w			#TACLR+TAIFG,TA1CTL				;	Delay subroutine, clearing flag
wait		bit.w			#TAIFG,TA1CTL					;	Checking flag
			jz				wait							;	Hold for flag
			ret												;	Return from subroutine
; ______________________________________________________________________________
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
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
            
