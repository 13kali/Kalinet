; USER_CODE is filled in on-the-fly with either ED_CODE or ZASM_CODE
.equ    ED_CODE         0x1900
.equ    ZASM_CODE       0x1d00
.equ    USER_RAMSTART   0xc200
.equ    FS_HANDLE_SIZE  6
.equ    BLOCKDEV_SIZE   8
; Make ed fit in SMS's memory
.equ    ED_BUF_MAXLINES 0x100
.equ    ED_BUF_PADMAXLEN 0x800

; Make zasm fit in SMS's memory
.equ	ZASM_REG_MAXCNT		0x80
.equ	ZASM_LREG_MAXCNT	0x10
.equ	ZASM_REG_BUFSZ		0x800
.equ	ZASM_LREG_BUFSZ		0x100

; *** JUMP TABLE ***
.equ	strncmp			0x03
.equ	addDE			0x06
.equ	addHL			0x09
.equ	upcase			0x0c
.equ	unsetZ			0x0f
.equ	intoDE			0x12
.equ	intoHL			0x15
.equ	writeHLinDE		0x18
.equ	findchar		0x1b
.equ	parseHex		0x1e
.equ	parseHexPair	0x21
.equ	blkSel			0x24
.equ	blkSet			0x27
.equ	fsFindFN		0x2a
.equ	fsOpen			0x2d
.equ	fsGetB			0x30
.equ	fsPutB			0x33
.equ	fsSetSize		0x36
.equ	cpHLDE			0x39
.equ	parseArgs		0x3c
.equ	printstr		0x3f
.equ	_blkGetB		0x42
.equ	_blkPutB		0x45
.equ	_blkSeek		0x48
.equ	_blkTell		0x4b
.equ	printcrlf		0x4e
.equ	stdioPutC		0x51
.equ	stdioReadLine	0x54

