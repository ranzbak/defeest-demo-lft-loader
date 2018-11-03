//BasicUpstart2(begin)                            // <- This creates a basic sys line that can start your program

.var picture = LoadBinary("./anus.kla", BF_KOALA)

* = $2000 "Horizontal drop"    // <- The name 'Main program' will appear in the memory map when assembling   jsr clear

.const DEBUG = 0
.const INTERUPT = 0
.const KEEP_SPRITES = 1
.const SKIP_JUMP = 0

// Main
begin:
  sei                                                   // Disable interrupts

  lda #$35 //Bank out kernal and basic
  sta $01  //$e000-$ffff
  
  lda #%01111111        // Switch off interrupts from the CIA-1
  sta $dc0d
  and $d011                             // Clear most significant bit in VIC raster register
  sta $d011
  lda #252                              // Set raster line to interrupt on
  sta $d012
  lda #<irq_25          // Set the interrupt vector to point to the service routine
  sta $FFFE
  lda #>irq_25
  sta $FFFF
  lda #%00000001        // Enable raster interrupt to VIC
  sta $d01a
  lda #$00
  sta $dd0d
  lda #29
  sta yloc
  
  asl $d019                             // Ack any previous raster interrupt
  bit $dc0d                             // reading the interrupt control registers 
  bit $dd0d                             // clears them

  lda #00                                 // Clear border garbage
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
                        sta $dd02	 		// Spindle version
//			lda #$02			// VIC bank 4000-7FFF
//                        sta $dd00	 		// Native version
                        ldx #0
loop1:          
                        .for (var i=0; i<4; i++) {
                                lda colorRam+i*$100,x
                                sta $d800+i*$100,x
                        }
                        inx
                        bne loop1

	

	lda #$1a
	sta $4400 + $7f8
	lda #$1b
	sta $4400 + $ff8

        lda #$0D                                // Using block 13 for Sprite 0
        sta $47f8
        lda #$0E                                // Using block 14 for Sprite 0
        sta $47f9
        lda #$0F                                // Using block 15 for Sprite 0
        sta $47fA

        lda #%00000111                          // Enable sprite 0, 1 and 2
        sta $D015

        lda #$07                                // multicolor register 0 to yellow
        sta $d025
        lda #$0e                                // multicolor register 1 to blue
        sta $d026

        lda #%00000111                          // Set multicolor sprite 0-2
        sta $d01c

        lda #0                                  // Sprite MSB X to 0
        sta $D010

        ldx #100                                // Set X position of sprite 0
        stx $D000
        ldx #148                                // Set X position of sprite 1
        stx $D002                       
        ldx #196                                // Set X position of sprite 2
        stx $D004

        lda #30                                 // Start of logo (30)
        sta yloc
        sta $D001                               // Set y for sprite 0
        sta $D003                               // Set y for sprite 1
        sta $D005                               // Set y for sprite 2

        lda #%00000111                          // Set sprite 0-2 double size 
        sta $D01D                               // Double X
        sta $D017                               // Double Y

  lda #$00
  sta $D01B               // Sprites in front

        ldx #0                                  // Copy sprite into sprite memory

!loop:
        lda defeest_sprite0, x
        sta $4340, x
        lda defeest_sprite1, x
        sta $4340+64, x
        lda defeest_sprite2, x
        sta $4340+128, x
        inx 
        cpx #63
        bne !loop-
        cli
main_loop:
        jmp *                                   // Endless loop

        sei
        lda #$00
        sta $d01a                               // disable raster interupts
        sta $d015                               // disable sprites
        asl $d019                               // ack raster irc
	lda #$37
	sta $01
        cli
//        jmp $fffc                             // reset for testing
        rts

irq_top_sprites:
	sta $02
        lda $DC0D
        stx $03
        sty $04
.if(DEBUG == 1){
        lda #0                                  // Border to black
        sta $d020
        sta $d021
}

        lda #55                                // raster interrupt just a bit lower of the screen
        sta $d012
        lda #<irq_midway
        ldx #>irq_midway
        sta $FFFE
        stx $FFFF

        lda sprites_0_nreg: #$00                // Disable sprite 0-2
.if(KEEP_SPRITES == 0){
        sta $d015
}

.if(DEBUG == 1){
        lda #picture.getBackgroundColor()                                  // Border to black
        sta $d020
        sta $d021
}

        lda #$01
        sta $D019
        ldy $04
        ldx $03
        lda $02
	rti

irq_midway:
        sta $02
        lda $DC0D
        stx $03
        sty $04
