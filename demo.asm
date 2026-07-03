; ---------------------------------------------------------------------------
;                                                                           ;
;  File:        demo.asm                                                    ;
;  Purpose:     Civilization 1 .MAP shellcode.                              ;
;  Remarks:     - Runs in real mode.                                        ;
;               - Assemble using nasm: nasm -f bin demo.asm -o demo.bin     ;
;                                                                           ;
; ---------------------------------------------------------------------------
bits 16
org 0xC92A                       ; Shellcode lands on DGROUP:0xC92A

; VGA mode
VGA equ 0xA000

; --------------------------------------------------------------------------;
;                                                                           ;
;  Routine:    start                                                        ;
;  Purpose:    Main routine - currently does a "synthwave" demo.            ;
;                                                                           ;
; ---------------------------------------------------------------------------
start:

    ; Set up VGA video mode
    mov     ax, 0x0013
    int     0x10

    ; Copy 8x8 BIOS font to the font buffer
    mov     ax, 0x1130
    mov     bh, 3
    int     0x10                 ; ES:BP = font
    push    ds
    mov     ax, es
    mov     ds, ax
    mov     si, bp
    push    cs
    pop     es
    mov     di, fontbuf
    mov     cx, 1024
    rep     movsw
    pop     ds

    ; VGA prep
    mov     ax, VGA
    mov     es, ax

    ; Sky rows (0 to 99) use palette [16..28] gradient
    xor     di, di
    xor     bx, bx

.sky:
    
    ; Prepare rows and palette
    mov     al, bl
    shr     al, 3
    add     al, 16
    mov     cx, 320
    rep     stosb
    inc     bx
    cmp     bx, 100
    jb      .sky

    ; Ground rows (100 to 199) use dark purple (1)
    mov     al, 1
    mov     cx, 320 * 100
    rep     stosb

    ; Retro sun - a circle center at (160, 74) with a radius of 34 and a gradient [32..47]
    mov     bx, 40               ; y = 74-34

.suny:
    
    ; Sun Y coordinate iteration
    xor     cx, cx

.sunx:

    ; Sun X coordinate iteration
    mov     ax, cx
    sub     ax, 160
    imul    ax, ax
    mov     si, bx
    sub     si, 74
    mov     dx, si
    imul    dx, dx
    add     ax, dx
    cmp     ax, 34*34
    ja      .suns
    mov     al, bl
    sub     al, 40
    shr     al, 1
    add     al, 32               ; 32 to 47
    cmp     bx, 74
    jb      .sunp
    test    bl, 2
    jnz     .sunp
    mov     al, 1                ; Dark stripe

.sunp:

    ; VGA memory direct write
    mov     di, bx
    imul    di, 320
    add     di, cx
    mov     [es:di], al

.suns:

    ; Sun end of iteration
    inc     cx
    cmp     cx, 320
    jb      .sunx
    inc     bx
    cmp     bx, 108
    jb      .suny

    ; Grid horizontals with color=40
    mov     bx, 100
    mov     bp, 1

.hz:

    ; Horizontal lines start of iteration
    mov     di, bx
    imul    di, 320
    mov     al, 40
    mov     cx, 320
    rep     stosb
    add     bx, bp
    mov     ax, bp
    shr     ax, 2
    inc     ax
    add     bp, ax
    cmp     bx, 200
    jb      .hz

    ; Grid verticals that converge to (160, 100) with color=40
    mov     si, -13

.vk:

    ; Vertical lines start of iteration
    mov     bx, 100

.vy:

    ; Vertical lines Y coordinate iteration
    mov     ax, bx
    sub     ax, 99
    imul    ax, si
    sar     ax, 2
    add     ax, 160
    cmp     ax, 0
    jl      .vn
    cmp     ax, 320
    jge     .vn
    mov     di, bx
    imul    di, 320
    add     di, ax
    mov     byte [es:di], 40

.vn:

    ; Vertical lines end of iteration
    inc     bx
    cmp     bx, 200
    jb      .vy
    inc     si
    cmp     si, 14
    jl      .vk
    call    set_palette

    ; Draw the text
    mov     si, msg1
    mov     word [penx], 40
    mov     word [peny], 22
    mov     bl, 15
    call    draw_string
    mov     si, msg2
    mov     word [penx], 60
    mov     word [peny], 34
    mov     bl, 14
    call    draw_string

    ; Animate neon grid (color 40 green sawtooth)
    xor     bp, bp

.loop:

    ; Looping animation
    mov     dx, 0x03DA

.l1:

    ; Loop part 1
    in      al, dx
    test    al, 8
    jnz     .l1

