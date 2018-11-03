.const C_SCREEN_BANK       = $4000              // screen bank base address
.const C_SCREEN_RAM        = C_SCREEN_BANK + $1800 // Screen Ram location

//BasicUpstart2(begin)        // <- This creates a basic sys line that can start your program

.const DEBUG=0

// Tell the assembler where the Koala file is
.var picture = LoadBinary("party-popper-phasebased.kla", BF_KOALA)

*=C_SCREEN_RAM          "ScreenRam";      .fill picture.getScreenRamSize(), picture.getScreenRam(i)
*=C_SCREEN_BANK + $1C00 "ColorRam:"; colorRam:  .fill picture.getColorRamSize(), picture.getColorRam(i)
*=C_SCREEN_BANK + $2000 "Bitmap";       .fill picture.getBitmapSize(), picture.getBitmap(i)

// Start of the main program
* = $2000 "Main Program"
begin:

  // Disable interrupts and start initialization
  sei                  // Disable interrupts

  lda #%01111111       // Disable CIA IRQ's
  sta $DC0D      // Clear interrupt register1
  sta $DD0D      // Clear interrupt register2

  lda #$35             // Bank out kernal and basic
  sta $01              // $e000-$ffff

  lda $D011       // Put the VIC into bitmap graphics mode
  ora #%00100000       // Enable bitmap mode bit 6
  sta $D011

  lda #$6f        // Remap the graphics memory to VIC bank + $2000-$3FFF
  sta $D018

// DEBUG restore when running in spindle
	lda #$3d						 // Bank switch the VIC to the first bank $4000-$7fff
	sta $dd02
// lda #$02
// sta $dd00

	lda #$18				// Multi color
	sta $D016

  // Start the main routine
  asl $d019        // Ack any previous raster interrupt
  lda $dc0d             // reading the interrupt control registers
  lda $dd0d             // clears them

  // Disable the sprites
  lda #$00
  sta $D015               // Disable sprites

	// Setup Image
  lda #$01
  sta $d020
  lda #picture.getBackgroundColor()
  sta $D021
  ldx #0

  !loop:
  .for (var i=0; i<4; i++) {
    lda colorRam+i*$100,x
			sta $d800+i*$100,x
  }
  inx
  bne !loop-

	// Set the TOD timer to 00:00:00 AM
	lda #%00000000 // Set time of day
	sta $DD0F
	lda #$00
	sta $DD0B // Set tenth of seconds and stop timer 
	sta $DD0A // Set seconds
	sta $DD09 // Set minutes
	sta $DD08 // Set hours and start timer

  // Setup the raster interrupt
  jsr raster_init

  cli                   // Enable interrupts again

////
// Ad infinitum, until self modifying code magic happens.
main_loop: jmp *

  // Back to normal text screen
	sei
	ldy #$00
  lda #$00
  sta $d01a               // Disable raster interrupt
  sta $d015							  // Disable Sprites
  asl $d019               // Ack RASTER IRQ

  cli

//	// DEBUG 
//	lda #03
//	sta $d020
//	sta $d021
//	jmp *

  rts                     // Back to the load routine

////
// Initialize Raster interrupt
raster_init:
  lda #$3b //Clear the High bit (lines 256-318)
  sta $D011

  lda #$F8
  sta $D012
	
  lda #<break_irq
  sta $FFFE
  lda #>break_irq
  sta $FFFF
  lda #$0f
  sta $D019
  lda #$01
  sta $D01A

  // Start the main routine
  bit $dc0d             // reading the interrupt control registers
  bit $dd0d             // clears them
  rts

// Break interrupt routine----------------------------------------------------------------------]
// ---------------------------------------------------------------------------------------------]
break_irq:
	inc $D019 // Ack interrupt

.if (DEBUG==1) {
	lda #$00
	sta $d020
}

	// handle space
	jsr wait_space

	// handle timeout
	jsr wait_timeout

.if (DEBUG==1) {
	lda #$01
	sta $d020
}

	rti

// Wait for space ------------------------------------------------------------------------------]
// ---------------------------------------------------------------------------------------------]
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

// Move on when needed--------------------------------------------------------------------------]
// ---------------------------------------------------------------------------------------------]
wait_timeout:	
  lda #$03          // Time in seconds to time out
  cmp $DD09
  bne !over+				// Seconds 
    lda #$0C        // Kill main loop
    sta main_loop
!over:
	rts
