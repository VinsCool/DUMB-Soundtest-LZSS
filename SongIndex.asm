;* Songs index always begin with the "intro" section, followed by the "loop" section, when applicable 
;* Index list must end with the dummy tune address to mark the end of each list properly 
;* Make sure to define the total number of tunes that could be indexed in code using it to avoid garbage data being loaded 

SongIndex 
	dta a(SNG_0),a(SEQ_0) 
	dta a(SNG_1),a(SEQ_1) 
/*
	dta a(SNG_0),a(SEQ_0) 
	dta a(SNG_1),a(SEQ_0) 
	dta a(SNG_2),a(SEQ_0) 
	dta a(SNG_3),a(SEQ_1) 
	dta a(SNG_4),a(SEQ_1) 
	dta a(SNG_5),a(SEQ_1) 
	dta a(SNG_6),a(SEQ_1) 
	dta a(SNG_7),a(SEQ_0) 
*/
SongIndexEnd 

;-----------------
		
;//---------------------------------------------------------------------------------------------

SongSequence
;SEQ_0	dta $00,$01,$81
SEQ_0	dta $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$82
SEQ_1	dta $00,$80
SongSequenceEnd 

;-----------------
		
;//---------------------------------------------------------------------------------------------

SongSection
SNG_0	dta a(LZ00)
	dta a(LZ01)
	dta a(LZ02)
	dta a(LZ03)
	dta a(LZ04)
	dta a(LZ05)
	dta a(LZ06)
	dta a(LZ07)
	dta a(LZ08)
	dta a(LZ09)
SNG_1	dta a(LZ10)
/*
	dta a(LZ01)
SNG_1	dta a(LZ10)
	dta a(LZ11)
SNG_2	dta a(LZ20)
	dta a(LZ21)
SNG_3	dta a(LZ30)
SNG_4	dta a(LZ40)
SNG_5	dta a(LZ50)
SNG_6	dta a(LZ60)
SNG_7	dta a(LZ70)
	dta a(LZ71)
*/
SNG_END	dta a(LZ_END) 
SongSectionEnd 

;-----------------
		
;//---------------------------------------------------------------------------------------------

;* LZSS data, all in a single block

LZ_DTA
LZ00	ins '/RANDOM3/lab.lz00'
LZ01	ins '/RANDOM3/lab.lz01'
LZ02	ins '/RANDOM3/lab.lz02'
LZ03	ins '/RANDOM3/lab.lz03'
LZ04	ins '/RANDOM3/lab.lz04'
LZ05	ins '/RANDOM3/lab.lz05'
LZ06	ins '/RANDOM3/lab.lz06'
LZ07	ins '/RANDOM3/lab.lz07'
LZ08	ins '/RANDOM3/lab.lz08'
LZ09	ins '/RANDOM3/lab.lz09'
LZ10	ins '/RANDOM3/Gordian Tomb Stereo.lzss'
/*
LZ00	ins '/RANDOM3/SKETCH_53.lzss'
LZ01	ins '/RANDOM3/SKETCH_53_LOOP.lzss'
LZ10	ins '/RANDOM3/SIEUR_GOUPIL.lzss'
LZ11	ins '/RANDOM3/SIEUR_GOUPIL_LOOP.lzss'
LZ20	ins '/RANDOM3/SHORELINE.lzss'
LZ21	ins '/RANDOM3/SHORELINE_LOOP.lzss'
LZ30	ins '/RANDOM3/SKETCH_58_LOOP.lzss'
LZ40	ins '/RANDOM3/SKETCH_69_LOOP.lzss'
LZ50	ins '/RANDOM3/SKETCH_24_LOOP.lzss'
LZ60	ins '/RANDOM3/DUMB3_LOOP.lzss'
LZ70	ins '/RANDOM3/BOUNCY_BOUNCER.lzss'
LZ71	ins '/RANDOM3/BOUNCY_BOUNCER_LOOP.lzss'
*/
LZ_END

;-----------------
		
;//---------------------------------------------------------------------------------------------

