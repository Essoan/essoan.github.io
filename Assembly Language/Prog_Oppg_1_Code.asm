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
; _______________________________________________________________________________
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
; Description:
;
; This program has two main functions controlled by a tilt switch.
; If the switch is tilted right, it will sound an alarm and the RGB LED will blink alternately red, green and blue.
; If the tilt switch position is changed to left, there are 3 buttons that access different functionalities.
;
; Button 1 makes a reading from a potensiometer and a photoresistor.
; This reading is stored sequentially on ADC12MEM0 and ADC12MEM1 after being converted by the ADC.
;
; Button 2 reads the value of the potentiometer and displays its relative value on the 7-segment display.
; Button 3 reads the value of the photoresistor and displays the relative light intensity level on the 7 segment display.
;
;
; Port mapping for 7-segment display:
;					______________
;			 g,P3.6 |	___a__	 | a,P3.0
;		     f,P3.5 |	|    |	 | b,P3.1
;				    |  f|	 |b  |
;		   Cat,3v3  |	|__g_|	 | Cat, 3v3
;					|	|	 |	 |
;			 e,P3.4 |  e|   c| DP| c,P3.2
;		     d,P3.3 |	|____| o | DP,P3.7
;					|_____d______|
;
; ______________________________________________________________________________
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
; Setting inputs and outputs
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

; Buttons (input)
; ==============================================================================

			bic.b			#BIT1,P1DIR						;	P1.1 input with pull-up resistor
			bis.b			#BIT1,P1REN						;	Bryter 1
			bis.b			#BIT1,P1OUT

			bic.b			#BIT1,P2DIR						;	P2.1 input with pull-up resistor
			bis.b			#BIT1,P2REN						;	Bryter 2
			bis.b			#BIT1,P2OUT

			bic.b			#BIT2,P2DIR						;	P2.2 input with pull-up resistor
			bis.b			#BIT2,P2REN						;	Bryter 3
			bis.b			#BIT2,P2OUT

; Tilt-Switch (input)
; ==============================================================================

			bic.b			#BIT3,P1DIR						;	P1.3 input with pull-up resistor
			bis.b			#BIT3,P1REN
			bis.b			#BIT3,P1OUT

; Potensiometer (input)
; ==============================================================================

			bic.b			#BIT0,P6DIR						;	P6.0 A0 input
			bis.b			#BIT0,P6SEL						;	For ADC readings

; Photoresistor (input)
; ==============================================================================

			bic.b			#BIT1,P6DIR						;	P6.1 A1 input
			bis.b			#BIT1,P6SEL						;	For ADC readings

; 7-Segment display (output)
; ==============================================================================

			bis.b			#11111111b,P3DIR								;	P3.0-7 output for 7-segment display
			bis.b			#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT	;	clearing display


; RGB-LED (output)
; ==============================================================================

			bis.b			#BIT5,P2DIR						;	P2.5 output
			bis.b			#BIT5,P2OUT						;	Red light - P2.5 set high (= no light)

			bis.b			#BIT4,P2DIR						;	P2.4 output
			bis.b			#BIT4,P2OUT						;	Green light - P2.4 set high (= no light)

			bis.b			#BIT5,P1DIR						;	P1.5 output
			bis.b			#BIT5,P1OUT						;	Blue light - P1.5 set high (= no light)

; Buzzer (output)
; ==============================================================================

			bis.b			#BIT0,P2DIR						;	P2.0 set as output
			bis.b			#BIT0,P2SEL						;	Controlled by peripheral unit: TA1CCR1

; ______________________________________________________________________________
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
; Setting timers
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

; Setting general delay timer
; ==============================================================================

			bis.w			#TASSEL_2+ID_2+MC_1,TA0CTL		;	SMCLK sourced, up-mode, /4 divider
			bis.w			#65535,TA0CCR0					;	Setting TA0CCR0 to max value

; Buzzer timer (frequency)
; ==============================================================================

			bis.w			#TASSEL_2+ID_0+MC_1,TA1CTL		;	SMCLK sourced, Up-mode set, no divider
			bis.w			#OUTMOD_2,TA1CCTL1				;	Output mode set to Toggle / Reset

; ______________________________________________________________________________
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
; Setting AD-converter
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

			bic.w			#ADC12ENC+ADC12SC,ADC12CTL0						;	Clearing bits before applying settings
			bis.w			#ADC12ON+ADC12SHT0_2+ADC12MSC,ADC12CTL0			;	Sample / hold time in pulse-sample mode (16x cycles)
