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
  hatX: .res 1
  hatY: .res 1
  hatOffsetLimitX: .res 1
  playerThrowingHatDirection: .res 1
  playerHealth: .res 1
  numberToDraw: .res 1
  numberX: .res 1
  numberY: .res 1
  remainder: .res 1
  digit1: .res 1
  digit2: .res 1
  equippedItem: .res 1 ; 0 == hat
  gamestate: .res 1  ; 0 == menu, 1 == in game level 1
  playerWalkingAnimationCounter: .res 1
  playerWalkingAnimationFrame: .res 1

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

  JSR clearOAM

  LDA gamestate
  CMP #$01
  BEQ handleInGame

  JSR drawMenu
  JSR updateMenu

  JMP continue

handleInGame:

  JSR updatePlayer
  JSR drawGame

continue:

  JSR updatePads

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
  STA gamestate
  STA playerWalkingAnimationCounter
  STA playerWalkingAnimationFrame

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

  LDA menuPalettes, X
  STA PPUDATA

  INX
  CPX #$10
  BNE loadPalletes

  LDX #$00

loadSprites:

  LDA sprites, X
  STA $0200, X
  INX
  CPX #$FF
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

  LDA playerIsWalking
  CMP #$00
  BEQ checkIfPressingB

  LDA #$00
  STA playerIsWalking
  STA playerWalkingAnimationCounter
  STA playerWalkingAnimationFrame

  JMP checkIfPressingB

pressingLeft:

  LDA playerX
  CMP #$09
  BCC checkIfPressingB

  DEC playerX

  LDA #$01
  STA playerIsWalking

  LDA #$00
  STA playerDirection

  LDA playerWalkingAnimationCounter
  CLC
  ADC #$01
  STA playerWalkingAnimationCounter

  JMP checkIfPressingB

pressingRight:

  LDA playerX
  CMP #$F0
  BCS checkIfPressingB

  INC playerX

  LDA #$01
  STA playerIsWalking

  STA playerDirection

  LDA playerWalkingAnimationCounter
  CLC
  ADC #$01
  STA playerWalkingAnimationCounter

  JMP checkIfPressingB

checkIfPressingB:

  LDA pad1
  AND #BUTTON_B
  BNE pressingB

  JMP checkIfShouldUpdateHat

pressingB:

  LDA playerIsThrowingHat
  CMP #$01
  BEQ updateHat

  LDA #$01
  STA playerIsThrowingHat

  LDA playerDirection
  STA playerThrowingHatDirection

  LDA playerX
  STA hatX

  LDA playerY
  STA hatY

  LDA playerThrowingHatDirection
  CMP #$01
  BEQ setHatOffsetRight

setHatOffsetLeft:

  LDA playerX
  SEC
  SBC #$1E
  BPL storeLeftLimit
  LDA #$00

storeLeftLimit:

  STA hatOffsetX
  JMP updateHat

setHatOffsetRight:

  LDA playerX
  CLC
  ADC #$1E

  CMP #$F0
  BCC storeRightLimit

  LDA #$F0

storeRightLimit:

  STA hatOffsetX
  JMP updateHat

  JMP updateHat

checkIfShouldUpdateHat:

  LDA playerIsThrowingHat
  CMP #$01
  BEQ updateHat

  JMP exitSubrotine

updateHat:

  LDA hatIsReturning
  CMP #$01
  BEQ returnHat

  LDA hatX
  CMP hatOffsetX
  BEQ setHatToReturn

  LDA playerThrowingHatDirection
  CMP #$00
  BEQ moveHatLeft

  JMP moveHatRight

setHatToReturn:

  LDA #$01
  STA hatIsReturning

  JMP returnHat

returnHat:

  LDA hatX
  CMP playerX
  BEQ stopHat

  LDA hatX
  CMP playerX
  BCC moveHatRight
  BCS moveHatLeft

stopHat:

  LDA #$00
  STA playerIsThrowingHat
  STA hatIsReturning

  JMP exitSubrotine

moveHatLeft:

  LDA hatX
  SEC
  SBC #$02
  STA hatX

  JMP exitSubrotine

moveHatRight:

  LDA hatX
  CLC
  ADC #$02
  STA hatX

  JMP exitSubrotine

