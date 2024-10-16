    MENU_ITEM_BACKGROUNDS = 0
    MENU_ITEM_SOUNDS = 1
    MENU_ITEM_SPRITES = 2
    MENU_ITEM_COUNT = (MENU_ITEM_SPRITES + 1)

main_menu_init:
    ; ERAPI_LoadSystemBackground()
    ; a = index (1-101)
    ; e = bg# (0-3)
    ld  a, #24
    ld  e, #1
    rst 0
    .db ERAPI_LoadSystemBackground

    ; ERAPI_SetBackgroundAutoScroll()
    ; a  = bg# (0-3)
    ; de = x
    ; bc = y
    ld  a, #1
    ld  de, #0
    ld  bc, #0x0040
    rst 0
    .db ERAPI_SetBackgroundAutoScroll

    ;; init cursor to first menu item
    ld a, 0
    ld (main_menu_arrow_index), a

    call main_menu_init_draw_menu
    call main_menu_init_arrows

    ; ERAPI_PlaySystemSound()
    ; hl=sound number
    ld hl, #738
    rst 8
    .db ERAPI_PlaySystemSound

    ret

main_menu_frame:
    ;; runs one frame of the main menu
    ;; sets the user's chose in a
    ;; 0xf = user made no choice
    ;; 0,1,2... = user chose a menu item
    ld hl, (input_just_pressed)

    ld a, l
    and #ERAPI_KEY_A
    jr z, main_menu_frame__skip_a
    call main_menu_setup_for_submenu
    jr main_menu_frame__done

main_menu_frame__skip_a:
    ld a, l
    and #ERAPI_KEY_DOWN
    jr z, main_menu_frame__skip_down
    call main_menu_arrow_down
    call main_menu_arrow_sfx
    jr main_menu_frame__done

main_menu_frame__skip_down:
    ld a, l
    and #ERAPI_KEY_UP
    jr z, main_menu_frame__skip_up
    call main_menu_arrow_up
    call main_menu_arrow_sfx

main_menu_frame__skip_up:
main_menu_frame__done:
    ret

main_menu_arrow_down:
    ld a, (main_menu_arrow_index)
    inc a
    cp #MENU_ITEM_COUNT
    jr nz, main_menu_arrow_down__skip_wrap
    ld a, 0

main_menu_arrow_down__skip_wrap:
    ld (main_menu_arrow_index),a
    call main_menu_move_arrow
    ret


main_menu_arrow_up:
    ld a, (main_menu_arrow_index)
    dec a
    cp #0xff
    jr nz, main_menu_arrow_up__skip_wrap
    ld a, #(MENU_ITEM_COUNT - 1)

main_menu_arrow_up__skip_wrap:
    ld (main_menu_arrow_index),a
    call main_menu_move_arrow
    ret

main_menu_arrow_sfx:
    ; ERAPI_PlaySystemSound()
    ; hl=sound number
    ld hl, #65
    rst 8
    .db ERAPI_PlaySystemSound
    ret

main_menu_choice_sfx:
    ; ERAPI_PlaySystemSound()
    ; hl=sound number
    ld hl, #86
    rst 8
    .db ERAPI_PlaySystemSound
    ret

main_menu_highlight_arrow:
    ld hl, (handle_arrow_r)
    ld e, 1
    rst 0
    .db ERAPI_SetSpriteFrame

    ;; auto animate so the arrow returns to frame zero automatically
    ;; hl = sprite handle
    ;; de = sprite frame duration in system frames
    ;; bc =
    ;; bc: 0 = Start Animating Forever
    ;;     1 = Stop Animation
    ;;     2 > Number of frames to animate for -2 (ex. 12 animates for 10 frames)
    ld de, 10
    ld bc, 12
    rst 0
    .db ERAPI_SpriteAutoAnimate
    ret

main_menu_setup_for_submenu:
    ; the user has pressed A, so we will init the submenu
    ; then set the frame function pointer so main can run it
    ld a, (main_menu_arrow_index)
    cp 0
    jr nz, main_menu_setup_for_submenu__skip_backgrounds
    ; they want backgrounds
    ld hl, #backgrounds_init ; we'll call init just after the menu cleans up
    ld (main_menu_submenu_init_fn), hl
    ld hl, #backgrounds_frame
    ld (_main_mode_frame_fn), hl
    jp main_menu_setup_for_submenu__done

main_menu_setup_for_submenu__skip_backgrounds:
    cp 1
    jr nz, main_menu_setup_for_submenu__skip_sounds
    ;; they want sounds
    ld hl, #sounds_init ; we'll call init just after the menu cleans up
    ld (main_menu_submenu_init_fn), hl
    ld hl, #sounds_frame
    ld (_main_mode_frame_fn), hl
    jp main_menu_setup_for_submenu__done

main_menu_setup_for_submenu__skip_sounds:
    ;; by process of elimination they want sprites
    ld hl, #sprites_init ; we'll call init just after the menu cleans up
    ld (main_menu_submenu_init_fn), hl
    ld hl, #sprites_frame
    ld (_main_mode_frame_fn), hl

