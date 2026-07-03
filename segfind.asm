; ---------------------------------------------------------------------------
;                                                                           ;
;  File:        segfind.asm                                                 ;
;  Purpose:     Prints out the DGROUP value.                                ;
;  Remarks:     - Compiled as COM: nasm -f bin segfind.asm -o SEGFIND.COM   ;
;               - Our exploit relies on the load base, which is different   ;
;                 between DOSBox and DOSBox-X, for example.                 ;
;               - To use the exploit, use --dgroup 0x(value).               ;
;                                                                           ;
; ---------------------------------------------------------------------------
bits 16
org 0x100

    ; Get the section and add the offset
    mov     ax, cs
    add     ax, 0x2a2b      ; Offset of DGROUP

    ; Prepare the hexadecimal buffer
    mov     di, hexbuf
    mov     cx, 4

.h:

    ; Translates the value to printable characters
    rol     ax, 4
    mov     bl, al
    and     bl, 0x0f
    cmp     bl, 10
    jb      .d
    add     bl, 'A'-10
    jmp     .p

.d:

    ; Handles digits
    add     bl, '0'

.p:

    ; Add the value to the hexadecimal buffer
    mov     [di], bl
    inc     di
    loop    .h

    ; Prints out the buffer
    mov     ah, 0x09
    mov     dx, msg
    int     0x21
    mov     ah, 0x08
    int     0x21
    mov     ax, 0x4c00
    int     0x21

; ---------------------------------------------------------------------------
;                                                                           ;
;  Data "section"                                                           ;
;                                                                           ;
; ---------------------------------------------------------------------------
penx    dw 0                                        ; X coordinate
msg     db 13,10,'DGROUP = 0x'                      ; Message header
hexbuf  db '0000'                                   ; Hexadecimal buffer
        db 13,10,$                                  ; Message footer
