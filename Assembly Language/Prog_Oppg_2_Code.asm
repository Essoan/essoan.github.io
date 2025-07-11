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
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
; Description:
; This program makes use of 6 buttons.
; Button 2 toggles a led light, button 1 performs an ADC12 conversion and
; presents the current potensiometer reading as a number (from 0 to 9) on a 7-segment display.
; Button 3 start a count up from 0-9 on the 7-seg. display, and button 4 counts down from 9 to 0.
; For both button 3 and 4, the counting is continous and will start over once the limit value is reached.
; Button 5 gives the opportunity to controll the counting speed based on the potentiometer reading.
; Finally, button 6 makes a buzzer sound. The sound continues until the button is pressed again.
; All functionality is based on interrupt. The main program is halted after configuring initial settings.
;
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
; ==============================================================================
; Inputs:
; ******************************************************************************

			bic.b			#BIT1,&P1DIR				;	Button 2 @ P1.1	(MiCo)
			bis.b			#BIT1,&P1REN
			bis.b			#BIT1,&P1OUT				;	Input with pull-up resistor

            bic.b			#BIT1,&P2DIR				;	Button 1 @ P2.1 (MiCo)
			bis.b			#BIT1,&P2REN
			bis.b			#BIT1,&P2OUT				;	Input with pull-up resistor

			bic.b			#BIT2,&P1DIR				;	Button 3 @ P1.2 (BrBo)
			bis.b			#BIT2,&P1REN
			bis.b			#BIT2,&P1OUT				;	Input with pull-up resistor

			bic.b			#BIT3,&P1DIR				;	Button 4 @ P1.3 (BrBo)
			bis.b			#BIT3,&P1REN
			bis.b			#BIT3,&P1OUT				;	Input with pull-up resistor

			bic.b			#BIT5,&P1DIR				;	Button 5 @ P1.5	(BrBo)
			bis.b			#BIT5,&P1REN
			bis.b			#BIT5,&P1OUT				;	Input with pull-up resistor

			bic.b			#BIT3,&P2DIR				;	Button 6 @ P2.3 (BrBo)
			bis.b			#BIT3,&P2REN
			bis.b			#BIT3,&P2OUT				;	Input with pull-up resistor

			bic.b			#BIT0,P6DIR					;	Potensiometer @ P6.0 (A0)
			bis.b			#BIT0,P6SEL					;	Read by peripheral unit

; ==============================================================================
; Outputs:
; ******************************************************************************

			bis.b			#11111111b,P3DIR			;	7-segment display @ P3.0-7

			bis.b			#BIT7,P4DIR					;	Led @ P4.7 (MiCo)
			bic.b			#BIT7,P4OUT					;	Clear led for init

			bis.b			#BIT2,P4DIR					;	Buzzer @ P4.2 (BrBo)

; ==============================================================================
; ADC Setup:
;
; The enable / start conversion is disabled to be able to adjust settings.
; Sample and hold time is set to 16x clock cycles, and  the AD converter is turned on.
; ADC12MEM0 set to memory location, ADC12SC bit set as source select, clock source is SMCLK
; Single-channel, single-conversion and SAMPCON signal source is the sampling timer.
; The resolution is set to 12 bit.
; Analog reading channel is set to A= (P6.0) and reference of Vr+ = AVCC and Vr- = AVSS
; Conversion is enabled after the previous settings are made.
; ******************************************************************************

			bic.w			#ADC12ENC+ADC12SC,ADC12CTL0
			bis.w			#ADC12SHT0_2+ADC12ON,ADC12CTL0

			bis.w			#ADC12CSTARTADD_0+ADC12SHS_0+ADC12SSEL_3,ADC12CTL1
			bis.w			#ADC12CONSEQ_0+ADC12SHP,ADC12CTL1

			bis.w			#ADC12RES_2,ADC12CTL2

			bis.b			#ADC12SREF_0+ADC12INCH_0,ADC12MCTL0

			bis.w			#ADC12ENC,ADC12CTL0

; ==============================================================================
; Port interrupt setup:
; ******************************************************************************

			bis.b			#BIT1+BIT2+BIT3+BIT5,&P1IES			;	Low-to-high trigger
			bic.b			#BIT1+BIT2+BIT3+BIT5,&P1IFG			;	Clearing interrupt flags
			bis.b			#BIT1+BIT2+BIT3+BIT5,&P1IE			;	P1.1-3 and P1.5 interrupt enabled

			bis.b			#BIT1+BIT3,&P2IES					;	Low-to-high trigger
			bic.b			#BIT1+BIT3,&P2IFG					;	Clearing interrupt flags
			bis.b			#BIT1+BIT3,&P2IE					;	P2.1 and P2.3 interrupt enabled

