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

    isJumping: .res 1
    isFalling: .res 1
    isSliding: .res 1

    jumpingYLimit: .res 1

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

    lastCosID: .res 1

    isCollidingHorizontal: .res 1
    isCollidingVertical: .res 1

    collectableItemX: .res 1
    collectableItemY: .res 1

    collectableItemIndex: .res 1
    collectableItemIsActive: .res 1

    pepperAnimationIndex: .res 1
    pepperAnimationCounter: .res 1

    alien1X: .res 1
    alien1Y: .res 1

    alien1IsAlive: .res 1
    alien1State: .res 1

    alien1AnimationCounter: .res 1

    alien1IsJumping: .res 1

    alien1IsFalling: .res 1

    alien1YLimit: .res 1

    alien1Health: .res 1

    alien1isCollidingVertical: .res 1

    alien1isCollidingHorizontal: .res 1
    
    alien1Direction: .res 1

    decrementHealthCounter: .res 1

    currentLevelPart: .res 1

    world: .res 2

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

    JSR updateMenu

    JMP continue

handleInGame:

    JSR updatePlayer
    JSR updateAliens
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
    STA isCollidingHorizontal
    STA isCollidingVertical
    STA isJumping
    STA isFalling
    STA isSliding
    STA jumpingYLimit
    STA lastCosID
    STA alien1X
    STA alien1Y
    STA alien1IsAlive
    STA alien1State
    STA alien1AnimationCounter
    STA alien1IsJumping
    STA alien1IsFalling
    STA alien1YLimit
    STA alien1isCollidingVertical
    STA alien1isCollidingHorizontal
    STA decrementHealthCounter
    STA currentLevelPart
    
    STA alien1Direction

    LDA #$1E
    STA throwableItemOffsetLim

    LDA #$01
    STA mustThrowableItemReturn

    LDA #$00
    STA digit1
    LDA #$05
    STA digit2

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
    CPX #$20
    BNE loadPalletes

    LDA #<menuLevelData
    STA world
    LDA #>menuLevelData

    STA world+1

    ; setup ppu for nametable data
    BIT PPUSTATUS
    LDA #$20
    STA PPUADDR
    LDA #$00
    STA PPUADDR

    LDX #$00
    LDY #$00
    loadWorld:

    LDA (world), Y
    STA PPUDATA
    INY
    CPX #$03
    BNE :+
    CPY #$C0
    BEQ doneLoadingWorld
:

    CPY #$00
    BNE loadWorld
    INX
    INC world+1
    JMP loadWorld

doneLoadingWorld:

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

    LDA pad1
    AND #BUTTON_UP
    BNE pressingUp

    LDA #$00
    STA playerIsWalking
    STA playerWalkingAnimationCounter
    STA playerWalkingAnimationFrame

    JMP checkIfPlayerShouldFall

pressingLeft:

    LDA playerX
    CMP #$09
    BCC checkIfPressingB

    JSR checkIfPlayerCanWalkLeft
    JMP checkIfPressingUp

pressingRight:

    LDA playerX
    CMP #$F0
    BCS checkIfPressingB

    JSR checkIfPlayerCanWalkRight
    JMP checkIfPressingUp

checkIfPressingUp:

    LDA pad1
    AND #BUTTON_UP
    BNE pressingUp

    JMP checkIfPlayerShouldFall

checkIfPlayerShouldFall:

    LDA isJumping
    CMP #$00
    BEQ checkIfPlayerIsFallingOrSlidingL

    LDA isFalling
    CMP #$01
    BEQ checkIfPlayerIsFallingOrSlidingL

    JMP pressingUp

checkIfPlayerIsFallingOrSlidingL:

    JSR checkIfPlayerIsFallingOrSliding

    JMP checkIfPressingB

pressingUp:

    LDA isFalling
    CMP #$01
    BEq checkIfPlayerShouldFall

    JSR checkIfPlayerCanJump
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

    JMP checkCosWithAlien

