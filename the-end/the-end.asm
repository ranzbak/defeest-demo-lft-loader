//:BasicUpstart2(start)
//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
//  					KOALA SHOWER
//
//This code displays the Koala picture in the file picture.prg
//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
.var picture = LoadBinary("./the-end.kla", BF_KOALA)

* = $1000 "Main Program"
start:  	
			sei					  // Disable all interrupts
			lda #$35			// Bank out kernal and basic
			sta $01				// $e000-$ffff
			lda #$00			// Disable interrupts
			sta $d01a
			lda #$28			// bitmap at $2000, Screen memory at $1800
			sta $d018
			lda #$d8			// Multi color 40 columns
			sta $d016
			lda #$3b
			sta $d011			// Bitmap mode on, screen visible, 25 roms, 011 vertical scroll
			lda #BLACK
			sta $d020			// Border color black
			lda #picture.getBackgroundColor()
			sta $d021			// set background color
			lda #$3c			// Spindle loader set VIC register Band #0 
			sta $dd02
			ldx #0
loop1:		
			.for (var i=0; i<4; i++) {
				lda colorRam+i*$100,x
				sta $d800+i*$100,x
			}
			inx
			bne loop1

			//cli						// enable interrupts again
			jmp *

*=$0800	"ScreenRam";						.fill picture.getScreenRamSize(), picture.getScreenRam(i)
*=$1c00	"ColorRam:"; colorRam: 	.fill picture.getColorRamSize(), picture.getColorRam(i)
*=$2000	"Bitmap";								.fill picture.getBitmapSize(), picture.getBitmap(i)

.print "ScreenRam="+picture.getScreenRamSize()+","+picture.getScreenRam(0)
.print "Koala format="+BF_KOALA