.if(DEBUG == 1){
        lda #0                                  // Border to black
        sta $d020
        sta $d021
}
        lda #249                                // raster interrupt just a bit lower of the screen
        sta $d012
        lda #<irq_24
        ldx #>irq_24
        sta $FFFE
        stx $FFFF

	lda yloc
//	jsr binhex
//	sta $0400       // counter msn to screen
//	stx $0401	// counter lsm to screen

        lda firstrun
        bne !skip+
        lda #%00000111	// sprites back on
        sta $d015
!skip:
        lda #$02
        sta firstrun
.if(DEBUG == 1){
        lda #picture.getBackgroundColor()                                  // Border to black
        sta $d020
        sta $d021
}
        lda #$01
        sta $D019
        ldy $04
        ldx $03
        lda $02
  	rti

// Interrupt handler set screen to 24 columns
irq_24:
        sta $02
        lda $DC0D
        stx $03
        sty $04
.if(DEBUG == 1){
        lda #0                                  // Border to black
        sta $d020
        sta $d021
}
        lda $d011                               // Clear bit 3 to enable 24 line mode
        and #%11110111
        sta $d011

        lda #252                                // raster interrupt just a bit lower of the screen
        sta $d012
        lda #<irq_25
        ldx #>irq_25
        sta $FFFE
        stx $FFFF

        jsr wait_space      

.if(INTERUPT == 1){
        ldx #$FD      	// setup kbd matrix
        stx $DC00
        lda $dc01       // read kbd matrix 
	and #%00100000	// key S
        bne !over+      // step through version
}
        clc
        lda #252
        sbc yloc
        bcs !kill_top_sprites+
.if(KEEP_SPRITES == 0) {
        lda #$00
        sta sprites_0_nreg
}              
!kill_top_sprites:

        inc yloc // increment y pos
        lda yloc
        bne overflow
        adc #$01
overflow:
	tay
.if(SKIP_JUMP == 0){
	lda #$01
	cmp yflag
	beq !skip+
	
	lda #37		// on 30 on y
	cmp yloc
	bne !skip+
	jsr flip_overflow
!skip:
	lda #79		// on 72 on y
	cmp yloc
	bne !skip+
	jsr flip_back
}
!skip:
	tya
        sta $D001                             // Sprite position Y inc 0
        sta $D003                             // Sprite position Y inc 1
        sta $D005                             // Sprite position Y inc 2

!over:
.if(DEBUG == 1){
        lda #picture.getBackgroundColor()                                  // Border to black
        sta $d020
	sta $d021
}

        lda #$01
        sta $D019
        ldy $04
        ldx $03
        lda $02
	rti

// Interrupt handler set screen to 25 colums
irq_25:
        sta $02
        lda $DC0D
        stx $03
        sty $04
.if(DEBUG == 1){
        lda #7                                  // Border to yellow
        sta $d020
        sta $d021
}

        lda $d011                               // Set bit 3 to enable 25 line mode
        ora #%00001000
        sta $d011

        lda #00                         // raster interrupt at the end of the screen
        sta $d012 
        lda #<irq_top_sprites
        ldx #>irq_top_sprites
        sta $FFFE
        stx $FFFF

.if(DEBUG == 1){
        lda #picture.getBackgroundColor()                                  // Border to black
        sta $d020
        sta $d021
}

        lda #$01
        sta $D019
        ldy $04
        ldx $03
        lda $02
	rti

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


flip_overflow:
        lda #$03                                  // Border to some color
        sta $d020
        sta $d021

	lda #$01
	cmp yflag
	beq !over+

	lda #$01
	sta yflag	

	lda #$207
	sta yloc
!over:
	lda #$0
        sta $d020
        lda #picture.getBackgroundColor()                                  // Border to black
        sta $d021
	rts

flip_back:
        lda #$04                                  // Border to some color
        sta $d020
        sta $d021

        lda #$00
        cmp yflag
        beq !over+

        lda #$03
        cmp yflag
        beq !over+

        lda #$03
        sta yflag

        lda #$30
        sta yloc
!over:
	lda #$0
        sta $d020
        lda #picture.getBackgroundColor()                                  // Border to black
        sta $d021
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

  asl $d019				// Acknowledge interrupt
  rti 

yloc: .byte $00, $00
firstrun: .byte $00
yflag: .byte $00

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

*=$4400 "ScreenRam";                                            .fill picture.getScreenRamSize(), picture.getScreenRam(i)
*=$1c00 "ColorRam:"; colorRam:  .fill picture.getColorRamSize(), picture.getColorRam(i)
*=$6000 "Bitmap";                                                               .fill picture.getBitmapSize(), picture.getBitmap(i)

.print "ScreenRam="+picture.getScreenRamSize()+","+picture.getScreenRam(0)
.print "Koala format="+BF_KOALA
