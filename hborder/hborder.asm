//BasicUpstart2(begin)  

.var picture = LoadBinary("./commy.kla", BF_KOALA)

* = $2000 "Horizontal drop"  // <- The name 'Main program' will appear in the memory map when assembling   jsr clear

.const VIC_OFFSET = $4000
.const KEEP_SPRITES = 0
.const DEBUG = 1
.const RASTER_DEBUG = 0
.const STEP_THROUGH = 0

// Main
begin:
  sei                                           // Disable interrupts

  lda #$35 //Bank out kernal and basic
  sta $01  //$e000-$ffff

  lda #%01111111  // Switch off interrupts from the CIA-1
  sta $dc0d
  and $d011                     // Clear most sig  .ificant bit in VIC raster register
  sta $d011

  lda #%00000001  // Enable raster interrupt to VIC
  sta $d01a
  lda #$00
  sta $dd0d
  lda #29
  sta yloc

  asl $d019                     // Ack any previous raster interrupt
  bit $dc0d                     // reading the interrupt control registers 
  bit $dd0d                     // clears them

  lda #00                         // Clear border garbage
  sta $3fff

   // Koala
  lda #$18                        // bitmap at $2000, Screen memory at $1800
  sta $d018
  lda #$d8                        // Multi color 40 columns
  sta $d016
  lda #$3b
  sta $d011                       // Bitmap mode on, screen visible, 25 roms, 011 vertical scroll
  lda #$0
  sta $d020                       // Border color black
  lda #picture.getBackgroundColor()
  sta $d021                       // set background color
  lda #$3d                      // VIC bank 4000-7FFF 
  sta $dd02                       // Spindle version
//  lda #$02                        // VIC bank 4000-7FFF
//  sta $dd00                     // Native version
  ldx #0
  loop1:
    .for (var i=0; i<4; i++) {
      lda colorRam+i*$100,x
      sta $d800+i*$100,x
    }
    inx
  bne loop1

  //lda #2
  //sta $dbe7 

  lda #$1a
  sta $4400 + $7f8
  lda #$1b
  sta $4400 + $ff8

  lda #picture.getBackgroundColor()
  sta $D021

  lda #$0D                        // Using block 13 for Sprite 0
  sta $07f8+VIC_OFFSET
  lda #$0E                                // Using block 14 for Sprite 0
  sta $07f9+VIC_OFFSET
  lda #$0F                                // Using block 15 for Sprite 0
  sta $07fA+VIC_OFFSET

  lda #%000000111                        // Enable sprite 0, 1 and 2
  sta $D015

  lda #$07                              // multicolor register 0 to yellow
  sta $d025
  lda #$0e                              // multicolor register 1 to blue
  sta $d026

  lda #$01
  sta $d027

  lda #%00000111                        // Set multicolor sprite 0-2
  sta $d01c

  lda #0                                // Sprite MSB X to 0
  sta $D010

  ldx #100                              // Set X position of sprite 0
  stx $D000
  ldx #148                                // Set X position of sprite 1
  stx $D002
  ldx #196                                // Set X position of sprite 2
  stx $D004
 
  lda #30                               // Start of logo (30)
  sta yloc
  sta $D001                             // Set y for sprite 0
  sta $D003                               // Set y for sprite 1
  sta $D005                               // Set y for sprite 2

  lda #%00000111                        // Set sprite 0-2 double size 
  sta $D01D                             // Double X
  sta $D017                             // Double Y

  lda #$00
  sta $D01B       // Sprites in front

  ldx #0                                // Copy sprite into sprite memory
  !loop:
    lda defeest_sprite0, x
    sta $0340+VIC_OFFSET, x
    lda defeest_sprite1, x
    sta $0340+64+VIC_OFFSET, x
    lda defeest_sprite2, x
    sta $0340+128+VIC_OFFSET, x
    inx
    cpx #63
  bne !loop-
  cli

!loop:
  lda #$0
  sta VIC_OFFSET + $800, x
  sta VIC_OFFSET + $800 + 64, x
  inx
  cpx #63
  bne !loop-

  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop

  lda #252                      // Set raster line to interrupt on
  sta $d012
  lda #<irq_252  // Switch to 25 columns 
  sta $FFFE
  lda #>irq_252
  sta $FFFF

main_loop:
  jmp *                                 // Endless loop
 
  rts

irq_252:
  sta $02		// copy registers and acknowlege interupt
  lda $DC0D
  stx $03
  sty $04

  .if(RASTER_DEBUG == 1){
    lda #1                                // Border and bkg to white
    sta $d020
    sta $d021
  }

  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop

  jsr flip_back 

  lda #00                       // raster interrupt at the end of the screen
  sta $d012			// which disables bottom sprites
  lda #<irq_00
  ldx #>irq_00
  sta $FFFE
  stx $FFFF

  .if(RASTER_DEBUG == 1){
    lda #0                                // Border and bkg to black
    sta $d020
    sta $d021
  }
  lda #$01	// copy registers back and Acknowledge raster interrup 
  sta $D019
  ldy $04
  ldx $03
  lda $02
  rti

