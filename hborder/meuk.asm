BasicUpstart2(begin)   

* = $2000 "Horizontal drop"  // <- The name 'Main program' will appear in the memory map when assembling   jsr clear

.const VIC_BANK = 0
.const KEEP_SPRITES = 0
.const DEBUG = 1
.const STEP_THROUGH = 1

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

  lda #$0
  sta $D020
  sta $D021

  lda #$0D                        // Using block 13 for Sprite 0
  sta $07f8+VIC_BANK

  lda #%000000001                        // Enable sprite 0, 1 and 2
  sta $D015

  lda #$07                              // multicolor register 0 to yellow
  sta $d025
  lda #$0e                              // multicolor register 1 to blue
  sta $d026

  lda #$01
  sta $d027

  lda #%00000001                        // Set multicolor sprite 0-2
  sta $d01c

  lda #0                                // Sprite MSB X to 0
  sta $D010

  ldx #100                              // Set X position of sprite 0
  stx $D000
 
  lda #30                               // Start of logo (30)
  sta yloc
  sta $D001                             // Set y for sprite 0

  lda #%00000001                        // Set sprite 0-2 double size 
  sta $D01D                             // Double X
  sta $D017                             // Double Y

  lda #$00
  sta $D01B       // Sprites in front

  ldx #0                                // Copy sprite into sprite memory
  !loop:
    lda defeest_sprite0, x
    sta $0340+VIC_BANK, x
    inx
    cpx #63
  bne !loop-
  cli

  lda #252                      // Set raster line to interrupt on
  sta $d012
  lda #<irq_252  // Switch to 25 columns 
  sta $FFFE
  lda #>irq_252
  sta $FFFF

main_loop:
  jmp *                                 // Endless loop

irq_252:
  sta $02		// copy registers and acknowlege interupt
  lda $DC0D
  stx $03
  sty $04

  .if(DEBUG == 1){
    lda #1                                // Border and bkg to white
    sta $d020
    sta $d021
  }
  lda $d011                             // Set bit 3 to enable 25 line mode
  ora #%00001000
  sta $d011

  jsr flip_back 

  lda #00                       // raster interrupt at the end of the screen
  sta $d012			// which disables bottom sprites
  lda #<irq_00
  ldx #>irq_00
  sta $FFFE
  stx $FFFF

  .if(DEBUG == 1){
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

  .if(DEBUG == 1){
    lda #1                                // Border and bkg to white
    sta $d020
    sta $d021
  }

  lda #$01
  cmp yflags		// yflags is $01
  bne !skipmore+
    lda #%0000001
    sta $d015
    clc
    lda #$0
    sbc yloc	
    bcs !skip+
      clc
      lda #$18
      sbc yloc
      bcc !skip+
        .if(KEEP_SPRITES == 0){
          //lda #$00              // Disable sprites 
          //sta $d015
        }
     //   clc			// just in case
     //   lda yloc
     //   sbc #$19	// way way wayyyyy lower
     //   adc #230
        lda #55
        sta flipline
        sta $d012                // turn sprites back on  from flipline      
        lda #<irq_55
        ldx #>irq_55
        sta $FFFE
        stx $FFFF
        jmp !skipmore+
    !skip:
    lda #55                              // raster interrupt just a bit lower of the screen
    sta $d012                        // turn sprites back on unless first time
    lda #<irq_55
    ldx #>irq_55
    sta $FFFE
    stx $FFFF 
  !skipmore:

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
    lda #55                              // raster interrupt just a bit lower of the screen
    sta $d012			     // turn sprites back on unless first time
    lda #<irq_55
    ldx #>irq_55
    sta $FFFE
    stx $FFFF 
  !skipmore:
	
  .if(DEBUG == 1){
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

  .if(DEBUG == 1){
    lda #1                                // Border and bkg to white
    sta $d020
    sta $d021
  }

  lda #$01
  cmp yflags
  beq !skip+
    ldx #%00000001  // sprites back on
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


  lda #249                              // raster interrupt pretty low of the screen
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
 
  .if(DEBUG == 1){
    lda #0                                // Border and bkg to black 
    sta $d020
    sta $d021

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

  .if(DEBUG == 1){
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
      lda #%00000001
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

  clc
  inc yloc // increment y pos
  lda yloc
  bne overflow
    adc #$01
  overflow:
  sta $D001                           // Sprite position Y 
  !step:

  .if(DEBUG == 1){
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
  .if(DEBUG == 1){
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

  .if(DEBUG == 1){
    lda #0                                // Border and bkg to black
    sta $d020
    sta $d021
  }

  rts

flip_back:
  .if(DEBUG == 1){
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

  .if(DEBUG == 1){
    lda #0                                // Border and bkg to black
    sta $d020
    sta $d021
  }

  rts

irq_flex:
  sta $02       // copy registers and acknowlege interupt
  lda $DC0D
  stx $03
  sty $04

  .if(DEBUG == 1){
    lda #8                                // Border and bkg to red or something
    sta $d020
    sta $d021
  }

  lda #%00000001  // sprites back on
  sta $d015

  

  lda #55                            
  sta $d012                         
  lda #<irq_55
  ldx #>irq_55
  sta $FFFE
  stx $FFFF

  .if(DEBUG == 1){
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
