;
;
; A Simple Asymmetrical Title Screen Playfield
;
; this is a simple kernel meant to be usable for a title screen.
; can be adapted to put playfield text at an arbitrary height on the screen
;
; it owes a great debt to Glenn Saunders Thu, 20 Sep 2001 Stella post
; " Asymmetrical Reflected Playfield" (who in turn took from Roger Williams,
; who in turn took from Nick Bensema--yeesh!)
;
; it's meant to be a tightish, welll-commented, flexible kernel,
; that displays a title (or other playfield graphic) once, 
; instead of repeating it - also it's a steady 60 FPS, 262 scanlines,
; unlike some of its predecessors
;
; It uses no RAM, but all Registers when it's drawing the title 


	processor 6502
	include vcs.h
	include macro.h
	org $F000
Start
	CLEAN_START

	lda #00
	sta COLUBK  ;black background 	
	lda #45    
	sta COLUPF  ;colored playfield

;MainLoop starts with usual VBLANK code,
;and the usual timer seeding
MainLoop
	VERTICAL_SYNC
	lda #60	
	sta TIM64T
;
; lots of logic can go here, obviously,
; and then we'll get to the point where we're waiting
; for the timer to run out

WaitForVblankEnd
	lda INTIM	
	bne WaitForVblankEnd	
	sta VBLANK  	


;so, scanlines. We have three loops; 
;TitlePreLoop , TitleShowLoop, TitlePostLoop
;
; I found that if the 3 add up to 174 WSYNCS,
; you should get the desired 262 lines per frame
;
; The trick is, the middle loop is 
; how many pixels are in the playfield,
; times how many scanlines you want per "big" letter pixel 

pixelHeightOfTitle = #6
scanlinesPerTitlePixel = #6

; ok, that's a weird place to define constants, but whatever


;just burning scanlines....you could do something else
	ldy #20
TitlePreLoop
	sta WSYNC	
	dey
	bne TitlePreLoop



	ldx #pixelHeightOfTitle ; X will hold what letter pixel we're on
	ldy #scanlinesPerTitlePixel ; Y will hold which scan line we're on for each pixel

;
;the next part is careful cycle counting from those 
;who have gone before me....

TitleShowLoop
	sta WSYNC 	
	lda PFData0Left-1,X           ;[0]+4
	sta PF0                 ;[4]+3 = *7*   < 23	;PF0 visible
	lda PFData1Left-1,X           ;[7]+4
	sta PF1                 ;[11]+3 = *14*  < 29	;PF1 visible
	lda PFData2Left-1,X           ;[14]+4
	sta PF2                 ;[18]+3 = *21*  < 40	;PF2 visible
	nop			;[21]+2
	nop			;[23]+2
	nop			;[25]+2
	;six cycles available  Might be able to do something here
	lda PFData0Right-1,X          ;[27]+4
	;PF0 no longer visible, safe to rewrite
	sta PF0                 ;[31]+3 = *34* 
	lda PFData1Right-1,X		;[34]+4
	;PF1 no longer visible, safe to rewrite
	sta PF1			;[38]+3 = *41*  
	lda PFData2Right-1,X		;[41]+4
	;PF2 rewrite must begin at exactly cycle 45!!, no more, no less
	sta PF2			;[45]+2 = *47*  ; >



	dey ;ok, we've drawn one more scaneline for this 'pixel'
	bne NotChangingWhatTitlePixel ;go to not changing if we still have more to do for this pixel
	dex ; we *are* changing what title pixel we're on...

	beq DoneWithTitle ; ...unless we're done, of course
	
	ldy #scanlinesPerTitlePixel ;...so load up Y with the count of how many scanlines for THIS pixel...

NotChangingWhatTitlePixel
	
	jmp TitleShowLoop

DoneWithTitle	

	;clear out the playfield registers for obvious reasons	
	lda #0
	sta PF2 ;clear out PF2 first, I found out through experience
	sta PF0
	sta PF1

;just burning scanlines....you could do something else
	ldy #137
TitlePostLoop
	sta WSYNC
	dey
	bne TitlePostLoop

; usual vblank
	lda #2		
	sta VBLANK 	
	ldx #30		
OverScanWait
	sta WSYNC
	dex
	bne OverScanWait
	jmp  MainLoop      

;
; the graphics!
;PlayfieldPal at https://alienbill.com/2600/playfieldpal.html
;to draw these things. Just rename them left and right

PFData0Left
        .byte #%00000000
        .byte #%10000000
        .byte #%10000000
        .byte #%10000000
        .byte #%10000000
        .byte #%10000000
        .byte #%00000000
        .byte #%00000000

PFData1Left
        .byte #%00000000
        .byte #%00100100
        .byte #%00100100
        .byte #%11000000
        .byte #%10001110
        .byte #%00101010
        .byte #%00000000
        .byte #%00000000

PFData2Left
        .byte #%00000000
        .byte #%01100101
        .byte #%00010101
        .byte #%01010101
        .byte #%00010111
        .byte #%01100001
        .byte #%00000000
        .byte #%00000000

PFData0Right
        .byte #%00000000
        .byte #%00100000
        .byte #%00100000
        .byte #%00100000
        .byte #%00000000
        .byte #%01110000
        .byte #%00000000
        .byte #%00000000

PFData1Right
        .byte #%00000000
        .byte #%10011001
        .byte #%10100100
        .byte #%10100000
        .byte #%00100101
        .byte #%10011000
        .byte #%00000000
        .byte #%00000000

PFData2Right
        .byte #%00000000
        .byte #%00000011
        .byte #%00000100
        .byte #%00000011
        .byte #%00000000
        .byte #%00000111
        .byte #%00000000
        .byte #%00000000



	org $FFFC
	.word Start
	.word Start
