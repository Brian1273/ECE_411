;********************************************************************************
; DOES IT WORK?		WORKS, BUT,  ... SEE VERSION 15 FOR WORKING CODE
; FILENAME:			METROKNOME
; VERSION:			17
; DATE:				01DEC2016	
; FILE SAVED AS:	16F648A_MetroKnomeV17.asm
; MICROCONTROLLER:	PIC16F648A
; CLOCK FREQUENCY:	32.768kHz using an off-board oscillator for battery life
;********************************************************************************
; FILES REQUIRED:  	p16f648a.inc
;********************************************************************************
; PROGRAM FUNCTION:
;	It's a minimalist metronome, two lights, a buzzer, control knob, and on/off button
;	adjustable alterating led illumination and piezo sound to accompany each flash
;	rate adjustable from about 30-256 bpm in rock time.  STARTS AT 60 BPM
;********************************************************************************
; NOTES:	TRYING TO GET RID OF THE DELAY LOOP IN FAVOR OF TIMER2 PWM PIEZO
;			WORKS THE FREQUENCY AND DUTY CYCLE OF TIMER2 NEEDS TO BE DETERMINED.


;			RA0	SOURCE GREEN LED											OUTPUT
;			RA1	SOURCE RED LED												OUTPUT
;			RA2	SOURCE BJT RELAY CONTROLLING POWER TO THE OPAMP AND PIEZO	OUTPUT
;			RB0	BUTTON														INPUT
;			RB3	PIEZO BUZZER SOUND WAVE										OUTPUT
;			RB4	ROTARY ENCODER												INPUT
;			RB5	ROTARY ENCODER												INPUT
;
;
;SOMEHOW THE ORDER OF SETUP INSTRUCTIONS INTCON FIRST THEN OPTION_REG MATTERS
;IT WORKS AS THIS IS WRITTEN
;I WANT TO KNOW WHY WHY WHY!!!!!!!!!!!!!!!
;
;	? RA4 can only sink power (no led sourcing?)
;
;********************************************************************************
; AUTHOR:			KAM ROBERTSON
; COMPANY:			ACORN ENERGY LLC
;********************************************************************************
;********************************************************************************
;********************************************************************************
; HOUSEKEEPING
    list p = 16f648a		; list directive to define processor
    include C:\Program Files (x86)\Microchip\MPASM Suite\p16f648a.inc	
    __CONFIG   _CP_OFF & _CPD_OFF & _LVP_OFF & _BOREN_OFF & _MCLRE_ON & _PWRTE_ON & _WDT_OFF & _LP_OSC           
	; PIC15F648A internal 4mhz oscillator
	; '__CONFIG' directive is used to embed configuration word within .asm file
;================================================================================
; DECLARATIONS cpu equates (memory map)
porta	EQU	0x05	; assigns the memory location of register PORTA to porta for use in code 
					; literals assigned with EQU cannot be changed elswhere in code
					; creates an un-changable pointer and allows use of lower case porta
portb	EQU	0x06	; allows use of lower case PORTB
;
; DECLARATIONS bit equates
num0	EQU	0x20	; "num0" is a pointer to register 32
num1	EQU	0x21	; "num1" is a pointer to register 33
num2	EQU	0x22	; "num2" is a pointer to register 34
work	EQU	0x23	; interrupt service temporarilly stores working register here
stat	EQU	0x24	; interrupt service temporarilly stores status register here
speed	EQU	0x25	; use for timer inc/dec that is used to run the led's and piezo buzzer
d1		equ	0x26	; determines time spent in the delay loop
duty1	equ	0x27	; used for pwm prescaler
duty2	equ	0x28	; used for pwm prescaler
ledstate	equ	0x29	; led ledstate green-set or red-clear
mute	equ	0x2A	; allows sound to be muted or not every other on/off cycle
roten	equ	0x2B	; quadrature
tone1	equ	0x2C	; quadrature
past	equ	0x2D	; quadrature
present	equ	0x2E	; quadrature
time	equ	0x2F	; used to set the beat tone sent to the piezo.  increments every light cycle
beatstate	equ	0x30	; use logic shift and bit test to set the beat time beatstate: mute, 4/4, 2/4, 2/3, 3/4. 6/4 
d2		equ	0x31	; determine time spent in the delay loop
;================================================================================
; PROGRAM STARTS BELOW
    ORG		0x000
    GOTO	start	; go to the start 
    ORG		0x004	; interrupt service vector at memory location 0x004 it goes here automatically when intcon bit-1 is set
    GOTO	intserv	; go to the interrupt service function
