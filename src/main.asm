
    .include "erapi.asm"

    .area CODE (ABS)
    .org 0x100

main:
    call main_init
    call input_init
    call main_load_main_menu

main_loop:
    call input_read
    call main_call_cur_frame
    ; render frame
    ld  a, #1
    halt

    jr  main_loop

    ;-------------------;
    ; *** FUNCTIONS *** ;
    ;-------------------;

main_call_cur_frame:
    ; _main_mode_frame_fn needs to point to a function that ends
    ; in ret, as we will use that ret to pop back up out of
    ; this intermediary call
    ld hl, (_main_mode_frame_fn)
    jp (hl)

main_init:
    ; ; ?
    ; ld  de, #0
    ; ld  hl, #0
    ; rst 8
    ; .db 0x21

    ; ERAPI_SetBackgroundMode()
    ; a = mode (0-2)
    ld a, #0
    rst 0
    .db ERAPI_SetBackgroundMode

    ; create a global text region that all screens will use
    ; (3,1) -> (27, 16) (in tiles)
    ; ERAPI_CreateRegion()
    ; h = bg# (0-3)
    ; l = palette bank (0-15)
    ; d = left
    ; e = top
    ; b = width
    ; c = height
    ld  de, #0x0301
    ld  bc, #0x180f
    ld  hl, #0x0000
    rst 0
    .db ERAPI_CreateRegion
    ld  (handle_text_region), a

    ; ERAPI_SetBackgroundPalette()
    ; hl = pointer to palette data
    ; de = offset
    ; c  = number of colors
    ld  c, #0x03
    ld  de, #0x00
    ld  hl, #palette
    rst 0
    .db ERAPI_SetBackgroundPalette

    ; ERAPI_SpriteCreate()
    ; e  = pal#
    ; hl = sprite data
    ld  e, #0xf
    ld  hl, #sprite_arrow
    rst 0
    .db ERAPI_SpriteCreate
    ld  (handle_arrow_r), hl

    ; ERAPI_SpriteCreate()
    ; e  = pal#
    ; hl = sprite data
    ld  e, #0xe
    ld  hl, #sprite_arrow
    rst 0
    .db ERAPI_SpriteCreate
    ld  (handle_arrow_l), hl

    ; ERAPI_SpriteMirrorToggle()
    ; hl = handle
    ; de = mirror, 1: horizontal, 2: vertical, 3: both
    ld   hl, (handle_arrow_l)
    ld   de, #1
    rst  0
    .db  ERAPI_SpriteMirrorToggle

    ret

main_exit:
    ; ERAPI_Exit()
    ; a = return value (1=restart 2=exit)
    ld  a, #2
    rst 8
    .db ERAPI_Exit

main_load_main_menu:
    ld hl, #main_menu_frame
    ld (_main_mode_frame_fn), hl
    call main_menu_init

    ; ERAPI_FadeIn()
    ; a = number of frames
    xor a
    rst 0
    .db ERAPI_FadeIn

    ret

    ;--------------;
    ; *** DATA *** ;
    ;--------------;

    .even 
palette:
    ; transparent, black, white
    .dw 0x0000, 0x0000, 0xffff

tiles_arrow:
    .include "arrow.sprite.raw.asm"

palette_arrow:
    .include "arrow.sprite.pal.asm"

sprite_arrow:
    .dw #tiles_arrow   ; tiles
    .dw #palette_arrow ; palette
    .db 0x01          ; width
    .db 0x01          ; height
    .db 0x02          ; frames
    .db 0x00          ; ?
    .db 0x00          ; ?
    .db 0x00          ; ?
    .db 0x00          ; ?

    ;-------------------;
    ; *** VARIABLES *** ;
    ;-------------------;

;; private
_main_mode_frame_fn:
    .ds 2
;; global
handle_arrow_l:
    .ds 2
handle_arrow_r:
    .ds 2
handle_text_region:
    .ds 1

    .even
    .include "itoa.asm"
    .even
    .include "input.asm"
    .even
    .include "main_menu.asm"
    .even
    .include "submenu.asm"
    .even
    .include "backgrounds.asm"
    .even
    .include "sounds.asm"
    .even
    .include "sprites.asm"