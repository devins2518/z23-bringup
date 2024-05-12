#target ROM
#code _EPROM, 0x0000, *

NCS_CNTRL_ADDR equ 0xFF80
SDI_CNTRL_ADDR equ 0xFF81
SCL_CNTRL_ADDR equ 0xFF82
NCS_ACCESS_ADDR equ 0xFF90
SDI_ACCESS_ADDR equ 0xFF91
SCL_ACCESS_ADDR equ 0xFF92

.org 0x1000, 0x00
_start:
    ; Set all spi pins to output
    ld hl, NCS_CNTRL_ADDR
    ld (hl), 0xFF ; NCS
    inc hl
    ld (hl), 0xFF ; SDI
    inc hl
    ld (hl), 0xFF ; SCL
    ; Set idle values
    ld hl, NCS_ACCESS_ADDR
    ld (hl), 0xFF ; NCS, idle 1
    inc hl
    ld (hl), 0x00 ; SDI, idle 0
    inc hl
    ld (hl), 0x00 ; SCL, idle 0
_main:
    ; Set up the oled
    ld de, 0x0038 ; Set 8 bit data, english font table
    call _send_spi_cmd
    ld de, 0x0008 ; Turn display off
    call _send_spi_cmd
    ld de, 0x0001 ; Clear display
    call _send_spi_cmd
    ld de, 0x0006 ; Auto increment ddram address
    call _send_spi_cmd
    ld de, 0x0002 ; Return to home
    call _send_spi_cmd
    ld de, 0x000C ; Turn display on
    call _send_spi_cmd
    ld e, 'a'
    call _send_spi_data
_done:
    halt

; Expected to put wait value in b before calling
_nano_wait:
    push bc
_nano_wait_wait:
    djnz _nano_wait_wait
_nano_wait_done:
    pop bc
    ret

; Sends lsb of A on SDI
_send_bit:
    ; push hl
    ; push bc
    ld hl, SDI_ACCESS_ADDR
    ld (hl), a ; Set bit on sdi
    ld b, 0xFF
    call _nano_wait ; Wait before pulsing clock
    inc hl
    ld (hl), 1
    call _nano_wait ; Wait before causing falling edge
    ld (hl), 0
    call _nano_wait ; Wait a bit after we send the data
    pop bc
    pop hl
    ret

; Send data to the oled through SPI. Value should be in lower 10 bits of de
_send_dword:
    ; push hl
    ; Rotate bit 10 to bit 15
    rl e \ rl d
    rl e \ rl d
    rl e \ rl d
    rl e \ rl d
    rl e \ rl d
    rl e \ rl d
    ld hl, NCS_ACCESS_ADDR
    ld (hl), 0 ; Activate nCS
    ld c, 0xA
_send_dword_loop:
    ld a, d
    rla ; Rotate bit 7 to carry
    rla ; Rotate carry to bit 0
    call _send_bit ; Send bit 7 from d to _send_bit
    rl e ; Rotate e once, puts bit 7 into carry
    rl d ; Rotate d once, taking carry into bit 0
    dec c
    jr nz, _send_dword_loop
    ld (hl), 0xFF ; Set nCS to idle 
    ; pop hl
    ret

_send_spi_cmd:
    call _send_dword
    ld b, 0xFF
    call _nano_wait
    ret

; Data should be in e
_send_spi_data:
    ld d, 0x2
    call _send_spi_cmd

.org 0x2000, 0x00
END
