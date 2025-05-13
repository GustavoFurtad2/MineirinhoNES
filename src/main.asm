.include "header.inc"
.include "constants.inc"

.segment "ZEROPAGE"
  playerX: .res 1
  playerY: .res 1
  pad1: .res 1
  playerDirection: .res 1
  playerIsWalking: .res 1
  playerIsThrowingHat: .res 1
  hatIsReturning: .res 1
  hatOffsetX: .res 1
  hatOffsetY: .res 1
  hatOffsetLimitX: .res 1
  playerHealth: .res 1
  numberToDraw: .res 1
  numberX: .res 1
  numberY: .res 1
  remainder: .res 1
  digit1: .res 1
  digit2: .res 1

.segment "CODE"

.proc irq_handler
  RTI
.endproc

.proc nmi_handler

  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA

  JSR updatePads

  JSR updatePlayer
  JSR drawGame

  LDA #$00
  STA $2005
  STA $2005

  PLA
  TAY
  PLA
  TAX
  PLA
  PLP



  RTI
.endproc

.proc reset_handler

  LDA #$00
  STA digit1
  LDA #$05
  STA digit2
  
  LDA #$80
  STA playerX
  LDA #$10
  STA playerY

  LDA #$03
  STA playerHealth

  SEI
  CLD
  LDX #$40
  STX $4017
  LDX #$FF
  TXS
  INX
  STX $2000
  STX $2001
  STX $4010
  BIT $2002
vblankwait:
  BIT $2002
  BPL vblankwait
vblankwait2:
  BIT $2002
  BPL vblankwait2
  JMP main
.endproc

.proc main

  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$10
  STX PPUADDR

  LDX #$00
  
loadPalletes:

  LDA palettes, X
  STA PPUDATA

  INX
  CPX #$10
  BNE loadPalletes

  LDX #$00

loadSprites:

  LDA sprites, X
  STA $0200, X
  INX
  CPX #$34
  BNE loadSprites

vblankwait:

  BIT PPUSTATUS
  BPL vblankwait
                
  LDA #%10010000
  STA PPUCTRL
  LDA #%00011110
  STA PPUMASK

forever:
  JMP forever
.endproc

.proc updatePads

  PHA
  TXA
  PHA
  PHP

  LDA #$01
  STA CONTROLLER1
  LDA #$00
  STA CONTROLLER1

  LDA #%00000001
  STA pad1

getButtonStates:

  LDA CONTROLLER1
  LSR A 
  ROL pad1 

  BCC getButtonStates
  
  PLP
  PLA
  TAX
  PLA
  RTS
.endproc

.proc updatePlayer

  LDA pad1
  AND #BUTTON_LEFT
  BNE pressingLeft

  LDA pad1
  AND #BUTTON_RIGHT
  BNE pressingRight

  LDA #$00
  STA playerIsWalking

  JMP continue

pressingLeft:

  DEC playerX

  LDA #$01
  STA playerIsWalking

  LDA #$00
  STA playerDirection

  JMP continue

pressingRight:

  INC playerX

  LDA #$01
  STA playerIsWalking

  STA playerDirection

continue:

.endproc

.proc drawGame

  ; face
  LDA playerY
  STA $0200

  LDA #FACE_TILE
  STA $0201

  LDX playerDirection
  CPX #$00
  BEQ invertFace

  LDA #%00000001

  JMP continueConfigFace

invertFace:

  LDA #%01000001

continueConfigFace:

  STA $0202

  LDA playerX
  STA $0203

  ; head

  LDA playerY
  STA $0204
  
  LDA #HEAD_TILE
  STA $0205

  LDX playerDirection
  CPX #$00
  BEQ invertHead

  LDA #%00000000

  JMP continueConfigHead

invertHead:

  LDA #%01000000

