;* Songs index always begin with the "intro" section, followed by the "loop" section, when applicable 
;* Index list must end with the dummy tune address to mark the end of each list properly 
;* Make sure to define the total number of tunes that could be indexed in code using it to avoid garbage data being loaded 

SongIndex 
	dta a(SNG_0),a(SEQ_0) 
;	dta a(SNG_1),a(SEQ_1) 
SongIndexEnd 

;-----------------
		
;//---------------------------------------------------------------------------------------------

SongSequence
SEQ_0	dta $00,$80
/*
SEQ_0	dta $00,$00,$00,$00
	dta $01,$01,$01,$01
	dta $02,$02,$02,$02
	dta $02,$02,$02,$02
	dta $03,$03,$03,$03
	dta $04,$04,$04,$04
	dta $05,$05,$05,$05
	dta $05,$05,$05,$05
	dta $80
SEQ_1	dta $00,$80
*/
SongSequenceEnd 

;-----------------
		
;//---------------------------------------------------------------------------------------------

SongSection
SNG_0	dta a(LZ00)
/*
	dta a(LZ01) 
	dta a(LZ04) 
	dta a(LZ09) 
	dta a(LZ16) 
	dta a(LZ20) 
	dta a(LZ25) 
SNG_1	dta a(LZ_FULL) 
*/
SNG_END	dta a(LZ_END) 
SongSectionEnd 

;-----------------
		
;//---------------------------------------------------------------------------------------------

;* LZSS data, all in a single block

LZ_DTA
LZ00	ins '/RANDOM3/Lab Stereo.lzss'
/*
LZ01	ins '/Sketch 44/Sketch 44.lz01'
LZ04	ins '/Sketch 44/Sketch 44.lz04'
LZ09	ins '/Sketch 44/Sketch 44.lz09'
LZ16	ins '/Sketch 44/Sketch 44.lz16'
LZ20	ins '/Sketch 44/Sketch 44.lz20'
LZ25	ins '/Sketch 44/Sketch 44.lz25'
LZ_FULL	ins '/Sketch 44/Sketch 44.lzss'
*/
LZ_END

;-----------------
		
;//---------------------------------------------------------------------------------------------

