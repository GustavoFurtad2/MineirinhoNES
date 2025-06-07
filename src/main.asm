.include "header.inc"
.include "constants.inc"

.segment "ZEROPAGE"
  playerX: .res 1
  playerY: .res 1
  pad1: .res 1
  playerDirection: .res 1
  playerIsWalking: .res 1
  playerIsThrowingItem: .res 1
  playerWasThrowingItem: .res 1
  itemIsReturning: .res 1
  itemOffsetX: .res 1
  itemOffsetY: .res 1
  itemX: .res 1
  itemY: .res 1
  itemOffsetLimitX: .res 1
  playerThrowingItemDirection: .res 1
  playerHealth: .res 1
  numberToDraw: .res 1
  numberX: .res 1
  numberY: .res 1
  remainder: .res 1
  digit1: .res 1
  digit2: .res 1
  equippedItem: .res 1 ; 0 == hat, 1 == crazy pizza, 2 == big hamburguer, 3 == pepper
  gamestate: .res 1  ; 0 == menu, 1 == in game level 1
  playerWalkingAnimationCounter: .res 1
  playerWalkingAnimationFrame: .res 1

  mustThrowableItemReturn: .res 1
  throwableItemOffsetLim: .res 1

  checkCosAX: .res 1
  checkCosAY: .res 1
  checkCosBX: .res 1
  checkCosBY: .res 1

  checkCosALimX: .res 1
  checkCosALimY: .res 1

  checkCosBLimX: .res 1
  checkCosBLimY: .res 1

  checkCosAWidth: .res 1
  checkCosAHeight: .res 1

  checkCosBWidth: .res 1
  checkCosBHeight: .res 1

  isColliding: .res 1

  collectableItemX: .res 1
  collectableItemY: .res 1

  collectableItemIndex: .res 1
  collectableItemIsActive: .res 1

  pepperAnimationIndex: .res 1
  pepperAnimationCounter: .res 1

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
  STA collectableItemX
  STA collectableItemY
  STA collectableItemIsActive
  STA equippedItem
  STA playerIsThrowingItem
  STA playerWasThrowingItem
  STA collectableItemIndex
  STA pepperAnimationIndex
  STA pepperAnimationCounter

  LDA #$1E
  STA throwableItemOffsetLim

  LDA #$01
  STA mustThrowableItemReturn

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

  JMP checkIfShouldUpdateItem

pressingB:

  LDA playerIsThrowingItem
  CMP #$01
  BEQ updateItem

  LDA playerIsThrowingItem
  STA playerWasThrowingItem
  LDA #$01
  STA playerIsThrowingItem

  LDA playerDirection
  STA playerThrowingItemDirection

  LDA playerX
  STA itemX

  LDA playerY
  STA itemY

  LDA playerThrowingItemDirection
  CMP #$01
  BEQ setItemOffsetRight

setItemOffsetLeft:

  LDA playerX
  SEC
  SBC throwableItemOffsetLim
  BPL storeLeftLimit
  LDA #$00

storeLeftLimit:

  STA itemOffsetX
  JMP updateItem

setItemOffsetRight:

  LDA playerX
  CLC
  ADC throwableItemOffsetLim

  CMP #$F0
  BCC storeRightLimit

  LDA #$F0

storeRightLimit:

  STA itemOffsetX
  JMP updateItem

  JMP updateItem

checkIfShouldUpdateItem:

  LDA playerIsThrowingItem
  CMP #$01
  BEQ updateItem

  JMP exitSubrotine

updateItem:

  LDA itemIsReturning
  CMP #$01
  BEQ returnItem

  LDA itemX
  CMP itemOffsetX
  BEQ checkIfShouldItemReturn

  LDA playerThrowingItemDirection
  CMP #$00
  BEQ moveItemLeft

  JMP moveItemRight

checkIfShouldItemReturn:

  LDA mustThrowableItemReturn
  CMP #$01
  BEQ setItemToReturn

  LDA #$01
  STA mustThrowableItemReturn
  LDA #$1E
  STA throwableItemOffsetLim
  LDA #$00
  STA equippedItem
  STA playerIsThrowingItem
  STA itemIsReturning

  RTS

setItemToReturn:

  LDA #$01
  STA itemIsReturning

  JMP returnItem

returnItem:

  LDA itemX
  CMP playerX
  BEQ stopItem

  LDA itemX
  CMP playerX
  BCC moveItemRight
  BCS moveItemLeft

stopItem:

  LDA playerIsThrowingItem
  STA playerWasThrowingItem
  LDA #$00
  STA playerIsThrowingItem
  STA itemIsReturning

  JMP exitSubrotine

