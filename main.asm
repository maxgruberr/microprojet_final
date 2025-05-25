; file	wire1_temp2.asm   target ATmega128L-4MHz-STK300		
; purpose Dallas 1-wire(R) temperature sensor interfacing: temperature

.dseg
x1 :			.byte 1	; position x du bateau du J1
y1 :			.byte 1 ; position y du bateau du J1
x2 :			.byte 1 ; position x du bateau du J2
y2 :			.byte 1 ; position y du bateau du j2
orientation_1 :	.byte 1	; orientation du bateau du joueur 1 (0 = horizontal, 1 = vertical)
orientation_2 :	.byte 1 ; orientation du bateau du joueur 2 (0 = horizontal, 1 = vertical)
player:			.byte 1	; 1 = player 1		2 = player 2
battle:			.byte 1 ; 0 = placement		1 = battle
hit_count_1 :	.byte 1	; indique le nombre de pixels touchés par le joueur 1
hit_count_2 :	.byte 1 ; indique le nombre de pixels touchés par le joueur 2
game_over :		.byte 1 ; 1 si un joueur a gagné la partie. 0 sinon
pixel1 : 		.byte 3 ; pixel à restore pour le joueur 1
pixel2 :		.byte 3 ; pixel à restore pour le joueur 2
ov_count :		.byte 1 ; overflow counter 
printf_char_delay_active_flag_addr :	.byte 1

.cseg 
.org 0
	jmp reset


.org	OVF0addr
	rjmp overflow0

.org 0x60

overflow0:		; routine d'interruption
	lds		_w, ov_count
	inc		_w
	cpi		_w, 10  ; le joueur n'a que 10 secondes pour placer sa bombe
	breq	timer_over
	sts		ov_count, _w

	reti

	timer_over :
	lds		_w, player
	cpi		_w, 1
	breq	PC+2
	rcall	restore_pixel_2
	cpi		_w, 2
	breq	PC+2
	rcall	restore_pixel_1  
	rcall	switch_player  ; remet en place le pixel d'origine et change de joueur
	clr		_w
	sts		ov_count, _w ; countdown réinitialisé
	reti
	
.include "battle.asm"

reset:
	LDSP	RAMEND			; Load Stack Pointer (SP)
	rcall	LCD_init
	rcall	ws2812b4_init	; initialize led matrix
	rcall	UART0_init		
	OUTI	DDRB, 0xff		; connect LEDs to PORTB, output mode
	OUTI	DDRC, 0x00
	OUTI    PORTB, 0xfe
	OUTI	ASSR, (1<<AS0)
	OUTI	TIMSK,(1<<TOIE0)
	sei

	ldi		b0, 0x03 ; initial x position
	ldi		b1, 0x03 ; initial y position

	ldi		w, 1	; player 1 starts
	sts		player, w
	sts		printf_char_delay_active_flag_addr, w	

	clr		w
	sts		battle, w
	sts		orientation_1, w
	sts		orientation_2, w
	sts		hit_count_1, w
	sts		hit_count_2, w
	sts		game_over, w
	sts		ov_count, w
	ldi		a0, 0
	ldi		a1, 0
	ldi		a2, 4
	sts		pixel1, a0 
	sts		pixel1+1, a1
	sts		pixel1+2, a2
	sts		pixel2, a0 
	sts		pixel2+1, a1
	sts		pixel2+2, a2
	clr		r1			; connect buttons to PORTC, input mode
	rcall   board_init	; board bleu avec bateau 1 au milieu
	rcall	battle_init_1
	rcall	battle_init_2
	rcall	m_initial_sequence ; message de debut de partie
	rjmp	main

main :
 
	lds		w, game_over
	cpi		w, 1
	breq	restart

	lds		w, battle ; phase de bataille
	cpi		w, 1
	breq	PC+2
	rcall	boat_positions ; phase de position des bateaux
	cpi		w, 0
	breq	PC+2
	rcall	bataille
	rjmp	main

	restart : 
	rcall	m_victory ; message de victoire 
	rcall	winner_flashing ; animation de victoire adaptée à la couleur du vainqueur
	rcall	m_game_over ; message de game over
	WAIT_MS	2000
	rjmp	reset 
