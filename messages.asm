


.include "printf.asm"

/////////////////////////////////////////////////////////////////////////
; clignotement pour le message d'intro
/////////////////////////////////////////////////////////////////////////

flash_delay:
  push r20
  push r21
  push r22

  ldi r22, 0x05      ; Outer loop counter (5). Was 0x0A for ~0.5s.
flash_delay_outer_loop:
  ldi r21, 0xC8      ; Middle loop counter (200)
flash_delay_middle_loop:
  ldi r20, 0xFA      ; Inner loop counter (250)
flash_delay_inner_loop:
  nop                  ; 1 cycle
  dec r20              ; 1 cycle
  brne flash_delay_inner_loop ; 2 cycles if branch taken
  dec r21              ; 1 cycle
  brne flash_delay_middle_loop ; 2 cycles
  dec r22              ; 1 cycle
  brne flash_delay_outer_loop ; 2 cycles

  pop r22
  pop r21
  pop r20
  ret

/////////////////////////////////////////////////////////////////////////
; message de game over
/////////////////////////////////////////////////////////////////////////

m_game_over :
  push r22         

  ldi r22, 5       
game_over_flash_loop:
  rcall LCD_clear
  ldi a0, 3
  rcall LCD_pos

  rcall disable_printf_char_delay 
  PRINTF LCD
  .db "GAME OVER", 0
  rcall enable_printf_char_delay  

  rcall flash_delay 
  rcall LCD_clear   
  rcall flash_delay 

  dec r22           
  brne game_over_flash_loop 

  pop r22           
  ret               


/////////////////////////////////////////////////////////////////////////
; message de placement des bateaux pour les 2 joueurs
/////////////////////////////////////////////////////////////////////////

m_p1_deploy_fleet:
  push a0
  rcall LCD_clear
  ldi a0, 3       
  rcall LCD_pos
  PRINTF LCD
  .db "P1: Deploy", 0
  ldi a0, 0x40 + 5 
  rcall LCD_pos
  PRINTF LCD
  .db "Fleet", 0
  pop a0
ret


m_p2_deploy_fleet:
  push a0
  rcall LCD_clear
  ldi a0, 3       
  rcall LCD_pos
  PRINTF LCD
  .db "P2: Deploy", 0
  ldi a0, 0x40 + 5 
  rcall LCD_pos
  PRINTF LCD
  .db "Fleet", 0
  pop a0
ret

/////////////////////////////////////////////////////////////////////////
; message bombe du joueur 1
/////////////////////////////////////////////////////////////////////////

m_p1_launch_salvo:
  push a0
  rcall LCD_clear
  ldi a0, 1
  rcall LCD_pos
  PRINTF LCD
  .db "P1: Drop Bomb!", 0
  pop a0
ret

/////////////////////////////////////////////////////////////////////////
; message bombe du joueur 2
/////////////////////////////////////////////////////////////////////////

m_p2_launch_salvo:
  push a0
  rcall LCD_clear
  ldi a0, 1
  rcall LCD_pos
  PRINTF LCD
  .db "P2: Drop Bomb!", 0
  pop a0
ret

/////////////////////////////////////////////////////////////////////////
; message de victoire ("Victory!) 
/////////////////////////////////////////////////////////////////////////

m_victory:
  push a0
  rcall LCD_clear
  ldi a0, 4
  rcall LCD_pos
  PRINTF LCD
  .db "Victory!", 0
  pop a0
ret

/////////////////////////////////////////////////////////////////////////
; message "prepare for battle"
/////////////////////////////////////////////////////////////////////////

m_prepare_for_battle:
  push a0
  rcall LCD_clear

  ldi a0, 2
  rcall LCD_pos
  PRINTF LCD
  .db "Prepare for", 0


  ldi a0, 0x40 + 4
  rcall LCD_pos
  PRINTF LCD
  .db "Battle!", 0
  pop a0
ret

/////////////////////////////////////////////////////////////////////////
; message de début de partie ("game start" clignotant + "p1 deploy fleet")
/////////////////////////////////////////////////////////////////////////

m_initial_sequence:  
  push r22          

  ldi r22, 5    
initial_sequence_flash_loop:
  rcall LCD_clear

  ldi a0, 2
  rcall LCD_pos
  rcall disable_printf_char_delay 
  PRINTF LCD
  .db "Start Game!", 0
  rcall enable_printf_char_delay 

  rcall flash_delay 
  rcall LCD_clear   
  rcall flash_delay 

  dec r22
  brne initial_sequence_flash_loop

  ldi a0, 0
  rcall LCD_pos
  PRINTF LCD
  .db "P1: Deploy Fleet", 0


  pop r22           
  ret
