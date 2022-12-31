;* --- Dumb Unless Made Better ---
;*
;* DUMB Soundtest-LZSS v0.1
;*
;* An attempt for a flexible LZSS music driver for the Atari 8-bit
;* By VinsCool, being worked on from July 27th to July 30th 2022 
;*
;* To build: 'mads lzssp.asm -l:ASSEMBLED/build.lst -o:ASSEMBLED/build.xex' 

;-----------------

;//---------------------------------------------------------------------------------------------

DISPLAY 	equ $FE		; Display List indirect memory address

;* Subtune index number is offset by 1, meaning the subtune 0 would be subtune 1 visually

TUNE_NUM	equ 3 		; Bunny Hop music by PG 

;* Sound effects index number will be displayed the same way for simplicity

SFX_NUM		equ 10		; Bunny Hop SFX by PG 

;-----------------

;//---------------------------------------------------------------------------------------------

;* Initialisation, then loop infinitely unless the program is told otherwise 

start       
	ldx #0			; disable playfield and the black colour value
	stx SDMCTL		; write to Shadow Direct Memory Access Control address
	jsr wait_vblank		; wait for vblank before continuing
	stx COLOR4		; Shadow COLBK (background colour), black
	stx COLOR2		; Shadow COLPF2 (playfield colour 2), black
	mwa #dlist SDLSTL	; Start Address of the Display List
	stx SongIdx 		; default tune index number
	stx SfxIdx 		; default sfx index number
	jsr set_index_count 	; print number of tunes and sfx indexed in memory
	jsr set_tune_name	; print the tune name 
	jsr set_sfx_name	; print the sfx name
	jsr stop_pause_reset	; clear the POKEY registers first 
	jsr SetNewSongPtrsFull	; initialise the LZSS driver with the song pointer using default values always 
	jsr detect_region
	jsr reset_timer	
	dec play_skip 		; initialise the PAL/NTSC condition, player is skipped every 6th frame in NTSC 
	ldx #$22		; DMA enable, normal playfield
	stx SDMCTL		; write to Shadow Direct Memory Access Control address
	ldx #50	
wait_init   
	jsr wait_vblank		; wait for vblank => 50 frames
	dex			; decrement index x
	bne wait_init		; repeat until x = 0, total wait time is ~2 seconds
init_done
	sei			; Set Interrupt Disable Status
	mwa VVBLKI oldvbi       ; vbi address backup
	mwa #vbi VVBLKI		; write our own vbi address to it 
	mva #$40 NMIEN		; enable vbi interrupts
	
;-----------------

;//---------------------------------------------------------------------------------------------

;* Mainloop, anything that could run while the screen is drawing 

loop
	jmp loop		; infinitely
	
;----------------- 

;//---------------------------------------------------------------------------------------------

;* VBI loop, run through all the code that is needed, then return with a RTI 

vbi 
	ldx #0				; PAL/NTSC adjustment flag 
play_skip equ *-1
	bmi do_play_always		; #$FF -> PAL region was detected 
	beq dont_play_this_frame	; #0 -> NTSC region was detected, skip the player call for this frame 
	dex 				; decrement the counter for the next frame
	stx play_skip 			; and overwrite the value 
	bpl do_play_always		; unconditional, this frame will be played
dont_play_this_frame
	lda #5				; reset the counter 
	sta play_skip
	bpl check_key_pressed 		; and skip this frame 
do_play_always 
	jsr setpokeyfull		; update the POKEY registers first, for both the SFX and LZSS music driver 
do_play
	lda is_playing_flag 		; 0 -> is playing, else it is either stopped or paused 
	bne do_sfx			; in this case, nothing will happen until it is changed back to 0 
	jsr LZSSPlayFrame		; Play 1 LZSS frame
	jsr LZSSUpdatePokeyRegisters	; buffer to let setpokeyfast match the RMT timing 
	jsr fade_volume_loop		; run the fadeing out code from here until it's finished
	lda is_playing_flag		; was the player paused/stopped after fadeing out?
	bne do_sfx			; if not equal, it was most likely stopped, and so there is nothing else to do here 
	jsr LZSSCheckEndOfSong		; is the current LZSS index done playing?
	bne do_sfx			; if not, go back to the loop and wait until the next call
	jsr SetNewSongPtrs		; update the subtune index for the next one in adjacent memory 
