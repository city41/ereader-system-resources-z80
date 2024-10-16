;; the sounds submenu

    MIN_SOUND = 0
    MAX_SOUND = 884

sounds_init:
    ld hl, 0
    ld (_sounds_cur_sound), hl


    call sounds_init_backgrounds
    call submenu_init_arrows
    call sounds_draw_text

    ret

sounds_init_backgrounds:
    ;; bg 3,
    ;; id 60
    ;; offset y: 45
    ;; autoscroll x: 20

    ; ERAPI_LoadSystemBackground()
    ; a = index (1-101)
    ; e = bg# (0-3)
    ld a, 60
    ld e, #3
    rst 0
    .db ERAPI_LoadSystemBackground

    ; ERAPI_SetBackgroundOffset()
    ; a  = bg# (0-3)
    ; de = x
    ; bc = y
    ld  a, #3
    ld  de, #0
    ld  bc, #45
    rst 0
    .db ERAPI_SetBackgroundOffset

    ; ERAPI_SetBackgroundAutoScroll()
    ; a  = bg# (0-3
    ; de = x
    ; bc = y
    ld  a, #3
    ld  de, #20
    ld  bc, #0
    rst 0
    .db ERAPI_SetBackgroundAutoScroll

    ;; bg 2,
    ;; id 21
    ;; offset y: 0
    ;; autoscroll x: 40

    ; ERAPI_LoadSystemBackground()
    ; a = index (1-101)
    ; e = bg# (0-3)
    ld a, 21
    ld e, #2
    rst 0
    .db ERAPI_LoadSystemBackground

    ; ERAPI_SetBackgroundOffset()
    ; a  = bg# (0-3)
    ; de = x
    ; bc = y
    ld  a, #2
    ld  de, #0
    ld  bc, #0
    rst 0
    .db ERAPI_SetBackgroundOffset

    ; ERAPI_SetBackgroundAutoScroll()
    ; a  = bg# (0-3)
    ; de = x
    ; bc = y
    ld  a, #2
    ld  de, #40
    ld  bc, #0
    rst 0
    .db ERAPI_SetBackgroundAutoScroll

    ;; bg 1,
    ;; id 8
    ;; offset y: -55
    ;; autoscroll x: 80

    ; ERAPI_LoadSystemBackground()
    ; a = index (1-101)
    ; e = bg# (0-3)
    ld a, 8
    ld e, #1
    rst 0
    .db ERAPI_LoadSystemBackground

    ; ERAPI_SetBackgroundOffset()
    ; a  = bg# (0-3)
    ; de = x
    ; bc = y
    ld  a, #1
    ld  de, #0
    ld  bc, #-55
    rst 0
    .db ERAPI_SetBackgroundOffset

    ; ERAPI_SetBackgroundAutoScroll()
    ; a  = bg# (0-3)
    ; de = x
    ; bc = y
    ld  a, #1
    ld  de, #80
    ld  bc, #0
    rst 0
    .db ERAPI_SetBackgroundAutoScroll

    ret



sounds_frame:
    call submenu_frame

    ld a, c

    ; did the user do nothing?
    cp 0
    ret z

    cp #0x11
    jr nz, sounds_frame__skip_exit
    call sounds_cleanup
    call main_load_main_menu
    ret

sounds_frame__skip_exit:
    ;; TODO: need to check for 16 bit wrapping
    ;; this is a little tedious as the z80 can only compare 8bit numbers

    ;; if we got here, either the user went left or right
    ; load the current sound index
    ld hl, (_sounds_cur_sound)
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

    ;; now wrap if needed, z80 offers no 16 bit comparisons, so we need
    ;; to roll our own
    ld bc, #(MIN_SOUND - 1)
    call cp16
    jr nz, sounds_frame__skip_wrap_to_top
    ld hl, MAX_SOUND
    jr sounds_frame__done_wrapping

sounds_frame__skip_wrap_to_top:
    ld bc, #(MAX_SOUND + 1)
    call cp16
    jr nz, sounds_frame__done_wrapping
    ld hl, MIN_SOUND

sounds_frame__done_wrapping:
    ; save the new index
    ld (_sounds_cur_sound), hl
    ; and finally, play it
    ; ERAPI_PlaySystemSound()
    ; hl=sound number
    rst 8
    .db ERAPI_PlaySystemSound
    call sounds_draw_text
    ret

; draws the current sound id to the screen
sounds_draw_text:
    ; first clear the region, as the changing sound id
    ; will cause overlapping text if we don't do this
    ; ERAPI_ClearRegion()
    ; a = handle
    ld  a, (handle_text_region)
    rst 0
    .db ERAPI_ClearRegion

    ld hl, (_sounds_cur_sound)
    ld b, h
    ld c, l
    ld hl, #_sounds_sound_number
    ;; convert the current sound id into a string
    ;; the conversion will happen in the correct spot
    ;; so DrawText can just do its thing below
    call itoa

    ; make sure the text is white
    ; ERAPI_SetTextColor()
    ; a = handle
    ; d = foreground color
    ; e = sound color
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
    ld  bc, #_sounds_sound_text
    ld  de, #0x3b09 ; x = 59px, y = 9px
    rst 0
    .db ERAPI_DrawText
    ret


sounds_cleanup:
    ; clean up the three backgrounds
    ld  de, #0
    ld  bc, #0
    ld a, #3
    rst 0
    .db ERAPI_SetBackgroundOffset
    rst 0
    .db ERAPI_SetBackgroundAutoScroll
    ld a, #2
    rst 0
    .db ERAPI_SetBackgroundOffset
    rst 0
    .db ERAPI_SetBackgroundAutoScroll
    ld a, #1
    rst 0
    .db ERAPI_SetBackgroundOffset
    rst 0
    .db ERAPI_SetBackgroundAutoScroll


    ; ERAPI_FadeOut()
    ; a = duration in frames
    ld a, #50
    rst 0
    .db ERAPI_FadeOut

    ; ; now wait for the fade out to finish
    ; ; how long to wait should be in a, 
    ; ; which it already is
    .db 0x76
    ret

;; does a 16 bit comparison between bc and hl
;; the result will be in the z flag as usual
cp16:
    ;; first compare the high byte
    ld a, b
    cp h
    ;; if they are not the same, then we are done comparing
    ret nz

    ;; they are the same, so compare lower byte
    ld a, c
    cp l
    ret

    .even
_sounds_sound_text:
    .ascii 'Sound: '
_sounds_sound_number:
    .ascii '000\0'
    .even
_sounds_cur_sound:
    .ds 2