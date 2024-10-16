;;
;; Ensures the arrows are in the upper corners
;; ready to be used by a submenu
;;
submenu_init_arrows:
    ;; show the left arrow
    ; ERAPI_SpriteShow()
    ; hl = sprite data
    ld   hl, (handle_arrow_l)
    rst  0
    .db  ERAPI_SpriteShow

    ; ERAPI_SetSpritePos()
    ; hl = handle
    ; de = x
    ; bc = y
    ld   hl, (handle_arrow_l)
    ld   de, #20
    ld   bc, #20
    rst  0

    .db  ERAPI_SetSpritePos
    ; ERAPI_SetSpritePos()
    ; hl = handle
    ; de = x
    ; bc = y
    ld   hl, (handle_arrow_r)
    ld   de, #220
    ld   bc, #20
    rst  0
    .db  ERAPI_SetSpritePos
    ret

;;
;; reads input and lets the caller know
;; ff: player chose to go left
;;  0: player chose nothing
;;  1: player chose to go right
;; 11: player chose to exit
;; 22: player chose to invoke the current item
;;
;; the return value is in c
submenu_frame:
    ld hl, (input_just_pressed)

    ld a, l
    and #ERAPI_KEY_B
    jr z, submenu_frame__skip_b
    ld c, #0x11
    jr submenu_frame__done
    
submenu_frame__skip_b:
    ld a, l
    and #ERAPI_KEY_A
    jr z, submenu_frame__skip_a
    ld c, #0x22
    jr submenu_frame__done

submenu_frame__skip_a:
    ld a, h
    and #ERAPI_KEY_L
    jr z, submenu_frame__skip_l
    ld c, #0xff
    call submenu_menu_move
    jr submenu_frame__done

submenu_frame__skip_l:
    ld a, h
    and #ERAPI_KEY_R
    jr z, submenu_frame__skip_r
    ld c, #0x1
    call submenu_menu_move

submenu_frame__skip_r:
submenu_frame__done:
    ret

submenu_menu_move:
    ld a, c
    cp #0x1
    jr nz, submenu_menu_move__skip_load_right_handle
    ld hl, (handle_arrow_r)
    jr submenu_move__handle_loaded

submenu_menu_move__skip_load_right_handle:
    ld hl, (handle_arrow_l)

submenu_move__handle_loaded:
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
    push bc
    ld de, 10
    ld bc, 12
    rst 0
    .db ERAPI_SpriteAutoAnimate
    pop bc

    ; ERAPI_PlaySystemSound()
    ; hl=sound number
    ld hl, #65
    rst 8
    .db ERAPI_PlaySystemSound
    ret