do_sfx
	jsr play_sfx			; process the SFX data, if an index is queued and ready to play for this frame 
	
;-----------------

check_key_pressed 
	ldx SKSTAT		; Serial Port Status
	txa
	and #$04		; last key still pressed?
	bne continue		; if not, skip ahead, no input to check 
	lda KBCODE		; Keyboard Code  
	and #$3F		; clear the SHIFT and CTRL bits out of the key identifier for the next part
	tay
	txa
	and #$08		; SHIFT key being held?
	beq skip_held_key_check	; if yes, skip the held key flag check, else, verify if the last key is still being held
check_keys_always
	lda #0 			; was the last key pressed also held for at least 1 frame? This is a measure added to prevent accidental input spamming
	held_key_flag equ *-1
	bmi continue_b		; the held key flag was set if the value is negative! skip ahead immediately in this case 
skip_held_key_check
	jsr check_keys		; each 'menu' entry will process its action, and return with RTS, the 'held key flag' must then be set!
	ldx #$FF
	bmi continue_a		; skip ahead and set the held key flag! 
continue			; do everything else during VBI after the keyboard checks 
	ldx #0			; reset the held key flag! 
continue_a 			; a new held key flag is set when jumped directly here
	stx held_key_flag 
continue_b 			; a key was detected as held when jumped directly here 
	jsr print_player_infos	; print most of the stuff on screen using printhex or printinfo in bulk 	
	jsr calculate_time 	; update the timer, this one is actually necessary, so even with DMA off, it will be executed
	jsr check_joystick	; check the inputs for tunes and sfx index 
return_from_vbi	
	pla			;* since we're in our own vbi routine, pulling all values manually is required! 
	tay
	pla
	tax
	pla
	rti			; return from interrupt, this ends the VBI time, whenever it actually is "finished" 

;-----------------

;//---------------------------------------------------------------------------------------------

;* Everything below this point is either stand alone subroutines that can be called at any time, and the display list 

;//---------------------------------------------------------------------------------------------

;* Wait for vblank subroutine

wait_vblank 
	lda RTCLOK+2		; load the real time frame counter to accumulator
wait        
	cmp RTCLOK+2		; compare to itself
	beq wait		; equal means it vblank hasn't began
	rts

;-----------------

; Print text from data tables, useful for many things 

printinfo 
	sty charbuffer
	ldy #0
do_printinfo
        lda $ffff,x
infosrc equ *-2
	sta (DISPLAY),y
	inx
	iny 
	cpy #0
charbuffer equ *-1
	bne do_printinfo 
	rts

;-----------------

; Print hex characters for several things, useful for displaying all sort of debugging infos
	
printhex
	ldy #0
printhex_direct     ; workaround to allow being addressed with y in different subroutines
	pha
	:4 lsr @
	;beq ph1    ; comment out if you want to hide the leftmost zeroes
	tax
	lda hexchars,x
ph1	
        sta (DISPLAY),y+
	pla
	and #$f
	tax
	mva hexchars,x (DISPLAY),y
	rts
hexchars 
        dta d"0123456789ABCDEF"

;-----------------

;* Convert Hexadecimal numbers to Decimal without lookup tables 
;* Based on the routine created by Andrew Jacobs, 28-Feb-2004 
;* http://6502.org/source/integers/hex2dec-more.htm 

hex2dec_convert
	cmp #10			; below 10 -> 0 to 9 inclusive will display like expected, skip the conversion
	bcc hex2dec_convert_b
	cmp #100		; process with numbers below 99, else skip the conversion entirely 
	bcs hex2dec_convert_b  
hex2dec_convert_a
	sta hex_num		; temporary 
	sed
	lda #0			; initialise the conversion values
	sta dec_num
	sta dec_num+1
	ldx #7			; 8 bits to process 