updateItem:

    LDA itemIsReturning
    CMP #$01
    BEQ returnItem
    
    LDA alien1IsAlive
    CMP #$01
    BNE continueUpdateItem

    LDA playerX
    STA checkCosAX
    LDA playerY
    STA checkCosAY
    LDA #PLAYER_WIDTH
    STA checkCosAWidth
    LDA #PLAYER_HEIGHT
    STA checkCosAHeight

    LDA alien1X
    STA checkCosBX
    LDA alien1Y
    STA checkCosBY

    LDA #$07
    STA checkCosAWidth
    STA checkCosAHeight

    JSR setupCos
    JSR checkCos

    LDA isColliding
    CMP #$01
    BNE continueUpdateItem

    JSR decrementAlienHealth

continueUpdateItem:

    LDA itemX
    CMP #$00
    BEQ checkIfShouldItemReturn
    CMP #$FF
    BEQ checkIfShouldItemReturn

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

    JMP checkCosWithAlien

moveItemLeft:

    LDA itemX
    SEC
    SBC #$02
    STA itemX

    JMP checkCosWithAlien

moveItemRight:

    LDA itemX
    CLC
    ADC #$02
    STA itemX

    JMP checkCosWithAlien

checkCosWithAlien:

    LDA alien1IsAlive
    CMP #$01
    BNE exitSubrotine

    LDA alien1X
    STA checkCosAX

    LDA alien1Y
    STA checkCosAY

    LDA #$07
    STA checkCosAWidth
    STA checkCosBHeight

    LDA playerX
    SEC
    SBC #$01
    STA checkCosBX

    LDA playerY
    STA checkCosBY

    LDA #PLAYER_WIDTH
    STA checkCosBWidth

    LDA #PLAYER_HEIGHT
    STA checkCosBHeight

    JSR setupCos

    JSR checkCosHorizontal

    LDA isCollidingHorizontal
    CMP #$01
    BNE exitSubrotine

    JSR checkCosVertical

    LDA isCollidingVertical
    CMP #$01
    BNE exitSubrotine

    INC decrementHealthCounter
    LDA decrementHealthCounter
    CMP #$32
    BNE exitSubrotine

    JSR decrementPlayerHealth
    LDA #$00
    STA decrementHealthCounter

exitSubrotine:

    RTS
.endproc


.proc checkIfPlayerCanWalkLeft

    LDX #$00
    LDY #$00

    STX isCollidingHorizontal

loopCos:

    INX

    LDA level1_part1Cos, X
    STA checkCosAX

    INX

    LDA level1_part1Cos, X
    STA checkCosAY

    INX

    LDA level1_part1Cos, X
    STA checkCosAWidth

    INX

    LDA level1_part1Cos, X
    STA checkCosAHeight

    INX

    LDA playerX
    SEC
    SBC #$01
    STA checkCosBX

    LDA playerY
    STA checkCosBY

    LDA #PLAYER_WIDTH
    STA checkCosBWidth

    LDA #PLAYER_HEIGHT
    STA checkCosBHeight

    JSR setupCos

    JSR checkCosHorizontal

    LDA isCollidingHorizontal
    CMP #$01
    BEQ collisionDetected

    INY
    CPY #LEVEL_1_PART1_TOTAL_COS
    BNE loopCos

    DEC playerX

    LDA #$01
    STA playerIsWalking

    LDA #$00
    STA playerDirection

    LDA isJumping
    CMP #$01
    BEQ noAnim

    LDA isFalling
    CMP #$01
    BEQ noAnim

    LDA playerWalkingAnimationCounter
    CLC
    ADC #$01
    STA playerWalkingAnimationCounter

    RTS

noAnim:
collisionDetected:

    LDA #$00
    STA playerIsWalking
    STA playerWalkingAnimationFrame
    STA playerWalkingAnimationCounter

    RTS
.endproc

.proc checkIfPlayerCanWalkRight

    LDX #$00
    LDY #$00

    STX isCollidingHorizontal