continueConfigHead:

  STA $0206

  LDA playerX
  STA $0207

  ; hat

  LDA playerY
  CLC
  ADC hatOffsetY
  STA $0208
  
  LDA #HAT_TILE
  STA $0209

  LDA #$03
  STA $020A

  LDA playerX
  CLC
  ADC hatOffsetX
  CLC
  ADC #$01
  STA $020B

  ; cloth detail 2

  LDA playerY
  CLC 
  ADC #$08
  STA $020C
  
  LDA #CLOTH_DETAIL_2_TILE
  STA $020D

  LDX playerDirection
  CPX #$00
  BEQ invertClothDetail2

  LDA #%00000011

  JMP continueDrawClothDetail2

invertClothDetail2:

  LDA #%01000011

continueDrawClothDetail2:

  STA $020E

  LDA playerX
  STA $020F

  ; cloth detail 1

  LDA playerY
  CLC 
  ADC #$07
  STA $0210
  
  LDA #CLOTH_DETAIL_1_TILE
  STA $0211

  LDX playerDirection
  CPX #$00
  BEQ invertClothDetail1

  LDA #%00000001

  JMP continueDrawClothDetail1

invertClothDetail1:

  LDA #%01000001

continueDrawClothDetail1:

  STA $0212

  LDA playerX
  STA $0213

  ; cloth

  LDA playerY
  CLC 
  ADC #$07
  STA $0214
  
  LDA #CLOTH_TILE
  STA $0215

  LDA #$00
  STA $0216

  LDA playerX
  STA $0217

  ; boots

  LDA playerY
  CLC 
  ADC #$12
  STA $0218
  
  LDA #BOOTS_TILE
  STA $0219

  LDX playerDirection
  CPX #$00
  BEQ invertBoots

  LDA #%00000010

  JMP continueDrawBoots

invertBoots:

  LDA #%01000010

continueDrawBoots:

  STA $021A

  LDA playerX
  STA $021B

  ; pants

  LDA playerY
  CLC 
  ADC #$0E
  STA $021C
  
  LDA #PANTS_TILE
  STA $021D

  LDA #$03
  STA $021E

  LDA playerX
  STA $021F

  LDX playerIsWalking
  CPX #$01
  BEQ drawFlexedArms


drawArms:

  ; arm 1

  LDA playerY
  CLC
  ADC #$08
  STA $0220
  
  LDA #ARM_TILE
  STA $0221

  LDA #$00
  STA $0222

  LDA playerX
  SEC
  SBC #$08
  STA $0223

  ; arm 2

  LDA playerY
  CLC
  ADC #$08
  STA $0224
  
  LDA #ARM_TILE
  STA $0225

  LDA #%01000000
  STA $0226

  LDA playerX
  CLC
  ADC #$08
  STA $0227

  JMP drawHUD

drawFlexedArms:

  ; arm 1

  LDX playerDirection
  CPX #$00
  BEQ configFlexedArm1Y

  LDA playerY
  CLC
  ADC #$08

  JMP continueSetupFlexedArm1Y

configFlexedArm1Y:

  LDA playerY
  CLC
  ADC #$03

continueSetupFlexedArm1Y:
  STA $0220
  
  LDA #FLEXED_ARM_TILE
  STA $0221

  LDX playerDirection
  CPX #$00
  BEQ invertFlexedArm1

  LDA #%00000000

  JMP continueDrawFlexedArm1

invertFlexedArm1:

  LDA #%10000000

continueDrawFlexedArm1:
  STA $0222

  LDA playerX
  SEC
  SBC #$08
  STA $0223

  ; arm 2

  LDX playerDirection
  CPX #$00
  BEQ configFlexedArm2Y

  LDA playerY
  CLC
  ADC #$03

  JMP continueSetupFlexedArm2Y

configFlexedArm2Y:

  LDA playerY
  CLC
  ADC #$08

continueSetupFlexedArm2Y:

  STA $0224
  
  LDA #FLEXED_ARM_TILE
  STA $0225

  LDX playerDirection
  CPX #$00
  BEQ invertFlexedArm2

  LDA #%11000000

  JMP continueDrawFlexedArm2

