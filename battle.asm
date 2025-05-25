/*
 * battle.asm
 *
 *  Created: 23/05/2025 21:06:36
 *   Author: IEM Courses
 */ 


 .include "placement.asm"

 /////////////////////////////////////////////////////////////////////////
; initialise les 2 boards pour les 2 joueurs
/////////////////////////////////////////////////////////////////////////

 battle_init_1 : 

	_LDI	r0, 64
	rcall	point_memory_player1

	loop6 : 
		ldi		a0, 0x00        
		ldi		a1, 0x00
		ldi		a2, 0x05
		st		z+, a0
		st		z+, a1
		st		z+, a2
		dec		r0
		brne	loop6

ret


 battle_init_2 : 

	_LDI	r0, 64
	rcall	point_memory_player2

	loop12 : 
		ldi		a0, 0x00        
		ldi		a1, 0x00
		ldi		a2, 0x05
		st		z+, a0
		st		z+, a1
		st		z+, a2
		dec		r0
		brne	loop12

ret

/////////////////////////////////////////////////////////////////////////
; routine principale de la phase de bataille
/////////////////////////////////////////////////////////////////////////

 bataille :	
	cli	

	lds		r29, player
	cpi		r29, 2
	breq	PC+2
	rcall	put_red
	cpi		r29, 1
	breq	PC+2
	rcall	put_green

	rcall	draw_board
	sbic	UCSR0A,RXC0
	rcall   read_uart_bomb
	sei
	nop 
	nop				; control interrupt moment
	nop
ret

//////////////////////////////////////////////////////////////////
; interprète les touches clavier
//////////////////////////////////////////////////////////////////

read_uart_bomb:
	
	in	r0,UDR0

	bh1:
		_CPI r0, 'z'
		brne bh2
		rjmp bomb_up
	bh2:
		_CPI r0, 'q'
		brne bh3
		rjmp bomb_left
	bh3:
		_CPI r0, 's'
		brne bh4
		rjmp bomb_down
	bh4:
		_CPI r0, 'd'
		brne bh5
		rjmp bomb_right	

	bh5: 
		_CPI r0, 'c'
		brne PC+2
		rjmp bomboclat

ret

////////////////////////////////////////////////////////////
; Chaque mvt déplace la bombe dans la direction souhaitée.
; La couleur du pixel est saved avant d'être restored lorsque 
; le curseur de la bombe s'en va.
////////////////////////////////////////////////////////////

bomb_right : 

	lds		w, player
	cpi		w, 1
	breq	PC+2
	rcall	restore_pixel_2
	cpi		w, 2
	breq	PC+2
	rcall	restore_pixel_1	

	dec		b0
	cpi		b0, -1
	brne	PC+2
	ldi		b0, 0

	cpi		w, 1
	breq	PC+2
	rcall	save_pixel_2
	cpi		w, 2
	breq	PC+2
	rcall	save_pixel_1

	cpi		w, 1
	breq	PC+2
	rcall	put_green
	cpi		w, 2
	breq	PC+2
	rcall	put_red	

	rcall	draw_board

ret

////////////////////////////////////////////////////////////

bomb_left : 

	lds		w, player
	cpi		w, 1
	breq	PC+2
	rcall	restore_pixel_2
	cpi		w, 2
	breq	PC+2
	rcall	restore_pixel_1	

	inc		b0
	cpi		b0, 8
	brne	PC+2
	ldi		b0, 7

	cpi		w, 1
	breq	PC+2
	rcall	save_pixel_2
	cpi		w, 2
	breq	PC+2
	rcall	save_pixel_1

	cpi		w, 1
	breq	PC+2
	rcall	put_green
	cpi		w, 2
	breq	PC+2
	rcall	put_red	

	rcall	draw_board

ret

////////////////////////////////////////////////////////////

bomb_up : 

	lds		w, player
	cpi		w, 1
	breq	PC+2
	rcall	restore_pixel_2
	cpi		w, 2
	breq	PC+2
	rcall	restore_pixel_1	

	inc		b1
	cpi		b1, 8
	brne	PC+2
	ldi		b1, 7

	cpi		w, 1
	breq	PC+2
	rcall	save_pixel_2
	cpi		w, 2
	breq	PC+2
	rcall	save_pixel_1

	cpi		w, 1
	breq	PC+2
	rcall	put_green
	cpi		w, 2
	breq	PC+2
	rcall	put_red	

	rcall	draw_board
ret

////////////////////////////////////////////////////////////

