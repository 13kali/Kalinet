; memt
;
; Write all possible values in all possible addresses that follow the end of
; this program. That means we don't test all available RAM, but well, still
; better than nothing...
;
; If there's an error, prints out where.
;
; *** Requirements ***
; printstr
; printHexPair
;
; *** Includes ***

.inc "user.h"
jp	memtMain

.inc "memt/main.asm"
USER_RAMSTART:
