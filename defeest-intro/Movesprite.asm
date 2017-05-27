//BasicUpstart2(begin)			// <- This creates a basic sys line that can start your program
//*************************************************
//* Create and move a simple sprite x,y           *
//*************************************************

* = $4500 "Data"		
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
.const SCRCLRADR = $DB97 // Color memory last line
.const INTCONTREG1 = $DC0D // CIA 1 Interrupt control
.const INTCONTREG2 = $DD0D // CIA 2 Interrupt control
.const INTVEC   = $FFFE

// Include macro's
#import "Macro.asm"

// Start of the main program
* = $4000 "Main Program"		// <- The name 'Main program' will appear in the memory map when assembling		jsr clear
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
  bit $dc0d    // reading the interrupt control registers 
  bit $dd0d  // clears them
  cli    //Allow IRQ's

// Main endless loop
main:     
  jmp *       //;jump to loop.


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

  // Music loader
  //*=$1000 "Music"
  //.label music_init =*			// <- You can define label with any value (not just at the current pc position as in 'music_init:') 
  //.label music_play =*+3			// <- and that is useful here
  //.import binary "ode to 64.bin"	// <- import is used for importing files (binary, source, c64 or text)	
	.label music_play = $1003
	

	

// Interrupt handling routines
#import "Irq.asm"
#import "Raster.asm"
// Import object data
#import "Data.asm"
#import "Scroll.asm"
