@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ NOTHING ABOVE		@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ INFORMATION BELOW	@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@
@ KAM ROBERTSON
@ MAY_2016
@ ECE371 
@  
@ BEAGLE BONE BLACK ASSEMBLY CODE
@
@ PROJECT TWO
@ Knight Industries Three-Thousand scanner control (The Ford)
@ written for the AD227529 processor
@
@ PROJECT TWO PART TWO 
@ button interupt that turns the scanning leds on/off (P8-20,gpio1_14)
@ scans the BBB gpio2 pins 6,8,10,12 (P8-45,43,41,39) 
@ led scan cycle leaves current led on until next led is turned on
@ scanning controlled by timer2 overflow interrupt condition
@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ INFORMATION ABOVE		@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ INTRODUCTION BELOW	@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@
.text
.globl	INT_DIRECTOR
.globl _start
@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ INTRODUCTION ABOVE	@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ EQUATES TO BELOW		@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@
.equ	led0set,	0x00200000
.equ	led0clr,	0XFFdFFFFF

.equ	led1set,	0x00400000
.equ	led1clr,	0xFFbFFFFF

.equ	led2set,	0x00800000
.equ	led2clr,	0xFF7FFFFF

.equ	led3set,	0x01000000
.equ	led3clr,	0xFeFFFFFF

.equ	bit6set,	0x00000040
.equ	bit6clr,	0xFFFFFFbF

.equ	bit8set,	0x00000100
.equ	bit8clr,	0xFFFFfeFF

.equ	bit10set,	0x00000400
.equ	bit10clr,	0xfffffbff

.equ	bit12set,	0x00001000
.equ	bit12clr,	0xFFFFeFFF

.equ	bit6_8_10_12set,	0x00001540
.equ	bit6_8_10_12clr,	0xFFFFeabF

.equ	bit8_10_12set,	0x00001500
.equ	bit6_10_12set,	0x00001440
.equ	bit6_8_12set,	0x00001140
.equ	bit6_8_10set,	0x00000540


.equ	bit14set,	0x00004000
.equ	bit14clr,	0xffffbfff

.equ	bit31set,	0x80000000	@ this is about the switch location P8-20
.equ	bit31clr,	0x7fffffff	@ it describes the location of bit 31

@ gpioX address (p.4875)
.equ	gpio0,		0x44e07000	@ gpio0 base address
.equ	gpio1,		0x4804c000	@ gpio1 base address	(p.4881)
.equ	gpio2,		0x481ac000	@ gpio2 base address
.equ	gpio3,		0x481ae000	@ gpio3 base address
	@ gpio offsets
	.equ	irqraw0,	0x24		@ core status information?
	.equ	irqraw1,	0x28		@ core status information?
	.equ	irqstatus0,	0x2c		@ disables irq
	.equ	irqstatus1,	0x30		@ enables irq 
	.equ	irqset0,	0x34		@ prepare for irq trigger 
	.equ	irqset1,	0x38		@ triger the irq trigger
	.equ	irqclr0,	0x3c		@ clear interrpt request
	.equ	irqclr1,	0x40		@ set interrupt	request
	
	.equ	output,		0x134		@ output enable
	.equ	datain,		0x138		@ not going to use?
	.equ	dataout,	0x13c		@ not going to use?
	
	.equ	risingdet,	0x148		@ rising edge detect
	.equ	fallingdet,	0x14c		@ falling edge detect
	
	.equ	debenable,	0x150		@ debouncing enable
	.equ	debtime,	0x154		@ debouncing time
	
	.equ	cleardata,	0x190		@ selected features above dissabled 
	.equ	setdata,	0x194		@ selected features above enabled 

@ interrupt controller address
.equ	intcps,		0x48200000	@ p.182,469 interrupt controller base address	(p.469,1369)
	@ interrupt controller offsets
	.equ	softreset,	0x10		@ software reset
	.equ	control,	0x48		@ p.476 interrupt control
	.equ	irqpend0,	0x98		@ gpio0 interrupt pending 
	.equ	fiqpend0,	0x9c		@ gpio0 fast interrupt pending 
	.equ	mir0,		0x84		@ mask
	.equ	mir0clr,	0x88		@ gpio0 interrupt mask clear
	.equ	mir0set,	0x8c		@ gpio0 interrupt mask set

	.equ	irqpend1,	0xb8		@ gpio1 interrpt pending shows interrupt status after masking
	.equ	fiqpend1,	0xbc		@ gpio1 fast interrupt pending
	.equ	mir1,		0xa4		@ contains the mask write one to enable/clear portion of the mask (p.469) 
	.equ	mir1clr,	0xa8		@ gpio1 interrupt mask clear (p.492)
	.equ	mir1set,	0xac		@ gpio1 interrupt mask set

	.equ	irqpend2,	0xd8		@ gpio2 interrpt pending
	.equ	fiqpend2,	0xdc		@ gpio2 fast interrupt pending
	.equ	mir2,		0xc4		@
	.equ	mir2clr,	0xc8		@ gpio2 interrupt trigger clear
	.equ	mir2set,	0xcc		@ gpio2 interrupt trigger set

	.equ	irqpend3,	0xf8		@ gpio3 interrpt pending
	.equ	fiqpend3,	0xfc		@ gpio3 fast interrupt pending
	.equ	mir3,		0xe4		@
	.equ	mir3clr,	0xe8		@ gpio3 interrupt trigger clear
	.equ	mir3set,	0xec		@ gpio3 interrupt trigger set
	
.equ	wdt1,		0x44E35000	@ watchdog timer base address	(p.4458)

.equ	timer2,		0x48040000	@ timer 2 base address p.4344
	.equ	tiocp_cfg,		0x10		@ timer configuration register
	.equ	timer_irqstat,	0x28		@ timer interrupt status  p4349
	.equ	tclr,			0x38		@ p.4354  timer control
	.equ	irqenable_set,	0x2c		@ timer interrupt enable set register
	.equ	irqenable_clr,	0x30		@ timer interrupt enable set register
	.equ	wakeup,			0x34		@ Timer IRQ Wakeup Enable Register
	.equ	tcrr,			0x3c		@ timer counter register
	.equ	tldr,			0x40		@ timer load register

.equ	cm_dpll,	0x44e00500	@ p.178
	.equ	t2_clkselect,	0x08		@ p.1287 clksel_timer2_clk used to mux timer 2
	
.equ	cm_per,		0x44e00000	@ p.178
	.equ	timer2enable,	0x80		@ p.1164 cm_pe_timer2_clkctrl used to enable timer 2
	
.equ	cm_wakeup,	0x44e00400	@ p.178	
	.equ	clk_control,	0x4			@ p.1224 write 0x2 to enable
	
	
@ timing, counting, and loop control numbers
.equ	zeros,		0x00000000
.equ	ones,		0xffffffff
.equ	unity,		0x1			
.equ	scan_speed,			0x0001A000
.equ	timer_delay1,	0x0000000a
.equ	timer_delay2,		0xffffa000

@		
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ EQUATES TO ABOVE	@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ MAINLINE BELOW	@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@

_start:

	@ set up the service memory in mode 13 and point to the beginning
	ldr	r13,	=SVCMODE13_MEM				
	add r13,	r13,	#0x0100

	bl	_INITIALIZER
	
	bl	_BUTTON_INITIALIZER
	
	bl	_TIMER_INITIALIZER
	
	FLY:	nop

		ldr		r0,	=SCAN_MEM
		ldr		r1,	[r0]
		ldr		r2,	=0xf01
		cmp		r2,	r1
		beq	_state1
		
		ldr		r0,	=SCAN_MEM
		ldr		r1,	[r0]
		ldr		r2,	=0xf02
		cmp		r2,	r1
		beq	_state2
		
		ldr		r0,	=SCAN_MEM
		ldr		r1,	[r0]
		ldr		r2,	=0xf03
		cmp		r2,	r1
		beq	_state3
		
		ldr		r0,	=SCAN_MEM
		ldr		r1,	[r0]
		ldr		r2,	=0xf04
		cmp		r2,	r1
		beq	_state4
		
		ldr		r0,	=SCAN_MEM
		ldr		r1,	[r0]
		ldr		r2,	=0xf05
		subs	r3,	r2,	r1
		beq	_state5
		
		ldr		r0,	=SCAN_MEM
		ldr		r1,	[r0]
		ldr		r2,	=0xf06
		subs	r3,	r2,	r1
		beq	_state6
	B	FLY

	
