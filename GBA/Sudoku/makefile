##
## Sudoku - makefile
## Nicolas ROBERT [NRX] - France 2006
##

#################
# Nom de la ROM #
#################
PROGNAME = Sudoku

##########################
# Options de compilation #
##########################
HAMDIR  = E:/Coding/GBA
GCCARM  = $(HAMDIR)/gcc-arm

INCDIR  = -I $(GCCARM)/arm-thumb-elf/include
LIBDIR  = -L $(GCCARM)/arm-thumb-elf/lib/interwork \
			 -L $(GCCARM)/lib/gcc-lib/arm-thumb-elf/3.3.2/interwork

LD_LIBS = -lgcc -lc

ASFLAGS = -mthumb-interwork
CFLAGS  = $(INCDIR) -c -O2 -mthumb-interwork -mlong-calls -Wall -save-temps -fverbose-asm -nostartfiles
LDFLAGS = $(LIBDIR) --script $(HAMDIR)/system/lnkscript

AS      = $(GCCARM)/bin/arm-thumb-elf-as.exe
CC      = $(GCCARM)/bin/arm-thumb-elf-gcc.exe
LD      = $(GCCARM)/bin/arm-thumb-elf-ld.exe
OBJCOPY = $(GCCARM)/bin/arm-thumb-elf-objcopy.exe
SHELL   = sh.exe

# Celle-ci est pour faire plaisir a VHAM...
ADD_LIBS+=

#################################
# Liste des fichiers a compiler #
#################################
OFILES = Sources/crt0.o	\
			Sources/Main.o	\
			Sources/Common/Common.o	\
			Sources/Game/Game.o	\
			Sources/Game/Sudoku/Sudoku.o	\
			Graphics/Generated/GameFont.raw.o

ifeq ($(ADPCM),enabled)
CFLAGS += -DADPCM_ENABLED
OFILES += Sources/Common/Adpcm/Adpcm.o
endif

#######################
# Targets "standards" #
#######################
all: $(PROGNAME).gba

%.gba: %.elf
	$(OBJCOPY) -v -O binary $< $@
	gbafix.exe $@ -t $*

$(PROGNAME).elf: $(OFILES)
	$(LD) $(LDFLAGS) -o $@ $(OFILES) $(LD_LIBS)

%.o: %.c
	$(CC) $(CFLAGS) -o $@ $<

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

# Celle-ci est utile lorsqu'on utilise VHAM (F6)
vbawin: all
	vbawin.exe $(PROGNAME).gba

#################################
# Targets speciales a ce projet #
#################################
clean:
	rm -f $(OFILES)
	rm -f *.s *.i *.elf *.gba *.sav
	rm -f Graphics/Generated/*.s

# Graphismes : regle generique
Graphics/Generated/%.map.s Graphics/Generated/%.raw.s: Graphics/Resources/%.bmp
	gfx2gba -fasm -Z -c16 -P -x -t8 -m -oGraphics/Generated $<

# Graphismes : regles particulieres
Graphics/Generated/GameFont.raw.s: Graphics/Resources/GameFont.bmp
	gfx2gba -fasm -Z -c16 -P -x -t8 -oGraphics/Generated $<

#######
# END #
#######

