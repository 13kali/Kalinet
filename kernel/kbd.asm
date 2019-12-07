; kbd - implement GetC for PS/2 keyboard
;
; It reads raw key codes from a FetchKC routine and returns, if appropriate,
; a proper ASCII char to type. See recipes rc2014/ps2 and sms/kbd.
;
; *** Defines ***
; Pointer to a routine that fetches the last typed keyword in A. Should return
; 0 when nothing was typed.
; KBD_FETCHKC

; *** Consts ***
.equ	KBD_KC_BREAK	0xf0
.equ	KBD_KC_EXT	0xe0
.equ	KBD_KC_LSHIFT	0x12
.equ	KBD_KC_RSHIFT	0x59

; *** Variables ***
; Set to previously received scan code
.equ	KBD_PREV_KC	KBD_RAMSTART
; Whether Shift key is pressed
.equ	KBD_SHIFT_ON	KBD_PREV_KC+1
.equ	KBD_RAMEND	KBD_SHIFT_ON+1

kbdInit:
	xor	a
	ld	(KBD_PREV_KC), a
	ld	(KBD_SHIFT_ON), a
	ret

kbdGetC:
	call	KBD_FETCHKC
	or	a
	jr	z, .nothing

	; scan code not zero, maybe we have something.
	; Do we need to skip it?
	ex	af, af'		; save fetched KC
	ld	a, (KBD_PREV_KC)
	; Whatever the KC, the new A becomes our prev. The easiest way to do
	; this is to do it now.
	ex	af, af'		; restore KC
	ld	(KBD_PREV_KC), a
	ex	af, af'		; restore prev KC
	; If F0 (break code) or E0 (extended code), we skip this code
	cp	KBD_KC_BREAK
	jr	z, .break
	cp	KBD_KC_EXT
	jr	z, .ignore
	ex	af, af'		; restore saved KC
	cp	0x80
	jr	nc, .ignore
	; No need to skip, code within bounds, we have something!
	call	.isShift
	jr	z, .shiftPressed
	; Let's see if there's a ASCII code associated to it.
	push	hl		; --> lvl 1
	ld	hl, KBD_SHIFT_ON
	bit	0, (hl)
	ld	hl, kbdScanCodes	; no flag changed
	jr	z, .shiftNotPressed
	; Shift is being pressed. Use Shifted table.
	ld	hl, kbdScanCodesS
.shiftNotPressed:
	call	addHL
	ld	a, (hl)
	pop	hl		; <-- lvl 1
	or	a
	jr	z, kbdGetC	; no code. Keep A at 0, but unset Z
	; We have something!
	cp	a		; ensure Z
	ret
.shiftPressed:
	ld	a, 1
	ld	(KBD_SHIFT_ON), a
	jr	.ignore		; to actual char to return
.break:
	ex	af, af'		; restore saved KC
	call	.isShift
	jr	nz, .ignore
	; We had a shift break, update status
	xor	a
	ld	(KBD_SHIFT_ON), a
	; continue to .ignore
.ignore:
	; A scan code over 0x80 is out of bounds or prev KC tell us we should
	; skip. Ignore.
	xor	a
	jr	kbdGetC
.nothing:
	; We have nothing. Before we go further, we'll wait a bit to give our
	; device the time to "breathe". When we're in a "nothing" loop, the z80
	; hammers the device really fast and continuously generates interrupts
	; on it and it interferes with its other task of reading the keyboard.
	push	bc
	ld	b, 0
.wait:
	nop
	djnz	.wait
	pop	bc
	jr	kbdGetC
; Whether KC in A is L or R shift
.isShift:
	cp	KBD_KC_LSHIFT
	ret	z
	cp	KBD_KC_RSHIFT
	ret

; A list of the values associated with the 0x80 possible scan codes of the set
; 2 of the PS/2 keyboard specs. 0 means no value. That value is a character than
; can be read in a GetC routine. No make code in the PS/2 set 2 reaches 0x80.
kbdScanCodes:
; 0x00    1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
.db   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  9,'`',  0
; 0x10 9 = TAB
.db   0,  0,  0,  0,  0,'q','1',  0,  0,  0,'z','s','a','w','2',  0
; 0x20 32 = SPACE
.db   0,'c','x','d','e','4','3',  0,  0, 32,'v','f','t','r','5',  0
; 0x30
.db   0,'n','b','h','g','y','6',  0,  0,  0,'m','j','u','7','8',  0
; 0x40 59 = ;
.db   0,',','k','i','o','0','9',  0,  0,'.','/','l', 59,'p','-',  0
; 0x50 13 = RETURN 39 = '
.db   0,  0, 39,  0,'[','=',  0,  0,  0,  0, 13,']',  0,'\',  0,  0
; 0x60 8 = BKSP
.db   0,  0,  0,  0,  0,  0,  8,  0,  0,'1',  0,'4','7',  0,  0,  0
; 0x70 27 = ESC
.db '0','.','2','5','6','8', 27,  0,  0,  0,'3',  0,  0,'9',  0,  0

; Same values, but shifted
kbdScanCodesS:
; 0x00    1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
.db   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  9,'~',  0
; 0x10 9 = TAB
.db   0,  0,  0,  0,  0,'Q','!',  0,  0,  0,'Z','S','A','W','@',  0
; 0x20 32 = SPACE
.db   0,'C','X','D','E','$','#',  0,  0, 32,'V','F','T','R','%',  0
; 0x30
.db   0,'N','B','H','G','Y','^',  0,  0,  0,'M','J','U','&','*',  0
; 0x40 59 = ;
.db   0,'<','K','I','O',')','(',  0,  0,'>','?','L',':','P','_',  0
; 0x50 13 = RETURN
.db   0,  0,'"',  0,'{','+',  0,  0,  0,  0, 13,'}',  0,'|',  0,  0
; 0x60 8 = BKSP
.db   0,  0,  0,  0,  0,  0,  8,  0,  0,  0,  0,  0,  0,  0,  0,  0
; 0x70 27 = ESC
.db   0,  0,  0,  0,  0,  0, 27,  0,  0,  0,  0,  0,  0,  0,  0,  0