@		
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ MAINLINE ABOVE	@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ PROCEDURES BELOW	@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@

	
_state1:									@ procedure to turn led0 ON and leave it off at the end (pwm style)
	LDR		r0,		=gpio2					@ LOAD gpio1 base ADDRESS INTO R0
	ADD		r1,		r0,		#setdata		@ LOAD gpio1_SETDATAOUT ADDRESS INTO R3
	LDR		R2,		=bit6set				@ LOAD TURN-ON SEQUENCE INTO R6 FOR LED0
	STR		R2,		[r1]					@ WRITE TO gpio1_SETDATAOUT ADDRESS  TURN-ON LED0 PIN

	LDR		r0,		=gpio2					@ gpio1 base ADDRESS 
	ADD		r1,		r0,		#cleardata		@ CLEARDATAOUT offset 
	LDR		R2,		=bit8_10_12set			@ LOAD TURN-OFF SEQUENCE 
	STR		R2,		[r1]					@ WRITE TURN-OFF SEQUENCE
	B	FLY
		
	
	
_state2:									@ procedure to turn on led1 and leave it off at the end (pwm style)
	LDR		r0,		=gpio2					@ LOAD gpio2 base ADDRESS INTO R0
	ADD		r1,		r0,		#setdata		@ LOAD gpio2_SETDATAOUT ADDRESS INTO R3
	LDR		R2,		=bit8set				@ LOAD TURN-ON SEQUENCE INTO R6 FOR LED0
	STR		R2,		[r1]					@ WRITE TO gpio2_SETDATAOUT ADDRESS  TURN-ON LED0 PIN

	LDR		r0,		=gpio2					@ gpio2 base ADDRESS 
	ADD		r1,		r0,		#cleardata		@ CLEARDATAOUT offset
	LDR		R2,		=bit6_10_12set			@ LOAD TURN-OFF SEQUENCE 
	STR		R2,		[r1]					@ WRITE TURN-OFF SEQUENCE
	B	FLY



				
_state3:									@ procedure to turn led2 ON and leave it off at the end (pwm style)
	LDR		r0,		=gpio2					@ LOAD gpio2 base ADDRESS INTO R0
	ADD		r1,		r0,		#setdata		@ LOAD gpio2_SETDATAOUT ADDRESS INTO R3
	LDR		R2,		=bit10set				@ LOAD TURN-ON SEQUENCE INTO R6 FOR LED0
	STR		R2,		[r1]					@ WRITE TO gpio2_SETDATAOUT ADDRESS  TURN-ON LED0 PIN

	LDR		r0,		=gpio2					@ LOAD gpio2 base ADDRESS INTO R0
	ADD		r1,		r0,		#cleardata		@ LOAD gpio2_CLEARDATAOUT ADDRESS INTO R2
	LDR		R2,		=bit6_8_12set			@ LOAD TURN-OFF SEQUENCE 
	STR		R2,		[r1]					@ WRITE TURN-OFF SEQUENCE
	B	FLY



				
_state4:									@ procedure to turn led3 ON and leave it off at the end (pwm style)
	LDR		r0,		=gpio2					@ LOAD gpio2 base ADDRESS INTO R0
	ADD		r1,		r0,		#setdata		@ LOAD gpio2_SETDATAOUT ADDRESS INTO R3
	LDR		R2,		=bit12set				@ LOAD TURN-ON SEQUENCE INTO R6 FOR LED0
	STR		R2,		[r1]					@ WRITE TO gpio2_SETDATAOUT ADDRESS  TURN-ON LED0 PIN

	LDR		r0,		=gpio2					@ LOAD gpio2 base ADDRESS INTO R0
	ADD		r1,		r0,		#cleardata		@ LOAD gpio2_CLEARDATAOUT ADDRESS INTO R2
	LDR		R2,		=bit6_8_10set			@ LOAD TURN-OFF SEQUENCE 
	STR		R2,		[r1]					@ WRITE TURN-OFF SEQUENCE
	B	FLY

	
				
_state5:									@ procedure to turn led2 ON and leave it off at the end (pwm style)
	LDR		r0,		=gpio2					@ LOAD gpio2 base ADDRESS INTO R0
	ADD		r1,		r0,		#setdata		@ LOAD gpio2_SETDATAOUT ADDRESS INTO R3
	LDR		R2,		=bit10set				@ LOAD TURN-ON SEQUENCE INTO R6 FOR LED0
	STR		R2,		[r1]					@ WRITE TO gpio2_SETDATAOUT ADDRESS  TURN-ON LED0 PIN

	LDR		r0,		=gpio2					@ LOAD gpio2 base ADDRESS INTO R0
	ADD		r1,		r0,		#cleardata		@ LOAD gpio2_CLEARDATAOUT ADDRESS INTO R2
	LDR		R2,		=bit6_8_12set			@ LOAD TURN-OFF SEQUENCE 
	STR		R2,		[r1]					@ WRITE TURN-OFF SEQUENCE
	B	FLY

	
		