irq_00:
  sta $02       // copy registers and acknowlege interupt
  lda $DC0D
  stx $03
  sty $04

  .if(RASTER_DEBUG == 1){
    lda #1                                // Border and bkg to white
    sta $d020
    sta $d021
  }

  lda #$01
  cmp yflags		// yflags is $01
  bne !skip+
    lda #%0000111
    sta $d015
  !skip:

  lda #$01
  cmp yflags
  beq !skipmore+
    lda yloc
    sbc #$45
    bcs !skip+
    .if(KEEP_SPRITES == 0){
      lda #$00              // Disable sprites 
      sta $d015
    }
    !skip:
  !skipmore:
  
  lda #55                              // raster interrupt just a bit lower of the screen
  sta $d012			     // turn sprites back on unless first time
  lda #<irq_55
  ldx #>irq_55
  sta $FFFE
  stx $FFFF 
	
  .if(RASTER_DEBUG == 1){
    lda #0                                // Border and bkg to black
    sta $d020
    sta $d021
  }
  lda #$01  // copy registers back and Acknowledge raster interrup 
  sta $D019
  ldy $04
  ldx $03
  lda $02
  rti

irq_55:
  sta $02   // copy registers and acknowlege interupt
  lda $DC0D
  stx $03
  sty $04

  .if(RASTER_DEBUG == 1){
    lda #1                                // Border and bkg to white
    sta $d020
    sta $d021
  }

  lda $d011                             // Set bit 3 to enable 25 line mode
  ora #%00001000
  sta $d011

  lda #$01
  cmp yflags
  beq !skip+
    ldx #%00000111  // sprites back on
    lda #$0
    cmp yloc
    bne !off+
      ldx $0
    !off:
    lda #$1
    cmp yloc
    bne !off+
      ldx $0
    !off:
    stx $d015
  !skip:

  lda #248                              // raster interrupt pretty low of the screen
  sta $d012				// back to 24 columns
  lda #<irq_249
  ldx #>irq_249
  sta $FFFE
  stx $FFFF
 
  // if yloc also 55 . . 
  lda #55         
  cmp yloc
  bne !skip+	// we need to reset the sprite location and set a flag
    jsr flip_overflow
  !skip:
 
  .if(RASTER_DEBUG == 1){
    lda #0                                // Border and bkg to black 
    sta $d020
    sta $d021
  }
  .if(DEBUG == 1){
    lda yloc
    jsr binhex
    sta $0400       // counter msn to screen
    stx $0401       // counter lsm to screen
    
    lda yflags
    jsr binhex
    sta $0403       // counter msn to screen
    stx $0404       // counter lsm to screen

    lda flipline
    jsr binhex
    sta $0406       // counter msn to screen
    stx $0407       // counter lsm to screen
  } else {
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
  }
  
  lda #$01  // copy registers back and Acknowledge raster interrup 
  sta $D019
  ldy $04
  ldx $03
  lda $02
  rti

irq_249:
  sta $02       // copy registers and acknowlege interupt
  lda $DC0D
  stx $03
  sty $04

  .if(RASTER_DEBUG == 1){
    lda #4                                // Border and bkg to red or something
    sta $d020
    sta $d021
  }

  lda $d011                             // Clear bit 3 to enable 24 line mode
  and #%11110111
  sta $d011

  lda #252                              // raster interrupt just a bit lower of the screen
  sta $d012				// to enable 25 line mode again
  lda #<irq_252
  ldx #>irq_252
  sta $FFFE
  stx $FFFF

  .if(KEEP_SPRITES == 0){
    clc
    lda #252	  	// switch sprites back on  .if below rasterline 252
    sbc yloc
    bcs !kill_only_top_sprites+
      lda #%00000111
      sta $d015 
    !kill_only_top_sprites:
  }

  clc
  lda yflags
  beq !skip+
    lda #$0
    sta $d015
  !skip: 

  .if(STEP_THROUGH == 1){
    clc
    ldx #$FD        // setup kbd matrix
    stx $DC00
    lda $dc01       // read kbd matrix 
    and #%00100000  // key S
    bne !step+      // step through version
  }

  jsr wait_space

  clc
  inc yloc // increment y pos
  lda yloc
  bne overflow
    adc #$01
  overflow:
  sta $D001                           // Sprite position Y 
  sta $D003                               // Set y for sprite 1
  sta $D005                               // Set y for sprite 2
  !step:

  .if(RASTER_DEBUG == 1){
    lda #0                                // Border and bkg to black
    sta $d020
    sta $d021
  }
  lda #$01  // copy registers back and Acknowledge raster interrup 
  sta $D019
  ldy $04
  ldx $03
  lda $02
  rti

