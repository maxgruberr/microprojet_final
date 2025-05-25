/*
 * drawing.asm
 *
 *  Created: 24/05/2025 15:36:26
 *   Author: IEM Courses
 */ 

.include "macros.asm"		; include macro definitions
.include "definitions.asm"
.include "uart.asm"


.macro	WS2812b4_WR0
	clr u
	sbi PORTD, 1
	out PORTD, u
	nop
	nop
.endm


.macro	WS2812b4_WR1
	sbi PORTD, 1
	nop
	nop
	cbi PORTD, 1
	;nop	;deactivated on purpose of respecting timings
	;nop

.endm

////////////////////////////////////////////////////////////////	
; place le pointeur z sur le board choisi : 
;	0x0400 = phase de placement
;	0x0500 = bataille du joueur 1
;	0x0600 = bataille du joueur 2
////////////////////////////////////////////////////////////////

point_memory_placement : 
	
	ldi zl,low(0x0400)
	ldi zh,high(0x0400)

ret


point_memory_player1 : 
	
	ldi zl,low(0x0500)
	ldi zh,high(0x0500)

ret


point_memory_player2 : 
	
	ldi zl,low(0x0600)
	ldi zh,high(0x0600)

ret

/////////////////////////////////////////////////////////////////////	
; place le pointeur z sur le bon board selon la phase de jeu actuelle
/////////////////////////////////////////////////////////////////////

check_memory : 

	lds		w, battle
	tst		w
	breq	placement
	
	lds		w, player
	cpi		w, 1
	breq	PC+2
	rcall	point_memory_player2
	cpi		w, 2
	breq	PC+2
	rcall	point_memory_player1

ret

	placement : 
	rcall point_memory_placement

ret

////////////////////////////////////////////////////////////////	
; dessine entièrement le board actuel
////////////////////////////////////////////////////////////////

draw_board :
	
	rcall	check_memory
	_LDI	r0,64
	loop4:
		ld a0, z+
		ld a1, z+		
		ld a2, z+
		cli
		rcall ws2812b4_byte3wr
		sei
		dec r0
		brne loop4
		rcall ws2812b4_reset
ret

winner_flashing:

	lds		w, player
	cpi		w, 1
	breq	PC+2
	rjmp	vic_2
	cpi		w, 2
	breq	PC+2
	rjmp	vic_1
	
	vic_1 : 
		clr		r27
	loop_vic1 :
		rcall	green_board
		WAIT_MS	250
		rcall	black_board
		WAIT_MS	250
		inc		r27
		cpi		r27,5
		brne	loop_vic1
ret

	vic_2 : 
		clr		r27
	loop_vic2 :
		rcall	red_board
		WAIT_MS	250
		rcall	black_board
		WAIT_MS	250
		inc		r27
		cpi		r27,5
		brne	loop_vic2
ret

////////////////////////////////////////////////////////////////	
; dessine un board tout éteint
////////////////////////////////////////////////////////////////
	
black_board :
	
	_LDI	r0, 64
	lds		w, player
	cpi		w, 1
	breq	PC+2
	rcall	point_memory_player2
	cpi		w, 2
	breq	PC+2
	rcall	point_memory_player1

	loop24 : 
		ldi		a0, 0x00        
		ldi		a1, 0x00
		ldi		a2, 0x00
		st		z+, a0
		st		z+, a1
		st		z+, a2
		dec		r0
		brne	loop24

	rcall	draw_board

ret

////////////////////////////////////////////////////////////////	
; dessine un board tout rouge
////////////////////////////////////////////////////////////////

red_board :
	
	_LDI	r0, 64
	rcall	point_memory_player2

	loop67 : 
		ldi		a0, 0x00        
		ldi		a1, 0x0f
		ldi		a2, 0x00
		st		z+, a0
		st		z+, a1
		st		z+, a2
		dec		r0
		brne	loop67

	rcall	draw_board

ret

////////////////////////////////////////////////////////////////	
; dessine un board tout vert
////////////////////////////////////////////////////////////////

green_board :
	
	_LDI	r0, 64
	rcall	point_memory_player1

	loop124 : 
		ldi		a0, 0x0f       
		ldi		a1, 0x00
		ldi		a2, 0x00
		st		z+, a0
		st		z+, a1
		st		z+, a2
		dec		r0
		brne	loop124

	rcall	draw_board

ret

////////////////////////////////////////////////////////////////	
; dessine un board tout bleu
////////////////////////////////////////////////////////////////

blue_board	:

	_LDI	r0, 64
	rcall	point_memory_placement

	loop20 : 
		ldi		a0, 0x00
		ldi		a1, 0x00
		ldi		a2, 0x05
		st		z+, a0
		st		z+, a1
		st		z+, a2
		dec		r0
		brne	loop20
ret

	
////////////////////////////////////////////////////////////////	
; allume un pixel de la matrice (code de la démo)
////////////////////////////////////////////////////////////////


ws2812b4_init:
	OUTI	DDRD,0x02
ret

; ws2812b4_byte3wr	; arg: a0,a1,a2 ; used: r16 (w)
; purpose: write contents of a0,a1,a2 (24 bit) into ws2812, 1 LED configuring
;     GBR color coding, LSB first
ws2812b4_byte3wr:

	ldi w,8

	ws2b3_starta0:
		sbrc a0,7
		rjmp	ws2b3w1
		WS2812b4_WR0			; write a zero
		rjmp	ws2b3_nexta0

	ws2b3w1:
		WS2812b4_WR1

	ws2b3_nexta0:
		lsl a0
		dec	w
		brne ws2b3_starta0
		ldi w,8

	ws2b3_starta1:
		sbrc a1,7
		rjmp	ws2b3w1a1
		WS2812b4_WR0			; write a zero
		rjmp	ws2b3_nexta1

	ws2b3w1a1:
		WS2812b4_WR1
	ws2b3_nexta1:
		lsl a1
		dec	w
		brne ws2b3_starta1
		ldi w,8

	ws2b3_starta2:
		sbrc a2,7
		rjmp	ws2b3w1a2
		WS2812b4_WR0			; write a zero
		rjmp	ws2b3_nexta2
	ws2b3w1a2:
		WS2812b4_WR1
	ws2b3_nexta2:
		lsl a2
		dec	w
		brne ws2b3_starta2
ret

; ws2812b4_byte3wr	; arg: a0,a1,a2 ; used: r16 (w)
; purpose: write contents of a0,a1,a2 (24 bit) into ws2812, 1 LED configuring
;     GBR color coding, LSB first


; ws2812b4_reset	; arg: void; used: r16 (w)
; purpose: reset pulse, configuration becomes effective
ws2812b4_reset:

	cbi PORTD, 1
	WAIT_US	50 	; 50 us are required, NO smaller works
ret
