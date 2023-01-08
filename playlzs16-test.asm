;
; LZSS Compressed SAP player for 16 match bits
; --------------------------------------------
;
; (c) 2020 DMSC
; Code under MIT license, see LICENSE file.
;
; This player uses:
;  Match length: 8 bits  (1 to 256)
;  Match offset: 8 bits  (1 to 256)
;  Min length: 2
;  Total match bits: 16 bits
;
; Compress using:
;  lzss -b 16 -o 8 -m 1 input.rsap test.lz16
;
; Assemble this file with MADS assembler, the compressed song is expected in
; the `test.lz16` file at assembly time.
;
; The plater needs 256 bytes of buffer for each pokey register stored, for a
; full SAP file this is 2304 bytes.
;

RTCLOK 		= $12
COLBK           = $D01A
VCOUNT          = $D40B

//////////////////////////////////

	org $80

chn_copy	.ds     9
chn_pos		.ds     9
bptr		.ds     2
SongStartPtr	.ds     2
SongEndPtr	.ds     2
song_ptr	.ds	2
cur_pos		.ds     1
chn_bitsInit	.ds     1
chn_bits	.ds     1
ptr_offset	.ds	1
bit_data	.byte   1

//////////////////////////////////

	org $800
buffers
	.ds 256 * 9
	
//////////////////////////////////

song_data
;	ins     '/RANDOM3/SKETCH_71_TUNE_1_LOOP.lzss'
	ins 	'/RANDOM3/SHORELINE_LOOP.lzss'
;	ins	'/RANDOM3/SKETCH_53_LOOP.lzss'
;	ins 	'/RANDOM3/DUMB3_LOOP.lzss'
;	ins	'/RANDOM3/SIEUR_GOUPIL_LOOP.lzss'
song_end

//////////////////////////////////

;* Begin here, setup pointers, etc etc, you know the dril

start
	ldx #50
wait_second
	jsr wait_vblank
	dex 
	bpl wait_second
SetNewSongPtrs
	mwa #song_data SongStartPtr
	mwa #song_end SongEndPtr
restart
	jsr init_song
loop
	lda #0
	sta COLBK
wait_frame
	lda VCOUNT
	bne wait_frame
play
	lda #$69
	sta COLBK
	jsr setpokeyfull
	jsr check_end_song
	beq restart	
	jsr play_frame
	jmp loop

//////////////////////////////////

;* Check for ending of song and jump to the next frame

check_end_song
	lda song_ptr+1
	cmp SongEndPtr+1
	bne check_end_song_done
	lda song_ptr
	cmp SongEndPtr
check_end_song_done
	rts

//////////////////////////////////

init_song
	mwa SongStartPtr song_ptr
	ldy #0
	sty bptr			; Initialize buffer pointer
	sty cur_pos
	lda (song_ptr),y		; Get the first byte to set the channel bits
	sta chn_bitsInit
	iny
	sty bit_data			; always get new bytes
	lda #>buffers			; Set the buffer offset 
	sta cbuf+2
	ldx #8				; Init all channels
clear
	lda (song_ptr),y		; Read just init value and store into buffer and POKEY
	iny
	sta SDWPOK0,x
;	sty chn_copy,x
cbuf
	sta buffers+255
	inc cbuf+2
	dex
	bpl clear
	tya
	clc
	adc song_ptr
	sta song_ptr
	scc:inc song_ptr+1
	rts

/*
init_song
	mwa SongStartPtr song_ptr
	jsr get_byte			; Get the first byte to set the channel bits
	sta chn_bitsInit
	lda #>buffers			; Set the buffer offset 
	sta cbuf+2
	ldy #1
	sty bit_data			; always get new bytes
	dey
	sty bptr			; Initialize buffer pointer
	sty cur_pos	
	ldx #8				; Init all channels
clear
	jsr get_byte			; Read just init value and store into buffer and POKEY
	sta SDWPOK0,x
	sty chn_copy,x
cbuf
	sta buffers+255
	inc cbuf+2
	dex
	bpl clear
	rts
*/

//////////////////////////////////

;* TODO: Use indirect addressing, to remove the need for multiple JSRs

/*
get_byte
	ldy #0
	lda (song_ptr),y
	inc song_ptr
	bne skip
	inc song_ptr+1
skip
	rts
*/

//////////////////////////////////

;* Play one frame of the song

play_frame
	lda #>buffers
	sta bptr+1
	lda chn_bitsInit
	sta chn_bits
	ldx #8			; Loop through all "channels", one for each POKEY register
	ldy #0 
	sty ptr_offset

chn_loop:
	lsr chn_bits
	bcs skip_chn		; C=1 : skip this channel
	lda chn_copy, x		; Get status of this stream
	bne do_copy_byte	; If > 0 we are copying bytes
	
	ldy ptr_offset

;* We are decoding a new match/literal

	lsr bit_data		; Get next bit
	bne got_bit
	
;	jsr get_byte		; Not enough bits, refill!
	lda (song_ptr),y
	iny
	
	ror			; Extract a new bit and add a 1 at the high bit (from C set above)
	sta bit_data
	
got_bit:

;	jsr get_byte		; Always read a byte, it could mean "match size/offset" or "literal byte"
	lda (song_ptr),y
	iny
	
	sty ptr_offset
	
	bcs store		; Bit = 1 is "literal", bit = 0 is "match"
	sta chn_pos, x		; Store in "copy pos"
	
;	jsr get_byte
	lda (song_ptr),y
	iny
	
	sta chn_copy, x		; Store in "copy length"
	
	sty ptr_offset

;* And start copying first byte

do_copy_byte:
	dec chn_copy, x		; Decrease match length, increase match position
	inc chn_pos, x
	ldy chn_pos, x
	lda (bptr), y		; Now, read old data, jump to data store
store:
	ldy cur_pos
	sta SDWPOK0,x		; Store to output and buffer
	sta (bptr), y
skip_chn:
	inc bptr+1		; Increment channel buffer pointer
	dex
	bpl chn_loop		; Next channel
	inc cur_pos
	
	lda song_ptr
	clc
	adc ptr_offset
	sta song_ptr
	scc:inc song_ptr+1
	
	rts

//////////////////////////////////

;* Wait for vblank subroutine

wait_vblank 
	lda RTCLOK+2		; load the real time frame counter to accumulator
wait        
	cmp RTCLOK+2		; compare to itself
	beq wait		; equal means it vblank hasn't began
	rts
	
//////////////////////////////////
	
setpokeyfull
	lda POKSKC0 
	sta $D20F 
	ldy POKCTL0
	lda POKF0
	ldx POKC0
	sta $D200
	stx $D201
	lda POKF1
	ldx POKC1
	sta $D202
	stx $D203
	lda POKF2
	ldx POKC2
	sta $D204
	stx $D205
	lda POKF3
	ldx POKC3
	sta $D206
	stx $D207
	sty $D208
	rts

SDWPOK0 
POKF0	dta $00
POKC0	dta $00
POKF1	dta $00
POKC1	dta $00
POKF2	dta $00
POKC2	dta $00
POKF3	dta $00
POKC3	dta $00
POKCTL0	dta $00
POKSKC0	dta $03	

//////////////////////////////////

;* Run from start address, and done

	run start