bomb_down : 

	lds		w, player
	cpi		w, 1
	breq	PC+2
	rcall	restore_pixel_2
	cpi		w, 2
	breq	PC+2
	rcall	restore_pixel_1	

	dec		b1
	cpi		b1, -1
	brne	PC+2
	ldi		b1, 0

	cpi		w, 1
	breq	PC+2
	rcall	save_pixel_2
	cpi		w, 2
	breq	PC+2
	rcall	save_pixel_1

	cpi		w, 1
	breq	PC+2
	rcall	put_green
	cpi		w, 2
	breq	PC+2
	rcall	put_red	

	rcall	draw_board

ret

////////////////////////////////////////////////////////////
; vérifie si la bombe touche un bateau
; change la couleur du pixel en conséquence
; change de joueur
////////////////////////////////////////////////////////////

bomboclat : 

	lds		w, player
	cpi		w, 1
	breq	PC+2
	rcall	compare_pixel_2
	cpi		w, 2
	breq	PC+2
	rcall	compare_pixel_1	
	rcall	draw_board
	WAIT_MS	1000
	rcall	switch_player
	clr		w
	sts		ov_count, w	
ret

////////////////////////////////////////////////////////////

compare_pixel_1 : 
	
	lds		r28, orientation_2
	cpi		r28, 0
	breq	compare_h1
	rjmp	compare_v1

	compare_h1 : 
		lds		r27, x2
		cp		b0, r27
		brne	pix1
		lds		r27, y2
		cp		b1, r27
		brne	pix1
		rjmp	hit1

		pix1 : 
		lds		r27, x2
		dec		r27
		cp		b0, r27
		brne	pix2
		lds		r27, y2
		cp		b1, r27
		brne	pix2
		rjmp	hit1

		pix2 : 
		lds		r27, x2
		inc		r27
		cp		b0, r27
		breq	PC+2
		rjmp	missed
		lds		r27, y2
		cp		b1, r27
		breq	PC+2
		rjmp	missed
		rjmp	hit1

	compare_v1 : 

		lds		r27, x2
		cp		b0, r27
		brne	pix3
		lds		r27, y2
		cp		b1, r27
		brne	pix3
		rjmp	hit1

		pix3 : 
		lds		r27, x2
		cp		b0, r27
		brne	pix4
		lds		r27, y2
		dec		r27
		cp		b1, r27
		brne	pix4
		rjmp	hit1

		pix4 : 
		lds		r27, x2
		cp		b0, r27
		breq	PC+2
		rjmp	missed
		lds		r27, y2
		inc		r27
		cp		b1, r27
		breq	PC+2
		rjmp	missed
		rjmp	hit1


	hit1 : 
		lds		r27, hit_count_1
		inc		r27
		cpi		r27, 3
		brne	PC+2
		rjmp	winner
		sts		hit_count_1, r27
		rcall	put_orange

ret
	
////////////////////////////////////////////////////////////

compare_pixel_2 : 

	lds		r28, orientation_1
	cpi		r28, 0
	breq	compare_h2
	rjmp	compare_v2

	compare_h2 : 
		lds		r27, x1
		cp		b0, r27
		brne	pix5
		lds		r27, y1
		cp		b1, r27
		brne	pix5
		rjmp	hit2

		pix5 : 
		lds		r27, x1
		dec		r27
		cp		b0, r27
		brne	pix6
		lds		r27, y1
		cp		b1, r27
		brne	pix6
		rjmp	hit2

		pix6 : 
		lds		r27, x1
		inc		r27
		cp		b0, r27
		breq	PC+2
		rjmp	missed
		lds		r27, y1
		cp		b1, r27
		brne	missed
		rjmp	hit2

	compare_v2 : 

		lds		r27, x1
		cp		b0, r27
		brne	pix7
		lds		r27, y1
		cp		b1, r27
		brne	pix7
		rjmp	hit2

		pix7 : 
		lds		r27, x1
		cp		b0, r27
		brne	pix8
		lds		r27, y1
		dec		r27
		cp		b1, r27
		brne	pix8
		rjmp	hit2

		pix8 : 
		lds		r27, x1
		cp		b0, r27
		brne	missed
		lds		r27, y1
		inc		r27
		cp		b1, r27
		brne	missed
		rjmp	hit2

	hit2 : 
		lds		r27, hit_count_2
		inc		r27
		cpi		r27, 3
		brne	PC+2
		rjmp	winner
		sts		hit_count_2, r27
		rcall	put_orange
ret
	
	missed : 
		rcall	put_dark_blue
ret

	winner : 
		ldi		r27, 1
		sts		game_over, r27
		rcall	put_orange
ret