hex2dec_loop
	asl hex_num 
	lda dec_num		; And add into result
	adc dec_num
	sta dec_num
	lda dec_num+1		; propagating any carry
	adc dec_num+1
	sta dec_num+1
	dex			; And repeat for next bit
	bpl hex2dec_loop
	cld			; Back to binary
	lda dec_num 
hex2dec_convert_b
	rts			; the value will be returned in the accumulator 

dec_num dta $00,$00
hex_num dta $00
	
;-----------------

; Stop and quit when execution jumps here

stop_and_exit
	jsr stop_pause_reset 
	mwa oldvbi VVBLKI	; restore the old vbi address
	ldx #$00		; disable playfield 
	stx SDMCTL		; write to Direct Memory Access (DMA) Control register
	dex			; underflow to #$FF
	stx CH			; write to the CH register, #$FF means no key pressed
	cli			; this may be why it seems to crash on hardware... I forgot to clear the interrupt bit!
	jsr wait_vblank		; wait for vblank before continuing
	jmp (DOSVEC)		; return to DOS, or Self Test by default

;----------------- 

;* Detect the machine region subroutine

detect_region	
	lda VCOUNT
	beq check_region	; vcount = 0, go to check_region and compare values
	tax			; backup the value in index y
	bne detect_region 	; repeat 
check_region
	cpx #$9B		; compare X to 155
	bmi set_ntsc		; negative result means the machine runs at 60hz
	lda #50
	ldx #0			; roll over to #$FF, will always play
	beq region_done
set_ntsc
	lda #60
	ldx #6 			; every 6th frame, a play call is skipped to adjust the speed between PAL to NTSC 
region_done	
	stx play_skip 
	sta framecount
	rts

;-----------------

;* Print most infos on screen
	
print_player_infos
	mwa #line_0 DISPLAY 	; get the right screen position

print_minutes
	lda v_minute
	ldy #8
	jsr printhex_direct
	
print_seconds
	ldx v_second
	txa
	ldy #10
	and #1
	beq no_blink 
	lda #0
	beq blink
no_blink 
	lda #":" 
blink
	sta (DISPLAY),y 
	iny 
done_blink
	txa
	jsr printhex_direct

print_order	
	lda ZPLZS.SongPtr+1
	ldy #34
	jsr printhex_direct
	
print_row
	lda ZPLZS.SongPtr 
	ldy #36
	jsr printhex_direct 
	
print_tune
	lda #1
tune_index equ *-1
	jsr hex2dec_convert 
	ldy #125
	jsr printhex_direct 
	
print_sfx
	lda #1
sfx_index equ *-1
	jsr hex2dec_convert 
	ldy #165
	jsr printhex_direct 

print_pointers
	ldy #55
	lda LZS.SongStartPtr+1
	jsr printhex_direct
	iny
	lda LZS.SongStartPtr
	jsr printhex_direct	
	ldy #71
	lda LZS.SongEndPtr+1
	jsr printhex_direct
	iny
	lda LZS.SongEndPtr
	jsr printhex_direct
	
print_flags
	ldy #89
	lda LZS.Initialized
	jsr printhex_direct
	
	ldy #97
	lda is_playing_flag
	jsr printhex_direct
	
	ldy #105
	lda is_looping
	jsr printhex_direct

	ldy #113
	lda is_fadeing_out
	jsr printhex_direct
	
	rts
	
;-----------------

;* Joystick input handler, using PORTA 

check_joystick
	ldx PORTA
	txa
	and #%00001111
	cmp #%00001111			; neutral
	bne check_joystick_being_held
	lda #0
	sta held_joystick_flag		; reset held joystick flag
	lda TRIG0			; 'Fire' button
	beq check_fire_being_held	; button pressed if 0
	lda #0
	sta held_fire_flag		; reset held button flag
	beq check_joystick_done
check_fire_being_held
	lda #0
held_fire_flag equ *-1
	bmi check_joystick_done		; fire is already being held, ignore the input
	dec held_fire_flag		; held button flag set again
	jmp set_sfx_to_play		; end with a RTS!
