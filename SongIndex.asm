;* Songs index always begin with the "intro" section, followed by the "loop" section, when applicable 
;* Index list must end with the dummy tune address to mark the end of each list properly 
;* Make sure to define the total number of tunes that could be indexed in code using it to avoid garbage data being loaded 

SongsIndexStart	
	dta a(S_Id_0) 
	dta a(S_Id_1) 
	dta a(S_Id_2) 
	dta a(S_DUMMY) 
SongsIndexEnd	

;-----------------
		
;//---------------------------------------------------------------------------------------------

LoopsIndexStart
	dta a(L_Id_0) 
	dta a(L_Id_1) 
	dta a(L_Id_2) 
	dta a(L_DUMMY) 
LoopsIndexEnd 

;-----------------			

;//---------------------------------------------------------------------------------------------

;* Intro subtunes index, this is the part of a tune that will play before a loop point 
;* If the intro and loop are identical, or close enough to sound seamless, the intro could be replaced by a dummy to save space
;* IMPORTANT: due to technical reasons, every indexes MUST end with a dummy subtune! Otherwise the entire thing will break apart!

;-----------------

;//---------------------------------------------------------------------------------------------

S_Id_0
	ins	'/Bunny Hop LZSS/TUNE_1_INTRO.lzss'
S_Id_1
	ins	'/Bunny Hop LZSS/TUNE_2_INTRO.lzss'
S_Id_2
	ins	'/Bunny Hop LZSS/TUNE_3_INTRO.lzss' 
S_DUMMY

;-----------------
		
;//---------------------------------------------------------------------------------------------

;* Looped subtunes index, if a dummy is inserted, the tune has a definite end and won't loop and/or fadeout!

L_Id_0
	ins	'/Bunny Hop LZSS/TUNE_1_LOOP.lzss' 
L_Id_1
	ins	'/Bunny Hop LZSS/TUNE_2_LOOP.lzss' 
L_Id_2
	ins	'/Bunny Hop LZSS/TUNE_3_LOOP.lzss' 
L_DUMMY 

;-----------------
		
;//--------------------------------------------------------------------------------------------- 

