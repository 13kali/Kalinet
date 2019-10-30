; classic RC2014 setup (8K ROM + 32K RAM) and a stock Serial I/O module
; The RAM module is selected on A15, so it has the range 0x8000-0xffff
.equ	RAMSTART	0x8000
.equ	RAMEND		0xffff
.equ	PGM_CODEADDR	0x9000
.equ	ACIA_CTL	0x80	; Control and status. RS off.
.equ	ACIA_IO		0x81	; Transmit. RS on.

jp	init	; 3 bytes

; *** Jump Table ***
jp	printstr
jp	sdcWaitResp
jp	sdcCmd
jp	sdcCmdR1
jp	sdcCmdR7
jp	sdcSendRecv

; interrupt hook
.fill	0x38-$
jp	aciaInt

.inc "err.h"
.inc "core.asm"
.inc "parse.asm"
.equ	ACIA_RAMSTART	RAMSTART
.inc "acia.asm"
.equ	BLOCKDEV_RAMSTART	ACIA_RAMEND
.equ	BLOCKDEV_COUNT		2
.inc "blockdev.asm"
; List of devices
.dw	sdcGetB, sdcPutB
.dw	blk2GetB, blk2PutB


.equ	STDIO_RAMSTART	BLOCKDEV_RAMEND
.inc "stdio.asm"

.equ	FS_RAMSTART	STDIO_RAMEND
.equ	FS_HANDLE_COUNT	1
.inc "fs.asm"

.equ	SHELL_RAMSTART		FS_RAMEND
.equ	SHELL_EXTRA_CMD_COUNT	11
.inc "shell.asm"
.dw	sdcInitializeCmd, sdcFlushCmd
.dw	blkBselCmd, blkSeekCmd, blkLoadCmd, blkSaveCmd
.dw	fsOnCmd, flsCmd, fnewCmd, fdelCmd, fopnCmd

.inc "blockdev_cmds.asm"
.inc "fs_cmds.asm"

.equ	PGM_RAMSTART		SHELL_RAMEND
.inc "pgm.asm"

.equ	SDC_RAMSTART	PGM_RAMEND
.equ	SDC_PORT_CSHIGH	6
.equ	SDC_PORT_CSLOW	5
.equ	SDC_PORT_SPI	4
.inc "sdc.asm"

init:
	di
	; setup stack
	ld	hl, RAMEND
	ld	sp, hl
	im	1
	call	aciaInit
	ld	hl, aciaGetC
	ld	de, aciaPutC
	call	stdioInit
	call	fsInit
	call	shellInit
	ld	hl, pgmShellHook
	ld	(SHELL_CMDHOOK), hl

	xor	a
	ld	de, BLOCKDEV_SEL
	call	blkSel

	ei
	jp	shellLoop

; *** blkdev 2: file handle 0 ***

blk2GetB:
	ld	ix, FS_HANDLES
	jp	fsGetB

blk2PutB:
	ld	ix, FS_HANDLES
	jp	fsPutB