loopCos:

    INX

    LDA level1_part1Cos, X
    STA checkCosAX

    INX

    LDA level1_part1Cos, X
    STA checkCosAY

    INX

    LDA level1_part1Cos, X
    STA checkCosAWidth

    INX

    LDA level1_part1Cos, X
    STA checkCosAHeight

    INX

    LDA playerX
    CLC
    ADC #$01
    STA checkCosBX

    LDA playerY
    STA checkCosBY

    LDA #PLAYER_WIDTH
    STA checkCosBWidth

    LDA #PLAYER_HEIGHT
    STA checkCosBHeight

    JSR setupCos

    JSR checkCosHorizontal

    LDA isCollidingHorizontal
    CMP #$01
    BEQ collisionDetected

    INY
    CPY #LEVEL_1_PART1_TOTAL_COS
    BNE loopCos

    INC playerX

    LDA #$01
    STA playerIsWalking

    STA playerDirection

    LDA isJumping
    CMP #$01
    BEQ noAnim

    LDA isFalling
    CMP #$01
    BEQ noAnim

    LDA playerWalkingAnimationCounter
    CLC
    ADC #$01
    STA playerWalkingAnimationCounter

    RTS

noAnim:
collisionDetected:
    LDA #$00
    STA playerIsWalking
    STA playerWalkingAnimationFrame
    STA playerWalkingAnimationCounter

    RTS
.endproc

.proc checkIfPlayerCanJump

    LDX #$00
    LDY #$00

    STX isCollidingVertical

    LDA isFalling
    CMP #$01
    BEQ exitSubrotine

    LDA isJumping
    CMP #$01
    BEQ stillJumping

loopCos:

    INX

    LDA level1_part1Cos, X
    STA checkCosAX

    INX

    LDA level1_part1Cos, X
    STA checkCosAY

    INX

    LDA level1_part1Cos, X
    STA checkCosAWidth

    INX

    LDA level1_part1Cos, X
    STA checkCosAHeight

    INX

    LDA playerX
    STA checkCosBX

    LDA playerY
    SEC
    SBC #$01
    STA checkCosBY

    LDA #PLAYER_WIDTH
    STA checkCosBWidth

    LDA #PLAYER_HEIGHT
    STA checkCosBHeight

    JSR setupCos

    JSR checkCosVertical

    LDA isCollidingVertical
    CMP #$01
    BEQ collisionDetected

    INY
    CPY #LEVEL_1_PART1_TOTAL_COS
    BNE loopCos

    LDA isFalling
    CMP #$01
    BEQ exitSubrotine

    LDA isJumping
    CMP #$01
    BEQ stillJumping

    LDA #$01
    STA isJumping

    LDA playerY
    SEC
    SBC #$1A
    STA jumpingYLimit

    LDA playerY
    SEC
    SBC PLAYER_Y_SPEED

    LDA #$00

    RTS

stillJumping:

    LDA playerY
    CMP jumpingYLimit
    BCC finishJump

    SEC
    SBC #PLAYER_Y_SPEED
    STA playerY

    LDA #$00

    RTS

finishJump:

    LDA #$01
    STA isFalling

    LDA #$00
    STA isJumping

    RTS

collisionDetected:

    LDA #$00

exitSubrotine:

    RTS
.endproc

.proc checkIfPlayerIsFallingOrSliding

    LDX #$00
    LDY #$00

    STX isCollidingVertical

loopCos:

    LDA level1_part1Cos, X
    CMP #$02
    BEQ setIsSlliding

    LDA #$00
    STA isSliding

    JMP continueLoopCos

setIsSlliding:

    STA lastCosID
    LDA #$01
    STA isSliding

