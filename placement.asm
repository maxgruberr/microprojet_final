.include "messages.asm"		

/////////////////////////////////////////////////////////////////////////
; initialise le board pour la phase de placement (bleu avec le bateau p1)
/////////////////////////////////////////////////////////////////////////

board_init : 

	_LDI r0, 64
	rcall	point_memory_placement

	loop2 : 
		ldi a0, 0x00        
		ldi a1, 0x00
		ldi a2, 0x05
		st z+, a0
		st z+, a1
		st z+, a2
		dec r0
		brne loop2
		   
	rcall	boat_red
	rcall	draw_board

ret

/////////////////////////////////////////////////////////////////////////
; place un bateau rouge aux coordonnées
/////////////////////////////////////////////////////////////////////////

boat_red :

	ldi		a0, 0x00        
	ldi		a1, 0x05
	ldi		a2, 0x00
	lds		r28, orientation_1
	cpi		r28, 0
	breq	PC+2
	rjmp	vertical
	rjmp	horizontal

/////////////////////////////////////////////////////////////////////////
; place un bateau vert aux coordonnées
/////////////////////////////////////////////////////////////////////////

boat_green :
	ldi		a0, 0x05       
	ldi		a1, 0x00
	ldi		a2, 0x00
	lds		r28, orientation_2
	cpi		r28, 0
	breq	PC+2
	rjmp	vertical
	rjmp	horizontal

	horizontal :  ; affiche le bateau horizontal
		push	r18
		push	r19
		rcall	pixel_addr_bateau
		pop		r19
		pop		r18
		st		z+, a0
		st		z+, a1
		st		z+, a2
		dec		b0
		push	r18
		push	r19
		rcall	pixel_addr_bateau
		pop		r19
		pop		r18
		st		z+, a0
		st		z+, a1
		st		z+, a2
		inc		b0
		inc		b0
		push	r18
		push	r19
		rcall	pixel_addr_bateau
		pop		r19
		pop		r18
		st		z+, a0
		st		z+, a1
		st		z+, a2
		dec		b0
ret

	vertical : ; affiche le bateau vertical
		push	r18
		push	r19
		rcall	pixel_addr_bateau
		pop		r19
		pop		r18
		st		z+, a0
		st		z+, a1
		st		z+, a2	
		inc		b1
		push	r18
		push	r19
		rcall	pixel_addr_bateau
		pop		r19
		pop		r18
		st		z+, a0
		st		z+, a1
		st		z+, a2	
		dec		b1
		dec		b1
		push	r18
		push	r19
		rcall	pixel_addr_bateau
		pop		r19
		pop		r18
		st		z+, a0
		st		z+, a1
		st		z+, a2	
		inc		b1
ret
	

//////////////////////////////////////////////////////////////////
; grande routine de la phase de placement
//////////////////////////////////////////////////////////////////

boat_positions: 

	clr		r27
	sts		ov_count, r27 ; évite les interruptions timer si on enchaine plusieurs parties
	sbic	UCSR0A,RXC0
	rcall   read_uart_boat
	ret

//////////////////////////////////////////////////////////////////
; interprète les touches clavier
//////////////////////////////////////////////////////////////////

read_uart_boat: 
	
	push	w
	in	r0,UDR0

	ch1:
		_CPI r0, 'z'
		brne ch2
		rjmp move_up
	ch2:
		_CPI r0, 'q'
		brne ch3
		rjmp move_left
	ch3:
		_CPI r0, 's'
		brne ch4
		rjmp move_down
	ch4:
		_CPI r0, 'd'
		brne ch5
		rjmp move_right	

	ch5:
		_CPI r0, 'r'
		brne ch6
		rjmp rotate

	ch6: 
		_CPI r0, 'c'
		brne PC+2
		rjmp confirm_pos

		
	fin:
		pop w
		ret

////////////////////////////////////////////////////////////
; chaque mvt déplace le bateau en tenant compte des limites 
; du board selon la disposition du bateau
////////////////////////////////////////////////////////////

move_right : 
	pop		w
	lds		r27, player
	cpi		r27, 1
	breq	PC+2
	rjmp	mover_2
	rjmp	mover_1

	mover_1 : 
		lds		r28, orientation_1
		cpi		r28, 0
		breq	PC+2
		rjmp	mover_v
		rjmp	mover_h

	mover_2 : 
		lds		r28, orientation_2
		cpi		r28, 0
		breq	PC+2
		rjmp	mover_v
		rjmp	mover_h

	mover_h : 
		dec		b0
		cpi		b0, 0
		brne	PC+2
		ldi		b0, 1
		rjmp	update

	mover_v : 
		dec		b0
		cpi		b0, -1
		brne	PC+2
		ldi		b0, 0
		rjmp	update

//////////////////////////////

move_left : 
	pop		w
	lds		r27, player
	cpi		r27, 1
	breq	PC+2
	rjmp	movel_2
	rjmp	movel_1

	movel_1 : 
		lds		r28, orientation_1
		cpi		r28, 0
		breq	PC+2
		rjmp	movel_v
		rjmp	movel_h

	movel_2 : 
		lds		r28, orientation_2
		cpi		r28, 0
		breq	PC+2
		rjmp	movel_v
		rjmp	movel_h

	movel_h : 
		inc		b0
		cpi		b0, 7
		brne	PC+2
		ldi		b0, 6
		rjmp	update

	movel_v : 
		inc		b0
		cpi		b0, 8
		brne	PC+2
		ldi		b0, 7
		rjmp	update