check_joystick_being_held
	lda #0
held_joystick_flag equ *-1
	bpl check_joystick_up_down	; process the check, otherwise, a direction is already being held, ignore the input 	
check_joystick_done
	rts

;-----------------

;* Up and Down bits

check_joystick_up_down
	ldy sfx_index	
	txa
	and #%00000011
	cmp #%00000011
	beq check_joystick_left_right
	dec held_joystick_flag

;-----------------

;* Down

do_joystick_down
	cmp #%00000001 
	bne do_joystick_up
	dey
	beq sfx_index_wrap
	bmi sfx_index_wrap
	bne update_sfx_index
sfx_index_wrap
	ldy #SFX_NUM
	bpl update_sfx_index

;-----------------

;* Up

do_joystick_up	
	cmp #%00000010 
	bne update_sfx_index
	iny
	cpy #SFX_NUM
	bcc update_sfx_index
	beq update_sfx_index
	ldy #1
update_sfx_index
	sty sfx_index 
	jsr check_sfx_index 
	lda #1				; play sfx: menu movement 
	jmp set_sfx_to_play_immediate	; end with a RTS! 

;-----------------

;* Left and Right bits

check_joystick_left_right
	ldy tune_index
	txa
	and #%00001100
	cmp #%00001100
	beq check_joystick_done
	dec held_joystick_flag 

;-----------------

;* Left

do_joystick_left	
	cmp #%00001000 
	bne do_joystick_right
	dey
	beq tune_index_wrap
	bmi tune_index_wrap
	bne update_tune_index
tune_index_wrap
	ldy #TUNE_NUM
	bpl update_tune_index

;-----------------

;* Right 

do_joystick_right	
	cmp #%00000100 
	bne update_tune_index 
	iny
	cpy #TUNE_NUM
	bcc update_tune_index
	beq update_tune_index
	ldy #1
update_tune_index
	sty tune_index
	jsr check_tune_index 
	lda #1				; play sfx: menu movement 
	jmp set_sfx_to_play_immediate	; end with a RTS!  

;-----------------

;* Initialise the SFX to play in memory once the joystick button is pressed, using the SFX index number

set_sfx_to_play
	lda #0
SfxIdx equ *-1
set_sfx_to_play_immediate
	asl @
	tax
	lda sfx_data,x
	sta sfx_src
	lda sfx_data+1,x
	sta sfx_src+1
	inc is_playing_sfx 
	lda #3 
	sta sfx_channel
	lda #0
	sta sfx_offset
	rts

;-----------------

;* Play the SFX currently set in memory, one frame every VBI

play_sfx
	lda #$FF		; #$00 -> Play SFX until it's ended, #$FF -> SFX has finished playing and is stopped
is_playing_sfx equ *-1
	bmi play_sfx_done
	lda #2			; 2 frames
	sta is_playing_sfx
	lda #0
sfx_offset equ *-1
	asl @
	tax
	inc sfx_offset
	lda #0
sfx_channel equ *-1
	asl @
	tay
	bpl begin_play_sfx
play_sfx_loop
	inx
	iny
begin_play_sfx
        lda $ffff,x
sfx_src equ *-2
	sta SDWPOK0,y
	dec is_playing_sfx
	bne play_sfx_loop
	lda SDWPOK0,y
	bne play_sfx_done
	dec is_playing_sfx
play_sfx_done
	rts

;-----------------

;* Compare the tune index number to the one being displayed
;* If they don't match, a new tune will play!

check_tune_index 
	ldx tune_index
	dex				; offset by 1, since the first entry is 0
	cpx SongIdx
	bne check_tune_index_a 
check_tune_index_done	
	rts				; if they are the same, there is nothing else to do here 
check_tune_index_a	
	stx SongIdx
	jsr update_tune_name 
	jsr SetNewSongPtrsFull 
	jmp reset_timer 		; end with a RTS! 

;-----------------

;* Compare the sfx index number to the one being displayed
;* If they don't match, a new sfx will play!

