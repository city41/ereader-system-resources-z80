;; the sprites submenu

    MIN_SPRITE = 1
    ;; TODO: what is the max sprite?
    MAX_SPRITE = 244

sprites_init:
    ld hl, 0
    ld (_sprites_system_sprite_handle), hl
    ld hl, MIN_SPRITE
    ld (_sprites_cur_sprite), hl

    ld d, h
    ld e, l
    call sprites_load_sprite
    call submenu_init_arrows
    call sprites_draw_text

    ; ERAPI_PlaySystemSound()
    ; hl=sound number
    ld hl, #93
    rst 8
    .db ERAPI_PlaySystemSound

    ; ERAPI_LoadSystemBackground()
    ; a = index (1-101)
    ; e = bg# (0-3)
    ld a, 70
    ld  e, #1
    rst 0
    .db ERAPI_LoadSystemBackground

    ret

sprites_frame:
    call submenu_frame
    ld a, c

    ;; did the user do nothing?
    cp 0
    ret z

    cp #0x11
    jr nz, sprites_frame__skip_exit
    call sprites_cleanup
    call main_load_main_menu
    ret

sprites_frame__skip_exit:
    ;; if we got here, either the user went left or right
    ld hl, (_sprites_cur_sprite)

sprites_frame__delta_cur_sprite:
    ;; c will either be 1 or ff
    ;; which is -1 when dealing with 8 bits, but this is 16
    ;; sign extending into de with this trick
    ;; https://stackoverflow.com/a/49076303/194940
    ld a, c
    ld e, a
    add a, a
    sbc a, a
    ld d, a

    ;; now take the sign extended value and add to hl
    ;; this will either inc or dec hl
    add hl, de

    ;; now check if we need to wrap. The sprite id needs to be in de for
    ;; ERAPI calls, but it is always 8 bit, so luckily we can move to a
    ld a, l
    cp #(MIN_SPRITE - 1)
    jr nz, sprites_frame__skip_wrap_to_top
    ld l, MAX_SPRITE
    jr sprites_frame__done_wrapping

sprites_frame__skip_wrap_to_top:
    cp #(MAX_SPRITE + 1)
    jr nz, sprites_frame__done_wrapping
    ld l, MIN_SPRITE

sprites_frame__done_wrapping:
    ;; is this a valid sprite?
    ; ERAPI_SystemSpriteIdIsValid()
    ; de = sprite index
    ; ret in a, 0 = invalid, 1 = valid
    ld d, h
    ld e, l
    rst 0
    .db ERAPI_SystemSpriteIdIsValid
    cp 0 ; 0 = invalid, 1 = valid
    ; if it wasn't valid, just go back and delta again until it is
    jr z, sprites_frame__delta_cur_sprite

    ld (_sprites_cur_sprite), hl

    call sprites_free_sprite
    
    ; and finally, load it
    call sprites_load_sprite
    call sprites_draw_text

    ret

;; de=sprite id to load
sprites_load_sprite:
    ; ERAPI_CreateSystemSprite()
    ; de = index (1-101)
    ; de is already loaded at this point
    rst 0
    .db ERAPI_CreateSystemSprite
    ld (_sprites_system_sprite_handle), hl

    ; ERAPI_SetSpritePos()
    ; hl = handle
    ; de = x
    ; bc = y
    ; hl is already the handle
    ld   de, #120
    ld   bc, #80
    rst  0
    .db  ERAPI_SetSpritePos
    ret

; draws the current sprite id to the screen
sprites_draw_text:
    ; first clear the region, as the changing sprite id
    ; will cause overlapping text if we don't do this
    ; ERAPI_ClearRegion()
    ; a = handle
    ld  a, (handle_text_region)
    rst 0
    .db ERAPI_ClearRegion

    ld hl, (_sprites_cur_sprite)
    ld b, h
    ld c, l
    ld hl, #_sprites_sprite_number
    ;; convert the current sprite id into a string
    ;; the conversion will happen in the correct spot
    ;; so DrawText can just do its thing below
    call itoa

    ; make sure the text is white
    ; ERAPI_SetTextColor()
    ; a = handle
    ; d = foreground color
    ; e = sprite color
    ld  a, (handle_text_region)
    ld  de, #0x0200
    rst 0
    .db ERAPI_SetTextColor

    ; ERAPI_DrawText()
    ; a  = handle
    ; bc = pointer to text
    ; d  = x in pixels
    ; e  = y in pixels
    ld  a, (handle_text_region)
    ld  bc, #_sprites_sprite_text
    ld  de, #0x3b09 ; x = 59px, y = 9px
    rst 0
    .db ERAPI_DrawText
    ret

sprites_free_sprite:
    ; free the existing sprite
    ld hl, (_sprites_system_sprite_handle)
    rst 0
    .db ERAPI_SpriteFree
    ret

sprites_cleanup:
    ; ERAPI_FadeOut()
    ; a = duration in frames
    ld a, #50
    rst 0
    .db ERAPI_FadeOut

    ; ; now wait for the fade out to finish
    ; ; how long to wait should be in a, 
    ; ; which it already is
    .db 0x76

    ; ERAPI_PauseSound()
    ; hl=sound number
    ld hl, #93
    rst 8
    .db ERAPI_PauseSound

    call sprites_free_sprite

    ret

    .even
_sprites_cur_sprite:
    .ds 2

    .even
_sprites_sprite_text:
    .ascii 'sprite: '
_sprites_sprite_number:
    .ascii '000\0'
_sprites_system_sprite_handle:
    .dw 2
_sprites_have_loaded_a_system_sprite:
    .dw 1