;; itoa
;; ----
;; takes the number in bc and converts into an ascii string,
;; written to where hl points. At most the number can have
;; three digits
;; the written string will add a null terminator after the final digit
;;
;; only works with up to three digits
;; only works with positive numbers
;; only works with integers

;; here is the implementation in javascript
;
; function itoa(n) {
;   let result = '';

;   const hundredsDigit = Math.floor(n/100);

;   if (hundredsDigit !== 0) {
;     result += String.fromCharCode(hundredsDigit + 48)
;     n -= hundredsDigit * 100;
;   }
  
;   const tensDigit = Math.floor(n/10);

;   if (tensDigit !== 0 || hundredsDigit !== 0) {
;     result += String.fromCharCode(tensDigit + 48);
;     n -= tensDigit * 10;
;   }

;   result += String.fromCharCode(n + 48);

;   return result;
; }
;
;
; WARNING: this code is brutal. This was not easy as a z80 newb
;
itoa:
    ;; save off all registers
    push af
    push bc
    push de

    push hl ; store the pointer on the stack

    ;; hundreds digit

    ;; first start by saying there was not a hundreds digit
    ;; if there was, this will get updated 
    ;; whether we output tens, even if it is zero, depends on this
    ld a, 1
    ld (_itoa_hundreds_is_zero), a


    ;; divide by 100 to get hundreds digit
    ;; hl <- bc
    ld h, b
    ld l, c
    ld de, 100
    rst 8
    ;; hl = hl / de
    .db ERAPI_Div
    ;; hl is now bc / 100, which will fit in a assuming bc was 999 or less
    ld a, l

    cp 0
    ;; if the hundreds digit is zero, jump ahead to do tens
    jr z, itoa__skip_hundreds

    push af ;; need to save a as it will soon get clobbered

    ;; there was a hundreds digit, we need to note that incase tens is zero
    ld a, 0
    ld (_itoa_hundreds_is_zero), a

    ;; need to make bc = bc - hundredsDigit*100 so we can do the tens digit
    ;; hl is already the hundreds digit, and de is already 100
    rst 8
    ;; hl = hl*de
    .db ERAPI_Mul16

    call itoa_sub_hl_from_bc

    pop af ;; restore a

    ;; the hundreds digit needs to be added to the string
    pop hl
    ;; a is the hundreds digit
    add a, #48  ; from binary to ascii for a single digit
    ld (hl), a  ; write to the string
    inc hl  ; move hl to point to the next byte
    push hl     ; store new pointer back on stack

itoa__skip_hundreds:

    ;; tens digit

    ;; divide by 10 to get tens digit
    ;; hl <- bc
    ld h, b
    ld l, c
    ld de, 10
    rst 8
    .db ERAPI_Div
    ;; hl is now bc / 10, which will fit in a, assuming bc was 99 or less

    ld a, l

    ;; if the tens digit is zero, we might skip, but might not
    ;; we don't skip if the hundreds digit was non-zero
    cp 0
    jr z, itoa__see_if_skip_tens
    ;; tens wasnt zero, so output it no matter what
    jr itoa__do_tens

itoa__see_if_skip_tens:
    ;; tens was zero, only output it if hundreds was *not* zero
    ld h, a ; save a into h temporarily
    ld a, (_itoa_hundreds_is_zero)
    cp 1
    ld a, h
    jr z, itoa__skip_tens

itoa__do_tens:
    push af ;; need to save a as it will soon get clobbered

    ;; need to make bc = bc - tensDigit*10 so we can do the tens digit
    ;; hl is already the hundreds digit, and de is already 100
    rst 8
    .db ERAPI_Mul16

    ;; sbc doesn't seem to work on the z80 emulator
    ;; so need to do 16 bit subtraction manually
    call itoa_sub_hl_from_bc

    pop af ; restore a

    ;; the tens digit needs to be added to the string
    pop hl
    ;; a is the tens digit
    add a, #48  ; from binary to ascii for a single digit
    ld (hl), a  ; write to the string
    inc hl  ; move hl to point to the next byte
    push hl     ; store new pointer back on stack

itoa__skip_tens:

    ;; ones digit

    ;; this one is simpler, just write it to the string
    ;; at this point bc should be less than 10
    ld a, c

    ;; the ones digit needs to be added to the string
    pop hl
    add a, #48  ; from binary to ascii for a single digit
    ld (hl), a  ; write to the string
    inc hl  ; move hl to point to the next byte
    push hl     ; store new pointer back on stack

    ;; write the null terminator
    ld (hl), 0

    ;; finally pop hl back to what it was
    pop hl

    ;; restore all the registers
    pop de
    pop bc
    pop af

    ret


;; seems on the e-reader's z80 emulator, sbc only works for 8 bit registers
;; I'm hopefully just doing something wrong, but for now, doing 16bit subtraction manually
itoa_sub_hl_from_bc:
    or a ; clear the carry flag

    ld a, c
    sbc a, l

    jr nc, itoa_sub_hl_from_bc__skip_carry
    ;; the carry flag was set, so need to pull the borrow from the high byte
    dec b

itoa_sub_hl_from_bc__skip_carry:
    ld c, a

    ld a, b
    sbc a,h

    ret

_itoa_hundreds_is_zero:
    .ds 1