moveItemLeft:

  LDA itemX
  SEC
  SBC #$02
  STA itemX

  JMP exitSubrotine

moveItemRight:

  LDA itemX
  CLC
  ADC #$02
  STA itemX

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

  LDA playerX
  STA $020B

  LDX equippedItem
  CPX #$00
  BNE continueConfigHat

  LDX playerIsThrowingItem
  CPX #$01
  BEQ applyOffset

  JMP continueConfigHat

applyOffset:

  LDA itemX
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

continue:

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
  
  LDA #INVENTORY_ITEM_TILE
  CLC
  ADC equippedItem
  STA $0239

  LDA #$03
  STA $023A

  LDA #$F4
  STA $023B

  ; draw collectable item

  LDA collectableItemIsActive
  CMP #$00
  BEQ checkIfShouldDrawThrowingItem

  LDA collectableItemX
  STA checkCosAX
  
  LDA collectableItemY
  STA checkCosAY

  LDA #$0B
  STA checkCosAWidth
  STA checkCosAHeight

  LDA playerX
  STA checkCosBX

  LDA playerY
  STA checkCosBY

  LDA #$0D
  STA checkCosBWidth

  LDA #$20
  STA checkCosBHeight

  JSR checkCos

  LDA collectableItemY
  STA $023C

  LDA #ITEM_TILE
  CLC
  ADC collectableItemIndex
  STA $023D

  LDA #$03
  STA $023E

  LDA collectableItemX
  STA $023F

  LDA isColliding
  CMP #$01
  BEQ checkIfCanCollectItem

  JMP checkIfShouldDrawThrowingItem

checkIfCanCollectItem:

  LDA playerIsThrowingItem
  CMP #$00
  BEQ collectItem

  JMP checkIfShouldDrawThrowingItem

collectItem:

  LDA #$00
  STA collectableItemIsActive
  STA mustThrowableItemReturn

  LDA #$3E
  STA throwableItemOffsetLim

  LDA collectableItemIndex
  STA equippedItem

checkIfShouldDrawThrowingItem:

  LDA equippedItem
  CMP #$00
  BEQ exitSubrotine

  LDA playerIsThrowingItem
  CMP #$01
  BEQ drawThrowingItem

  RTS

drawThrowingItem:

  LDA itemY
  CLC
  ADC #$08
  STA $0240

  LDA equippedItem
  CMP #$03
  BEQ isPepper

  LDA #ITEM_TILE
  CLC
  ADC equippedItem
  STA $0241

  JMP continueDrawThrowingItem

isPepper:

  LDA #PEPPER_FIRE_FRAME_1
  CLC
  ADC pepperAnimationIndex
  STA $0241

  LDA pepperAnimationIndex
  CMP #$05 ; total pepper fire frames
  BNE incrementPepperAnimationCounter

  JMP continueDrawThrowingItem

incrementPepperAnimationCounter:

  LDA pepperAnimationCounter
  CLC
  ADC #$01
  STA pepperAnimationCounter

  CMP #$02
  BNE continueDrawThrowingItem

  LDA #$00
  STA pepperAnimationCounter

  LDA pepperAnimationIndex
  CLC
  ADC #$01
  STA pepperAnimationIndex

continueDrawThrowingItem:

  LDA #$03
  STA $0242

  LDA itemX
  STA $0243

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

  LDA #$2F
  STA collectableItemX
  LDA #$1A
  STA collectableItemY
  LDA #$01
  STA collectableItemIsActive
  LDA #$03
  STA collectableItemIndex

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

.proc checkCos

  LDA #$00
  STA isColliding
  STA checkCosALimX
  STA checkCosALimY
  STA checkCosBLimX
  STA checkCosBLimY

  LDA checkCosALimX
  CLC
  ADC checkCosAX
  CLC
  ADC checkCosAWidth
  STA checkCosALimX

  LDA checkCosALimY
  CLC
  ADC checkCosAY
  CLC
  ADC checkCosAHeight
  STA checkCosALimY

  LDA checkCosBLimX
  CLC
  ADC checkCosBX
  CLC
  ADC checkCosBWidth
  STA checkCosBLimX

  LDA checkCosBLimY
  CLC
  ADC checkCosBY
  CLC
  ADC checkCosBHeight
  STA checkCosBLimY

  LDA checkCosAX
  CMP checkCosBLimX
  BCS exitSubrotine

  LDA checkCosALimX
  CMP checkCosBX
  BCC exitSubrotine

  LDA checkCosAY
  CMP checkCosBLimY
  BCS exitSubrotine

  LDA checkCosALimY
  CMP checkCosBY
  BCC exitSubrotine

  LDA #$01
  STA isColliding

exitSubrotine:

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