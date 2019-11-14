; 8K of onboard RAM
.equ	RAMSTART	0xc000
; Memory register at the end of RAM. Must not overwrite
.equ	RAMEND		0xddd0

	jp	init

.fill 0x66-$
	retn

.inc "err.h"
.inc "ascii.h"
.inc "core.asm"
.inc "str.asm"
.inc "parse.asm"

.inc "sms/kbd.asm"
.equ	KBD_RAMSTART	RAMSTART
.equ	KBD_FETCHKC	smskbdFetchKCB
.inc "kbd.asm"

.equ	VDP_RAMSTART	KBD_RAMEND
.inc "sms/vdp.asm"

.equ	STDIO_RAMSTART	VDP_RAMEND
.equ	STDIO_GETC	kbdGetC
.equ	STDIO_PUTC	vdpPutC
.inc "stdio.asm"

.equ	SHELL_RAMSTART	STDIO_RAMEND
.equ	SHELL_EXTRA_CMD_COUNT 0
.inc "shell.asm"

init:
	di
	im	1

	ld	sp, RAMEND

	; Initialize the keyboard latch by "dummy reading" once. This ensures
	; that the adapter knows it can fill its '164.
	; Port B TH output, high
	ld	a, 0b11110111
	out	(0x3f), a
	nop
	; Port A/B reset
	ld	a, 0xff
	out	(0x3f), a

	call	kbdInit
	call	vdpInit
	call	shellInit
	jp	shellLoop

.fill 0x7ff0-$
.db "TMR SEGA", 0x00, 0x00, 0xfb, 0x68, 0x00, 0x00, 0x00, 0x4c

