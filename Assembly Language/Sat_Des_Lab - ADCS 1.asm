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
; In this program for ADCS - Part 1, The indicator for low light will be a red
; light on an RGB LED, medium light will be green light and high light will be
; a blue light.
;
; Since this is meant to be a solar sensor, the limit for blue light is set
; rather high as is the green light limit. A direct hit with a led lenser T7
; flashlight was used to find the trigger limit.
; The green light limit is slightly lower when the flashlight beam indirectly hits
; the photoresistor.This will make sense later, as the engine will stop only if
; hit directly with a strong enough lightsource.
; ______________________________________________________________________________
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
; Buttons (input)
; ==============================================================================

			bic.b			#BIT1,P1DIR						;	P1.1 input with pull-up resistor
			bis.b			#BIT1,P1REN						;	Switch 1
			bis.b			#BIT1,P1OUT

			bic.b			#BIT1,P2DIR						;	P2.1 input with pull-up resistor
			bis.b			#BIT1,P2REN						;	Switch 2
			bis.b			#BIT1,P2OUT

; Photoresistor (input)
; ==============================================================================

			bic.b			#BIT0,P6DIR						;	P6.0 A0 input
			bis.b			#BIT0,P6SEL						;	Photoresistor read by peripheral unit

; RGB-LED (output)
; ==============================================================================

			bis.b			#BIT0,P3DIR						;	P3.0 RGB Output (Blue light)
			bis.b			#BIT0,P3OUT						;	P3.0 set high (No light at init)

			bis.b			#BIT1,P3DIR						;	P3.1 RGB Output (Green light)
			bis.b			#BIT1,P3OUT						;	P3.1 set high (No light at init)

			bis.b			#BIT2,P3DIR						;	P3.2 RGB Output (Red light)
			bis.b			#BIT2,P3OUT						;	P3.2 set high (No light at init)

; Motor control (output)
; ==============================================================================

			bis.b			#BIT2,P1DIR						;	P1.2 controlled by peripheral unit
			bis.b			#BIT2,P1SEL						;	TA0CCR1 controlling motor (PWM)

; Motor control output and timers
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


			cmp.w			#0E40h,ADC12MEM0				; 	Compare ADC12MEM1 with hexadecimal C30
			jl				red								;	Jump to red if ADC12MEM1 is lower than C30h
			cmp.w			#0F80h,ADC12MEM0				;	Compare ADC12MEM1 with hexadecimal EC0
			jl				green							;	Jump to green if ADC12MEM1 is lower than EC0h
			cmp.w			#0F80h,ADC12MEM0				;	Compare ADC12MEM1 with hexadecimal EC0
			jge				blue							;	Jump to blue if ADC12MEM1 is greather than or equal to F50h

			jmp				buttonCheck						;	Jump back to buttonCheck

slow		call			#delay							;	Call delay subroutine
			mov.w			#0x04AA,TA0CCR1					;	Setting slow speed
			jmp 			buttonCheck						;	Jump back to buttonCheck

fast
			call			#delay							;	Call delay subroutine
			mov.w			#0x000A,TA0CCR1					;	Setting fast speed
			jmp 			buttonCheck						;	Jump back to buttonCheck


red			bis.b			#BIT0,P3OUT						;	Shut off the blue light
			bis.b			#BIT1,P3OUT						;	Shut off the green light
			bic.b			#BIT2,P3OUT						;	Turn on the red light
			jmp				buttonCheck						;	Jump back to buttonCheck

green		bis.b			#BIT0,P3OUT						;	Shut off the blue light
			bic.b			#BIT1,P3OUT						;	Turn on the green light
			bis.b			#BIT2,P3OUT						;	Shut off the red light
			jmp				buttonCheck						;	Jump back to buttonCheck

blue		bic.b			#BIT0,P3OUT						;	Turn on the blue light
			bis.b			#BIT1,P3OUT						;	Shut off the green light
			bis.b			#BIT2,P3OUT						;	Shut off the red light
			jmp				buttonCheck						;	Jump back to buttonCheck
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
            