//////////////////////////////

move_up : 
	pop		w
	lds		r27, player
	cpi		r27, 1
	breq	PC+2
	rjmp	moveu_2
	rjmp	moveu_1

	moveu_1 : 
		lds		r28, orientation_1
		cpi		r28, 0
		breq	PC+2
		rjmp	moveu_v
		rjmp	moveu_h

	moveu_2 : 
		lds		r28, orientation_2
		cpi		r28, 0
		breq	PC+2
		rjmp	moveu_v
		rjmp	moveu_h

	moveu_h : 
		inc		b1
		cpi		b1, 8
		brne	PC+2
		ldi		b1, 7
		rjmp	update

	moveu_v : 
		inc		b1
		cpi		b1, 7
		brne	PC+2
		ldi		b1, 6
		rjmp	update

//////////////////////////////

move_down : 
	pop		w
	lds		r27, player
	cpi		r27, 1
	breq	PC+2
	rjmp	moved_2
	rjmp	moved_1

	moved_1 : 
		lds		r28, orientation_1
		cpi		r28, 0
		breq	PC+2
		rjmp	moved_v
		rjmp	moved_h

	moved_2 : 
		lds		r28, orientation_2
		cpi		r28, 0
		breq	PC+2
		rjmp	moved_v
		rjmp	moved_h

	moved_h : 
		dec		b1
		cpi		b1, -1
		brne	PC+2
		ldi		b1, 0
		rjmp	update

	moved_v : 
		dec		b1
		cpi		b1, 0
		brne	PC+2
		ldi		b1, 1
		rjmp	update

//////////////////////////////

rotate : 
	pop		w
	lds		r27, player
	cpi		r27, 1
	breq	PC+2
	rjmp	rotate_2
	rjmp	rotate_1

	rotate_1 : 
		lds		r28, orientation_1
		cpi		r28, 0
		breq	PC+2
		rjmp	rotate_v1
		rjmp	rotate_h1

		rotate_v1 :
			cpi		b0, 0
			breq	cancel
			cpi		b0, 7	
			breq	cancel
			clr		r29
			sts		orientation_1, r29
			rjmp	update

		rotate_h1 :
			cpi		b1, 0
			breq	cancel
			cpi		b1, 7	
			breq	cancel
			ldi		r29, 1
			sts		orientation_1, r29
			rjmp	update

	rotate_2 : 
	lds		r28, orientation_2
	cpi		r28, 0
	breq	PC+2
	rjmp	rotate_v2
	rjmp	rotate_h2

		rotate_v2 :
			cpi		b0, 0
			breq	cancel
			cpi		b0, 7	
			breq	cancel
			clr		r29
			sts		orientation_2, r29
			rjmp	update

		rotate_h2 :
			cpi		b1, 0
			breq	cancel
			cpi		b1, 7	
			breq	cancel
			ldi		r29, 1
			sts		orientation_2, r29
			rjmp	update

	cancel : 
		rjmp	update
		

//////////////////////////////


confirm_pos :
	pop		w
	lds		w, player 
	cpi		w, 2
	breq	PC+2
	rjmp	save_P1
	cpi		w, 1
	breq	PC+2
	rjmp	save_P2

save_P1 : ; sauvegarde la position du bateau du joueur 1

	sts		x1, b0
	sts		y1, b1
	ldi		b0, 3
	ldi		b1, 3
	ldi		w, 2
	sts		player, w
	ldi		w, 1
	rcall	m_p2_deploy_fleet
	rjmp	update


save_P2 : ; sauvegarde la position du bateau du joueur 2

	sts		x2, b0
	sts		y2, b1
	ldi		b0, 3
	ldi		b1, 3
	ldi		w, 1
	sts		player, w
	sts		battle, w
	rcall	m_prepare_for_battle
	WAIT_MS	1000
	rcall	m_p1_launch_salvo
	OUTI	TCCR0,5   ; CS0=5  Clk/128  Activation timer

/////////////////////////////////////////////////////////////////////////
; dessine le fond bleu avec le bateau approprié par dessus
/////////////////////////////////////////////////////////////////////////

update :  
	rcall	blue_board
	lds		r29, player
	cpi		r29, 1
	breq	PC+2
	rcall	boat_green
	cpi		r29, 2
	breq	PC+2
	rcall	boat_red
	rcall	draw_board
ret

/////////////////////////////////////////////////////////////////////////
; se positionne à la bonne adresse mémoire en fct des coordonnées
/////////////////////////////////////////////////////////////////////////

pixel_addr_bateau: 

    ; --- y*24 = y*16 + y*8 -------------------------------
    mov   r18, b1          ; r18 = y
    lsl   r18              ; x2
    lsl   r18              ; x4
    lsl   r18              ; x8   (y*8)
    mov   r19, r18         ; r19 = y*8
    lsl   r18              ; x16 (=y*16)
    add   r18, r19         ; y*16 + y*8 = y*24
    ; --- x*3 = x + 2x ------------------------------------
    mov   r19, b0		   ; r19 = x
    lsl   r19              ; 2x
    add   r19, b0         ; 3x
    ; --- offset total ------------------------------------
    add   r18, r19   
	rcall point_memory_placement
	add	  zl, r18 
ret






