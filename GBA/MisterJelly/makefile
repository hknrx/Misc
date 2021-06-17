##
## Mister Jelly - makefile
## Nicolas ROBERT [NRX] - France 2006
##

#################
# Nom de la ROM #
#################
PROGNAME = MisterJelly

##########################
# Options de compilation #
##########################
HAMDIR  = E:/Coding/GBA
GCCARM  = $(HAMDIR)/gcc-arm

INCDIR  = -I $(GCCARM)/arm-thumb-elf/include
LIBDIR  = -L $(GCCARM)/arm-thumb-elf/lib/interwork \
			 -L $(GCCARM)/lib/gcc-lib/arm-thumb-elf/3.3.2/interwork

LD_LIBS = -lm -lgcc -lc

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
			Sources/Common/GBAccelerometer/GBAccelerometer.o	\
			Sources/Game/Game.o	\
			Sources/Game/Blob/Blob.o	\
			Graphics/Generated/Sprites.raw.o \
			Graphics/Generated/Sprites.pal.o \
			Graphics/Generated/Background.raw.o \
			Graphics/Generated/Background.map.o \
			Graphics/Generated/Background.pal.o

#######################
# Targets "standards" #
#######################
all: $(PROGNAME).gba

%.gba: %.elf
	$(OBJCOPY) -v -O binary $< $@
	gbafix.exe $@ -t$*

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
Graphics/Generated/%.raw.s Graphics/Generated/%.map.s Graphics/Generated/%.pal.s: Graphics/Resources/%.bmp
	gfx2gba -fasm -c16 -x -t8 -zt -m -zm -oGraphics/Generated $<

# Graphismes : regles particulieres
Graphics/Generated/Background.raw.s Graphics/Generated/Background.map.s Graphics/Generated/Background.pal.s: Graphics/Resources/Background.bmp
	gfx2gba -fasm -x -t8 -zt -rs -F -m -zm -oGraphics/Generated $<

Graphics/Generated/Sprites.raw.s Graphics/Generated/Sprites.pal.s: Graphics/Resources/Sprites.bmp
	gfx2gba -fasm -x -t8 -zt -oGraphics/Generated $<

#######
# END #
#######

