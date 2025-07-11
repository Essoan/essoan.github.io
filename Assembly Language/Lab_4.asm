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
; ==============================================================================

;	Description:
;	This program will make a buzzer sound when Button 2 on P2.1 is pressed and held.
;	Button 1 on P1.1 will alternate between binary counting, and a wandering light on the
;	LEDs connected to P3.0-7

; ==============================================================================

; Inputs and outputs:
; ******************************************************************************
			bic.b			#BIT1,&P1DIR							;	Button 1
			bis.b			#BIT1,&P1REN							;	P1.1 Input with pull-up resistor
			bis.b			#BIT1,&P1OUT

			bic.b			#BIT1,&P2DIR							;	Button 2
			bis.b			#BIT1,&P2REN							;	P2.1 Input with pull-up resistor
			bis.b			#BIT1,&P2OUT

			bis.b			#0FFh,P3DIR								;	P3.0-7 Output for 8 separate LED lights
			bic.b			#0FFh,P3OUT								;	Clear lights at start

			bis.b			#BIT1,P8DIR								;	P8.1 Buzzer output

; Timers and interrupt settings
; ******************************************************************************
			bis.b			#BIT0,&P1IES							;	Port 1 interrupt set to trigger on "low to high" edge
			bic.b			#BIT1,&P1IFG							;	Interrupt pending set.
			bis.b			#BIT1,&P1IE								;	Interrupt enabled for P1.

			bis.w			#TASSEL_2+ID_3+MC_3+TAIE,TA0CTL			;	Timer A0 interrupt enabled, input divider set to 8, up/down mode, SMCLK.
			bis.w			#OUTMOD_4,TA0CCTL1						;	TA0CCTL1 set to toggle
			bis.w			#TAIDEX_7,TA0EX0						;	Input divider expansion set to 8
			bis.w			#65535,TA0CCR0							;	Set TA0CCR0 to max to have an initial setting
			bis.w			#1,TA0CCR1								;	TA0CCR1 set to 1. Lower TA0CCR0 means quicker pace.

			bis.w			#TASSEL_2+ID_0+MC_1+TAIE,TA1CTL			;	Frequency timer, SMCLK, No input divider, Up mode, Timer A1 interrupt enabled.
			mov.w			#1000,TA1CCR0							;	Low value TA1CCR0 for higher frequency output (no calculated frequency).

			bis.w			#TASSEL_2+ID_2+MC_1,TA2CTL				;	General delay timer, SMCLK, input divider 4, Up-mode, TA2
			mov.w			#65535,TA2CCR0							;	TA2CCR0 max value set

; ADC12 settings
; ******************************************************************************
			bic.w			#ADC12ENC+ADC12SC,ADC12CTL0				;	Disable ADC12 to apply settings
			bis.w			#ADC12ON+ADC12SHT0_2,ADC12CTL0			;	Turning on ADC12, sample and hold set to 16 clock cycles.

;			ADC12MEM0 set as conversion storage adress, Sample and hold source set set to ADC12SC bit, SMCLK, signal from sampling timer,
;			Single-channel, single-conversion.
			bis.w			#ADC12CSTARTADD_0+ADC12SHS_0+ADC12SSEL_3+ADC12SHP+ADC12CONSEQ_0,ADC12CTL1
			bis.w			#ADC12RES_2,ADC12CTL2					;	12 bit conversion result resolution
			bis.b			#ADC12SREF_0+ADC12INCH_0,ADC12MCTL0		;	Reference:	Vr+ = AVCC and Vr- = AVSS, A0 set as input channel.
			bis.w			#ADC12ENC,ADC12CTL0						;	ADC12 conversion enabled

; Set global interrupt
; ******************************************************************************
			nop
			bis.w			#GIE,SR									; 	Global interrupt enabled
			nop

; Main program
; ******************************************************************************
loop		bic.w			#ADC12IFG0,ADC12IFG						; 	Reset ADC12MEM0 flag
			bis.w			#ADC12SC,ADC12CTL0						;	Starting AD conversion
retry		bit.w			#ADC12IFG0,ADC12IFG						; 	Check if conversion is done
			jz				retry									;	If it is not, try again
			bic.w			#ADC12SC,ADC12CTL0						;	Clearing ADC12SC bit for new conversion
			mov.w			ADC12MEM0,TA0CCR0						;	Placing conversion value in ADC12MEM0 in TA0CCR0
			jmp				loop									;	Do conversion again

PORT1_ISR															;	Port 1 interrupt routine
			xor.b			#BIT0,R5								;	Flipping a bit in R5 everytime button 1 is pressed
			bic.b			#0FFh,P3OUT							;	Clearing lights on the 8 LEDs connected to P3
			bic.w			#BIT1,&P1IFG							;	Clearing flag to enable further interrupts
			call			#delay									;	General delay
			bic.w			#BIT1,&P1IFG							;	Clearing flag again, to increase button accuracy.
			reti													;	Return from interrupt

TA0_ISR																;	Timer A0 interrupt routine
			bis.w			#TACLR,TA0CTL							;	Set TACLR
			bit.b			#BIT0,R5								;	Testing BIT0 in R5
			jz				count									;	If bit is zero, jump to count.
			jnz				wander									;	If bit is 1, jump to wander

count																;	Routine for binary counting on P3
			inc.b			P3OUT									;	Increments P3
			jmp				return									;	jump to return

wander																;	Routine for wandering led
			rla.b			&P3OUT									;	Rotate left arithmetically
			bit.b			#11111111b,P3OUT						;	Testing if any bit on P3 is high
			jnz				return									;	Jump to return if any bit is high
			mov.b			#00000001b,P3OUT						;	if not, set the first bit high

return		bic.w			#TAIFG,TA0CTL							;	Clear timer flag to enable further interrupts
			reti													;	Return from interrupt

TA1_ISR																;	Timer A1 interrupt routine
			bit.b			#BIT1,P2IN								; 	Check if button 2 is pressed
			jnz				end										;	If it is not, go to end
			xor.b			#BIT1,P8OUT								;	If it is, alternate buzzer output.
end			bic.w			#TAIFG,TA1CTL							;	Clear timer flag to enable further interrupts.
			reti													;	Return from interrupt

delay		bis.w			#TACLR,TA2CTL							;	Set	TACLR
			bic.w			#TAIFG,TA2CTL							;	Clear timer flag
hold		bit.w			#TAIFG,TA2CTL							;	Test timer flag
			jz				hold									;	If flag not set, check again
			ret														;	return from delay routine

;-------------------------------------------------------------------------------
;           Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect 	.stack

;-------------------------------------------------------------------------------
;           Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET

			.sect	".int47"										;	Port 1 Interrupt vector
			.short	PORT1_ISR										;	Pointer to the P1 interrupt routine

			.sect	".int52"										;	TA0 Interrupt vector
			.short	TA0_ISR											;	Pointer to the TA0 interrupt routine

			.sect	".int48"										;	TA1 Interrupt vector
			.short	TA1_ISR											;	Pointer to the TA1 interrupt routine