continueLoopCos:

    INX

    LDA level1_part1Cos, X
    STA checkCosAX

    INX

    LDA level1_part1Cos, X
    STA checkCosAY

    INX

    LDA level1_part1Cos, X
    STA checkCosAWidth

    INX

    LDA level1_part1Cos, X
    STA checkCosAHeight

    INX

    LDA playerX
    STA checkCosBX

    LDA playerY
    CLC
    ADC #$01
    STA checkCosBY

    LDA #PLAYER_WIDTH
    STA checkCosBWidth

    LDA #PLAYER_HEIGHT
    STA checkCosBHeight

    JSR setupCos

    JSR checkCosVertical

    LDA isCollidingVertical
    CMP #$01
    BEQ collisionDetected

    INY
    CPY #LEVEL_1_PART1_TOTAL_COS
    BNE loopCos

    LDA playerY
    SEC
    SBC #$03
    CMP checkCosBLimY
    BCS setBLimY

    LDA playerY
    CLC
    ADC #PLAYER_Y_SPEED
    STA playerY

    LDA #$01
    STA isFalling
    LDA #$00
    
    RTS

setBLimY:

    CLC
    ADC #PLAYER_Y_SPEED
    STA playerY

    LDA #$01
    STA isFalling
    LDA #$00

    RTS

collisionDetected:

    LDA #$00

    STA isFalling

    LDA isSliding
    CMP #$01
    BNE exitSubrotine

    LDA lastCosID
    CMP #$00
    BEQ exitSubrotine

    CMP #$01
    BEQ slideLeft

    ; slide right
    INC playerX

    RTS

slideLeft:

    DEC playerX

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

    JMP exitSubrotine

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

    JSR drawAliens

    RTS
.endproc

.proc drawAliens

    LDA alien1IsAlive
    CMP #$01
    BNE exitSubrotine

    LDA alien1Y
    SEC
    SBC #$08
    STA $0244

    LDA alien1Direction
    CMP #$01
    BEQ invertAlien1

    LDA #%00000010
    STA $0246
    LDA #%00000010
    STA $024A

    JMP continueDrawAlien1

invertAlien1:

    LDA #%01000010
    STA $0246
    LDA #%01000010
    STA $024A

continueDrawAlien1:

    LDA alien1X
    STA $0247

    LDA alien1Y
    STA $0248

    LDA alien1X
    STA $024B

    LDA alien1State
    CMP #$00
    BNE setAlien1Flexed

    LDA #ALIEN_HEAD_TILE
    STA $0245

    LDA #ALIEN_LEGS_TILE
    STA $0249

    JMP exitSubrotine

setAlien1Flexed:

    LDA #ALIEN_FLEXED_HEAD_TILE
    STA $0245

    LDA #ALIEN_FLEXED_LEGS_TILE
    STA $0249

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
    JMP checkIfDied

adjustTo9:

    LDA #$09
    STA digit2
    DEC digit1

checkIfDied:

    LDA digit1
    CMP #$06
    BCC exitSubrotine

    LDA #$00
    STA digit1
    STA digit2

    LDA currentLevelPart
    CMP #$00
    BEQ currentLevelPart1

currentLevelPart1:

    JSR setupInGameLevel1

exitSubrotine:

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

.proc updateAliens

    LDA alien1IsAlive
    CMP #$01
    BNE goToAlien2

    LDA alien1State
    CMP #$00
    BEQ alien1State0
    CMP #$01
    BEQ alien1State1
    CMP #$02
    BEQ alien1State2
    CMP #$03
    BEQ alien1State3

alien1State0:

    LDA alien1AnimationCounter
    CMP #$20
    BEQ alien1ToState1
    INC alien1AnimationCounter
    JMP alien2

alien1ToState1:

    LDA #$00
    STA alien1AnimationCounter
    LDA #$01
    STA alien1State
    JMP alien2

alien1State1:

    LDA alien1AnimationCounter
    CMP #$10
    BEQ alien1ToState2
    INC alien1AnimationCounter
    JMP alien2

alien1ToState2:

    LDA #$00
    STA alien1AnimationCounter
    LDA #$02
    STA alien1State

    LDA alien1Y
    SEC
    SBC #$0F
    STA alien1YLimit
    JMP alien2