; ==============================================================================
; Timer settings
; ******************************************************************************

			bis.w			#TASSEL_2+ID_3+MC_3+TAIE,TA0CTL		;	SMCLK, input div. 8, up/down-mode, interrupt enabled
			bis.w			#OUTMOD_4,TA0CCTL1					;	Output mode: Toggle
			bis.w			#TAIDEX_7,TA0EX0					;	Divider expansion: 8x
			bis.w			#0xFFF,TA0CCR0
			mov.w			#1,TA0CCR1							;	Setting TA0CCR1 to lowest value (for pot. meter adjustments).

			bis.w			#TASSEL_2+ID_0+MC_1+TAIE,TA1CTL		;	SMCLK, no input divider, up-mode, interrupt enabled
			mov.w			#1000,TA1CCR0						;	Low value TA1CCR0 for frequency output

			bis.w			#TASSEL_2+ID_3+MC_1,TA2CTL			;	SMCLK, Input div. 8, up-mode
			mov.w			#65535,TA2CCR0						;	General delay timer, short delay.

; ==============================================================================
; Saving values for 7-seg. display to R5 register
; ******************************************************************************

			mov.w			#11011000000000b,R5					;	loading initial value to R5
			mov.b			#01000000b,0h(R5)					;	Setting value for number 0
			mov.b			#01111001b,1h(R5)					;	Setting value for number 1
			mov.b			#00100100b,2h(R5)					;	Setting value for number 2
			mov.b			#00110000b,3h(R5)					;	Setting value for number 3
			mov.b			#00011001b,4h(R5)					;	Setting value for number 4
			mov.b			#00010010b,5h(R5)					;	Setting value for number 5
			mov.b			#00000010b,6h(R5)					;	Setting value for number 6
			mov.b			#01111000b,7h(R5)					;	Setting value for number 7
			mov.b			#00000000b,8h(R5)					;	Setting value for number 8
			mov.b			#00010000b,9h(R5)					;	Setting value for number 9
			mov.b			#11111111b,P3OUT					;	Clearing 7 seg display

; ==============================================================================
; Clearing other rgisters that the program will use
; ******************************************************************************

			mov.w			#0x000000,R9
			mov.w			#0x000000,R12

; ==============================================================================
; Setting global interrupt
; ******************************************************************************

			nop
			bis.w			#GIE,SR								;	Global interrupt enabled
			nop

; ==============================================================================
; Main program
; ******************************************************************************

init
			jmp				$									;	Hold here.

; ==============================================================================
; P1 interrupt handler
; ******************************************************************************

P1_Handler														;	Port 1 interrupt handler
			ADD 			&P1IV,PC							;	Add offset to Jump table
			reti												; 	Return from interrupt
			jmp 			P1_0_HND 							; 	Jump to P1.0 Interrupt handler
			jmp 			P1_1_HND 							; 	Jump to P1.1 Interrupt handler
			jmp 			P1_2_HND 							;	Jump to P1.2 Interrupt handler
			jmp 			P1_3_HND 							; 	Jump to P1.3 Interrupt handler
			jmp 			P1_4_HND 							; 	Jump to P1.4 Interrupt handler
			jmp 			P1_5_HND 							; 	Jump to P1.5 Interrupt handler
			jmp 			P1_6_HND 							; 	Jump to P1.6 Interrupt handler
			jmp 			P1_7_HND 							; 	Jump to P1.7 Interrupt handler

P1_7_HND 	reti												; 	P1.7, not used in this program
P1_6_HND 	reti												; 	P1.6, not used in this program
P1_4_HND 	reti												; 	P1.4, not used in this program
P1_0_HND 	reti												; 	P1.0, not used in this program

P1_5_HND 														;	P1.5 Interrupt code
			bic.w			#ADC12IFG0,ADC12IFG					;	Clearing ADC12MEM0 result flag
			bis.w			#ADC12SC,ADC12CTL0					;	Starting conversion
check		bit.w			#ADC12IFG0,ADC12IFG					;	Checking ADC12MEM0 flag
			jz				check								;	Flag up? If not, check again
			bic.w			#ADC12SC,ADC12CTL0					;	Clearing ADC12SC bit for new conversion
			call			#delay								;	delay call
			mov.w			ADC12MEM0,TA0CCR0					;	Transfering ADC12MEM0 value to TA0CCR0
			reti												;	Return from interrupt

P1_3_HND 														;	P1.3 Interrupt code
			mov.w			#0x0B,R12							;	Set R12 register to 0Bh
			bis.w			#0x0FFF,TA0CCR0						;	Set TA0CCR0 to max ADC12MEM0 value
			mov.w			#11011000001001b,R5					;	Set R5 register value to return number 9
			mov.b			@R5,P3OUT							;	R5 value to P3
			call			#delay
			reti												;	Return from interrupt