.l2:

    ; Loop part 2
    in     al, dx
    test    al, 8
    jz      .l2
    mov     dx, 0x03C8
    mov     al, 40
    out     dx, al
    inc     dx
    mov     al, 0x3f
    out     dx, al               ; Red
    mov     ax, bp
    and     al, 0x3f
    out     dx, al               ; Green pulse
    mov     al, 0x30
    out     dx, al               ; Blue
    inc     bp
    jmp     .loop

; --------------------------------------------------------------------------;
;                                                                           ;
;  Routine:    draw_string                                                  ;
;  Purpose:    Draws a string.                                              ;
;  Parameters: - SI: the NUL-terminated string.                             ;
;              - BL: the color to use.                                      ;
;              - [penx]: the X coordinate.                                  ;
;              - [peny]: the Y coordinate.                                  ;
;  Remarks:    - Uses the "fontbuf" font buffer.                            ;
;                                                                           ;
; ---------------------------------------------------------------------------
draw_string:

    ; VGA prep
    mov     ax, VGA
    mov     es, ax

.ch:

    ; Load the next character and refer to the font buffer
    lodsb
    test    al, al
    jz      .done
    mov     ah, 0
    mov     di, ax
    shl     di, 3
    add     di, fontbuf
    xor     bh, bh

.row:

    ; Calculate row
    mov     al, bh
    xor     ah, ah
    add     ax, [peny]
    imul    ax, 320
    add     ax, [penx]
    mov     bp, ax
    mov     dl, [di]
    inc     di
    mov     cx, 8

.bit:

    ; Handle current bit
    shl     dl, 1
    jnc     .nb
    mov     [es:bp], bl

.nb:

    ; End of iteration
    inc     bp
    loop    .bit
    inc     bh
    cmp     bh, 8
    jb      .row
    add     word [penx], 8
    jmp     .ch

.done:

    ; Return from routine
    ret

; --------------------------------------------------------------------------;
;                                                                           ;
;  Routine:    set_palette                                                  ;
;  Purpose:    Sets the palette for the demo.                               ;
;  Remarks:    - Uses many color constants and assumptions about the demo.  ;
;                                                                           ;
; ---------------------------------------------------------------------------
set_palette:

    ; Prepare sky (16 to 28)
    mov     cx, 13
    xor     bx, bx

.sky:

    ; Sky color iteration
    mov     dx, 0x03C8
    mov     al, 16
    add     al, bl
    out     dx, al
    inc     dx
    mov     al, bl
    add     al, 10
    out     dx, al
    mov     al, bl
    shr     al, 1
    out     dx, al
    mov     al, bl
    add     al, 24
    cmp     al, 63
    jbe     .skb
    mov     al, 63

.skb:

    ; Sky output
    out     dx, al
    inc     bx
    loop    .sky

    ; Prepare sun (32 to 47)
    mov     cx, 16
    xor     bx, bx

.sun:

    ; Sun color iteration
    mov     dx, 0x03C8
    mov     al, 32
    add     al, bl
    out     dx, al
    inc     dx
    mov     al, 63
    out     dx, al
    mov     al, 58
    sub     al, bl
    sub     al, bl
    sub     al, bl
    out     dx, al
    mov     al, bl
    add     al, bl
    out     dx, al
    inc     bx
    loop    .sun

    ; Set 1 as ground purple
    mov     dx, 0x03C8
    mov     al, 1
    out     dx, al
    inc     dx
    mov     al, 14
    out     dx, al
    xor     al, al
    out     dx, al
    mov     al, 22
    out     dx, al

    ; Set 40 as neon magenta
    mov     dx, 0x03C8
    mov     al, 40
    out     dx, al
    inc     dx
    mov     al, 63
    out     dx, al
    mov     al, 8
    out     dx, al
    mov     al, 48
    out     dx, al

    ; Set 14 as cyan
    mov     dx, 0x03C8
    mov     al, 14
    out     dx, al
    inc     dx
    mov     al, 24
    out     dx, al
    mov     al, 63
    out     dx, al
    mov     al, 63
    out     dx, al
    mov     al, 63
    out     dx, al
    mov     al, 63
    out     dx, al
    mov     al, 63
    out     dx, al
    ret

; ---------------------------------------------------------------------------
;                                                                           ;
;  Data "section"                                                           ;
;                                                                           ;
; ---------------------------------------------------------------------------
penx    dw 0                                        ; X coordinate
peny    dw 0                                        ; Y coordinate
msg1    db 'Pwn by Jonathan Bar Or ("JBO")', 0      ; Message part 1
msg2    db 'https://jonathanbaror.com', 0           ; Message part 2
align 2
fontbuf: times 2048 db 0                            ; Font buffer
