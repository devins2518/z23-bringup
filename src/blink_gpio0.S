#target ROM
#code _EPROM, 0x0000, *
.org 0x1000, 0x00

GPIO_CNTRL_ADDR equ 0xFF80
GPIO_ACCESS_ADDR equ 0xFF90

_start:
    ld hl, GPIO_CNTRL_ADDR
    ld (hl), 0xFF ; enable gpio 0
    ld hl, GPIO_ACCESS_ADDR
    ld (hl), 0xFF ; set gpio 0
    ld d, 0xFF
_loop:
    ld a, (hl)
    cpl
    ld (hl), a
    ld b, 0x4
_wait:
    djnz _wait
    dec d
    jp z, _done
    jp _loop
_done:
    halt

.org 0x2000, 0x00
END
