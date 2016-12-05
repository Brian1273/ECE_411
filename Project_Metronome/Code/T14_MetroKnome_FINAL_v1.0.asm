;********************************************************************************
; DOES IT WORK?		YES!!!
; FILENAME:			T14_MetroKnome_Final_V1.0
; VERSION:			1.0
; DATE:				30 NOV 2016	
; FILE SAVED AS:	T14_MetroKnome_Final_V1.0.asm
; MICROCONTROLLER:	PIC16F648A
; CLOCK FREQUENCY:	32kHz using the on-board(ext) oscillator for battery life
;********************************************************************************
; FILES REQUIRED:  	p16f648a.inc
;********************************************************************************
; PROGRAM FUNCTION:	METROKNOME 
;		THIS CODE IS FOR FINAL OPERATION		
;********************************************************************************
; HOUSEKEEPING
	list p=16f648a		; list directive to define processor
	include C:\Program Files (x86)\Microchip\MPLABX\v3.45\mpasmx\p16f648a.inc	
	 ; '__CONFIG' directive is used to embed configuration word within .asm file
		__CONFIG _FOSC_LP & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF
;================================================================================
; DECLARATIONS cpu equates (memory map)
TMR0	EQU	0x01		; Timer0 Module Register
porta	EQU	0x05		; assigns the memory location of register PORTA to porta for use in code 
PORTA	EQU	0x05		; literals assigned with EQU cannot be changed elswhere in code
PORTB	EQU	0x06		; creates an un-changable pointer and allows use of lower case porta
portb	EQU	0x06		; allows use of lower case PORTB
state	EQU	0x21		; stores current lighting state
tic_rt	EQU	0xFC		; variable for tic rate. ~10ms
work	EQU	0x23		; interrupt service temporarilly stores working register here
stat	EQU	0x24		; interrupt service temporarilly stores status register here
oldstate    EQU 0x25		; register to store encoder prior state
newstate    EQU 0x26		; register to store register current state
rate	EQU 0x27		; register to store encoder rate to pass to timer
w_temp  EQU     0x71        	; variable used for context saving 
status_temp EQU     0x72        ; variable used for context saving
pclath_temp EQU     0x73        ; variable used for context saving
; DECLARATIONS bit equates
w	EQU 0			; allows for use of "w" =working register instead of zero for the destination
f	EQU 1			; allows for use of "f" =file instead of one for the destination
;()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()
;()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()
; START
	ORG	0x00
	GOTO	start
	ORG	0x04
	GOTO	intserv
	
start
	CALL	initializer
	GOTO	main

main	
	NOP

	GOTO 	main

;()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()
;()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()


;*********************************************************************************
	; Subroutines and Functions
;*********************************************************************************

intserv
;---------------------------------------------------------
	
	;Push registers to store current state before interrupt
		movwf   w_temp            		; save off current W register contents
		movf	STATUS,w          		; move status register into W register
		movwf	status_temp       		; save off contents of STATUS register
		movf	PCLATH,w          		; move pclath register into W register
		movwf	pclath_temp       		; save off contents of PCLATH register
	;Check Timer
		BTFSC	INTCON, 2			; Timer0 interrupt flag
		GOTO 	timer_svc	
	;Check Button(PORTB:0)
		BTFSC	INTCON,	1			; RB0 Interrupt flag			
		GOTO	button_svc
	;Check Encoder(PORTB:(4:5))
		BTFSC	INTCON,	0			; PORTB Interrupt flag
		GOTO	encoder_svc
		GOTO	intexit				; Must be a glitch get out and hope nobody noticed
;---------------------------------------------------------	
timer_svc
		
		BTFSS	state, 0			; Test current state
		CALL	toc				; If 0 goto 'toc'
		BTFSC 	state, 0			; If 0, return from call from previous line will skip this
		CALL 	tic				; If 1 goto 'tic'
		COMF	state, f			; Toggle state bit
		BCF	INTCON,	2			; Clear interrupt flag
		GOTO	intexit				; END TIMER_SVC
button_svc
		BCF	INTCON, 5			; Disable interrupt for Timer0
		BCF	INTCON, 1			; Clear interrupt flag
loopb		BTFSS	INTCON, 1			; Wait for button press
		GOTO	loopb				; If button not pressed keep waiting
		BCF	INTCON, 1
		BSF	INTCON, 5			; ReEnable interupt for Timer0
		GOTO	intexit				; END BUTTON_SVC
encoder_svc
		MOVF	PORTB, f			; Clears interrupt condition
		CALL	chk_encoder			; Read encoder
		BCF	INTCON, 0			; Clear interrupt flag
		GOTO	intexit				; END ENCODER_SVC

intexit
	;Pop to registers to state before interrupts
		BSF	INTCON, 5
		MOVF	rate, w			; Load UPDATED timer rate for Timer0
		MOVWF	TMR0			; Load timer rate INTO Timer0
		movf    pclath_temp,w     	; retrieve copy of PCLATH register
		movwf	PCLATH            	; restore pre-isr PCLATH register contents
		movf    status_temp,w     	; retrieve copy of STATUS register
		movwf	STATUS            	; restore pre-isr STATUS register contents
		swapf   w_temp,f
		swapf   w_temp,w          	; restore pre-isr W register contents
		RETFIE
;**************************************************************************************************************************************************
;**************************************************************************************************************************************************

initializer

; Set PORTA Tri-State. Outputs are bits PORTA:0,1,2. 	Bits PORTA:3,4,5 are input by default
;		
		CLRF	PORTA				; Set outputs to 0 FOR SAFETY
		BSF	STATUS, 5			; GO to bank 1
		BCF	TRISA, 0			; PORTA:0 IS AN OUTPUT
		BCF	TRISA, 1			; PORTA:1 IS AN OUTPUT
		BCF	TRISA, 2			; PORTA:2 IS AN OUTPUT
		BCF	STATUS, 5			; Back to Bank0

; Set PORTB Tri-State. Output is PORTB:3 		; Bits PORTB:0,1,2,4,5,6,7 are inputs by defaults
;
		CLRF	PORTB				; GO to bank 1
		BSF	STATUS, 5			
		BCF	TRISB,	3			; PORTB:3 IS AN OUTPUT
		BCF	STATUS, 5			; Bank0
;

; Set-up Timer TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
;TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
		CLRWDT	
	;OPTION REGISTER(81h)	
		BSF	STATUS, 5		; BANK1
		BCF	OPTION_REG, 7		; PORTB PULL-UPS ENABLED
		BSF	OPTION_REG, 6		; INTERRUPT ON RISING EDGE
		BCF	OPTION_REG, 5		; TIMER0 CLOCK SOURCE IS INTERNAL
		BCF	OPTION_REG, 4		; UNUSED WHEN INTERNAL CLOCK SOURCE BUT SET 0 FOR LOW-HIGH TRANSITION	
		BCF	OPTION_REG, 3		; PRESCALER IS ASSIGNED TO TIMER0 NOT WDT	
		BSF	OPTION_REG, 2		; PS:2 PRESCALER RATE BITS<2:0>. USING 128<1,1,0> FOR PRESCALER
		BSF	OPTION_REG, 1		; PS:1
		BCF	OPTION_REG, 0		; PS:0
		BCF	STATUS, 5		;RETURN TO BANK 0
	; INTERRUPT CONTROL REGISTER
		BCF	INTCON, 2		;(T0IF) TIMER0 INTERRUPT FLAG CLEARED
		BSF	INTCON, 5		;(T0IE) ENABLE INTTERUPT FOR TIMER0
	; SET TEMPO AND STORE	
		MOVLW	0x80			; 80 IS MIDRANGE FOR STARTING TEMPO	
		MOVWF	rate			; STORE TEMPO IN 'RATE' REGISTER
		CLRF	state			; 'state' stores current lighting condition at bit 0. 0 is 'toc' 1 is 'tic'
;TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
;TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT		
		
;PWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWM
;PWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWM
; Set-up PWM for Audio____________________________________________
;_________________________________________________________________	
; * PWM registers configuration
; * Fosc = 32768 Hz
; * Fpwm = 1024.00 Hz (Requested : 1000 Hz)
; * Duty Cycle = 25 %
; * Resolution is 5 bits
; * Prescaler is 1
; * Uses TIMER2 and CCP to create PWM 
;		PR2 	= 	0b00000001 ;		; Timer2 preset
;		T2CON 	= 	0b00000100 ;		; Sets timer2 prescale and enables timer2
;		CCPR1L 	= 	0b00000001 ;		; Sets Duty Cycle
;		CCP1CON = 	0b00111100 ;
;_________________________________________________________________
	; PR2						; TIMER2 PERIOD REGISTER IN BANK1
		BSF 	STATUS, 5
		;MOVLW	0b0000111
		MOVLW	0x07
		MOVWF	PR2
		BCF	STATUS, 5
	; T2CON
		BSF	T2CON, 2
	; CCPR1L
		BSF	CCPR1L, 1	
	; CCP1CON
		;MOVLW	0b00111100
		MOVLW	0x0C
		MOVWF	CCP1CON
;___________________________________________________________________
;PWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWM
;PWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWMPWM

; Enable Interrupts for IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
;IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
	; TIMER
		BCF	INTCON, 2		; Clear timer0 interrupt flag
		BSF	INTCON, 5		; Timer0 interrupt enable
	; BUTTON
		BCF	INTCON,	1		; Clear RB0 interrupt flag
		BSF	INTCON, 4		; RB0 interrupt enable
	; ENCODER
		BCF   	INTCON,	0		; Clear register B interrupt on change flag
		BSF	INTCON, 3		; PORTB interrupt on change enable
	; Global interrupt enable
		BSF	INTCON, 7		; Global Interrupt Enable
	
;IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII


	RETURN					;END OF INITIALIZER

;********************************************************************
;********************************************************************
chk_encoder
		CLRF TMR0
		goto enc_st_4
; Encoder uses grey code to cycle through its states. <1:1> is the start/end state
; Code reads each bit and determines the next state from these inputs
; If the sequence is completed, the 'rate' is inc/dec accordingly and the code exits
; If the sequence is not completed, then the code exits
; If a change in encoder state is missed then the next turn of the encoder will catch the missed state and continue		
;   PORTB	bits			<a:b>
		enc_st_1	;	1:0
		btfss	PORTB, 4
		goto 	enc_st_2
		btfsc 	PORTB, 5
		goto	decrement_rate
		goto 	enc_st_1
enc_st_2	;			0:0	
		btfsc	PORTB, 4
		goto 	enc_st_1
		btfsc 	PORTB, 5
		goto	enc_st_3
		goto 	enc_st_2
enc_st_3	;			0:1
		btfsc	PORTB, 4
		goto 	enc_st_4
		btfss 	PORTB, 5
		goto	enc_st_2
		goto 	enc_st_3
enc_st_4	;			1:1
		btfss 	PORTB, 4
		goto 	enc_st_3
		btfss 	PORTB, 5
		goto 	enc_st_5
		RETURN
enc_st_5	;			1:0
		btfss	PORTB, 4
		goto	enc_st_6
		btfsc	PORTB, 5
		goto	enc_st_4
		goto	enc_st_5
enc_st_6	;			0:0
		btfsc PORTB, 4
		goto	enc_st_5
		btfsc	PORTB, 5
		goto	enc_st_7
		goto 	enc_st_6
enc_st_7	;			0:1
		btfsc	PORTB,4
		goto	increment_rate
		btfss	PORTB, 5
		goto	enc_st_6
		goto	enc_st_7
;=======================================
decrement_rate
		CALL	toc
		MOVLW	0x01		    ;To determine scaling factor, the 3 MSB's are checked
		BTFSS	rate, 7		    ; Amount to increment or decrement is  weighted by these bits
		ADDLW	0x08		    ; Range of change is from 1 to 16
		BTFSS	rate, 6		    ; bits<7:5> are used from 'rate'
		ADDLW	0x04		    ; bit:7 set adds 8
		BTFSS	rate, 5		    ; bit:6 set adds 4
		ADDLW	0x02		    ; bit:5 set adds 2
		SUBWF	rate, f		    ; Subtract scaled amount from rate
		return

increment_rate		
		CALL 	tic		    ; Same as decrement except with add
		MOVLW	0x01		    ; Amount to increment or decrement is  weighted by these bits
		BTFSS	rate, 7		    ; Range of change is from 1 to 16
		ADDLW	0x08		    ; bits<7:5> are used from 'rate'
		BTFSS	rate, 6		    ; bit:7 set adds 8
		ADDLW	0x04		    ; bit:6 set adds 4
		BTFSS	rate, 5		    ; bit:5 set adds 2
		ADDLW	0x02
		ADDWF	rate, f		    ; Add scaled amount to rate
		return
;++++++++++++++++++++++++++++++++++++++++
tic		
		BSF	PORTA, 0		; turn on green led
		BSF	PORTA, 2		; turn on sound
		BCF	INTCON, 2		; Clear timer0 interrupt flag
		MOVF	tic_rt, w		; load time for sound on(~10ms)
		MOVWF	TMR0			; load time into TMR0
loopa		BTFSS	INTCON, 2		; wait for TMR0
		GOTO 	loopa
		BCF 	PORTA, 0		; turn off green led
		BCF	PORTA, 2		; turn off sound
		RETURN
toc	
		BSF	PORTA, 1		; turn on green led
		BSF	PORTA, 2		; turn on sound
		BCF	INTCON, 2		; Clear timer0 interrupt flag
		MOVF	tic_rt, w		; load time for sound on(~10ms)
		MOVWF	TMR0			; load time into TMR0
loopc		BTFSS	INTCON, 2		; wait for TMR0
		GOTO 	loopc
		BCF 	PORTA, 1		; turn off green led
		BCF	PORTA, 2		; turn off sound; turn on red led
		RETURN
;**********************************************************
;**********************************************************		
;================================================================================
	END
;================================================================================