; ______________________________________________________________________________
; Setting ADC12MEM0 as first data conversion storage, Sample-and-hold set to ADC12SC bit,
; SAMPCON signal sourced from sampling timer, SMCLK set as clock source, sequence of channels set.
; ``````````````````````````````````````````````````````````````````````````````

			bis.w			#ADC12CSTARTADD_0+ADC12SHS_0+ADC12SHP+ADC12SSEL_3+ADC12CONSEQ_1,ADC12CTL1
			bis.w			#ADC12RES_2,ADC12CTL2							;	Resolution 12bit
			bis.b			#ADC12SREF_0+ADC12INCH_0,ADC12MCTL0				;	Input set to A0, Ref: (Vr+ = AVCC, Vr- = AVSS)
			bis.b			#ADC12SREF_0+ADC12INCH_1+ADC12EOS,ADC12MCTL1	;	Input set to A1, Ref: (Vr+ = AVCC, Vr- = AVSS), EOS bit set (last channel in sequence)
			bis.w			#ADC12ENC,ADC12CTL0								;	Activating AD-Converter
; ______________________________________________________________________________
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
; Main Program
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

initiate	bit.b			#BIT3,P1IN						;	Check P1.3 for tilt-switch state
			jnz				rightTilt						;	If not zero, jump to rightTilt
			jz				leftTilt						;	If zero, jump to leftTilt
			jmp				initiate						;	Jump to initiate

; Assignment 1
; ==============================================================================

rightTilt	call			#Hz200							;	Call for a 200Hz alarm to be played on the buzzer
			call			#blink							;	Call to make the RGB LED sequentially blink red, green and blue
			jmp				initiate						;	Jump to initiate
; ______________________________________________________________________________

; Assignment 2
; ==============================================================================
leftTilt	mov.w			#0,TA1CCR0						;	Stop buzzer sound, by setting TA1CCR0 to 0
			bis.b			#BIT4+BIT5,P2OUT				;	Clearing the red and green light
			bis.b			#BIT5,P1OUT						;	Clearing the blue light
			bit.b			#BIT1,P1IN						;	Check P1.1 for pushbutton action
			jz				button1							;	If button is pressed, jump to button1
			bit.b			#BIT1,P2IN						;	Check P2.1 for pushbutton action
			jz				button2							;	If button is pressed, jump to button2
			bit.b			#BIT2,P2IN						;	Check P2.2 for pushbutton action
			jz				button3							;	If button is pressed, jump to button3
			jmp				initiate						;	Jump to initiate

button1		bis.b			#BIT4+BIT5,P2OUT				;	Clearing the red and green light
			bis.b			#BIT5,P1OUT						;	Clearing the blue light
			call			#letterA						;	Call to print the letter A on the 7-segment display
			call			#Hz200							;	Call for a 200Hz alarm to be played on the buzzer
			bic.w			#ADC12IFG0,ADC12IFG				; 	Reset ADC12MEM0 flag
			bic.w			#ADC12IFG1,ADC12IFG				; 	Reset ADC12MEM1 flag
			bis.w			#ADC12SC,ADC12CTL0				;	Starting AD conversion
retry1		bit.w			#ADC12IFG0,ADC12IFG				;	Check if conversion to ADC12MEM0 is done
			jz				retry1							;	Jump to retry1 if it is not
retry2		bit.w			#ADC12IFG1,ADC12IFG				;	Check if conversion to ADC12MEM1 is done
			jz				retry2							;	Jump to retry2 if it is not
			bic.w			#ADC12SC,ADC12CTL0				;	Clearing ADC12SC bit for new conversion
			call			#delay500						;	Call for 0.5s delay
			xor.b			#BIT5,P2OUT						;	Alternate red light on / off
			call			#delay500						;	Call for 0.5s delay
			xor.b			#BIT5,P2OUT						;	Alternate red light on / off
			call			#delay500						;	Call for 0.5s delay
			xor.b			#BIT5,P2OUT						;	Alternate red light on / off
			call			#delay500						;	Call for 0.5s delay
			xor.b			#BIT5,P2OUT						;	Alternate red light on / off
			call			#delay500						;	Call for 0.5s delay
			xor.b			#BIT5,P2OUT						;	Alternate red light on / off
			call			#delay500						;	Call for 0.5s delay
			mov.w			#0,TA1CCR0						;	Stop buzzer sound, by setting TA1CCR0 to 0
			call			#nothing						;	Clear the 7-segment display
			bis.b			#BIT5,P2OUT						;	Red light off
			bic.b			#BIT4,P2OUT						;	Green light on
