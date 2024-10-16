# Makefile.asm
#
# This Makefile takes z80 assembly code and does everything need to get it bunbled into raw cards, bmps, and can
# also directly run the result in mGBA
#
# The compiled z80 bin can either be one you have made via assembling a z80 program, or one you
# have extracted out of an existing e-reader card
SHELL :=/bin/bash


# root name of the z80 assembly file (without the .asm extension) that is the starting point of everything here 
Z80_ASM_NAME=main
# The primary name that will show up in the E-Reader interface
EREADER_NAME=SystemResources
# The root name for the raw and bmp files, will be $OUTNAME.ereader1.raw, $OUTNAME.ereader2.raw, $OUTNAME.dotcode1.bmp, etc
OUTNAME=systemResources

# If running on Linux (and presumably MacOS), this is used to run the E-Reader tools through wine
# wine.sh is just a simple script that will take an installed wine command and allow it to run against
# exe's in the bin directory
WINE=../../scripts/wine.sh
RAW2BMP=$(WINE) raw2bmp.exe
NEDCMAKE=$(WINE) nedcmake.exe
NEVPK=$(WINE) nevpk.exe
ASLINK=$(WINE) aslink.exe
ASZ80_EREADER=$(WINE) asz80-ereader.exe

# this allows a custom mgba setup to execute and run the e-reader and have the cards ready to go
# your mgba binary
MGBA=mgbae.sh
# the location of a savestate that was taken right before scanning a card in the ereader
EREADER_MGBA_SAVESTATE=~/roms/gba/ereaderUSA_savestate
# the ereader rom
EREADER_MGBA_ROM=~/roms/gba/ereaderUSA.zip

SPRITE=arrow

$(SPRITE).sprite.raw.asm: $(SPRITE).bmp
	$(WINE) gfx2gba.exe -q -p$(SPRITE).pal -t8 -c16 $(SPRITE).bmp && \
	 $(WINE) b2x.exe -p -y < $(SPRITE).raw > $(SPRITE).sprite.raw.asm

$(SPRITE).sprite.pal.asm: $(SPRITE).bmp
	$(WINE) gfx2gba.exe -q -p$(SPRITE).pal -t8 -c16 $(SPRITE).bmp && \
	 $(WINE) b2x.exe -p -y < $(SPRITE).pal > $(SPRITE).sprite.pal.asm

# this craziness allows this Makefile to work no matter how many strips a given z80 binary needs
# so after nedcmake runs, if it made one raw or 8 raws, it will create new make rules for each created raw
# that way "make raws" or "make bmps" makes the correct number accounting for all needed strips
raws.mk: $(Z80_ASM_NAME).vpk
	$(NEDCMAKE) -i $(Z80_ASM_NAME).vpk -o $(Z80_ASM_NAME).raw -type 1 -region 1 -name "$(EREADER_NAME)" -raw -save 0;
	I=1; for r in $(Z80_ASM_NAME).raw*.raw; do \
		echo "$(OUTNAME).ereader$$I.raw: $r"; \
		echo "	mv $$r $(OUTNAME).ereader$$I.raw"; \
		echo "RAW_TARGETS += $(OUTNAME).ereader$$I.raw"; \
		echo "MGBA_ECARD_FLAGS += --ecard $(OUTNAME).ereader$$I.raw"; \
		echo "$(OUTNAME).ereader$$I.bmp: $(OUTNAME).ereader$$I.raw"; \
		echo "	$(RAW2BMP) -i $(OUTNAME).ereader$$I.raw -o $(OUTNAME).dotcode$$I -dpi 600"; \
		echo "BMP_TARGETS += $(OUTNAME).ereader$$I.bmp"; \
		((I = I + 1)); \
	done > $@

-include raws.mk

raws: $(RAW_TARGETS)
bmps: $(BMP_TARGETS)

$(Z80_ASM_NAME).vpk: $(Z80_ASM_NAME).bin
	$(NEVPK) -i $(Z80_ASM_NAME).bin -o $(Z80_ASM_NAME).vpk -c -level 2

$(Z80_ASM_NAME).bin: $(Z80_ASM_NAME).s19
	objcopy --input-target=srec --output-target=binary $(Z80_ASM_NAME).s19 $(Z80_ASM_NAME).bin

$(Z80_ASM_NAME).s19: $(Z80_ASM_NAME).rel
	$(ASLINK) -n -s $(Z80_ASM_NAME).rel

$(Z80_ASM_NAME).rel: $(Z80_ASM_NAME).asm \
 $(SPRITE).sprite.raw.asm \
 $(SPRITE).sprite.pal.asm
	$(ASZ80_EREADER) -o $(Z80_ASM_NAME).asm

clean:
	rm -rf $(OUTNAME).ereader*.raw \
	$(Z80_ASM_NAME).vpk \
	$(Z80_ASM_NAME).rel \
	$(Z80_ASM_NAME).bin \
	$(Z80_ASM_NAME).s19 \
	$(Z80_ASM_NAME).raw-*.raw \
	raws.mk \
	$(OUTNAME).dotcode*.bmp

run:
	$(MGBA) --savestate $(EREADER_MGBA_SAVESTATE) $(EREADER_MGBA_ROM) $(MGBA_ECARD_FLAGS)