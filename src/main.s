.segment "HEADER"
  ; .byte "NES", $1A      ; iNES header identifier
  .byte $4E, $45, $53, $1A
  .byte 2               ; 2x 16KB PRG code
  .byte 1               ; 1x  8KB CHR data
  .byte $01, $00        ; mapper 0, vertical mirroring

.export Main

.segment "CODE"

  .proc Main
    ; Começa carregando o valor 5 no registrador X e Y
    ldx #5
    ldy #5

    ; Aumenta o valor de X duas vezes
    inx
    inx

    ; Diminui o valor de X uma vez
    dex

    ; Diminui o valor de Y duas vezes
    dey
    dey

    ; Aumenta o valor de Y uma vez
    iny

    ; Ja que aumentamos 2 vezes e diminuimos
    ; uma vez no X, deve ser igual a 6
    ; Ja que diminuimos 2 vezes no Y e aumentamos
    ; uma vez, deve ser igual a 4
    rts
.endproc