reCheck1	bit.b			#BIT1,P1IN						;	Checking P1.1
			jz				button1							;	If pressed, go to button 1
			bit.b			#BIT1,P2IN						;	Checking P2.1
			jz				button2							;	If pressed, go to button 2
			bit.b			#BIT2,P2IN						;	Checking P2.2
			jz				button3							;	if pressed, go to button3
			bit.b			#BIT3,P1IN						; 	Checking tilt-switch
			jnz				rightTilt						;	If not zero, go to rightTilt
			jmp				reCheck1						;	Jumps to reCheck1


button2		bis.b			#BIT4+BIT5,P2OUT				;	Clearing the red and green light
			bic.b			#BIT5,P1OUT						;	Turn on the blue light
			call			#letterP						;	Call for letter P to appear on 7-seg display
			call			#delay1500						;	2x 1,5s delay calls for a total 3 second break
			call			#delay1500
			bis.b			#BIT5,P1OUT						;	Turns off the blue light
			cmp.w			#019Ah,ADC12MEM0				; 	Compare ADC12MEM0 with hexadecimal 19A
			jl				level9							;	Jump to levelH if ADC12MEM1 is lower than 19A
			cmp.w			#0334h,ADC12MEM0				; 	Compare ADC12MEM0 with hexadecimal 334
			jl				level8							;	Jump to levelH if ADC12MEM1 is lower than 334
			cmp.w			#04CEh,ADC12MEM0				; 	Compare ADC12MEM0 with hexadecimal 4CE
			jl				level7							;	Jump to levelH if ADC12MEM1 is lower than 4CE
			cmp.w			#0668h,ADC12MEM0				; 	Compare ADC12MEM0 with hexadecimal 668
			jl				level6							;	Jump to levelH if ADC12MEM1 is lower than 668
			cmp.w			#0802h,ADC12MEM0				; 	Compare ADC12MEM0 with hexadecimal 802
			jl				level5							;	Jump to levelH if ADC12MEM1 is lower than 802
			cmp.w			#099Ch,ADC12MEM0				; 	Compare ADC12MEM0 with hexadecimal 99C
			jl				level4							;	Jump to levelH if ADC12MEM1 is lower than 99C
			cmp.w			#0B36h,ADC12MEM0				; 	Compare ADC12MEM0 with hexadecimal B36
			jl				level3							;	Jump to levelH if ADC12MEM1 is lower than B36
			cmp.w			#0CD0h,ADC12MEM0				; 	Compare ADC12MEM0 with hexadecimal CD0
			jl				level2							;	Jump to levelH if ADC12MEM1 is lower than CD0
			cmp.w			#0E6Ah,ADC12MEM0				; 	Compare ADC12MEM0 with hexadecimal E6A
			jl				level1							;	Jump to levelH if ADC12MEM1 is lower than E6A
			cmp.w			#0E6Ah,ADC12MEM0				; 	Compare ADC12MEM0 with hexadecimal E6A
			jge				level0							;	Jump to levelH if ADC12MEM1 is greater than or equal to E6A

reCheck2	bit.b			#BIT1,P1IN						;	Checking P1.1
			jz				button1							;	If pressed, go to button 1
			bit.b			#BIT1,P2IN						;	Checking P2.1
			jz				button2							;	If pressed, go to button 2
			bit.b			#BIT2,P2IN						;	Checking P2.2
			jz				button3							;	if pressed, go to button3
			bit.b			#BIT3,P1IN						; 	Checking tilt-switch
			jnz				rightTilt						;	If not zero, go to rightTilt
			jmp				reCheck2						;	Jumps to reCheck2

level0		call			#number0						;	Call for number 0 to appear on 7-seg display
			jmp				reCheck2						;	Jumps to reCheck2

level1		call			#number1						;	Call for number 1 to appear on 7-seg display
			jmp				reCheck2						;	Jumps to reCheck2

level2		call			#number2						;	Call for number 2 to appear on 7-seg display
			jmp				reCheck2						;	Jumps to reCheck2

level3		call			#number3						;	Call for number 3 to appear on 7-seg display
			jmp				reCheck2						;	Jumps to reCheck2

level4		call			#number4						;	Call for number 4 to appear on 7-seg display
			jmp				reCheck2						;	Jumps to reCheck2

level5		call			#number5						;	Call for number 5 to appear on 7-seg display
			jmp				reCheck2						;	Jumps to reCheck2