P1_2_HND 														;	P1.2 Interrupt code
			mov.w			#0x0A,R12							;	Set R12 register to 0Bh
			bis.w			#0x0FFF,TA0CCR0						;	Set TA0CCR0 to max ADC12MEM0 value
			mov.w			#11011000000000b,R5					;	Set R5 register value to number 0
			mov.b			@R5,P3OUT							;	R5 value to P3
			call			#delay								; 	delay call
			reti												;	Return from interrupt

P1_1_HND 														;	Button 2 @ P1.1 Interrupt routine
			xor.b			#BIT7,P4OUT							;	Toogle P4.7
			bic.w			#BIT1,&P1IFG						;	Clear interrupt flag
			call			#delay								;	delay call
			bic.w			#BIT1,&P1IFG						;	clear interrupt flag again
			reti												;	Return from interrupt

; ==============================================================================
; P2 interrupt handler
; ******************************************************************************

P2_Handler														;	Port 2 interrupt handler
			ADD 			&P2IV,PC							;	Add offset to Jump table
			reti												; 	Return from interrupt
			jmp 			P2_0_HND 							; 	Jump to P2.0 Interrupt handler
			jmp 			P2_1_HND 							; 	Jump to P2.1 Interrupt handler
			jmp 			P2_2_HND 							;	Jump to P2.2 Interrupt handler
			jmp 			P2_3_HND 							; 	Jump to P2.3 Interrupt handler
			jmp 			P2_4_HND 							; 	Jump to P2.4 Interrupt handler
			jmp 			P2_5_HND 							; 	Jump to P2.5 Interrupt handler
			jmp 			P2_6_HND 							; 	Jump to P2.6 Interrupt handler
			jmp 			P2_7_HND 							; 	Jump to P2.7 Interrupt handler

P2_7_HND 	reti												; 	P2.7, not used in this program
P2_6_HND 	reti												; 	P2.6, not used in this program
P2_5_HND 	reti												;	P2.5, not used in this program
P2_4_HND 	reti												; 	P2.4, not used in this program
P2_2_HND 	reti												;	P2.2, not used in this program
P2_0_HND 	reti												; 	P2.0, not used in this program

P2_3_HND														;	P2.3 Interrupt code
			xor.b			#BIT0,R9							;	Alternate bit 0 in R9
			bic.b			#BIT3,&P2IFG						;	Clear P2.3 interrupt flag
			call			#delay								;	Delay call
			bic.b			#BIT3,&P2IFG						;	Clear P2.3 interrupt flag
			reti												;	Return from interrupt

P2_1_HND 														;	P2.1 Interrupt code
			mov.w			#0x000000,R12						;	Clear R12 values
			bic.w			#ADC12IFG0,ADC12IFG					;	Clearing ADC12MEM0 result flag
			bis.w			#ADC12SC,ADC12CTL0					;	Starting conversion
reCheck		bit.w			#ADC12IFG0,ADC12IFG					;	Checking ADC12MEM0 flag
			jz				reCheck								;	Flag up? If not, check again
			bic.w			#ADC12SC,ADC12CTL0					;	Clearing ADC12SC bit for new conversion

			cmp.w			#019Ah,ADC12MEM0					;	Compare 019Ah with ADC12MEM0 value
			jl				num9								;	If lesser, jump to num 9
			cmp.w			#0334h,ADC12MEM0					;	Compare 0334h with ADC12MEM0 value
			jl				num8								;	If lesser, jump to num 8
			cmp.w			#04CEh,ADC12MEM0					;	Compare 04CEh with ADC12MEM0 value
			jl				num7								;	If lesser, jump to num 7
			cmp.w			#0668h,ADC12MEM0					;	Compare 0668h with ADC12MEM0 value
			jl				num6								;	If lesser, jump to num 6
			cmp.w			#0802h,ADC12MEM0					;	Compare 0802h with ADC12MEM0 value
			jl				num5								;	If lesser, jump to num 5
			cmp.w			#099Ch,ADC12MEM0					;	Compare 099Ch with ADC12MEM0 value
			jl				num4								;	If lesser, jump to num 4
			cmp.w			#0B36h,ADC12MEM0					;	Compare 0B36h with ADC12MEM0 value
			jl				num3								;	If lesser, jump to num 3
			cmp.w			#0CD0h,ADC12MEM0					;	Compare 0CD0h with ADC12MEM0 value
			jl				num2								;	If lesser, jump to num 2
			cmp.w			#0E6Ah,ADC12MEM0					;	Compare 019Ah with ADC12MEM0 value
			jl				num1								;	If lesser, jump to num 1
			cmp.w			#0E6Ah,ADC12MEM0					;	Compare 019Ah with ADC12MEM0 value
			jge				num0								;	If greather than or equal, jump to num 0
			jmp				end