exitSubrotine:

  RTS
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

  LDX playerIsThrowingHat
  CPX #$01
  BEQ applyOffset

  LDA playerX
  STA $020B

  JMP continueConfigHat

applyOffset:

  LDA hatX
  STA $020B

continueConfigHat:

  LDA playerY
  STA $0208
  
  LDA #HAT_TILE
  STA $0209

  LDA #$03
  STA $020A

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


  LDA playerWalkingAnimationCounter
  CMP #$06
  BCS setWalkingBootsAnim1

  LDA playerY
  CLC 
  ADC #$12
  STA $0218


  LDA #BOOTS_TILE
  STA $0219

  JMP continueDrawBoots1

setWalkingBootsAnim1:

  LDA playerY
  CLC 
  ADC #$10
  STA $0218

  LDA playerWalkingAnimationCounter
  CMP #$12
  BCS setWalkingBootsAnim2

  LDA #RIGHT_FLEXED_BOOTS_TILE
  STA $0219

  JMP continueDrawBoots1

setWalkingBootsAnim2:

  LDA #LEFT_FLEXED_BOOTS_TILE
  STA $0219

  LDA playerWalkingAnimationCounter
  CMP #$18
  BNE continueDrawBoots1

  LDA #$00
  STA playerWalkingAnimationCounter

continueDrawBoots1:


  LDX playerDirection
  CPX #$00
  BEQ invertBoots

  LDA #%00000010

  JMP continueDrawBoots2

invertBoots:

  LDA #%01000010

continueDrawBoots2:

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

 ; draw inventory current item slot

  LDA #$0A
  STA $0234

  LDA #SLOT_TILE
  STA $0235

  LDA #$01
  STA $0236

  LDA #$F4
  STA $0237

  ; draw current equipped item

  LDA #$0A
  STA $0238
  
  LDA #HAT_ITEM_TILE
  STA $0239

  LDA #$03
  STA $023A

  LDA #$F4
  STA $023B


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
  DEC digit1

exitSubrotine:

  RTS
.endproc

