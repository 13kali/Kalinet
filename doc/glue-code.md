# Writing the glue code

Collapse OS's kernel code is loosely knit. It supplies parts that you're
expected to glue together in a "glue code" asm file. Here is what a minimal
glue code for a shell on a Classic [RC2014][rc2014] with an ACIA link would
look like:


    ; The RAM module is selected on A15, so it has the range 0x8000-0xffff
    .equ	RAMSTART	0x8000
    .equ	RAMEND		0xffff
    .equ	ACIA_CTL	0x80	; Control and status. RS off.
    .equ	ACIA_IO		0x81	; Transmit. RS on.

    jp	init

    ; interrupt hook
    .fill	0x38-$
    jp	aciaInt

    .inc "err.h"
    .inc "ascii.h"
    .inc "core.asm"
    .inc "parse.asm"
    .equ	ACIA_RAMSTART	RAMSTART
    .inc "acia.asm"

    .equ	STDIO_RAMSTART	ACIA_RAMEND
    .equ	STDIO_GETC	aciaGetC
    .equ	STDIO_PUTC	aciaPutC
    .inc "stdio.asm"

    .equ	SHELL_RAMSTART	STDIO_RAMEND
    .equ	SHELL_EXTRA_CMD_COUNT 0
    .inc "shell.asm"

    init:
        di
        ; setup stack
        ld	hl, RAMEND
        ld	sp, hl
        im 1

        call	aciaInit
        call	shellInit
        ei
        jp	shellLoop

Once this is written, building it is easy: 

    zasm < glue.asm > collapseos.bin

## Building zasm

Collapse OS has its own assembler written in z80 assembly. We call it
[zasm][zasm]. Even on a "modern" machine, it is that assembler that is used,
but because it is written in z80 assembler, it needs to be emulated (with
[libz80][libz80]).

So, the first step is to build zasm. Open `tools/emul/README.md` and follow
instructions there.

## Platform constants

The upper part of the code contains platform-related constants, information
related to the platform you're targeting. You might want to put it in an
include file if you're writing multiple glue code that targets the same machine.

In all cases, `RAMSTART` are necessary. `RAMSTART` is the offset at which
writable memory begins. This is where the different parts store their
variables.

`RAMEND` is the offset where writable memory stop. This is generally
where we put the stack, but as you can see, setting up the stack is the
responsibility of the glue code, so you can set it up however you wish.

`ACIA_*` are specific to the `acia` part. Details about them are in `acia.asm`.
If you want to manage ACIA, you need your platform to define these ports.

## Header code

Then comes the header code (code at `0x0000`), a task that also is in the glue
code's turf. `jr init` means that we run our `init` routine on boot.

`jp aciaInt` at `0x38` is needed by the `acia` part. Collapse OS doesn't dictate
a particular interrupt scheme, but some parts might. In the case of `acia`, we
require to be set in interrupt mode 1.

## Includes

This is the most important part of the glue code and it dictates what will be
included in your OS. Each part is different and has a comment header explaining
how it works, but there are a couple of mechanisms that are common to all.

### Defines

Parts can define internal constants, but also often document a "Defines" part.
These are constant that are expected to be set before you include the file.

See comment in each part for details.

### RAM management

Many parts require variables. They need to know where in RAM to store these
variables. Because parts can be mixed and matched arbitrarily, we can't use
fixed memory addresses.

This is why each part that needs variable define a `<PARTNAME>_RAMSTART`
constant that must be defined before we include the part.

Symmetrically, each part define a `<PARTNAME>_RAMEND` to indicate where its
last variable ends.

This way, we can easily and efficiently chain up the RAM of every included part.

### Tables grafting

A mechanism that is common to some parts is "table grafting". If a part works
on a list of things that need to be defined by the glue code, it will place a
label at the very end of its source file. This way, it becomes easy for the
glue code to "graft" entries to the table. This approach, although simple and
effective, only works for one table per part. But it's often enough.

For example, to define extra commands in the shell:

    [...]
    .equ    SHELL_EXTRA_CMD_COUNT 2
    #include "shell.asm"
    .dw myCmd1, myCmd2
    [...]

### Initialization

Then, finally, comes the `init` code. This can be pretty much anything really
and this much depends on the part you select. But if you want a shell, you will
usually end it with `shellLoop`, which never returns.

[rc2014]: https://rc2014.co.uk/
[zasm]: ../tools/emul/README.md
[libz80]: https://github.com/ggambetta/libz80