level6		call			#number6						;	Call for number 6 to appear on 7-seg display
			jmp				reCheck2						;	Jumps to reCheck2

level7		call			#number7						;	Call for number 7 to appear on 7-seg display
			jmp				reCheck2						;	Jumps to reCheck2

level8		call			#number8						;	Call for number 8 to appear on 7-seg display
			jmp				reCheck2						;	Jumps to reCheck2

level9		call			#number9						;	Call for number 9 to appear on 7-seg display
			jmp				reCheck2						;	Jumps to reCheck2

; ______________________________________________________________________________

; Assignment 3
; ==============================================================================

button3		bis.b			#BIT4+BIT5,P2OUT				;	Clearing the red and green light
			bic.b			#BIT5,P1OUT						;	Turn on the blue light
			call			#letterL						;	Call for letter L to show on the 7-segment display
			call			#delay1500						;	Call for 1,5s delay
			call			#delay1500						;	Call for 1,5s delay
			bis.b			#BIT5,P1OUT						;	turn off blue light
			cmp.w			#00E4h,ADC12MEM1				; 	Compare ADC12MEM1 with hexadecimal E4
			jl				levelF							;	Jump to levelF if ADC12MEM1 is lower than E4h
			cmp.w			#0600h,ADC12MEM1				;	Compare ADC12MEM1 with hexadecimal E4
			jl				levelC							;	Jump to levelC if ADC12MEM1 is lower than 600h
			cmp.w			#0600h,ADC12MEM1				;	Compare ADC12MEM1 with hexadecimal 600
			jge				levelH							;	Jump to levelH if ADC12MEM1 is greather than or equal to 600h

levelF		call			#letterF						;	Call for letter F to appear on 7-seg display
			jmp				reCheck3						;	Jumps to reCheck3

levelC		call			#letterC						;	Call for letter F to appear on 7-seg display
			jmp				reCheck3						;	Jumps to reCheck3

levelH		call			#letterH						;	Call for letter F to appear on 7-seg display
			jmp				reCheck3						;	Jumps to reCheck3

reCheck3	bit.b			#BIT1,P1IN						;	Checking P1.1
			jz				button1							;	If pressed, go to button 1
			bit.b			#BIT1,P2IN						;	Checking P2.1
			jz				button2							;	If pressed, go to button 2
			bit.b			#BIT2,P2IN						;	Checking P2.2
			jz				button3							;	if pressed, go to button3
			bit.b			#BIT3,P1IN						; 	Checking tilt-switch
			jnz				rightTilt						;	If not zero, go to rightTilt
			jmp				reCheck3						;	Jumps to reCheck3

;_______________________________________________________________________________

; Calls  for assignment 1
; ==============================================================================

Hz200		mov.w 			#5243,TA1CCR0					;	200Hz buzzer output
            mov.w 			#2621,TA1CCR1
            ret

blink		call			#delay400						;	Call 400ms delay
			bis.b			#BIT4,P2OUT						;	Turn off blue and green
			bis.b			#BIT5,P1OUT
			bic.b			#BIT5,P2OUT						;	Turn on red
			call			#delay400						;	Call 400ms delay
			bis.b			#BIT5,P2OUT						;	Turn off red and blue
			bis.b			#BIT5,P1OUT
			bic.b			#BIT4,P2OUT						;	Turn on green
			call			#delay400						;	Call 400ms delay
			bis.b			#BIT4,P2OUT						;	Turn off red and green
			bis.b			#BIT5,P2OUT
			bic.b			#BIT5,P1OUT						;	Turn on blue
			ret
; ______________________________________________________________________________

; Delay calls
; ==============================================================================

delay400	bic.w			#BIT0+BIT1+BIT2,TA0EX0			;	Clearing TA0EX0 Bits
			bis.w			#TAIDEX_1,TA0EX0				;	Setting TAIDEX_1
           	mov.w 			#52429,TA0CCR0   				;	400ms delay
           	bis.w			#TACLR,TA0CTL					;	Set TACLR
            bic.w 			#TAIFG,TA0CTL					;	Clearing flag
wait400     bit.w 			#TAIFG,TA0CTL					;	Checking flag
            jz      		wait400							; 	Flag up? If not, check again.
            ret												;	Return to call

delay500	bic.w			#BIT0+BIT1+BIT2,TA0EX0			;	Clearing TA0EX0 Bits
			bis.w			#TAIDEX_1,TA0EX0				;	Setting TAIDEX_1
           	mov.w 			#65535,TA0CCR0   				;	500ms delay
           	bis.w			#TACLR,TA0CTL					;	Set TACLR
            bic.w 			#TAIFG,TA0CTL					;	Clearing flag
