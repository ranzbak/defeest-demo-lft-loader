// Macro's
.macro ClearScreen(clearByte) {
  ldx #$00
    !clear:  lda #$20     // #$20 is the spacebar Screen Code
    sta $0400,x  // fill four areas with 256 spacebar characters
    sta $0500,x
    sta $0600,x 
    sta $06e8,x 
    lda #$00     // set foreground to black in Color Ram 
    sta $d800,x  
    sta $d900,x
    sta $da00,x
    sta $dae8,x
    inx           // increment X
    bne !clear-     // did X turn to zero yet?
}

// Way to complicated routine to move sprites the full screen width
.macro MoveSpriteX(num, xposl, xposm) {
  ldy xposl // least significant position byte first
    ldx xposm // most significant position byte
    cpy #180
    beq spritehigh
    iny
    iny
    sty xposl
    jmp spritexpos
    spritehigh:  inx // Add least significant byte to most significant
    inx
    stx xposm
    cpx #180
    bne spritexpos // When the msb reaches 160 start back at zero for both
    ldx #0
    stx xposl
    stx xposm
    spritexpos: lda xposl
    clc
    adc xposm
    sta SP0X+num*2
    lda MSBX
    ldx #num
    and bitmaskinv, x // carry not set
    bcc spritemost
    ora bitmask, x // carry set
    spritemost: sta MSBX
}

.macro AnimSprite(num, animp, countp) {
  ldy countp // Get value
    //ldx fcount // Frame count
    //inx
    //cpx #03 // number of frames to wait
    //bne over
    ldx #0
    lda animp, y
    sta SP0Y+num*2
    iny // Cycle through animation
    cpy #32
    bne over
    ldy #0
    over:  sty countp
    //stx fcount
}

.macro SetBorderColor(color) {
  lda #color
  sta $d020
}

.macro SetBackgroundColor(color) {
  lda #color
    sta $d021
}

// Set the color on the last line
.macro SetTextColor(color) {
	lda #color
	ldy #80
colorloop:
	sta SCRCLRADR, y
	dey
	bne colorloop
}
  

.macro StretchSpriteX(bits) {
  lda #bits	// Sprite 0 double size X
    sta $D01D
}

.macro StretchSpriteY(bits) {
  lda #bits	// Sprite 0 double size Y
    sta $D017
}

.macro SpriteMultiColor(bits) {
  lda #bits	// Sprite 0 double size Y
    sta SPRMULTI // Multicolor
}

