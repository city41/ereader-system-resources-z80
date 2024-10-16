;; the backgrounds submenu

    MIN_BACKGROUND = 1
    MAX_BACKGROUND = 101

backgrounds_init:
    ld  a, #MIN_BACKGROUND
    ld (_backgrounds_cur_background), a

    ; ERAPI_LoadSystemBackground()
    ; a = index (1-101)
    ; e = bg# (0-3)
    ld  e, #1
    rst 0
    .db ERAPI_LoadSystemBackground


    call submenu_init_arrows
    call backgrounds_draw_text

    ; ERAPI_PlaySystemSound()
    ; hl=sound number
    ld hl, #82
    rst 8
    .db ERAPI_PlaySystemSound

    ret

backgrounds_frame:
    call submenu_frame
    ld a, c

    ; did the user do nothing?
    cp 0
    ret z

    cp #0x11
    jr nz, backgrounds_frame__skip_exit
    call backgrounds_cleanup
    call main_load_main_menu
    ret

backgrounds_frame__skip_exit:
    ;; if we got here, either the user went left or right
    ld a, (_backgrounds_cur_background)
    ;; c will either be 1 or -1
    add a, c
    cp #(MIN_BACKGROUND - 1)
    jr nz, backgrounds_frame__skip_wrap_to_top
    ld a, #MAX_BACKGROUND

backgrounds_frame__skip_wrap_to_top:
    cp #(MAX_BACKGROUND + 1)
    jr nz, backgrounds_frame__skip_wrap_to_bottom
    ld a, #MIN_BACKGROUND
    
backgrounds_frame__skip_wrap_to_bottom:
    ; save the new index
    ld (_backgrounds_cur_background), a
    ; and finally, load it
    ; ERAPI_LoadSystemBackground()
    ; a = index (1-101)
    ; e = bg# (0-3)
    ld  e, #1
    rst 0
    .db ERAPI_LoadSystemBackground
    call backgrounds_draw_text
    ret

backgrounds_draw_text:
    ; first clear the region, as the changing background id
    ; will cause overlapping text if we don't do this
    ; ERAPI_ClearRegion()
    ; a = handle
    ld  a, (handle_text_region)
    rst 0
    .db ERAPI_ClearRegion

    ld a, (_backgrounds_cur_background)

    ld b, 0
    ld c, a
    ld hl, #_backgrounds_background_number
    ;; convert the current background id into a string
    ;; the conversion will happen in the correct spot
    ;; so DrawText can just do its thing below
    call itoa

    ; make sure the text is white
    ; ERAPI_SetTextColor()
    ; a = handle
    ; d = foreground color
    ; e = background color
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
    ld  bc, #_backgrounds_background_text
    ld  de, #0x3b09 ; x = 59px, y = 9px
    rst 0
    .db ERAPI_DrawText
    ret


backgrounds_cleanup:
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
    ld hl, #82
    rst 8
    .db ERAPI_PauseSound

    ret


    .even
_backgrounds_cur_background:
    .ds 1

    .even
_backgrounds_background_text:
    .ascii 'Background: '
_backgrounds_background_number:
    .ascii '000\0'