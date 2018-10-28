//BasicUpstart2(begin)			// <- This creates a basic sys line that can start your program
//*************************************************
//* Create and move a simple sprite x,y           *
//*************************************************

// Raster debug ?
.const DEBUG = 0

* = $2600 "Data"
// Animation vars
fcount:  .byte 0 // Frame counter
pos0:    .byte 0 // Array animation position pointer 0
xposl0:  .byte 0 // Least significant byte Xpos sprite 0
xposm0:  .byte 0 // Most significant byte Xpes sprite 0
pos1:    .byte 4 // Array animation position pointer 0
xposl1:  .byte 34 // Least significant byte Xpos sprite 0
xposm1:  .byte 0 // Most significant byte Xpes sprite 0
pos2:    .byte 8 // Array animation position pointer 0
xposl2:  .byte 70 // Least significant byte Xpos sprite 0
xposm2:  .byte 0 // Most significant byte Xpes sprite 0
pos3:    .byte 12 // Array animation position pointer 0
xposl3:  .byte 104 // Least significant byte Xpos sprite 0
xposm3:  .byte 0 // Most significant byte Xpes sprite 0
pos4:    .byte 16 // Array animation position pointer 0
xposl4:  .byte 140 // Least significant byte Xpos sprite 0
xposm4:  .byte 0 // Most significant byte Xpes sprite 0
pos5:    .byte 20 // Array animation position pointer 0
xposl5:  .byte 174 // Least significant byte Xpos sprite 0
xposm5:  .byte 0 // Most significant byte Xpes sprite 0
pos6:    .byte 24 // Array animation position pointer 0
xposl6:  .byte 180 // Least significant byte Xpos sprite 0
xposm6:  .byte 30 // Most significant byte Xpes sprite 0
pos7:    .byte 28 // Array animation position pointer 0
xposl7:  .byte 180 // Least significant byte Xpos sprite 0
xposm7:  .byte 64 // Most significant byte Xpes sprite 0

// Zero page
.const Q = 2
.const XPIXSHIFT = 4
.const TMP1 = 5
.const TEXTADR = 6

//helpful labels
.const CLEAR = $E544
.const GETIN  =  $FFE4
.const SCNKEY =  $FF9F

//sprite 0 setup
.const SCRLADR = $7c0
.const SPRITE0 = $7F8
.const SPRITE1 = $7F9
.const SPRITE2 = $7FA
.const SPRITE3 = $7FB
.const SPRITE4 = $7FC
.const SPRITE5 = $7FD
.const SPRITE6 = $7FE
.const SPRITE7 = $7FF
.const SP0VAL	= $3000
.const SP0X	= $D000
.const SP0Y	= $D001
.const SP1X = $D002
.const SP1Y = $D003
.const MSBX	= $D010
.const SCRCONTREG = $D011
.const CURRASTLN = $D012
.const ENABLE  = $D015
.const YEXPAND	= $D017
.const MEMSETREG = $D018
.const INTSTATREG = $D019
.const INTVICCONTREG = $D01A
.const SPRMULTI = $D01C
.const XEXPAND	= $D01D
.const FRAMCOL  = $D020
.const SCRCOL   = $D021
.const EXCOLOR1 = $D025
.const EXCOLOR2 = $D026
.const COLOR0   = $D027
.const COLOR1   = $D028
.const COLOR2   = $D029
.const COLOR3   = $D02A
.const COLOR4   = $D02B
.const COLOR5   = $D02C
.const COLOR6   = $D02D
.const COLOR7   = $D02E
.const VOICE1		= $D404
.const VOICE2   = $D40B
.const VOICE3   = $D412
.const SCRCLRADR = $DB97 // Color memory last line
.const INTCONTREG1 = $DC0D // CIA 1 Interrupt control
.const INTCONTREG2 = $DD0D // CIA 2 Interrupt control
.const INTVEC   = $FFFE

// Include macro's
#import "Macro.asm"