switch_player : 
	
	lds		w, player
	cpi		w, 1
	breq	pl2
	rjmp	pl1

	pl1 : 
		ldi		w, 1
		sts		player, w
		rcall	m_p1_launch_salvo
		rjmp	init_coord

	pl2 : 
		ldi		w, 2
		sts		player, w
		rcall	m_p2_launch_salvo
		rjmp	init_coord

	init_coord :
	 
		ldi		b0, 3
		ldi		b1, 3
	clr		w
	sts		ov_count, w
ret


////////////////////////////////////////////////////////////////	
; se positionne à la bonne adresse mémoire en fct des coordonnées
////////////////////////////////////////////////////////////////

pixel_addr_bomb: 

    ; --- y*24 = y*16 + y*8 -------------------------------
    mov   r18, b1         ; r18 = y
    lsl   r18              ; x2
    lsl   r18              ; x4
    lsl   r18              ; x8   (y*8)
    mov   r19, r18         ; r19 = y*8
    lsl   r18              ; x16 (=y*16)
    add   r18, r19         ; y*16 + y*8 = y*24
    ; --- x*3 = x + 2x ------------------------------------
    mov   r19, b0		   ; r19 = x
    lsl   r19              ; 2x
    add   r19, b0		   ; 3x
    ; --- offset total ------------------------------------
    add   r18, r19
	lds	  w, player
	cpi	  w, 1
	breq  PC+2
	rcall point_memory_player2
	cpi	  w, 2
	breq  PC+2
	rcall point_memory_player1	   
	add	  zl, r18 
    ret

////////////////////////////////////////////////////////////////	
; stocke la couleur du pixel à l'emplacement dédié
; cette couleur sera ensuite restored 
////////////////////////////////////////////////////////////////
	
save_pixel_1:

	rcall	pixel_addr_bomb   ; Z -> G du pixel courant
	ld		r27,  z+          ; r27 = oldG
    ld		r28,  z+          ; r28 = oldR
    ld		r29,  z+          ; r29 = oldB
	sts		pixel1, r27 
	sts		pixel1+1, r28
	sts		pixel1+2, r29

ret

save_pixel_2:

	rcall	pixel_addr_bomb        ; Z -> G du pixel courant
	ld		r27,  z+          ; r27 = oldG
    ld		r28,  z+          ; r28 = oldR
    ld		r29,  z+          ; r29 = oldB
	sts		pixel2, r27 
	sts		pixel2+1, r28
	sts		pixel2+2, r29
ret

////////////////////////////////////////////////////////////////	
; restore le pixel saved auparavant
////////////////////////////////////////////////////////////////

restore_pixel_1:

	rcall	pixel_addr_bomb
	lds		r27, pixel1
	lds		r28, pixel1+1
	lds		r29, pixel1+2
	st		z+, r27        ; G
	st		z+, r28        ; R
	st		z+, r29        ; B

ret 

restore_pixel_2:   
	
	rcall	pixel_addr_bomb
	lds		r27, pixel2
	lds		r28, pixel2+1
	lds		r29, pixel2+2
	st		z+, r27        ; G
	st		z+, r28        ; R
	st		z+, r29		   ; B 
ret	        

////////////////////////////////////////////////////////////////	
; place des pixels de couleur donnée à l'adresse actuelle
////////////////////////////////////////////////////////////////

put_red : 
	
	push	r18
	push	r19
	push	r20
	rcall	pixel_addr_bomb
	pop		r20
	pop		r19
	pop		r18
	ldi		a0, 0
	ldi		a1, 5
	ldi		a2, 0
	st		z+, a0       
	st		z+, a1       
	st		z+, a2

ret

put_green : 
	
	push	r18
	push	r19
	push	r20
	rcall	pixel_addr_bomb
	pop		r20
	pop		r19
	pop		r18
	ldi		a0, 5
	ldi		a1, 0
	ldi		a2, 0
	st		z+, a0       
	st		z+, a1       
	st		z+, a2
ret

put_dark_blue : 
	
	push	r18
	push	r19
	push	r20
	rcall	pixel_addr_bomb
	pop		r20
	pop		r19
	pop		r18
	ldi		a0, 1
	ldi		a1, 1
	ldi		a2, 1
	st		z+, a0       
	st		z+, a1       
	st		z+, a2 
	

ret

put_orange : 
	
	push	r18
	push	r19
	push	r20
	rcall	pixel_addr_bomb
	pop		r20
	pop		r19
	pop		r18
	ldi		a0,	2
	ldi		a1, 6
	ldi		a2, 0
	st		z+, a0       
	st		z+, a1       
	st		z+, a2 

ret


	





	