alien1State2:

    LDA alien1Y
    CMP alien1YLimit
    BCC alien1ToState3

    DEC alien1Y

    LDA alien1X
    CMP playerX
    BCC moveAlien1Right2
    BEQ alien2

    JSR alien1CheckCosHorizontal
    LDA alien1isCollidingHorizontal
    CMP #$01
    BEQ alien2

    DEC alien1X
    LDA #$00
    STA alien1Direction
    JMP alien2

goToAlien2:

    JMP alien2

moveAlien1Right2:

    JSR alien1CheckCosHorizontal
    LDA alien1isCollidingHorizontal
    CMP #$01
    BEQ alien2
    
    INC alien1X
    LDA #$01
    STA alien1Direction
    JMP alien2

alien1ToState3:

    LDA #$03
    STA alien1State
    JMP alien2

alien1State3:

    JSR alien1CheckCosVertical
    LDA alien1isCollidingVertical
    CMP #$01
    BEQ alien1ToState0

    JSR alien1CheckCosHorizontal
    LDA alien1isCollidingHorizontal
    CMP #$01
    BEQ alien2

    INC alien1Y

    LDA alien1X
    CMP playerX
    BCC moveAlien1Right3
    BEQ alien2

    DEC alien1X
    LDA #$00
    STA alien1Direction
    JMP alien2

moveAlien1Right3:

    JSR alien1CheckCosHorizontal
    LDA alien1isCollidingHorizontal
    CMP #$01
    BEQ alien2

    INC alien1X
    LDA #$01
    STA alien1Direction
    JMP alien2

alien1ToState0:

    LDA #$00
    STA alien1AnimationCounter
    LDA #$00
    STA alien1State
    JMP alien2

alien2:
exitSubrotine:

    RTS
.endproc

.proc alien1CheckCosHorizontal

    LDY isCollidingHorizontal

    LDA alien1X
    STA checkCosAX
    
    LDA alien1Y
    SEC
    SBC #$06
    STA checkCosAY

    LDA #$07
    STA checkCosAWidth
    STA checkCosAHeight

    LDX #$00
    LDY #$00
    STX alien1isCollidingHorizontal

loopCos:

    INX

    LDA level1_part1Cos, X
    STA checkCosBX

    INX

    LDA level1_part1Cos, X
    STA checkCosBY

    LDA level1_part1Cos, X
    STA checkCosBWidth

    INX

    LDA level1_part1Cos, X
    STA checkCosBHeight

    INX

    JSR setupCos
    JSR checkCosHorizontal

    LDA isCollidingHorizontal
    CMP #$01
    BEQ collisionFound

    INY
    CPY #LEVEL_1_PART1_TOTAL_COS
    BNE loopCos

    LDA #$00
    STA alien1isCollidingHorizontal
    RTS

collisionFound:

    LDA #$01
    STA alien1isCollidingHorizontal
    RTS
.endproc

.proc alien1CheckCosVertical

    LDY isCollidingVertical

    LDA alien1X
    STA checkCosAX
    
    LDA alien1Y
    SEC
    SBC #$06
    STA checkCosAY

    LDA #$07
    STA checkCosAWidth
    STA checkCosAHeight

    LDX #$00
    LDY #$00
    STX alien1isCollidingVertical

loopCos:

    INX

    LDA level1_part1Cos, X
    STA checkCosBX

    INX

    LDA level1_part1Cos, X
    STA checkCosBY

    LDA level1_part1Cos, X
    STA checkCosBWidth

    INX

    LDA level1_part1Cos, X
    STA checkCosBHeight

    INX

    JSR setupCos
    JSR checkCosVertical

    LDA isCollidingVertical
    CMP #$01
    BEQ collisionFound

    INY
    CPY #LEVEL_1_PART1_TOTAL_COS
    BNE loopCos

    LDA #$00
    STA alien1isCollidingVertical
    RTS