check_sfx_index 
	ldx sfx_index
	dex				; offset by 1, since the first entry is 0
	cpx SfxIdx 
	bne check_sfx_index_a 
check_sfx_index_done	
	rts				; if they are the same, there is nothing else to do here 
check_sfx_index_a
	stx SfxIdx
	jmp update_sfx_name 		; end with a RTS! 

;-----------------

;* Update the song name displayed on screen based on the index number

set_tune_name
	ldx #0				; default index number, else, use the value from X directly
update_tune_name
	mwa #line_3+12 DISPLAY		; set the screen coordinates for the song name displayed on screen
	mwa #song_name infosrc		; set the memory address for the text data 
	jmp update_both_name		; end with a RTS over there! 

;-----------------

;* Update the sfx name displayed on screen based on the index number

set_sfx_name
	ldx #0				; default index number, else, use the value from X directly
update_sfx_name
	mwa #line_4+12 DISPLAY		; set the screen coordinates for the sfx name displayed on screen
	mwa #sfx_name infosrc		; set the memory address for the text data 

;-----------------

;* Both the song name and sfx name will use the same code for drawing text on screen after addresses initialisation 

update_both_name 
	txa
	:5 asl @
	scc:inc infosrc+1
	tax 
	ldy #28				; 32 characters per index 
	jmp printinfo			; end with a RTS! 

;-----------------

;* Display the number of tunes and sfx indexed in memory, using the values defined at assembly time 

set_index_count
	mwa #line_0 DISPLAY 	; get the right screen position
	lda #TUNE_NUM
	jsr hex2dec_convert 
	ldy #128 
	jsr printhex_direct
	lda #SFX_NUM
	jsr hex2dec_convert 
	ldy #168
	jsr printhex_direct
	rts

;-----------------

;* check all keys that have a purpose here... 
;* this is the world's most cursed jumptable ever created!
;* regardless, this finally gets rid of all the spaghetti code I made previously!

check_keys 
	tya				; transfer to the accumulator to make a quick and dirty jump table
	asl @				; ASL only once, allowing a 2 bytes index, good enough for branching again immediately and unconditionally, 128 bytes needed sadly...
	sta k_index+1			; branch will now match the value of Y
k_index	bne * 
	rts:nop				; Y = 0 -> L key
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	rts:nop				; Y = 6 -> Atari 'Left' / '+' key
	rts:nop				; Y = 7 -> Atari 'Right' / '*' key 
	bcc do_stop_toggle 		; Y = 8 -> 'O' key (not zero!!) 
	rts:nop
	bcc do_play_pause_toggle	; Y = 10 -> 'P' key
	rts:nop
	rts:nop				; Y = 12 -> 'Enter' key
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	rts:nop				; Y = 18 -> 'C' key
	rts:nop
	rts:nop
	rts:nop
	rts:nop				; Y = 22 -> 'X' key
	rts:nop				; Y = 23 -> 'Z' key
	rts:nop				; Y = 24 -> '4' key
	rts:nop
	rts:nop				; Y = 26 -> '3' key
	rts:nop				; Y = 27 -> '6' key
	bcc do_exit			; Y = 28 -> 'Escape' key
	rts:nop				; Y = 29 -> '5' key
	rts:nop				; Y = 30 -> '2' key
	rts:nop				; Y = 31 -> '1' key
	rts:nop
	rts:nop			 	; Y = 33 -> 'Spacebar' key
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	rts:nop				; Y = 40 -> 'R' key
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	rts:nop				; Y = 46 -> 'W' key
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	rts:nop				; Y = 51 -> '7' key
	rts:nop
	rts:nop				; Y = 53 -> '8' key
	rts:nop
	rts:nop
	bcc do_trigger_fade_immediate	; Y = 56 -> 'F' key
	rts:nop				; Y = 57 -> 'H' key
	rts:nop				; Y = 58 -> 'D' key
	rts:nop
	rts:nop
	rts:nop
	rts:nop				; Y = 62 -> 'S' key
	rts:nop				; Y = 63 -> 'A' key

;-----------------

;* Jumptable from the branches above, long range in case things don't quite reach 

