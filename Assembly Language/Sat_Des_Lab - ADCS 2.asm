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
; The intent of this program is to simulate a solar sensor using a photoresistor,
; a DC motor and a microcontroller (MSP430F5529).
;
; The Photoresistor will sense the level of ambient light. When the level is
; regarded as high or maximized, the motor will stop spinning to indicate
; the sun being straight ahead.
;
; In the two other scenarios the motor will spin slowly for medium ambient light,
; and faster for low ambient light.
;
; The light level will be meassured by doing readings from the value of ADC12MEM0
; in wich the readings from the potentiometer will be stored after being digitally
; converted. A Flashlight will be used to indicate max ambient light and medium
; ambient light. Low ambient light will be normal indoor light.
;
; In this program for ADCS - Part 2, The engine will spin fast when there is a
; low light environment, spin a bit slower when the ambienbt light is brighter
; and stopp all together when the light level is high.
;
; Since this is meant to be a solar sensor, the limit for stopping the motor is set
; rather high as is the slow spin limit. A direct hit with a led lenser T7
; flashlight was used to find the trigger limit.
; The green li limit is slightly lower when the flashlight beam indirectly hits
; the photoresistor.This means the engine will stop only if
; hit directly with a strong enough lightsource.
; ______________________________________________________________________________
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
; Photoresistor (input)
; ==============================================================================

			bic.b			#BIT0,P6DIR						;	P6.0 A0 input
			bis.b			#BIT0,P6SEL						;	Photoresistor read by peripheral unit

; Motor control (output)
; ==============================================================================

			bis.b			#BIT2,P1DIR						;	P1.2 controlled by peripheral unit
			bis.b			#BIT2,P1SEL						;	TA0CCR1 controlling motor (PWM)

; Motor control timers
; ==============================================================================

			bis.w			#TASSEL_2+MC_1+ID_0,TA0CTL		;	SMCLK, Up Mode, no divider
			bis.w			#OUTMOD_2,TA0CCTL1				; 	Toggle / Reset mode, P1.2 TA0.1 (Lower value TA0CCR1 means longer "high" pulse width)
			bis.w			#0x0FFF,TA0CCR0					;	Setting TA0CCR0 to max
			bis.w			#0x0FFF,TA0CCR1					;	Motor not running at start

; General delay timer
; ==============================================================================

			bis.w			#TASSEL_2+ID_2+MC_1,TA1CTL
			bis.w			#65535,TA1CCR0

; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
; Configuring AD-converter
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
			bit.b			#BIT1,P1IN						;	Testing P1.1 for push-button action
			jz				slow							;	If button is pressed, jump to Slow
			bit.b			#BIT1,P2IN						;	Testing P2.1 for push-button action
			jz				fast							;	If button is pressed, jump to Fast


			cmp.w			#0E00h,ADC12MEM0				; 	Compare ADC12MEM1 with hexadecimal C30
			jl				fast							;	Jump to red if ADC12MEM1 is lower than C30h
			cmp.w			#0F40h,ADC12MEM0				;	Compare ADC12MEM1 with hexadecimal EC0
			jl				slow							;	Jump to green if ADC12MEM1 is lower than EC0h
			cmp.w			#0F40h,ADC12MEM0				;	Compare ADC12MEM1 with hexadecimal EC0
			jge				still							;	Jump to blue if ADC12MEM1 is greather than or equal to F50h

			jmp				buttonCheck						;	Jump back to buttonCheck

still		call			#delay							; 	Call delay subroutine
			mov.w			#0x0FFF, TA0CCR1				;	Setting engine stop
			jmp				buttonCheck						; jump back to buttonCheck

slow		call			#delay							;	Call delay subroutine
			mov.w			#0x04AA,TA0CCR1					;	Setting slow speed
			jmp 			buttonCheck						;	Jump back to buttonCheck

fast
			call			#delay							;	Call delay subroutine
			mov.w			#0x0003,TA0CCR1					;	Setting fast speed
			jmp 			buttonCheck						;	Jump back to buttonCheck
			nop

delay		bic.w			#TACLR+TAIFG,TA1CTL				;	Delay subroutine, clearing flag
wait		bit.w			#TAIFG,TA1CTL					;	Checking flag
			jz				wait							;	Hold for flag
			ret												;	Return from subroutine

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