flip_overflow:
  .if(RASTER_DEBUG == 1){
    lda #3                                // Border and bkg to red or something
    sta $d020
    sta $d021
  }

  lda #$01
  cmp yflags
  beq !skip+ 
    lda #$01
    sta yflags

    lda #0            // y location "back" to 0 
    sta yloc
  !skip:

  .if(RASTER_DEBUG == 1){
    lda #0                                // Border and bkg to black
    sta $d020
    sta $d021
  }
  rts

flip_back:
  .if(RASTER_DEBUG == 1){
    lda #2                                // Border and bkg to red or something
    sta $d020
    sta $d021
  }

  lda #97		// On yloc 55+42 ?
  cmp yloc
  bne !skip+
    lda #$00
    sta yflags
  !skip:

  .if(RASTER_DEBUG == 1){
    lda #0                                // Border and bkg to black
    sta $d020
    sta $d021
  }
  rts

wait_space:
        ldx #$7F                        //%01111111, Detect if space is pressed
        stx $DC00
        lda $DC01
        and #$10                        //mask %00010000
        bne !over+
        lda #$0C                         // Illegal opcode NOP $FFFF, replace the jump command with a nop, this will end the loop
        sta main_loop
!over:
        rts

/*================================================================================
;
;binhex: CONVERT BINARY BYTE TO HEX ASCII CHARS
;
;   ————————————————————————————————————
;   Preparatory Ops: .A: byte to convert
;
;   Returned Values: .A: MSN ASCII char
;                    .X: LSN ASCII char
;                    .Y: entry value
;   ————————————————————————————————————
*/
binhex:
  pha                   // save byte
  and #%00001111        // extract LSN
  tax                   // save it
  pla                   // recover byte
  lsr                   // extract...
  lsr                   // MSN
  lsr
  lsr
  pha                   // save MSN
  txa                   // LSN
  jsr convert_nybble    // generate ASCII LSN
  tax                   // save
  pla                   // get MSN & fall thru

//  convert nybble to hex ASCII equivalent...
convert_nybble:
  cmp #$0a
  bcc finalize_nybble   // in decimal range
  adc #$46              // hex compensate

finalize_nybble:
  adc #$30              // finalize nybble
  and #%01111111
  rts                   // done

// variables
yloc: .byte $00, $00
yflags: .byte $00
flipline: .byte $00

// define the sprite data
.pc = $8000 "Sprite"
.align $40
 
;// sprite0
defeest_sprite0:
.byte $00,$15,$55
.byte $05,$55,$55
.byte $05,$55,$55
.byte $15,$55,$55
.byte $15,$55,$5F
.byte $15,$55,$7F
.byte $15,$55,$F7
.byte $15,$57,$F7
.byte $15,$5F,$D7
.byte $15,$5F,$D7
.byte $05,$5F,$D7
.byte $05,$5F,$FF
.byte $01,$57,$FF
.byte $00,$57,$FF
.byte $00,$55,$FF
.byte $00,$15,$7F
.byte $00,$05,$57
.byte $00,$00,$55
.byte $00,$00,$15
.byte $00,$00,$05
.byte $00,$00,$00
.byte 0
;// sprite1
defeest_sprite1:
.byte $55,$54,$00
.byte $55,$55,$50
.byte $55,$55,$54
.byte $FF,$F5,$55
.byte $FF,$FF,$D5
.byte $FF,$FF,$FF
.byte $FF,$FF,$FF
.byte $5F,$FF,$FF
.byte $5F,$FF,$FF
.byte $7F,$FF,$FF
.byte $5D,$75,$D7
.byte $FD,$F7,$DF
.byte $FD,$F7,$DF
.byte $FD,$75,$D7
.byte $FD,$F7,$DF
.byte $FD,$F7,$DF
.byte $FD,$F5,$D7
.byte $7F,$FF,$FF
.byte $55,$FF,$FF
.byte $55,$55,$55
.byte $00,$55,$55
.byte 0
;// sprite2
defeest_sprite2:
.byte $00,$00,$00
.byte $00,$00,$00
.byte $00,$00,$00
.byte $40,$00,$00
.byte $50,$00,$00
.byte $55,$00,$00
.byte $F5,$40,$00
.byte $FD,$50,$00
.byte $FF,$50,$00
.byte $FF,$D4,$00
.byte $D5,$75,$00
.byte $7D,$F5,$00
.byte $7D,$FD,$00
.byte $5D,$FD,$00
.byte $DD,$F5,$00
.byte $DD,$F5,$00
.byte $7D,$D4,$00
.byte $FF,$50,$00
.byte $55,$40,$00
.byte $55,$00,$00
.byte $40,$00,$00
.byte 0

*=$4400 "ScreenRam"; .fill picture.getScreenRamSize(), picture.getScreenRam(i)
*=$1c00 "ColorRam:"; colorRam:  .fill picture.getColorRamSize(), picture.getColorRam(i)
*=$6000 "Bitmap";    .fill picture.getBitmapSize(), picture.getBitmap(i)

.print "ScreenRam="+picture.getScreenRamSize()+","+picture.getScreenRam(0)
.print "Koala format="+BF_KOALA

