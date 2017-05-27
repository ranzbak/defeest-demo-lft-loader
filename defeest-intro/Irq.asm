// File holding the Raster interrupt handler routines

// Second interrupt to handle the Music
irq1:
  // Music IRQ
  pha
  txa
  pha
  tya
  pha
  lda #$ff // Acknowledge interrupt
  sta	$d019

  SetBorderColor(RED)			// <- This is how macros are executed
  jsr music_play
  SetBorderColor(BLACK)		// <- There are predefined constants for colors

  pla
  tay
  pla
  tax
  pla

  // Set the interrupt for SID handling
  lda #<scroll_irq // Set inturrupt register to routine 2
  ldx #>scroll_irq
  sta INTVEC
  stx INTVEC+1

  // Trigger at raster line 200
  ldy #60
  sty $d012

  rti

  //asl INTSTATREG
  //jmp $EA31

// Set Border and backround to blue
irq2:
  lda #$ff // Acknowledge interrupt
  sta	$d019

  clc
  ldx #$10
!loop: dex
  bpl !loop-
  
//  SetBorderColor(BLUE)
//  SetBackgroundColor(BLUE)

  // Set the interrupt for SID handling
  lda #<irq3 // Set inturrupt register to routine 2
  ldx #>irq3
  sta INTVEC
  stx INTVEC+1

  // Trigger at raster line 255
  ldy #$FF
  sty $d012

  rti

// Rasterbar and animation loop
irq3: 
  lda #$ff // Acknowledge interrupt
  sta	$d019

//  lda #7 // Turn screen border yellow
//  sta FRAMCOL
//  SetBorderColor(YELLOW)		

  // Move sprites over the X axis
  MoveSpriteX(0, xposl0, xposm0)
  MoveSpriteX(1, xposl1, xposm1)
  MoveSpriteX(2, xposl2, xposm2)
  MoveSpriteX(3, xposl3, xposm3)
  MoveSpriteX(4, xposl4, xposm4)
  MoveSpriteX(5, xposl5, xposm5)
  MoveSpriteX(6, xposl6, xposm6)
  MoveSpriteX(7, xposl7, xposm7)

  // Move sprites over the Y axis
  AnimSprite(0, bounce, pos0)
  AnimSprite(1, bounce, pos1)
  AnimSprite(2, bounce, pos2)
  AnimSprite(3, bounce, pos3)
  AnimSprite(4, bounce, pos4)
  AnimSprite(5, bounce, pos5)
  AnimSprite(6, bounce, pos6)
  AnimSprite(7, bounce, pos7)

//  SetBorderColor(BLACK)		
//  SetBackgroundColor(BLACK)

  // Set the interrupt for SID handling
  lda #<irq1 // Set inturrupt register to routine 2
  ldx #>irq1
  sta INTVEC
  stx INTVEC+1

  // Trigger at raster line 20
  ldy #20
  sty $d012

  rti

