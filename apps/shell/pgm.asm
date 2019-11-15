; pgm - execute programs loaded from filesystem
;
; Implements a shell hook that searches the filesystem for a file with the same
; name as the cmd, loads that file in memory and executes it, sending the
; program a pointer to *unparsed* arguments in HL.
;
; We expect the loaded program to return a status code in A. 0 means success,
; non-zero means error. Programs should avoid having error code overlaps with
; the shell so that we know where the error comes from.
;
; *** Requirements ***
; fs
;
; *** Defines ***
; PGM_CODEADDR: Memory address where to place the code we load.
;
; *** Variables ***
.equ	PGM_HANDLE	PGM_RAMSTART
.equ	PGM_RAMEND	@+FS_HANDLE_SIZE

; Routine suitable to plug into SHELL_CMDHOOK. HL points to the full cmdline.
; which has been processed to replace the first ' ' with a null char.
pgmShellHook:
	; (HL) is suitable for a direct fsFindFN call
	call	fsFindFN
	jr	nz, .noFile
	; We have a file! Advance HL to args
	xor	a
	call	findchar
	inc	hl		; beginning of args
	; Alright, ready to run!
	jp	.run
.noFile:
	ld	a, SHELL_ERR_IO_ERROR
	ret
.run:
	push	hl		; unparsed args
	ld	ix, PGM_HANDLE
	call	fsOpen
	ld	hl, 0		; addr that we read in file handle
	ld	de, PGM_CODEADDR	; addr in mem we write to
.loop:
	call	fsGetB		; we use Z at end of loop
	ld	(de), a		; Z preserved
	inc	hl		; Z preserved in 16-bit
	inc	de		; Z preserved in 16-bit
	jr	z, .loop

	pop	hl		; recall args
	; ready to jump!
	jp	PGM_CODEADDR