_state6:									@ procedure to turn on led1 and leave it off at the end (pwm style)
	LDR		r0,		=gpio2					@ LOAD gpio2 base ADDRESS INTO R0
	ADD		r1,		r0,		#setdata		@ LOAD gpio2_SETDATAOUT ADDRESS INTO R3
	LDR		R2,		=bit8set				@ LOAD TURN-ON SEQUENCE INTO R6 FOR LED0
	STR		R2,		[r1]					@ WRITE TO gpio2_SETDATAOUT ADDRESS  TURN-ON LED0 PIN

	LDR		r0,		=gpio2					@ LOAD gpio2 base ADDRESS INTO R0
	ADD		r1,		r0,		#cleardata		@ LOAD gpio2_CLEARDATAOUT ADDRESS INTO R2
	LDR		R2,		=bit6_10_12set			@ LOAD TURN-OFF SEQUENCE 
	STR		R2,		[r1]					@ WRITE TURN-OFF SEQUENCE
	B	FLY


		


@ the intitializer cleans it up, shuts it down, and sets it up.
_INITIALIZER:
	stmfd	sp!,	{r0-r3, lr}
	cps	#0x12
	ldr	r13,	=IRQMODE12_MEM				
	add	r13,	r13,	#0x0100
	cps	#0x13

	@ make sure that the processor interrupt is enabled in the CPSR
	mrs	r3,		CPSR						@ copy cpsr to r3
	bic	r3,		#0x80						@ clear bit seven
	msr	CPSR_c,	R3							@ write back to the current program status register CPSR_c
	
	ldr		r0,		=intcps					@ 0x48200000 interrupt controller address intcps p.469
	add		r1,		r0,		#softreset		@ 0x10 offset
	mov		r2,		#0x02					@ software reset interrupts
	ldr		r3,		[r1]
	orr		r3,		r3,	r2
	str		r3,		[r1]
	
	LDR		r0,		=gpio2					@ LOAD GPIO1 base ADDRESS INTO R0
	ADD		r1,		r0,		#cleardata		@ LOAD gpio2_CLEARDATAOUT ADDRESS INTO R2
	LDR		R2,		=bit6_8_10_12set		@ LOAD TURN-OFF SEQUENCE INTO R6 FOR LED0
	STR		R2,		[r1]					@ WRITE TO gpio2_CLEARDATAOUT ADDRESS INITIALIZE LED0 AND LED2 PINS

	LDR		r0,		=gpio2					@ LOAD gpio2 base ADDRESS INTO R0
	ADD		r1,		r0,		#output			@ load gpio2_OE OUTPUT ENABLE ADDRESS INTO R0
	LDR		R2,		[R1]					@ LOAD CONTENTS OF OUTPUT ENABLE INTO R5
	LDR		R3,		=bit6_8_10_12clr		@ LOAD ENABLE SEQUENCE INTO R6 FOR LED0
	and		R3,		R2,		R3				@ FLIP THE BITS THAT WILL ENABLE LED0 WHEN LOADED INTO OUTPUT ENABLE
	STR		R3,		[r1]					@ WRITE TO gpio2_OA ADDRESS  INITIALIZE LED0 PINS

	ldmfd	sp!,	{r0-r3, pc}

	
	
	
@ set-up and preparation for a BBB debounced button interrupt at P8-16 on gpio1_14
_BUTTON_INITIALIZER:	
	stmfd	sp!,	{r0-r3, lr}
	
	@ detect falling edge on gpio1_14 and enable to assert pointpend1
	ldr		r0,		=gpio1						@ 0x4804c000 gpio1 address
	add		r1,		r0,		#fallingdet			@ gpio1 -> fallingdet offset
	mov		r2,		#bit31set					@ bit set number for pin 14 button
	ldr		r3,		[r1]
	orr		r3,		r3,	r2
	str		r3,		[r1]
	
	ldr		r0,		=gpio1						@ 0x4804c000 gpio1 address
	add		r1,		r0,		#irqset0			@ gpio1 -> irqset0 offset
	mov		r2,		#bit31set					@ bit set number for pin 14 button
	str		r2,		[r1]						@ bit set number for pin 14 button store into gpio1_irqset0
		
	@ initialize INTC	
	ldr		r0,		=intcps						@ 0x48200000 interrupt controller address intcps p.469			
	add		r1,		r0,		#mir3clr					@ 0xe8 offset
	mov		r2,		#0x4						@ value to unmask intc_int_98 gpoint 1a
	str		r2,		[r1]						@ write to intc_mir_clear3 register
	
	@ initialize INTC	
	ldr		r0,		=intcps						@ 0x48200000 interrupt controller address intcps p.469			
	add		r1,		r0,		#mir2clr					@ 0xe8 offset
	mov		r2,		#0x10						@ value to unmask intc_int_98 gpoint 1a
	str		r2,		[r1]						@ write to intc_mir_clear3 register
	
	ldmfd	sp!,	{r0-r3, pc}
	

	
	


	
