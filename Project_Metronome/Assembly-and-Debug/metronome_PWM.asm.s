
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; THE FOLLOWING STEPS SHOULD BE TAKEN WHEN CONFIGURING THE CCP MODULE FOR PWM OPERATION: ;
;                                                                                        ;
; 1. SET THE PWM PERIOD BY WRITING TO THE PR2 REGISTER.                                  ;
; 2. SET THE PWM DUTY CYCLE BY WRITING TO THE CCPR1L REGISTER AND CCP1CON<5:4> BITS.     ;
; 3. MAKE THE CCP1 PIN AN OUTPUT BY CLEARING THE TRISB<3> BIT.                           ;
; 4. SET THE TMR2 PRESCALE VALUE AND ENABLE TIMER2 BY WRITING TO T2CON.                  ;                                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;;;SET PWM PIN TO OUTPUT MODE;;;
	BSF STATUS, 5 				;SELECT BANK 01
	BCF TRISB, 3 				;SET RB3 AS OUTPUT, TO USE FOR PWM
	BCF STATUS, 5  				;SELECT BANK 00

	;PWM PERIOD = [(PR2)+1] * 4 * TOSC * (TMR2 PRESCALE VALUE) 
	;PR2 = TMR2 PERIOD REGISTER, TOSC = PIC CLOCK PERIOD (FOSC = 1 / TOSC)
	;PWM DUTY CYCLE = (CCPR1L:CCP1CON<5:4>) * TOSC * (TMR2 PRESCALE VALUE)
	
	
	;;;SET PWM STARTING DUTY CYCLE;;;
	CLRF CCPR1L
	MOVLW B'00001100' 			;SET PWM MODE, BITS 5 AND 4 ARE THE TWO LSBs OF THE 10BIT DUTY CYCLE REGISTER (CCPR1L:CCP1CON<5:4>)
	MOVWF CCP1CON
	
	
	;;;SET TIMER 2 PRESCALE VALUE;;;
	;PRESCALE = 16 SO THE PWM PERIOD = 2064uS => PWM FREQUENCY = 484Hz
	MOVLW B'00000010'
	MOVWF T2CON
	
	;;;CLEAR TIMER 2 MODULE;;;
	CLRF TMR2
	
	;;;ENABLE TIMER 2 MODULE;;;
	BSF T2CON, TMR2ON

	;;;SET PWM LOW FREQUENCY;;;
	BSF STATUS, 5 				;SELECT BANK 01
	MOVLW D'128' 				;SET PR2 TO 128 DECIMAL SO THE PWM PERIOD = 2064uS => PWM FREQUENCY = 484Hz
	MOVWF PR2
	BCF STATUS, 5 				;SELECT BANK 00
	
	;;;SET PWM HIGH FREQUENCY;;;
	BSF STATUS, 5 				;SELECT BANK 01
	MOVLW D'128' 				;SET PR2 TO 128 DECIMAL SO THE PWM PERIOD = 2064uS => PWM FREQUENCY = 484Hz
	MOVWF PR2
	BCF STATUS, 5 				;SELECT BANK 00