num9		mov.w			#11011000001001b,R5					;	Set R5 register value to return number 9
			jmp				end									;	Jump to end
num8		mov.w			#11011000001000b,R5					;	Set R5 register value to return number 8
			jmp				end									;	Jump to end
num7		mov.w			#11011000000111b,R5					;	Set R5 register value to return number 7
			jmp				end									;	Jump to end
num6		mov.w			#11011000000110b,R5					;	Set R5 register value to return number 6
			jmp				end									;	Jump to end
num5		mov.w			#11011000000101b,R5					;	Set R5 register value to return number 5
			jmp				end									;	Jump to end
num4		mov.w			#11011000000100b,R5					;	Set R5 register value to return number 4
			jmp				end									;	Jump to end
num3		mov.w			#11011000000011b,R5					;	Set R5 register value to return number 3
			jmp				end									;	Jump to end
num2		mov.w			#11011000000010b,R5					;	Set R5 register value to return number 2
			jmp				end									;	Jump to end
num1		mov.w			#11011000000001b,R5					;	Set R5 register value to return number 1
			jmp				end									;	Jump to end
num0		mov.w			#11011000000000b,R5					;	Set R5 register value to return number 0
			jmp				end									;	Jump to end
end			mov.b			@R5,P3OUT							;	R5 value to P3
			call			#delay								;	Call delay
			reti												;	Return from interrupt

; ==============================================================================
; TA0 interrupt handler
; ******************************************************************************

TA0_Handler														;	TimerA0 interrupt handler
			cmp.w			#0Ah,R12							;	Comparing 0Ah with value in R12
			jeq				countUp								;	If equal, jump to countUp
			cmp.w			#0Bh,R12							;	Comparing 0Bh with value in R12
			jeq				countDown							;	If equal, jump to countDown
			jne				TA0_ret								;	If not equal, jump to TA0_ret

countUp		add.w			#1,R5								;	Add 1 to R5
			cmp.w			#11011000001010b,R5					;	Checking if R5 value has reached upper limit value
			jeq				reSetUp								;	If equal, jump to reSetUp
			mov.b			@R5,P3OUT							;	Send R5 value to P3
			jmp				TA0_ret								;	Jump to TA0_ret

countDown	sub.w			#01h,R5								;	Subtract 1 from R5
			cmp.w			#11010111111111b,R5					;	Checking if R5 value has reached lower limit value
			jeq				reSetDown							;	If equal, jump to reSetDown
			mov.b			@R5,P3OUT							;	Send R5 value to P3
			jmp				TA0_ret								;	Jumpt to TA0_ret

reSetUp		mov.w			#11011000000000b,R5					;	Setting R5 to 0 value
			mov.b			@R5,P3OUT							;	Send R5 value to P3
			jmp				TA0_ret								;	Jumpt to TA0_ret

reSetDown	mov.w			#11011000001001b,R5					;	Setting R5 to 9 value
			mov.b			@R5,P3OUT							;	Send R5 value to P3
			jmp				TA0_ret								;	Jumpt to TA0_ret

TA0_ret 	bic.w			#TAIFG,TA0CTL						;	Clearing timer flag to enable further interrupts.
			reti												;	Return from interrupt

; ==============================================================================
; TA1 interrupt handler
; ******************************************************************************

TA1_Handler														;	TimerA1 interrupt handler
			bit.b			#BIT0,R9							;	Testing bit0 in R9 register
			jz				TA1_Ret								;	If zero, jump to TA1_ret
			xor.b			#BIT2,P4OUT							;	Alternate P4.2 (light toggle)

TA1_Ret		bic.w			#TAIFG,TA1CTL						;	Clearing TA1 flag to enable further interrupts.
			reti

; ==============================================================================
; Call routines:
; ******************************************************************************

delay		bis.w			#TACLR,TA2CTL						;	Setting TACLR bit
			bic.w			#TAIFG,TA2CTL						;	Clearing timer flag
reTest		bit.w			#TAIFG,TA2CTL						;	Testing timer flag
			jz				reTest								;	Flag back up? If not check again
			ret													;	return


;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ;	MSP430 RESET Vector
            .short  RESET
            
            .sect	".int47"				;	Port 1 interrupt vector
            .short	P1_Handler				;	Location of interrupt handler

            .sect	".int42"				;	Port 2 interrupt vector
            .short	P2_Handler				;	Location of interrupt handler

            .sect	".int52"				;	TA0 interrupt vector
			.short	TA0_Handler				;	Location of interrupt handler

            .sect	".int48"				;	TA1 interrupt vector
			.short	TA1_Handler				;	Location of interrupt handler
