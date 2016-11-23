;********************************************************************************
; DOES IT WORK?		???
; FILENAME:			METROKNOME_test_v1.0
; VERSION:			1.0
; DATE:				19OCT2016	
; FILE SAVED AS:	16F648A_MetroKnomeV1.asm
; MICROCONTROLLER:	PIC16F648A
; CLOCK FREQUENCY:	48kHz using the on-board oscillator for battery life
;********************************************************************************
; FILES REQUIRED:  	p16f648a.inc
;********************************************************************************
; PROGRAM FUNCTION:	METROKNOME 
;					want: alternate flashing two led's
;					want: sound a piezo buzzer with each flash of an led
;					have: toggle output using the interrupt at pin RB0/INT
;					want: control speed with RB1 and RB2 by polling at interrupt
;********************************************************************************
; NOTES:			have: flash 5volts to RA3,RA2,RA1,RA0,RB5,RB3
;					? RA4 can only sink power (no led sourcing?)
;					want: flashing lights and a cricket sound.
;********************************************************************************
;********************************************************************************
;********************************************************************************
;********************************************************************************
; HOUSEKEEPING
	list p = 16f648a		; list directive to define processor
	include C:\Program Files (x86)\Microchip\MPLABX\v3.45\mpasmx\p16f648a.inc	
	__CONFIG   _CP_OFF & _CPD_OFF & _LVP_OFF & _BOREN_OFF & _MCLRE_ON & _PWRTE_OFF & _WDT_OFF & _INTOSC_OSC_NOCLKOUT          
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
oldstate	EQU 0x025	; register to store encoder prior state
newstate	EQU 0x026	;register to store register current state
rate	EQU 0x027	; register to store encoder rate to pass to timer
; DECLARATIONS bit equates
;d1		EQU 0x02	; determines time spent in the delay loop
;d2		EQU	0x04	; determines time spent in the delay loop
;d3		EQU 0x06	; determines time spent in the delay loop
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
	goto main
main
	movf	PORTB, w
	andlw	30h
	rrf		w,0
	rrf		w,0
	rrf		w,0
	rrf		w,0
	movwf	oldstate
	call	red_off
	call	green_off
	btfss	PORTB, 4
	call    red_on
	btfss	PORTB, 5
	call	green_on
temp1	goto main
check	
	;call chk_encoder
	GOTO	temp1	; loops back to main
;================================================================================
; SUBROUTINES AND FUNCTIONS
chk_encoder
	movf	PORTB, w
	andlw	30h
	rrf	w,0
	rrf	w,0
	rrf	w,0
	rrf	w,0
	movwf	newstate
	xorwf	oldstate, 0
	btfsc	w, 0
	goto	eval_encoder
	btfsc	w, 1
	goto	eval_encoder
	return
eval_encoder
	movf	oldstate, 0
	rlf	w, 0
	xorwf	newstate, 0
	btfsc	w, 1
	goto up
down
	call	red_on
	call	green_off
	movf	newstate
	movwf	oldstate
	return
up	
	call green_on
	call red_off
	movf	newstate
	movwf	oldstate
	return
red_on
	bsf PORTA, 1
	return
red_off 
	bcf PORTA, 1
	return
green_on    
	bsf PORTA, 0
	return
green_off
	bcf PORTA, 0
	return
initializer
	; this selects the on board oscillator speed 48khz or 4mhz
	BSF		STATUS, 5	; set a one at bit-5 position in the status register... select bank1
	MOVLW	0x00		; put literal into working register to set the oscillator frequency p.29 16f648a datasheet
	MOVWF	PCON		; set the power control register to 0x8=4MHz or 0x0=48kHz p.29 16f648a datasheet
	BCF		STATUS,	5	; set a zero at bit-5 position in the status register... return to bank0
	;
	; setting PORTA as an output.  P.16,22 16F648A datasheet.  WORKS!
	CLRF	PORTA		; set all of porta to ground before making it an output with the trisa register
	BSF	STATUS, 5	; set a one at bit-5 position in the status register... select bank1
	MOVLW	0x000     	; set bits/literal that will make RA pins an output into working registeroutputs
	MOVWF	TRISA  		; change default input status of RA pins to output using TRISA register in bank1
	BCF	STATUS,	5	; set a zero at bit-5 position in the status register... return to bank0
	;
	; setting PORTB as an input
	BSF STATUS, 5
	MOVLW	b'110001'
	MOVWF	TRISB
	BCF	STATUS, 5
	; SET-UP THE INTERRUPT
	CLRF	PORTB			; clear portb... safe it off
	BSF		STATUS,	5		; set status to bank1
	BSF		STATUS,	6		; set status to bank3
	;MOVLW	31h			; move literal to working register.  use to make portb RB0/INT, RB4, RB5 an input.
	;MOVWF	TRISB			; make all portb and RB0/INT an input.  
	BCF		OPTION_REG,	7	; enable weak pull ups in option register.  (open button=5volts, depressed button is to ground)
	BSF		OPTION_REG,	6	; set interrupt to trigger on the rising edge in option register
	BSF		INTCON,	7		; enable global interrupt in the interrupt control register
	BSF		INTCON,	4		; enable external interrupt in the interrupt control register
	BCF		INTCON,	1		; clear interrupt holder bit in the interrupt control register
	BCF		STATUS,	6		; set status register back to bank1
	BCF		STATUS,	5		; set status register back to bank0
	;
	RETURN	; 
;
;

;
intserv	; hey service this interrupt.  save those registers, do stuff, bring those registers back.  YAY!!!
	;MOVWF	work		; save current working register in memory
	SWAPF	STATUS, w	; d=destination working register.  get current status without changing flags
	MOVWF	stat		; store current status register in memory
	BCF		INTCON,	1	; clear interrupt holder bit in the interrupt control register	
	; interrupt service code below
intcode	
	BCF		PORTA,	0	; SINK pin RA0 to ground
	BCF		PORTA,	1	; SINK pin RA1 to ground
	BCF		PORTA,	2	; SINK pin RA2 to ground
	BCF		PORTA,	3	; SINK pin RA3 to ground
	BCF		PORTA,	4	; SINK pin RA4 to ground
	BCF		PORTB,	3	; SINK pin RB3 to ground
	BCF		PORTB,  4
	BCF		PORTB,	5	; SINK pin RB5 to ground
read_encoder	
	movf	PORTB, w
	;rrf		w,0
	;rrf		w,0
	;rrf		w,0
	;rrf		w,0
	;movwf	PORTA
	movwf	oldstate
	BTFSC	PORTB, 4
	call	down	
	BTFSC	PORTB, 5
	CALL	up
	BTFSS	INTCON,	1	; polling for an interrupt otherwise stay in the intcode loop
	GOTO	read_encoder		; intcode loop uses button to toggle the led active or led inactive
	; interrupt service code above
intexit
	BCF		INTCON,	1	; clear interrupt holder bit in the interrupt control register	
	SWAPF	stat,	w	; d=destination working register
	MOVWF	STATUS		; puts working register into status register... back to what it was
	SWAPF	work,	f	; d=destination file register... twist, no holder change.
	;SWAPF	work,	w	; d=destination working register... untwist and back to what it was.  no holder change
	RETFIE	; back from whence you came and as you were.
;================================================================================
	END
;================================================================================




