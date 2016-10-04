;********************************************************************************
; DOES IT WORK?		YES
; FILENAME:			METRONOME
; VERSION:			1.0
; DATE:				01OCT2016	
; FILE SAVED AS:	16F648A_ECE411_DEMO.asm
; MICROCONTROLLER:	PIC16F648A
; CLOCK FREQUENCY:	48kHz using the on-board oscillator is desired for battery life
;********************************************************************************
; FILES REQUIRED:  	p16f648a.inc
;********************************************************************************
; PROGRAM FUNCTION:	METRONOME development board demonstration
;					flash 5volts to RA3,?RA2,RA1,RA0,RA7,?RA6,RB5,RB3.RB2,RB1
;					and toggle output using the interrupt at pin RB0/INT
;********************************************************************************
; NOTES:			? RA4 can only sink power (no led sourcing)
;					? RA2 and RA6 need some software switches flipped to source led
;					switch debounce would benefit from interrupt driven led's
;
;					flashing lights and a cricket sound.
;********************************************************************************
; AUTHOR:			KAM ROBERTSON
; COMPANY:			ACORN ENERGY LLC
;********************************************************************************
;********************************************************************************
;********************************************************************************
; HOUSEKEEPING
	list p = 16f648a		; list directive to define processor
	include C:\Program Files (x86)\Microchip\MPASM Suite\p16f648a.inc	
	__CONFIG   _INTOSC_OSC_CLKOUT & _WDT_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF  
	; PIC15F648A internal 4mhz oscillator
	; '__CONFIG' directive is used to embed configuration word within .asm file
;================================================================================
; DECLARATIONS cpu equates (memory map)
porta	EQU 0x005	; assigns the memory location of register PORTA to porta for use in code 
					; literals assigned with EQU cannot be changed elswhere in code
					; creates an un-changable pointer and allows use of lower case porta
portb	EQU 0x006	; allows use of lower case PORTB
num0	EQU 0x020	; "num0" is a pointer to register 32
num1	EQU	0x021	; "num1" is a pointer to register 33
num2	EQU 0x022	; "num2" is a pointer to register 34
work	EQU	0x023	; interrupt service temporarilly stores working register here
stat	EQU	0x024	; interrupt service temporarilly stores status register here
; DECLARATIONS bit equates
d1		EQU 0x010	; determines time spent in the delay loop
d2		EQU	0x011	; determines time spent in the delay loop
d3		EQU 0x012	; determines time spent in the delay loop
w		EQU 0		; allows for use of "w" =workingregister instead of zero for the destination
f		EQU 1		; allows for use of "f" =file istead of one for the destination
;================================================================================
; PROGRAM STARTS BELOW
	ORG		0x000
	GOTO	start	; go to the start 
	ORG		0x004	; interrupt service vector at memory location 0x004 it goes here automatically when intcon bit-1 is set
	GOTO	intserv	; go to the interrupt service function
start
	CALL initializer	; CALL the function "initializer"
	MOVLW 0x060			; moves literal number into working register passing this literal to the function delay
	CALL delay		; CALL the function "delay"
main
	BCF PORTA, 4	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d1		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BSF PORTA, 4 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d1		; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	BCF porta, 4	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d2		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BSF porta, 4 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d2			; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	BCF porta, 4	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d3		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BSF porta, 4 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d3			; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	;
	;
	BSF PORTA, 3	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d1		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF PORTA, 3 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d1		; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	BSF porta, 3	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d2		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF porta, 3 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d2			; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	BSF porta, 3	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d3		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF porta, 3 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d3			; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	;
	;	
	BSF PORTA, 2	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d1		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF PORTA, 2 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d1		; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	BSF porta, 2	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d2		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF porta, 2 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d2			; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	BSF porta, 2	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d3		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF porta, 2 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d3			; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	;
	;
	BSF PORTA, 1	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d1		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF PORTA, 1 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d1		; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	BSF porta, 1	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d2		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF porta, 1 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d2			; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	BSF porta, 1	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d3		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF porta, 1 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d3			; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	;
	;	
	BSF PORTA, 0	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d1		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF PORTA, 0 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d1		; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	BSF porta, 0	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d2		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF porta, 0 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d2			; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	BSF porta, 0	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d3		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF porta, 0 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d3			; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	;
	;
	BSF PORTA, 7	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d1		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF PORTA, 7 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d1		; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	BSF porta, 7	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d2		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF porta, 7 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d2			; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	BSF porta, 7	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d3		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF porta, 7 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d3			; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	;
	;	
	BSF PORTA, 6	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d1		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF PORTA, 6 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d1		; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	BSF porta, 6	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d2		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF porta, 6 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d2			; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	BSF porta, 6	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d3		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF porta, 6 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d3			; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	;
	;	
	BSF PORTB, 5	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d1		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF PORTB, 5 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d1		; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	BSF portb, 5	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d2		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF portb, 5 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d2			; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	BSF portb, 5	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d3		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF portb, 5 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d3			; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	;
	;	
	BSF PORTB, 3	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d1		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF PORTB, 3 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d1		; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	BSF portb, 3	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d2		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF portb, 3 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d2			; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	BSF portb, 3	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d3		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF portb, 3 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d3			; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	;
	;	
	BSF PORTB, 2	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d1		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF PORTB, 2 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d1		; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	BSF portb, 2	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d2		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF portb, 2 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d2			; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	BSF portb, 2	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d3		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF portb, 2 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d3			; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	;
	;	
	BSF PORTB, 1	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d1		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF PORTB, 1 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d1		; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	BSF portb, 1	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d2		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF portb, 1 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d2			; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	BSF portb, 1	; turn on LED at pin RA3, use bit-number for bit-position(3,2,1,0)
	MOVLW d3		; moves literal number into working register passing this literal to the function delay
	CALL delay	; CALL the function "delay"
	BCF portb, 1 	; turn off LED at pin RA3 (3,2,1,0 bit position)
	MOVLW d3			; moves literal into register "w".  use "w" to pass number of loops thru to function "delay"
	CALL delay	; CALL the function "delay"
	;
	GOTO	main	; loops back to main