collisionFound:

    LDA #$01
    STA alien1isCollidingVertical
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

    ; LDA #$2F
    ; STA collectableItemX
    ; LDA #$B0
    ; STA collectableItemY
    ; LDA #$01
    ; STA collectableItemIsActive

    ; LDA #$03
    ; STA collectableItemIndex

    LDA #$08
    STA playerX
    LDA #$B1
    STA playerY

    LDA #$01
    STA playerDirection
    STA alien1IsAlive

    LDA #$6A
    STA alien1X
    LDA #$C1
    STA alien1Y

    LDA #$1A
    STA alien1Health

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

    LDA #<level1_part1Data
    STA world
    LDA #>level1_part1Data

    STA world+1

    ; setup ppu for nametable data
    BIT PPUSTATUS
    LDA #$20
    STA PPUADDR
    LDA #$00
    STA PPUADDR

    LDX #$00
    LDY #$00
    loadWorld:

    LDA (world), Y
    STA PPUDATA
    INY
    CPX #$03
    BNE :+
    CPY #$C0
    BEQ doneLoadingWorld
:

    CPY #$00
    BNE loadWorld
    INX
    INC world+1
    JMP loadWorld

doneLoadingWorld:

    LDX #$00

    LDA #%10010000
    STA PPUCTRL
    LDA #%00011110
    STA PPUMASK

    LDX #$00

    RTS

.endproc

.proc setupCos

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

.endproc

.proc checkCos

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

.proc checkCosHorizontal

    LDA #$00
    STA isCollidingHorizontal

    LDA checkCosALimX
    CMP checkCosBX
    BCC exitSubrotine

    LDA checkCosAX
    CMP checkCosBLimX
    BCS exitSubrotine

    LDA checkCosAY
    CMP checkCosBLimY
    BCS exitSubrotine

    LDA checkCosALimY
    CMP checkCosBY
    BCC exitSubrotine

    LDA #$01
    STA isCollidingHorizontal

exitSubrotine:

    RTS
.endproc

.proc checkCosVertical

    LDA #$00
    STA isCollidingVertical

    LDA checkCosALimY
    CMP checkCosBY
    BCC exitSubrotine

    LDA checkCosAY
    CMP checkCosBLimY
    BCS exitSubrotine

    LDA checkCosAX
    CMP checkCosBLimX
    BCS exitSubrotine

    LDA checkCosALimX
    CMP checkCosBX
    BCC exitSubrotine

    LDA #$01
    STA isCollidingVertical

exitSubrotine:

    RTS
.endproc

.proc decrementAlienHealth

    DEC alien1Health

    LDA alien1Health
    CMP #$00
    BNE exitSubrotine

    LDA #$00
    STA alien1IsAlive

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

    .byte $31, $20, $1D, $27
    .byte $29, $2E, $20, $28
    .byte $29, $36, $20, $28
    .byte $29, $36, $20, $28

level1Palettes:

    .byte $31, $2A, $07, $17
    .byte $29, $11, $15, $1D
    .byte $29, $19, $20, $01
    .byte $29, $06, $26, $15

    .byte $31, $36, $20, $28
    .byte $29, $11, $15, $1D
    .byte $29, $19, $20, $01
    .byte $29, $06, $26, $15

menuLevelData:

    .incbin "menu.bin"

level1_part1Data:

    .incbin "level1_part1.bin"

level1_part1Cos:

    .byte $00, $00, $D0, $18, $0E
    .byte $00, $58, $E0, $48, $0E
    .byte $00, $A0, $D0, $08, $07
    .byte $00, $A8, $C0, $08, $07
    .byte $00, $B0, $B0, $18, $07

    .byte $02, $1F, $D0, $07, $07
    .byte $02, $26, $D0, $07, $07
    .byte $02, $2D, $D2, $07, $07
    .byte $02, $34, $D3, $07, $07
    .byte $02, $3B, $D4, $07, $07
    .byte $02, $42, $D5, $07, $07
    .byte $02, $49, $D6, $07, $07
    .byte $02, $50, $D7, $07, $07
    .byte $02, $57, $D8, $07, $07

    .byte $00, $B8, $E0, $40, $07

    .byte $03, $C8, $D8, $40, $07

.segment "CHR"
.incbin "game.chr"