_TIMER_INITIALIZER:
	stmfd	sp!,	{r0-r3, lr}
	
	LDR		r0,		=timer2					@ 0x48040000 base.  p.4344 timer2 address
	ADD		r1,		r0,		#tiocp_cfg		@ 0x10 offset
	LDR		R2,		=0x1					@ resets timer2 and disables idle mode
	STR		R2,		[r1]					@ reset timer2

	ldr		r0,		=timer2					@ 0x48040000 base.  p.4344 timer2 address
	add		r1,		r0,		#tldr			@ 0x40 offset timer load value register p.4356
	ldr		r2,		=timer_delay2
	str		r2,		[r1]

	ldr		r0,		=timer2					@ 0x48040000 base.  p.4344 timer2 address
	add		r1,		r0,		#tcrr			@ 0x3c offset timer load value register p.4356
	ldr		r2,		=timer_delay2
	str		r2,		[r1]

	ldr		r0,		=intcps					@ 0x48200000 interrupt controller address intcps p.469
	add		r1,		r0,		#mir2clr		@ 0xc8 offset
	mov		r2,		#0x10					@
	str		r2,		[r1]					@ using mir2clr for timer2

	LDR		r0,		=cm_dpll				@ 0x44e00500 base p1287
	ADD		r1,		r0,		#t2_clkselect	@ 0x08 offset p1289
	LDR		R2,		=0x2					@ sets the timer to 32MHz
	STR		R2,		[r1]					@ 
	
	LDR		r0,		=cm_wakeup				@ 0x44e00400 base p1287
	ADD		r1,		r0,		#clk_control	@ 0x04 offset p1289
	LDR		R2,		=0x2					@ 
	STR		R2,		[r1]					@ 
	
	@ turn on timer2 clock
	LDR		r0,		=cm_per					@ 0x44e00000 base p178 p1164
	ADD		r1,		r0,		#timer2enable	@ 0x80 offset p1192
	LDR		R2,		=0x2					@ 
	STR		R2,		[r1]					@ 
		
	LDR		r0,		=timer2					@ 0x48040000 base.  p.4344 timer2 address
	ADD		r1,		r0,		#tclr			@ 0x38 offset p.4354
	LDR		R2,		=0x3					@ auto reload timer feature and turn it on
	STR		R2,		[r1]					@ auto reload timer feature

		ldr		r0,		=timer2					@ 0x48040000 base.  p.4344 timer2 address
		add		r1,		r0,		#irqenable_set	@ 0x2c offset timer enable set register  p.4350
		mov		r2,		#0x2   
		str		r2,		[r1]	@ this clears the timer2 overflow flag

	ldmfd	sp!,	{r0-r3, pc}

	
	
	
	