start
    CALL initializer	; CALL the function "initializer"
    goto main
	;
	;
main
	
;	goto	fourfour
;
	btfsc	beatstate,	0
	goto	zerofour
	;
	btfsc	beatstate,	1
	goto	mutefour
	;
	btfsc	beatstate,	2
	goto	fourfour
	;
	btfsc	beatstate,	3
	goto	twofour
	;
	btfsc	beatstate,	4
	goto	threefour
	;
	btfsc	beatstate,	5
	goto	twothree
	;
	btfsc	beatstate,	6
	goto	sixfour
	;
	






zerofour
	BCF		PORTA,	2
	SLEEP
	goto	main
	;
	;
mutefour
redmute
    BTFSS	ledstate,	7
	GOTO	redmute
    call	redledmute
greenmute
    BTFSC	ledstate,	7
	GOTO	greenmute
    call	greenledmute	
	goto	main
	;
	;
fourfour
fourred
    BTFSS	ledstate,	7
	GOTO	fourred
    CALL	redled
fourgreen
    BTFSC	ledstate,	7
	GOTO	fourgreen
    CALL	greenled
	GOTO	main
	;
	;
twofour
twored
    BTFSS	ledstate,	7
    GOTO	twored
    call	redled
twogreen
    BTFSC	ledstate,	7
    GOTO	twogreen
    call	greenledbeat	
	goto	main
	;
	;
	;
	;
	;
	;
	;
	;
	;
	;
	;
twothree
two3red
    BTFSS	ledstate,	7
	GOTO	two3red
    call	redledbeat
two3green
    BTFSC	ledstate,	7
	GOTO	two3green
    call	greenledbeat	
	goto	main
	;
	;
threefour
threered
    BTFSS	ledstate,	7
    GOTO    threered
    call	redled
threegreen
    BTFSC	ledstate,	7
	GOTO	threegreen
    call	greenled	
	goto	main
	;
	;
sixfour
sixred
    BTFSS	ledstate,	7
	GOTO	sixred
    call	redled
