;* Songs index always begin with the "intro" section, followed by the "loop" section, when applicable 
;* Index list must end with the dummy tune address to mark the end of each list properly 
;* Make sure to define the total number of tunes that could be indexed in code using it to avoid garbage data being loaded 

SongIndex 
	dta a(SNG_0),a(SEQ_0) 
	dta a(SNG_1),a(SEQ_1) 
	dta a(SNG_2),a(SEQ_2) 
;	dta a(SNG_0),a(SEQ_3) 
SongIndexEnd 

;-----------------
		
;//---------------------------------------------------------------------------------------------

/*
SongSequence
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
SongSequenceEnd 
*/


SongSequence
SEQ_0	dta $00,$01,$81
SEQ_1	dta $00,$01,$81
SEQ_2	dta $00,$01,$81
;SEQ_3	dta $00,$01,$01,$02,$03,$03,$04,$05,$05,$FF
SongSequenceEnd 


;-----------------
		
;//---------------------------------------------------------------------------------------------

/*
SongSection
SNG_0	
;	dta a(LZ00) 
	dta a(LZ01) 
	dta a(LZ04) 
;	dta a(LZ08) 
	dta a(LZ09) 
	dta a(LZ16) 
	dta a(LZ20) 
;	dta a(LZ24) 
	dta a(LZ25) 
SNG_1	dta a(LZ_FULL) 
SNG_END	dta a(LZ_END) 
SongSectionEnd 
*/

SongSection
SNG_0	dta a(LZ_0_0) 
	dta a(LZ_0_1) 
SNG_1	dta a(LZ_1_0) 
	dta a(LZ_1_1) 
SNG_2	dta a(LZ_2_0) 
	dta a(LZ_2_1) 
SNG_END	dta a(LZ_END) 
SongSectionEnd 


;-----------------
		
;//---------------------------------------------------------------------------------------------

;* LZSS data, all in a single block

/*
LZ_DTA
;LZ00	ins '/Sketch 44/Sketch 44.lz00'
LZ01	ins '/Sketch 44/Sketch 44.lz01'
LZ04	ins '/Sketch 44/Sketch 44.lz04'
;LZ08	ins '/Sketch 44/Sketch 44.lz08'
LZ09	ins '/Sketch 44/Sketch 44.lz09'
LZ16	ins '/Sketch 44/Sketch 44.lz16'
LZ20	ins '/Sketch 44/Sketch 44.lz20'
;LZ24	ins '/Sketch 44/Sketch 44.lz24'
LZ25	ins '/Sketch 44/Sketch 44.lz25'
LZ_FULL	ins '/Sketch 44/Sketch 44.lzss'
LZ_END
*/


LZ_DTA
LZ_0_0	ins	'/Bunny Hop LZSS/TUNE_1_INTRO.lzss'
LZ_0_1	ins	'/Bunny Hop LZSS/TUNE_1_LOOP.lzss' 
LZ_1_0	ins	'/Bunny Hop LZSS/TUNE_2_INTRO.lzss'
LZ_1_1	ins	'/Bunny Hop LZSS/TUNE_2_LOOP.lzss' 
LZ_2_0	ins	'/Bunny Hop LZSS/TUNE_3_INTRO.lzss' 
LZ_2_1	ins	'/Bunny Hop LZSS/TUNE_3_LOOP.lzss' 
LZ_END


;-----------------
		
;//---------------------------------------------------------------------------------------------

