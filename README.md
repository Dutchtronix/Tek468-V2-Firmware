# Tek468-V2-Firmware
This is a somewhat annotated listing of the Tektronix V2 Firmware

Assemble this file using "Makroassembler AS v1.42" by Alfred Arnold,
	ported to windows in a package called "aswcurr"
	http://john.ccac.rwth-aachen.de:8000/as/

..\aswcurr\bin\asw -i . -cpu 8085 -L rom468combined.asm

..\aswcurr\bin\p2bin.exe rom468combined -r $0000-$3fff

comp Rom468Originals.bin rom468combined.bin <no.txt

where Rom468Originals.bin is a binary copy of the combined original roms U565 and U575
and no.txt just contains the word "no"