sixgreen
    BTFSC	ledstate,	7
	GOTO	sixgreen
    call	greenled	
	goto	main
	;
	;
	GOTO	main	; loops back to main (it's a catcher)
	;
	;
;================================================================================
; SUBROUTINES AND FUNCTIONS
initializer					; first set numbers into the equate register declarations
    MOVLW	0x05
    MOVWF	d1
	;
    MOVLW	0x07
    MOVWF	d2
	;
    MOVLW	0x02
    MOVWF	duty1
	;
    MOVLW	0x02
    MOVWF	duty2
	;
;    MOVLW	0x20	    ; does not appear to work on PR2 in  bank1
;    MOVWF	tone1	    ; does not appear to work on PR2 in  bank1
	;
    MOVLW	0xC0
    MOVWF	speed
	;
    MOVLW	0x00
    MOVWF	ledstate
    MOVWF	work
    MOVWF	stat
    MOVWF	roten
    MOVWF	mute
    MOVWF	past
    MOVWF	present	
	;
	MOVLW	0x01
	MOVWF	beatstate
	BCF		STATUS,	0		; CLEAR THE CARRY FLAG
	;
	; setting PORTA as an output.  P.16,22 16F648A datasheet.  WORKS!
	; SET-UP THE INTERRUPT
    CLRF	PORTA			; set all of porta to ground before making it an output with the trisa register
    MOVLW 	0x07 			; Turn comparators off and
    MOVWF 	CMCON 			; enable pins for I/O functions
	;
    CLRF	PORTB			; clear portb... safe it off
	;
    BCF		STATUS,	7		; 3 PART BANK CHANGE BANK_1
    BCF		STATUS, 6		; set a one at bit-5 position in the status register... select bank1  PAGE24
    BSF		STATUS, 5		; set a one at bit-5 position in the status register... select bank1  PAGE24
	;
    BSF		STATUS, 4		;  SET UP THE SLEEP FUNCTION   PAGE24
    BCF		STATUS, 3		;  SET UP THE SLEEP FUNCTION   PAGE24
	;	
    MOVLW	0x000     		; set bits/literal that will make RA pins an output into working registeroutputs
    MOVWF	TRISA  			; change default input status of RA pins to output using TRISA register in bank1
	;
    MOVLW	0x31			; move literal to working register.  use to make portb an input for the interrupt
    MOVWF	TRISB			; make some of portb (RB0/INT) an input.  hook it up to a button and debounce the button
	;
    BCF		OPTION_REG,	7	; enable weak pull ups in option register.  (open button=5volts, depressed button is to ground) don't need this
    BSF		OPTION_REG,	6	; interrupt triggers on the FALLING EDGE CLEAR THE BIT (option register PAGE 25)
    BCF		OPTION_REG,	5	; TIMER-ZERO MODE	(PAGE 25)
    BSF		OPTION_REG,	4	; HMMMMM DUNNO
    BCF		OPTION_REG,	3	; TIMER-ZERO PRESCALER ASSIGNED TO TIMER	PAGE25
    BSF		OPTION_REG,	2	; TIMER-ZERO PRESCALE DIVISOR	PAGE25
    BCF		OPTION_REG,	1	; TIMER-ZERO PRESCALE DIVISOR	PAGE25
    BSF		OPTION_REG,	0	; TIMER-ZERO PRESCALE DIVISOR	PAGE25
	;
;	bcf		PIE1,	1		; DISABLE TIMER TWO INTERRUPT
;	movf	tone1,	0		; SET THE TONE OF THE PWM TO THE PIEZO.  this won't work tone1 is in bank0  PR2 is in bank1
;    BSF		STATUS, 5		; set a one at bit-5 position in the status register... select bank1  PAGE24
	movlw 	0x03
	movwf	PR2				; SET THE TONE OF THE PWM TO THE PIEZO
;    BCF		STATUS, 5		; set a one at bit-5 position in the status register... select bank1  PAGE24
	
	;
    BCF		STATUS,	7		; set status to bank0
    BCF		STATUS, 6		; set a one at bit-5 position in the status register... select bank1  PAGE24
    BCF		STATUS,	5		; 3 PART BANK CHANGE  RETURN TO BANK ZERO
	;
    BSF		PORTA,	2		; SOURCE op-amp-relay at pin RA2, turn on power to speaker amplifier
    MOVF	speed,	0
    MOVWF	TMR0			; write a number to the timer zero register for scaling the led metronome blink timing
	;
	
	MOVF	duty1,		0	; SET THE DUTY CYCLE OF THE PWM TO THE PIEZO
	MOVWF	CCPR1L			; SET THE DUTY CYCLE OF THE PWM TO THE PIEZO  msb of timer two
	BCF		CCP1CON,	5	; lsb of timer two
	BCF		CCP1CON,	4	; lsb of timer two
	
	BSF		CCP1CON,	3
	BSF		CCP1CON,	2
	BSF		CCP1CON,	1
	BSF		CCP1CON,	0
	
	BSF		T2CON,	2		; set means timer two is on
	BCF		T2CON,	1		; timer two prescaler
	BCF		T2CON,	0		; timer two prescaler page55
	bcf		PIR1,	1		; clear unused timer two flag
	;
    BSF		INTCON,	7		; enable global interrupt in the interrupt control register
    BCF		INTCON,	6		; enable PERIPHERAL interrupt in the interrupt control register
    BSF		INTCON,	5		; TOIE TIMER-ZERO	INTERRUPT ENABLE	PAGE26
    BSF		INTCON,	4		; enable external interrupt in the interrupt control register
    BSF		INTCON,	3		; enable RBx interrupt-on-change in the interrupt control register
    BCF		INTCON,	2		; TOIF TIMER-ZERO	INTERRUPT FLAG		PAGE26
    BCF		INTCON,	1		; clear interrupt holder bit in the interrupt control register interrupt pin RB0
    BCF		INTCON,	0		; clear interrupt holder bit in the interrupt control register interrupt-on-change RBx pins
	;
    RETURN					; midline chips.  back from whence you came.
;
;	
;
;	
redledmute
    MOVF	d1,		0	; moves literal number into working register passing this literal to the function delay
	BCF		PORTA,	2	; SOURCE op-amp-relay at pin RA2, turn on power to speaker amplifier
    BSF 	PORTA,		1	; SOURCE RED LED at pin RA1, use bit-number for bit-position(3,2,1,0)
    CALL	delay			; CALL the function "delay"
    BCF		PORTA,		1	; SINK RED LED at pin RA1, use bit-number for bit-position(3,2,1,0)
    return
greenledmute
    MOVF	d1,		0	; moves literal number into working register passing this literal to the function delay
	BCF		PORTA,	2	; SOURCE op-amp-relay at pin RA2, turn on power to speaker amplifier
	BSF 	PORTA,		0	; SOURCE GREEN LED at pin RA0, use bit-number for bit-position(3,2,1,0)
    CALL	delay			; CALL the function "delay"
    BCF 	PORTA,		0 	; SINK GREEN LED at pin RA0 (3,2,1,0 bit position)
    return
;
;
redled
    MOVF	d1,		0	; moves literal number into working register passing this literal to the function delay
	BSF		PORTA,	2	; SOURCE op-amp-relay at pin RA2, turn on power to speaker amplifier
    BSF 	PORTA,		1	; SOURCE RED LED at pin RA1, use bit-number for bit-position(3,2,1,0)
    CALL	delay			; CALL the function "delay"
    BCF		PORTA,		1	; SINK RED LED at pin RA1, use bit-number for bit-position(3,2,1,0)
	BCF		PORTA,	2	; SOURCE op-amp-relay at pin RA2, turn on power to speaker amplifier
    return
greenled
    MOVF	d1,		0	; moves literal number into working register passing this literal to the function delay
	BSF		PORTA,	2	; SOURCE op-amp-relay at pin RA2, turn on power to speaker amplifier
	BSF 	PORTA,		0	; SOURCE GREEN LED at pin RA0, use bit-number for bit-position(3,2,1,0)
    CALL	delay			; CALL the function "delay"
    BCF 	PORTA,		0 	; SINK GREEN LED at pin RA0 (3,2,1,0 bit position)
    BCF		PORTA,	2	; SOURCE op-amp-relay at pin RA2, turn on power to speaker amplifier
    return
;
;
redledbeat
    MOVF	d1,		0	; moves literal number into working register passing this literal to the function delay
	BSF		PORTA,	2	; SOURCE op-amp-relay at pin RA2, turn on power to speaker amplifier
    BSF 	PORTA,		1	; SOURCE RED LED at pin RA1, use bit-number for bit-position(3,2,1,0)
    CALL	delay			; CALL the function "delay"
    BCF		PORTA,		1	; SINK RED LED at pin RA1, use bit-number for bit-position(3,2,1,0)
	BCF		PORTA,	2	; SOURCE op-amp-relay at pin RA2, turn on power to speaker amplifier
    return
greenledbeat
    BCF		STATUS, 5		; set a one at bit-5 position in the status register... select bank1  PAGE24
    MOVF	d1,		0	; moves literal number into working register passing this literal to the function delay
	BSF		PORTA,	2	; SOURCE op-amp-relay at pin RA2, turn on power to speaker amplifier
	BSF 	PORTA,		0	; SOURCE GREEN LED at pin RA0, use bit-number for bit-position(3,2,1,0)
    CALL	delay			; CALL the function "delay"
    BCF 	PORTA,		0 	; SINK GREEN LED at pin RA0 (3,2,1,0 bit position)
    BCF		PORTA,	2	; SOURCE op-amp-relay at pin RA2, turn on power to speaker amplifier
	BCF		CCP1CON,	5	; lsb of timer two
	BCF		CCP1CON,	4	; lsb of timer two
    return
;
;
delay				; 8-bit system so... setting counters to zero gives 256 bits/decrements
					; uses literal number in working register to determine how many passes through the d_loop
    MOVWF	num2	; pass value from working register into delay counter at R34
    MOVWF	num1	; pass value from working register into delay counter at R33
;	MOVWF	num0	; pass value from working register into delay counter at R32
d_loop
    DECFSZ	num2, f	; decrements delay counter by one then skips next step if count1_register-nine ontains zero
    GOTO	d_loop	; returns to d_loop if R9 contains any ones
    MOVWF	num2	; prepares for next use by setting R9 back to zero
	;
    DECFSZ	num1, f	; decrements delay counter by one then skips next step if count2_register-eight contains a zero
    GOTO	d_loop	; returns to d_loop if R8 contains any ones
    MOVWF	num1	; prepares for next use by setting R8 back to zero
	;
;	DECFSZ	num0, f	; decrements delay counter by one then skips next step if count0_register-seven contains a zero
;	GOTO	d_loop	; returns to d_loop if R7 contains any ones
    RETURN		; the larger command set on midline chips supports the "return" command. It is more appropriate here
;
;
intserv	; hey service this interrupt.  save those registers, do stuff, bring those registers back.  YAY!!!
    MOVWF	work		; save current working register in memory
    SWAPF	STATUS, 0	; d=destination working register.  get current status without changing flags
    MOVWF	stat		; store current status register in memory
	;
    BTFSC	INTCON,	0	; TEST TO SEE IF INTERRUPT CAME FROM THE BUTTON AT RB0/INT
    goto 	rotencoder
	;
    BTFSC	INTCON,	1	; TEST TO SEE IF INTERRUPT CAME FROM THE BUTTON AT RB0/INT
    goto	button
	;
    BTFSC	INTCON,	2	; CHECK THE TIMER ZERO FLAG
    GOTO	led
	;
    GOTO	intexit		; who knows where the interrupt came from.  let's get outa dodge.
;
;
; ROTARY ENCODER is designed/built/set NORMALLY HIGH with momentary-debounced-out-of-phase LOW SWITCHING.
rotencoder
    MOVF	PORTB,	0
    MOVWF	roten
    MOVLW	0x030		; mask that allows only the portb pins four and five to show
    ANDWF	roten,	1	; mask that allows only the portb pins four and five to show
    RLF		past,	1
    MOVF	roten,	0
    XORWF	past,	1
    BTFSS	past,	5
    GOTO	decrement
    GOTO 	increment
increment
    MOVWF	past
    MOVLW	0x01
    ADDWF	speed,	1
    BCF		INTCON,	0	; clear interrupt holder bit in the interrupt control register	INTERRUPT-ON-CHANGE
    GOTO	intexit
decrement
    MOVWF	past
    MOVLW	0x01
    SUBWF	speed,	1
    BCF		INTCON,	0	; clear interrupt holder bit in the interrupt control register	INTERRUPT-ON-CHANGE
    GOTO	intexit
	;	
	;
button					; puts ucon to sleep and controls mute function
	RLF		beatstate
	BTFSC	beatstate,	3
	goto	buttondeax
    BCF		INTCON,	1	; clear interrupt holder bit in the interrupt control register	
	GOTO	intexit
buttondeax
	movlw	0x01
	movwf	beatstate
	bcf		INTCON,	1
	goto	intexit
	;
	;
led						; timer zero overflow interrupt changes the led ledstate.... makes them flash then alternate with timer
	INCF	time,	1	; increment 'time' register every light cycle and use to set the beat tone sent ot the piezo buzzer
	COMF	ledstate,	1
    MOVF	speed,	0
    MOVWF	TMR0		; write a number to the timer zero register for scaling
    BCF		INTCON,	2	; TOIF TIMER-ZERO	INTERRUPT FLAG		PAGE26
    GOTO	intexit
	;
	;
intexit
    SWAPF	stat,	0	; d=destination working register
    MOVWF	STATUS		; puts working register into status register... back to what it was
    SWAPF	work,	1	; d=destination file register... twist, no holder change.
    SWAPF	work,	0	; d=destination working register... untwist and back to what it was.  no holder change
    RETFIE				; back from whence you came and as you were.
	;
	;
;================================================================================
    END
;================================================================================