INT_DIRECTOR:
		stmfd	sp!,	{r0-r3, lr}			@ store 'em all let the processor sort 'em out
		
		ldr		r0,		=gpio1				@ 0x4804c000 gpio1 base with irqstatus0 offset
		add		r1,		r0,		#irqstatus0	@ button service has priority over timer service
		ldr		r2,		[r1]				@ read status register
		tst		r2,		#bit31set			@ check if bit 31 = 1
		bne	BUTTON_SVC						@ if bit31 = 1 then the button was/is pushed
		
		ldr		r0,	=timer2					@ 0x48040000 base.  p.4344 timer2 address
		add		r1,	r0,	#timer_irqstat		@ 0x28 offset	Timer Status Register
		ldr		r2,	[r1]
		tst		r2,	#0x2
		bne	TIMER_SVC  
		
		
		
	LOU:	
		ldmfd	sp!,	{r0-r3, lr}			@ load 'em all let the processor sort 'em out
		subs	pc,	lr,	#0x4				@ safety valve for interrupts not part of this program
	

	
	BUTTON_SVC:
		ldr		r0,		=intcps					@ address of intc_control register
		add		r1,		r0,		#control		@ 0x48 offset
		mov		r2,		#0x1					@ value to clear bit 0
		str		r2,		[r1]

		ldr		r0,		=gpio1						@ 0x4804c000 gpio1 base with irqstatus0 offset
		add		r1,		r0,		#irqstatus0
		mov		r2,		#bit31set					@ value turns off gpio1_31 and INTC interrupt request
		str		r2,		[r1]						@ write to gpio1_irqstatus_0 register

		ldr		r0,		=timer2						@ 0x48040000 base timer two
		add		r1,		r0,		#timer_irqstat		@ 0x28 offset
		mov		r2,		#0x2
		str		r2,		[r1]	@ this does not simulate an overflow interrupt				
	
		ldr		r0,		=timer2						@ 0x48040000 base.  p.4344 timer2 address
		add		r1,		r0,		#irqenable_set		@ 0x2c offset timer enable set register  p.4350
		mov		r2,		#0x2   
		str		r2,		[r1]	@ this simulates an overflow interrupt

		ldr		r0,		=intcps						@ address of intc_control register
		add		r1,		r0,		#control			@ 0x48 offset
		mov		r2,		#0x1						@ value to clear bit 0
		str		r2,		[r1]

		ldr		r0,		=SCAN_MEM
		ldr		r1,		[r0]
		tst		r1,		#0x0400
		bne	LIGHTS_OFF
		b	SCAN_START
		
		LIGHTS_OFF:
			@ put this in the button service
			LDR		r0,		=SCAN_MEM
			LDR		R1,		=zeros
			STR		R1,		[r0]				@ indicates the lights are off

			LDR		r0,		=gpio2				@ gpio2 base address
			ADD		r1,		r0,		#cleardata	@ 0x190 LOAD GPIO1_CLEARDATAOUT ADDRESS
			LDR		R2,		=bit6_8_10_12set	@  turn off the lights
			STR		R2,		[r1]

			ldmfd	sp!,	{r0-r3, lr}
			subs	pc,		lr,	#0x4
		
		SCAN_START:
			ldr		r0,		=SCAN_MEM			@ active state memory
			ldr		r1,		=0xf01				@ lights are active
			str		r1,		[r0]	
			ldmfd	sp!,	{r0-r3, lr}
			subs	pc,		lr,		#0x4

		SCAN:
			ldr		r0,		=SCAN_MEM
			ldr		r1,		[r0]
			add		r2,		r1,		#0x1
			str		r2,		[r0]
			ldmfd	sp!,	{r0-r3, lr}
			subs	pc,		lr,		#0x4
		
		
	TIMER_SVC:
		ldr		r0,		=timer2						@ 0x48040000 base timer two
		add		r1,		r0,		#timer_irqstat		@ 0x28 offset
		mov		r2,		#0x2
		str		r2,		[r1]	@ this does not simulate an overflow interrupt				
	
		ldr		r0,		=timer2						@ 0x48040000 base.  p.4344 timer2 address
		add		r1,		r0,		#irqenable_set		@ 0x2c offset timer enable set register  p.4350
		mov		r2,		#0x2   
		str		r2,		[r1]	@ this simulates an overflow interrupt
	
		ldr		r0,		=intcps					@ address of intc_control register
		add		r1,		r0,		#control		@ 0x48 offset
		mov		r2,		#0x1					@ value to clear bit 0
		str		r2,		[r1]
	
		ldr		r0,		=SCAN_MEM
		ldr		r1,		[r0]
		tst		r1,		#0x400
		beq		LIGHTS_OFF
		
		ldr		r0,		=SCAN_MEM
		cmp		r1,		r2
		ldr		r2,		=0xf06
		cmp		r1,		r2 
		beq		SCAN_START
		b		SCAN
						
				
				
@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ PROCEDURES ABOVE	@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ MEMORY BELOW		@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@

.data
.align	4

	SCAN_MEM:			@ memory location for the on/off condition of the lights
		.word	0x0		@ lights on = 0xffffffff, lights off = 0x00000000
		
	IRQMODE12_MEM:		@ button service memory
		.rept	256
		.word	0x0
		.endr
			
	SVCMODE13_MEM:		@ interrupt memory
		.rept	256
		.word	0x0
		.endr
theend: b theend		
.end
@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ MEMORY ABOVE		@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ NOTHING BELOW		@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@
