// Interrupt handler
scroll_irq:
	lda #$ff		// Acknowledge interrupt
	sta $d019

.if (DEBUG==1) {
  lda #7      // Turn screen frame yellow
  sta $d020
}

.var DESTSTART=*+1
  ldx #39 //39
.var SRCSTART=*+1
  ldy #39 //37

xpixshiftadd:
  dec XPIXSHIFT

  lda XPIXSHIFT // shift register
  and #7
  sta $d016

  cmp XPIXSHIFT
  sta XPIXSHIFT
  beq endirq

  lda SCRLADR,Y   // Getting the characters from the string on screen.
  sta TMP1
  lda SCRLADR-1,Y
  pha             // Push acc
s:
  lda TMP1
  sta SCRLADR-1,X
  pla             // Pull acc
  sta TMP1
  lda SCRLADR-2,Y
  pha             // push acc
  dey
  dex
  bne s
  pla             // pull acc

// getnewchar:
  lda (TEXTADR,X) // Load the current character
  bne overrestart // If it's zero, start over
  lda #<text  // Reset to the beginning of the text
  sta TEXTADR
  lda #>text
  sta TEXTADR+1
  jmp endirq
overrestart:

  iny
  bmi nobegin
  ldx #$27

nobegin:
  inc TEXTADR
  bne textlower
  inc TEXTADR+1

textlower:
  tay  // Transfer A to Y
  bmi dirchange // A < than num

  sta SCRLADR,X
  bpl endirq // Jump to main loop
  //---------------------------------------
dirchange:
  lda xpixshiftadd
  eor #$20
  sta xpixshiftadd

  ldx DESTSTART
  ldy SRCSTART
  dex
  iny
  stx SRCSTART
  sty DESTSTART
  //bne loop
endirq:
.if (DEBUG==1) {
  lda #0
  sta $d020   // Background to black
}
  asl $d019   // Acknowledge interrupt

  // Jump to the Raster bar routine
  lda #<rasirq1 // Set inturrupt register to routine 2
  ldx #>rasirq1
  sta INTVEC
  stx INTVEC+1

	// Trigger Next interrupt
	ldy #200
	sty $d012

	rti

//---------------------------------------
text:
  .text " deFEEST, does copy paste scrollers."
  .text "                    "
  .text "                    "
  .byte $FF // back
	.text " .rehtegot edoc eht teg su gnipleh rof stnemelE evisrevbuS ehT fo srebmem eht ot sknahT"
  .text "                    "
  .text "                    "
  .byte $FF // forward
	.text " Roses are red, violets are blue, deFEETS can't do poetry and so can't you."
  .text "                    "
  .text "                    "
  .byte $FF // back
	.text " .hsinniF nrael dna msa nrael ot emit dnuof ohw "
	.text " ,sniF eht tsael ton tub tsal dna stleb tuohtiw "
	.text " elpoep hcsinaD eht ,sniF eht ,srelweK ot sgniteerG"
  .text " .... "
  .text "                    "
  .text "                    "
  .byte $FF // forward
	.text " No animals where hurt during the creation of this demo, we believe."
  .text "                    "
  .text "                    "
  .byte $FF // Backward
	.text " ?teggunneh a eb si t'ndluohs ,ti ni sneh sah ylno teggunnekcihc a nehW"
  .text "                    "
  .text "                    "
  .byte $FF,0
