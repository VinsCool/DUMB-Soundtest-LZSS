# DUMB-Soundtest-LZSS
An attempt for a flexible LZSS music driver for the Atari 8-bit

By VinsCool, originally worked on from July 27th to July 30th 2022, 
using a stripped down then improved version of [VUPlayer](https://github.com/VinsCool/VUPlayer-LZSS)'s routines.
This was made as a contribution to the game Bunny Hop, by Fandal and PG.

This project became a thing out of necessity, since VUPlayer used too much hardcoded procedures, and as such, 
made it difficult to adapt into different projects as a stand alone music driver.

### To build: 
> mads lzssp.asm -l:ASSEMBLED/build.lst -o:ASSEMBLED/build.xex

### Plans for the future: 
- Backport all improvements into VUPlayer's codebase, which may remain a thing of its own if necessary
- Improve the Stereo procedure, this was a hack originally designed for VUPlayer, added at the last minute to avoid editing the Unrolled LZSS routines
- Rewrite the SFX routines, this was also a last minute addition, and was actually not even needed for Bunny Hop, but made anyway just for fun
- Cleanup code and remove any unused routines, and port the remaining "hardcoded" VUPlayer routines and optimise them accordingly
- Add a more flexible LZSS decompression routine, which may be adapted for more specific purposes later, such as memory vs cpu usage optimisations
- Optimise the compression further using clever tricks to cut down redundancy, but this is currently out of scope due to the complexity of the task
- Add new compression schemes? LZ16 seems to be the best one for now, but this is something also out of scope for this project for obvious reasons