wait500     bit.w 			#TAIFG,TA0CTL					;	Checking flag
            jz      		wait500							; 	flag up? If not, check again.
			ret												;	Return to call

delay1500	bic.w			#BIT0+BIT1+BIT2,TA0EX0			;	Clearing TA0EX0 Bits
			bis.w			#TAIDEX_5,TA0EX0				;	Setting TAIDEX_1
           	mov.w 			#65535,TA0CCR0   				;	500ms delay
           	bis.w			#TACLR,TA0CTL					;	Set TACLR
            bic.w 			#TAIFG,TA0CTL					;	Clearing flag
wait1500    bit.w 			#TAIFG,TA0CTL					;	Checking flag
            jz      		wait1500						; 	flag up? If not, check again.
			ret												;	Return to call
; ______________________________________________________________________________

; 7-Segment Display values
; ==============================================================================

letterA		bis.b			#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT		;	Clears 7-segment display
			bic.b			#BIT0+BIT1+BIT2+BIT4+BIT5+BIT6+BIT7,P3OUT			;	Sets the letter A on the 7-segment display
			ret

letterP		bis.b			#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT		;	Clears 7-segment display
			bic.b			#BIT0+BIT1+BIT4+BIT5+BIT6+BIT7,P3OUT				;	Sets the letter P on the 7-segment display
			ret

letterL		bis.b			#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT		;	Clears 7-segment display
			bic.b			#BIT3+BIT4+BIT5+BIT7,P3OUT							;	Sets the letter L on the 7-segment display
			ret

letterF		bis.b			#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT		;	Clears 7-segment display
			bic.b			#BIT0+BIT4+BIT5+BIT6+BIT7,P3OUT						;	Sets the letter F on the 7-segment display
			ret

letterC		bis.b			#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT		;	Clears 7-segment display
			bic.b			#BIT0+BIT3+BIT4+BIT5+BIT7,P3OUT						;	Sets the letter C on the 7-segment display
			ret

letterH		bis.b			#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT		;	Clears 7-segment display
			bic.b			#BIT1+BIT2+BIT4+BIT5+BIT6+BIT7,P3OUT				;	Sets the letter H on the 7-segment display
			ret

number0		bis.b			#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT		;	Clears 7-segment display
			bic.b			#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT7,P3OUT			;	Sets the number 0 on the 7-segment display
			ret

number1		bis.b			#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT		;	Clears 7-segment display
			bic.b			#BIT1+BIT2+BIT7,P3OUT								;	Sets the number 1 on the 7-segment display
			ret

number2		bis.b			#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT		;	Clears 7-segment display
			bic.b			#BIT0+BIT1+BIT3+BIT4+BIT6+BIT7,P3OUT				;	Sets the number 2 on the 7-segment display
			ret

number3		bis.b			#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT		;	Clears 7-segment display
			bic.b			#BIT0+BIT1+BIT2+BIT3+BIT6+BIT7,P3OUT				;	Sets the number 3 on the 7-segment display
			ret

number4		bis.b			#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT		;	Clears 7-segment display
			bic.b			#BIT1+BIT2+BIT5+BIT6+BIT7,P3OUT						;	Sets the number 4 on the 7-segment display
			ret

number5		bis.b			#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT		;	Clears 7-segment display
			bic.b			#BIT0+BIT2+BIT3+BIT5+BIT6+BIT7,P3OUT				;	Sets the number 5 on the 7-segment display
			ret

number6		bis.b			#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT		;	Clears 7-segment display
			bic.b			#BIT0+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT			;	Sets the number 6 on the 7-segment display
			ret

number7		bis.b			#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT		;	Clears 7-segment display
			bic.b			#BIT0+BIT1+BIT2+BIT7,P3OUT							;	Sets the number 7 on the 7-segment display
			ret

number8		bis.b			#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT		;	Clears 7-segment display
			bic.b			#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT		;	Sets the number 8 on the 7-segment display
			ret

number9		bis.b			#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT		;	Clears 7-segment display
			bic.b			#BIT0+BIT1+BIT2+BIT3+BIT5+BIT6+BIT7,P3OUT			;	Sets the number 9 on the 7-segment display
			ret

nothing		bis.b			#BIT0+BIT1+BIT2+BIT3+BIT4+BIT5+BIT6+BIT7,P3OUT		;	Clears 7-segment display
			ret
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
            