main_menu_setup_for_submenu__done:
    ;; since they are moving off to a submenu, time to cleanup
    call main_menu_highlight_arrow
    call main_menu_choice_sfx
    call main_menu_cleanup
    ld hl, (main_menu_submenu_init_fn)
    call main_menu_call_hl

    ; ERAPI_FadeIn()
    ; a = number of frames
    ld a, #50
    rst 0
    .db ERAPI_FadeIn
    ret

main_menu_call_hl:
    jp (hl)

;;
;; Draws the main menu's text
;;
main_menu_init_draw_menu:
    ; set the text to black, over in init we set the first
    ; palette to [transparent, black]
    ; we are using the first palette because in CreateRegion
    ; we specified l=0, ie palette 0

    ; ERAPI_SetTextColor()
    ; a = handle
    ; d = foreground color
    ; e = background color
    ld  a, (handle_text_region)
    ld  de, #0x0100
    rst 0
    .db ERAPI_SetTextColor

    ; draw "System Resources"
    ; ERAPI_DrawText()
    ; a  = handle
    ; bc = pointer to text
    ; d  = x in pixels
    ; e  = y in pixels
    ld  a, (handle_text_region)
    ld  bc, #main_menu_title_text
    ld  de, #0x3030 ; x = 48px, y = 48px
    rst 0
    .db ERAPI_DrawText

    ; draw "Backgrounds"
    ld  bc, #main_menu_backgrounds_text
    ld  de, #0x3046 ; x = 48px, y = 70px
    rst 0
    .db ERAPI_DrawText

    ; draw "Sounds"
    ld  bc, #main_menu_sounds_text
    ld  de, #0x3054 ; x = 48px, y = 84px
    rst 0
    .db ERAPI_DrawText

    ; draw "Sprites"
    ld  bc, #main_menu_sprites_text
    ld  de, #0x3062 ; x = 48px, y = 98px
    rst 0
    .db ERAPI_DrawText

    ret

;;
;; Gets the arrow sprites ready to be used by the main menu
;;
;; globals: handle_arrow_l, handle_arrow_r
main_menu_init_arrows:
    ;; hide the left arrow
    ; ERAPI_SpriteHide()
    ; hl = sprite data
    ld   hl, (handle_arrow_l)
    rst  0
    .db  ERAPI_SpriteHide

    ;; purposely falling through as init needs to also 
    ;; move the arrow to the correct location

main_menu_move_arrow:
    ;; move the right arrow to the correct spot based on arrow index
    ld a,(main_menu_arrow_index)

    MAIN_MENU_ARROW_OFFSET_X = 56
    MAIN_MENU_ARROW_OFFSET_Y = 81
    MAIN_MENU_ENTRY_SPACING = 14

    ; x is just the offset, as the menu is vertical
    ld   de, #MAIN_MENU_ARROW_OFFSET_X
    ; y needs to be incremented based on current value of main_menu_arrow_index
    push af  ; save a, need to push f too as push only works on 16bit registers
    push hl  ; save hl
    ld   hl, #MAIN_MENU_ARROW_OFFSET_Y  ; where we're going to build the value
    ld   bc, #MAIN_MENU_ENTRY_SPACING   ; how much to increment for each arrow index
main_menu_move_arrow__loop_y:
    cp 0  ; is a zero? then we are done
    jr z, main_menu_move_arrow__done_y
    add hl, bc ; move down one more entry's worth of pixels
    dec a
    jr main_menu_move_arrow__loop_y ; do it all over again

main_menu_move_arrow__done_y:
    ; hl into bc, but needs to be two steps as only 8 bit loads are allowed here
    ld b, h
    ld c, l
    pop hl ; restore hl
    pop af ; restore a

    ; ERAPI_SetSpritePos()
    ; hl = handle
    ; de = x
    ; bc = y
    ld   hl, (handle_arrow_r)
    rst  0
    .db  ERAPI_SetSpritePos

    ret

main_menu_cleanup:
    ; ERAPI_FadeOut()
    ; a = duration in frames
    ld a, #50
    rst 0
    .db ERAPI_FadeOut

    ; ; now wait for the fade out to finish
    ; ; how long to wait should be in a, 
    ; ; which it already is
    .db 0x76

    ; ERAPI_ClearRegion()
    ; a = handle
    ld  a, (handle_text_region)
    rst 0
    .db ERAPI_ClearRegion

    ; ERAPI_PauseSound()
    ; hl=sound number
    ld hl, #738
    rst 8
    .db ERAPI_PauseSound

    ; turn off auto scroll
    ; ERAPI_SetBackgroundAutoScroll()
    ; a  = bg# (0-3)
    ; de = x
    ; bc = y
    ld  a, #1
    ld  de, #0
    ld  bc, #0
    rst 0
    .db ERAPI_SetBackgroundAutoScroll

    ; put the background back to 0,0
    ; ERAPI_SetBackgroundOffset()
    ; a  = bg# (0-3)
    ; de = x
    ; bc = y
    ld  a, #1
    ld  de, #0
    ld  bc, #0
    rst 0
    .db ERAPI_SetBackgroundOffset
    ret

main_menu_title_text:
    .ascii 'System Resources\0'

main_menu_backgrounds_text:
    .ascii 'Backgrounds\0'

main_menu_sounds_text:
    .ascii 'Sounds\0'

main_menu_sprites_text:
    .ascii 'Sprites\0'

main_menu_arrow_index:
    .ds 1
main_menu_submenu_init_fn:
    .ds 2