do_exit
	jmp stop_and_exit		; stop and exit to DOS 
	
do_stop_toggle
	jmp stop_toggle			; toggle stop flag
	
do_play_pause_toggle	
	jmp play_pause_toggle		; toggle play/pause flag

do_trigger_fade_immediate
	jmp trigger_fade_immediate	; immediately set the 'fadeout' flag then stop the player once finished
	
;-----------------

;//---------------------------------------------------------------------------------------------

;* Song and SFX text data, 32 characters per entry, display 28 characters or less for best results

song_name        
	dta d"Happy Bunnies, Boing Boing!     " 
	dta d"Fantaisie Nocturne              " 
	dta d"The Forest Is Peaceful Again    " 

sfx_name
	dta d"Menu - Press                    " 
	dta d"Menu - Movement                 " 
	dta d"Menu - Keyclick                 " 
	dta d"Menu - Code Rejected            " 
	dta d"Menu - Code Accepted            " 
	dta d"Game - Select Unselect          " 
	dta d"Game - Move Fox                 " 
	dta d"Game - Move Bunny               " 
	dta d"Game - In Hole                  " 
	dta d"Game - Cannot Do                " 

;-----------------

;* Sound effects index  

sfx_data
	dta a(sfx_00)
	dta a(sfx_01)
	dta a(sfx_02)
	dta a(sfx_03)
	dta a(sfx_04)
	dta a(sfx_05)
	dta a(sfx_06)
	dta a(sfx_07)
	dta a(sfx_08)
	dta a(sfx_09)  

;* Sound effects data 

sfx_00	ins '/Bunny Hop SFX/menu-press.sfx'
sfx_01	ins '/Bunny Hop SFX/menu-movement.sfx'
sfx_02	ins '/Bunny Hop SFX/menu-keyclick.sfx'
sfx_03	ins '/Bunny Hop SFX/menu-code_rejected.sfx'
sfx_04	ins '/Bunny Hop SFX/menu-code_accepted.sfx'
sfx_05	ins '/Bunny Hop SFX/game-select_unselect.sfx'
sfx_06	ins '/Bunny Hop SFX/game-move_fox.sfx'
sfx_07	ins '/Bunny Hop SFX/game-move_bunny.sfx'
sfx_08	ins '/Bunny Hop SFX/game-in_hole.sfx'
sfx_09	ins '/Bunny Hop SFX/game-cannot_do.sfx' 

;-----------------

;* Screen memory 
	
line_0	dta d"  Time: 00:00      LZSS Address: $0000  "
line_1	dta d"    StartPtr: $0000   EndPtr: $0000     "
line_2	dta d"     I: $00  P: $00  L: $00  F: $00     "
line_3	dta d"Tune 01/01: (insert title here)         "
line_4	dta d" SFX 01/01: (28 chars or less maybe)    "
line_5	dta d"     Tune: Left/Right SFX: Up/Down      "
line_6	dta d"  Press 'Fire' to play the selected SFX "
line_7	dta d" DUMB Soundtest-LZSS by VinsCool   "
line_7a	dta d"v0.1"*,$00

;-----------------

;* VBI address backup 

oldvbi	
	dta a(0) 
	
;-----------------

;* Display list 

dlist 
	:6 dta $70		; start with 6 empty lines
	dta $42			; ANTIC mode 2 
	dta a(line_0)		; line_0 
	:1 dta $70		; empty lines
	dta $02			; line_1
	:1 dta $70		; empty lines
	dta $02			; line_2
	:3 dta $70		; empty lines
	:2 dta $02		; line_3 and line_4
	:2 dta $70		; empty lines
	dta $02			; line_5
	:1 dta $70		; empty lines
	dta $02			; line_6 
	:4 dta $70		; empty lines
	dta $02			; line_7 
	dta $41,a(dlist)	; Jump and wait for vblank, return to dlist 
	run start 		; run address was put here for simplicity, so it come after everything else in memory 

;----------------- 

;//---------------------------------------------------------------------------------------------

;* And that's all folks :D

;----------------- 

