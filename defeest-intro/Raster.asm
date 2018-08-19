//===========================================================================================
// First Raster bar
// [x] denotes the number of cycles
//===========================================================================================
rasirq1:
  //The CPU cycles spent to get in here   [7]
  sta reseta1    //Preserve A,X and Y        [4]
  stx resetx1    //Registers         [4]
  sty resety1    //using self modifying code     [4]

  lda #<rasirq2  //Set IRQ Vector        [4]
  ldx #>rasirq2  //to point to the       [4]
  //next part of the
  sta INTVEC     //Stable IRQ          [4]
  stx INTVEC+1   //            [4]
  inc $d012      //set raster interrupt to the next line   [6]
  asl $d019      //Ack raster interrupt        [6]
  tsx            //Store the stack pointer! It points to the [2]
  cli            //return information of irq1.     [2]
  //Total spent cycles up to this point   [51]
  nop            //            [53]
  nop            //            [55]
  nop            //            [57]
  nop            //            [59]
  nop            //Execute nop's         [61]
  nop            //until next RASTER       [63]
  nop            //IRQ Triggers

//===========================================================================================
// Part 2 of the Main interrupt handler
//===========================================================================================
rasirq2:
         txs      //Restore stack pointer to point the the return
                  //information of irq1, being our endless loop.

         ldx #$09 //Wait exactly 9 * (2+3) cycles so that the raster line
         dex      //is in the border        [2]
         bne *-1  //             [3]

         // Set the colors
         SetBorderColor(BLUE)
         SetBackgroundColor(BLUE)

         lda #<rasirq21 //Set IRQ to point
         ldx #>rasirq21 //to subsequent IRQ
         ldy #$E0   //at line $FE
         sta INTVEC
         stx INTVEC+1
         sty $D012
         asl $D019  //Ack RASTER IRQ

lab_a1: lda #$00    //Reload A,X,and Y
.label reseta1 = lab_a1+1

lab_x1: ldx #$00
.label resetx1 = lab_x1+1

lab_y1: ldy #$00
.label  resety1 = lab_y1+1

         rti    //Return from IRQ

//===========================================================================================
// Second raster bar
// [x] denotes the number of cycles
//===========================================================================================
rasirq21:
  //The CPU cycles spent to get in here   [7]
  sta reseta21    //Preserve A,X and Y        [4]
  stx resetx21    //Registers         [4]
  sty resety21    //using self modifying code     [4]

  lda #<rasirq22  //Set IRQ Vector        [4]
  ldx #>rasirq22  //to point to the       [4]
  //next part of the
  sta INTVEC     //Stable IRQ          [4]
  stx INTVEC+1   //            [4]
  inc $d012      //set raster interrupt to the next line   [6]
  asl $d019      //Ack raster interrupt        [6]
  tsx            //Store the stack pointer! It points to the [2]
  cli            //return information of irq1.     [2]
  //Total spent cycles up to this point   [51]
  nop            //            [53]
  nop            //            [55]
  nop            //            [57]
  nop            //            [59]
  nop            //Execute nop's         [61]
  nop            //until next RASTER       [63]
  nop            //IRQ Triggers

//===========================================================================================
// Part 2 of the Main interrupt handler
//===========================================================================================
rasirq22:
  txs      //Restore stack pointer to point the the return
  //information of irq1, being our endless loop.

  ldx #$09 //Wait exactly 9 * (2+3) cycles so that the raster line
  dex      //is in the border        [2]
  bne *-1  //             [3]

  // Set the colors
  SetBorderColor(BLACK)
  SetBackgroundColor(BLACK)

  lda #<irq3 //Set IRQ to point
  ldx #>irq3 //to subsequent IRQ
  ldy #$FE   //at line $FE
  sta INTVEC
  stx INTVEC+1
  sty $d012
  asl $d019  //Ack RASTER IRQ

lab_a21: lda #$00    //Reload A,X,and Y
.label reseta21 = lab_a21+1

lab_x21: ldx #$00
.label resetx21 = lab_x21+1

lab_y21: ldy #$00
.label  resety21 = lab_y21+1

  rti    //Return from IRQ