invertFlexedArm2:
  
  LDA #%01000000

continueDrawFlexedArm2:

  STA $0226

  LDA playerX
  CLC
  ADC #$08
  STA $0227

drawHUD:

  LDA #$0A
  STA $0228
  
  LDA #HEART_TILE
  STA $0229

  LDA #$01
  STA $022A

  LDA #$02
  STA $022B

drawPlayerHealth:

  ; digit 1

  LDX digit1
  CPX #$00
  BEQ configDigit2XOneDigit

  LDA #$0A
  STA $022C

  LDX digit1
  CPX #$06
  BCC digit1LessThan6
  BEQ digit1Equals6

; digit1BiggerThan6

  CLC
  LDA #NUMBER_0_TILE
  ADC digit1
  SEC
  SBC #$01
  STA $022D

  LDA #$00
  STA $022E

  JMP continueConfigDigit1

digit1Equals6:

  LDA #NUMBER_9_TILE
  STA $022D

  LDA #%11000000
  STA $022E

  JMP continueConfigDigit1

digit1LessThan6:  
    
  CLC
  LDA #NUMBER_0_TILE
  ADC digit1
  STA $022D

  LDA #$00
  STA $022E

continueConfigDigit1:

  LDA #$0B
  STA $022F

  JMP configDigit2XTwoDigits

configDigit2XOneDigit:

  LDA #$0B
  STA $0233

  LDA #$FE
  STA $022C

  JMP drawDigit2

configDigit2XTwoDigits:

  LDA #$12
  STA $0233

drawDigit2:
  
  LDA #$0A
  STA $0230

  LDX digit2
  CPX #$06
  BCC digit2LessThan6
  BEQ digit2Equals6

; digit1BiggerThan6

  CLC
  LDA #NUMBER_0_TILE
  ADC digit2
  SEC
  SBC #$01
  STA $0231

  LDA #$00
  STA $0232

  JMP continueConfigDigit2

digit2Equals6:

  LDA #NUMBER_9_TILE
  STA $0231

  LDA #%11000000
  STA $0232

  JMP continueConfigDigit2

digit2LessThan6:
    
  CLC
  LDA #NUMBER_0_TILE
  ADC digit2
  STA $0231

  LDA #$00
  STA $0232

continueConfigDigit2:

  LDA #$0A
  STA $0230

exitSubrotine:
  RTS
.endproc

.proc incrementPlayerHealth

  INC digit2
  LDA digit2
  CMP #$09
  BCC exitSubrotine
  LDA #$00
  STA digit2
  INC digit1

exitSubrotine:

  RTS
.endproc

.proc decrementPlayerHealth

  LDA digit2
  BEQ adjustTo9

  DEC digit2
  JMP exitSubrotine

adjustTo9:

  LDA #$09
  STA digit2
  DEc digit1

exitSubrotine:

  RTS
.endproc

.segment "VECTORS"
  .addr nmi_handler, reset_handler, irq_handler

.segment "RODATA"

sprites:

  .byte $70, $04, $00, $80
  .byte $70, $05, $00, $80
  .byte $70, $06, $00, $80
  .byte $70, $07, $00, $80
  .byte $70, $08, $00, $80
  .byte $70, $09, $00, $80
  .byte $70, $0A, $00, $80
  .byte $70, $0B, $00, $80
  .byte $70, $0C, $00, $80
  .byte $70, $0D, $00, $80
  .byte $70, $0E, $00, $80
  .byte $FE, $0F, $00, $00
  .byte $FE, $0F, $00, $00

palettes:

  .byte $29, $36, $20, $28
  .byte $29, $11, $15, $1D
  .byte $29, $19, $20, $01
  .byte $29, $06, $26, $15

  ; .byte $29, $1D, $27
  ; .byte $29, $36, $27, $30
  ; .byte $29, $19, $20, $21
  ; .byte $29, $06, $26, $15

.segment "CHR"
.incbin "game.chr"