.proc drawMenu

 LDA #$7C
 STA $0200

 LDA #LETTER_P_TILE
 STA $0201

 LDA #$02
 STA $0202

 LDA #$6C
 STA $0203

 LDA #$7C
 STA $0204

 LDA #LETTER_L_TILE
 STA $0205

 LDA #$02
 STA $0206

 LDA #$73
 STA $0207

 LDA #$7C
 STA $0208

 LDA #LETTER_A_TILE
 STA $0209

 LDA #$02
 STA $020A

 LDA #$7A
 STA $020B

 LDA #$7C
 STA $020C

 LDA #LETTER_Y_TILE
 STA $020D

 LDA #$02
 STA $020E

 LDA #$81
 STA $020F

 LDA #$2C
 STA $0210

 LDA #TITLE_MINEIRINHO_1
 STA $0211

 LDA #$01
 STA $0212

 LDA #$5F
 STA $0213

 LDA #$2C
 STA $0214

 LDA #TITLE_MINEIRINHO_2
 STA $0215

 LDA #$01
 STA $0216

 LDA #$67
 STA $0217

 LDA #$2C
 STA $0218

 LDA #TITLE_MINEIRINHO_3
 STA $0219

 LDA #$01
 STA $021A

 LDA #$6F
 STA $021B
 
 LDA #$2C
 STA $021C

 LDA #TITLE_MINEIRINHO_4
 STA $021D

 LDA #$01
 STA $021E

 LDA #$77
 STA $021F

 LDA #$2C
 STA $0220

 LDA #TITLE_MINEIRINHO_5
 STA $0221

 LDA #$01
 STA $0222

 LDA #$7F
 STA $0223

 LDA #$2C
 STA $0224

 LDA #TITLE_MINEIRINHO_6
 STA $0225

 LDA #$01
 STA $0226

 LDA #$87
 STA $0227

 LDA #$2C
 STA $0228

 LDA #TITLE_MINEIRINHO_7
 STA $0229

 LDA #$01
 STA $022A

 LDA #$8F
 STA $022B

 LDA #$34
 STA $022C

 LDA #TITLE_ULTRA_1
 STA $022D

 LDA #$01
 STA $022E

 LDA #$67
 STA $022F

 LDA #$34
 STA $0230

 LDA #TITLE_ULTRA_2
 STA $0231

 LDA #$01
 STA $0232

 LDA #$6F
 STA $0233

 LDA #$34
 STA $0234

 LDA #TITLE_ULTRA_3
 STA $0235

 LDA #$01
 STA $0236

 LDA #$77
 STA $0237

 LDA #$34
 STA $0238

 LDA #TITLE_ULTRA_4
 STA $0239

 LDA #$01
 STA $023A

 LDA #$7F
 STA $023B

 LDA #$34
 STA $023C

 LDA #TITLE_ULTRA_5
 STA $023D

 LDA #$01
 STA $023E

 LDA #$87
 STA $023F

 LDA #$3C
 STA $0240

 LDA #TITLE_ADVENTURES_1
 STA $0241

 LDA #$01
 STA $0242

 LDA #$5F
 STA $0243

 LDA #$3C
 STA $0244

 LDA #TITLE_ADVENTURES_2
 STA $0245

 LDA #$01
 STA $0246

 LDA #$67
 STA $0247

 LDA #$3C
 STA $0248

 LDA #TITLE_ADVENTURES_3
 STA $0249

 LDA #$01
 STA $024A

 LDA #$6F
 STA $024B

 LDA #$3C
 STA $024C

 LDA #TITLE_ADVENTURES_4
 STA $024D

 LDA #$01
 STA $024E

 LDA #$77
 STA $024F

 LDA #$3C
 STA $0250

 LDA #TITLE_ADVENTURES_5
 STA $0251

 LDA #$01
 STA $0252

 LDA #$7F
 STA $0253

 LDA #$3C
 STA $0254

 LDA #TITLE_ADVENTURES_6
 STA $0255

 LDA #$01
 STA $0256

 LDA #$87
 STA $0257

 LDA #$3C
 STA $0258

 LDA #TITLE_ADVENTURES_7
 STA $0259

 LDA #$01
 STA $025A

 LDA #$8F
 STA $025B

 LDA #$34
 STA $025C

 LDA #BLACK_TILE
 STA $025D

 LDA #$01
 STA $025E

 LDA #$5F
 STA $025F

 LDA #$34
 STA $0260

 LDA #BLACK_TILE
 STA $0261

 LDA #$01
 STA $0262

 LDA #$8F
 STA $0263

 RTS

.endproc

.proc updateMenu

  LDA pad1
  AND #BUTTON_A
  BNE loadGame

  JMP exitSubrotine

loadGame:

  LDA #$01
  STA gamestate

  JSR setupInGameLevel1

exitSubrotine:

  RTS

.endproc

.proc clearOAM

  LDX #$00
  LDA #$FF

loop:

  STA $200, X

  INX
  INX
  INX
  INX
  
  BNE loop

  RTS
.endproc

.proc setupInGameLevel1

  LDA #%00000000
  STA PPUMASK

  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR

  LDX #$00
  
loadPalletes:

  LDA level1Palettes, X
  STA PPUDATA

  INX
  CPX #$20
  BNE loadPalletes

  LDA #%10010000
  STA PPUCTRL
  LDA #%00011110
  STA PPUMASK

  LDX #$00

  RTS

.endproc

.segment "VECTORS"
  .addr nmi_handler, reset_handler, irq_handler

.segment "RODATA"

sprites:

  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80
  .byte $F8, $00, $00, $80

menuPalettes:

  .byte $31, $36, $20, $28
  .byte $29, $2E, $20, $28
  .byte $29, $36, $20, $28
  .byte $29, $36, $20, $28

  .byte $31, $36, $20, $28
  .byte $29, $2E, $20, $28
  .byte $29, $36, $20, $28
  .byte $29, $36, $20, $28

level1Palettes:

  .byte $31, $36, $20, $28
  .byte $29, $11, $15, $1D
  .byte $29, $19, $20, $01
  .byte $29, $06, $26, $15

  .byte $31, $36, $20, $28
  .byte $29, $11, $15, $1D
  .byte $29, $19, $20, $01
  .byte $29, $06, $26, $15

.segment "CHR"
.incbin "game.chr"