;================================================================================
; SUBROUTINES AND FUNCTIONS
initializer
	; this selects the on board oscillator speed 48khz or 4mhz
	BSF		STATUS, 5	; set a one at bit-5 position in the status register... select bank1
	MOVLW	0x08		; put literal into working register to set the oscillator frequency p.29 16f648a datasheet
	MOVWF	PCON		; set the power control register to 0x8=4MHz or 0x0=48kHz p.29 16f648a datasheet
	BCF		STATUS,	5	; set a zero at bit-5 position in the status register... return to bank0
	;
	; setting PORTA as an output.  P.16,22 16F648A datasheet.  WORKS!
	CLRF	PORTA		; set all of porta to ground before making it an output with the trisa register
	NOP
	BSF		STATUS, 5	; set a one at bit-5 position in the status register... select bank1
	MOVLW	0x04     	; set bits/literal that will make RA3 an output into working registeroutputs
	MOVWF	TRISA  		; change default input status of RA3 to output using TRISA register in bank1
	BCF		STATUS,	5	; set a zero at bit-5 position in the status register... return to bank0
	;
	; SET-UP THE INTERRUPT
	CLRF	PORTB			; clear portb... safe it off
	BSF		STATUS,	5		; set status to bank1
	BSF		STATUS,	6		; set status to bank3
	MOVLW	0x01			; move literal to working register.  use to make portb an input for the interrupt
	MOVWF	TRISB			; make all portb and RB0/INT an input.  hook it up to a button and maybe debounce the button
	BCF		OPTION_REG,	7	; enable weak pull ups in option register.  (open button=5volts, depressed button is to ground)
	BSF		OPTION_REG,	6	; set interrupt to trigger on the rising edge in option register
	BSF		INTCON,	7		; enable global interrupt in the interrupt control register
	BSF		INTCON,	4		; enable external interrupt in the interrupt control register
	BCF		INTCON,	1		; clear interrupt holder bit in the interrupt control register
	BCF		STATUS,	6		; set status register back to bank1
	BCF		STATUS,	5		; set status register back to bank0
	;
	RETURN	; midline chips.  back from whence you came.
;
;
delay	; 8-bit system so... setting counters to zero gives 256 bits/decrements
		; uses literal number in working register to determine how many passes through the d_loop
	MOVWF	num2	; sets register-nine to zero using the pointer that holds the file address, count2
	MOVWF	num1	; sets register-eight to zero using the pointer that holds the file address, count1
	MOVWF	num0	; loads literal number from working register into register-seven using the pointer count0	
d_loop
	DECFSZ	num2, f	; decrements number at R9 by one then skips next step if count1_register-nine ontains zero
	GOTO	d_loop	; returns to d_loop if R9 contains any ones
	MOVWF	num2	; prepares for next use by setting R9 back to zero
	;
	DECFSZ	num1, f	; decrements number at R8 by one then skips next step if count2_register-eight contains a zero
	GOTO	d_loop	; returns to d_loop if R8 contains any ones
	MOVWF	num1	; prepares for next use by setting R8 back to zero
	;
	DECFSZ	num0, f	; decrements number at R7 by one then skips next step if count0_register-seven contains a zero
	GOTO	d_loop	; returns to d_loop if R7 contains any ones
	RETURN		; the larger command set on midline chips supports the "return" command. It is more appropriate here
;
;
intserv	; hey service this interrupt.  save those registers, do stuff, bring those registers back.  YAY!!!
	MOVWF	work		; save current working register in memory
	SWAPF	STATUS, w	; d=destination working register.  get current status without changing flags
	MOVWF	stat		; store current status register in memory
	BCF		INTCON,	1	; clear interrupt holder bit in the interrupt control register	
	; interrupt service code below
intcode	
	BCF		PORTA,	3	; set pin RA3 to ground
	BTFSS	INTCON,	1	; polling for an interrupt otherwise stay in the intcode loop
	GOTO	intcode		; intcode loop uses button to toggle the led active or led inactive
	; interrupt service code above
intexit
	BCF		INTCON,	1	; clear interrupt holder bit in the interrupt control register	
	SWAPF	stat,	w	; d=destination working register
	MOVWF	STATUS		; puts working register into status register... back to what it was
	SWAPF	work,	f	; d=destination file register... twist, no holder change.
	SWAPF	work,	w	; d=destination working register... untwist and back to what it was.  no holder change
	RETFIE	; back from whence you came and as you were.
;================================================================================
	END
;================================================================================