// Start of the main program
* = $2000 "Main Program"		// <- The name 'Main program' will appear in the memory map when assembling		jsr clear
begin:
  sei            // Disable interrupts
  lda #%01111111 //Disable CIA IRQ's
  sta INTCONTREG1      // Clear interrupt register1
  sta INTCONTREG2      // Clear interrupt register2

	ldx #$00 // Clear X register
	ldy #$00 // Clear Y register

  lda #$35 //Bank out kernal and basic
  sta $01  //$e000-$ffff

  SetBorderColor(BLACK) // Initialize the screen memory
  SetBackgroundColor(BLACK)
  ClearScreen(00)
	SetTextColor(WHITE)

	// Text to lowercase
  lda #23
  sta $d018 // Text mode to lower

  // Init text scroller
  lda #<text
  sta TEXTADR
  lda #>text
  sta TEXTADR+1

  // Initialize the sprites
  jsr sprite_init

  // Setup the SID Not needed?
	//lda #0
	//jsr $1000

  // Init the raster interrupt that does the animation
  jsr raster_init // Setup the raster interrupt

  // Start teh main routine
  asl INTSTATREG  // Ack any previous raster interrupt
  bit $dc0d				// reading the interrupt control registers
  bit $dd0d				// clears them

	// Initiliaze TOD timer in CIA2
  // Start the main routine
	lda $80			 // Set the 50Hz
	sta $DD0E		
	lda $84			 // nmi on
	sta $DD0D  
  lda $DD0D

	// Set the TOD timer to 00:00:00 AM
	lda #%00000000 // Set time of day
	sta $DD0F
	lda #$00
	sta $DD0B // Set tenth of seconds and stop timer 
	sta $DD0A // Set seconds
	sta $DD09 // Set minutes
	sta $DD08 // Set hours and start timer

  cli							// Allow IRQ's

	// Main until space is pressed
	jsr wait_space_time

	// Stop raster interrupts
	lda #%00000000
	sta INTVICCONTREG

	// Remove sprites from screen
	sta ENABLE

	// Reset SID
	sta VOICE1			// disable voice 1 <- #0
	sta VOICE2			// disable voice 2 <- #0
	sta VOICE3			// disable voice 3 <- #0

	// Disable scroll mode
	lda #%00010000
	sta SCRCONTREG

	// Finally empty the screen
  ClearScreen(00)

	// DEBUG!
	.if (DEBUG==1) {
		lda #00				// Black
		sta FRAMCOL
		sta SCRCOL
	}

	// Back to upper case
  lda #%00010101      // To upper case
  sta MEMSETREG

	// Bank in Kernal again
  lda #$37 //Bank in kernal and basic
  sta $01  //$e000-$ffff

	// Even more debug
	rts

	// Wait for space key
wait_space_time:
	// timout?
	sei
	lda #$01
	cmp $DD0A
	bne !over+				// minutes
  lda #$50          // Time in seconds to time out
  cmp $DD09
  bne !over+			  // seconds
		rts							// Done time is reached
!over:
	cli
	// space pressed?
	sei				// SEI and CLI are needed around this routine
	lda #$7F  //%01111111
	sta $DC00
	lda $DC01
	and #$10  //mask %00010000
	cli
	bne wait_space_time
release_space:
	sei				// When interrupts aren't disabled this just won't work
	lda #$7f	// %01111111
	sta $dc00
	lda $dc01
	and #$10
	cli
	beq release_space
	rts

  // Sprite init
sprite_init:
  StretchSpriteX(%11111111)
  StretchSpriteY(%11111111)
  SpriteMultiColor(%11111111)

  // Point the Spriter pointers to the correct memory locations $2000/$40=$80
  lda #(SP0VAL/$40)	//using block 13 for sprite0
  sta SPRITE0
  lda #(SP0VAL/$40)+1	//using block 13 for sprite0
  sta SPRITE1
  lda #(SP0VAL/$40)+2	//using block 13 for sprite0
  sta SPRITE2
  lda #(SP0VAL/$40)+1	//using block 13 for sprite0
  sta SPRITE3
  lda #(SP0VAL/$40)+1	//using block 13 for sprite0
  sta SPRITE4
  lda #(SP0VAL/$40)+3	//using block 13 for sprite0
  sta SPRITE5
  lda #(SP0VAL/$40)+4	//using block 13 for sprite0
  sta SPRITE6

  // Enable sprites	0-6
  lda #%01111111		//enable sprites
  sta ENABLE

  // Color to the sprites
  lda #05		//use red for sprite0
  sta COLOR0
  sta COLOR1
  sta COLOR2
  sta COLOR3
  sta COLOR4
  sta COLOR5
  sta COLOR6
  lda #09
  sta EXCOLOR1
  lda #07
  sta EXCOLOR2   // 3rd sprite color
  rts

  // Setup Raster interrupt
raster_init:
  //lda #%01111111  // Switch of interrupt signals from CIA-1
  //sta INTCONTREG

  //and SCRCONTREG
  lda #$1b //Clear the High bit (lines 256-318)
  sta SCRCONTREG

  lda #$F8
  sta CURRASTLN

  lda #<irq1
  sta INTVEC
  lda #>irq1
  sta INTVEC+1
  lda #%00000001
  sta INTSTATREG
  sta INTVICCONTREG
  rts

  // Music play address
	.label music_play = $1003

// Interrupt handling routines
#import "Irq.asm"
#import "Raster.asm"
// Import object data
#import "Data.asm"
#import "Scroll.asm"
