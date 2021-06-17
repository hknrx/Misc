##
## God - makefile
## Nicolas ROBERT [NRX] - Hong Kong 2005
##

################
# HAM Makefile #
################
include master.mak

#
# Set the name of your desired GBA image name here
#
PROGNAME=God

#
# Compile using Krawall software? (set to yes or no)
# Also specify if Krawall is registered (yes or no)
#
USE_KRAWALL=no
KRAWALL_IS_REGISTERED=no
KRAWALL_FILES=

#
# Set a list of files you want to compile
#
OFILES += Sources/crt0.o	\
	Sources/Main.o	\
	Sources/Common/Common.o	\
	Sources/Common/Adpcm/Decoder/Adpcm.o	\
	Sources/Intro/Intro.o	\
	Sources/Intro/Bump/Bump.o	\
	Sources/Intro/Voxel/Voxel.o	\
	Sources/World/World.o	\
	Sources/World/3dIso/3dIso.o	\
	Sources/World/AStar/AStar.o	\
	Sounds/Generated/EffectAmbiant01.o	\
	Sounds/Generated/EffectAmbiant02.o	\
	Sounds/Generated/EffectAmbiant03.o	\
	Sounds/Generated/EffectPutBloc.o	\
	Sounds/Generated/EffectRemoveBloc.o	\
	Sounds/Generated/EffectStartGame.o	\
	Sounds/Generated/MusicAmbiant01.o	\
	Sounds/Generated/MusicAmbiant02.o	\
	Sounds/Generated/MusicAmbiant03.o	\
	Sounds/Generated/MusicAmbiant04.o	\
	Sounds/Generated/MusicTitle.o	\
	Graphics/Generated/Font.raw.o	\
	Graphics/Generated/Nrx.raw.o	\
	Graphics/Generated/HongKong2005.raw.o	\
	Graphics/Generated/GOD.pal.o	\
	Graphics/Generated/GOD.raw.o	\
	Graphics/Generated/Sprites3dIso.pal.o	\
	Graphics/Generated/Sprites3dIso.raw.o	\
	Graphics/Generated/Tiles3dIso.pal.o	\
	Graphics/Generated/Tiles3dIso.raw.o	\
	Graphics/Generated/TilesMenu.raw.o

#
# Set a list of libraries you want to link
#
ADD_LIBS +=

########################################
# Standard Makefile targets start here #
########################################
all: clean	\
	sfx	\
	gfx	\
	$(PROGNAME).$(EXT)

#
# Most Makefile targets are predefined for you, such as
# vba, clean... in the following file
#
include $(HAMDIR)/system/standard-targets.mak

######################################
# Custom Makefile targets start here #
######################################
clean:
	$(HAMDIR)/tools/$(HAM_PLATFORM)/rm -f *.o *.i *.s *.elf
	$(HAMDIR)/tools/$(HAM_PLATFORM)/rm -f Sources/*.o
	$(HAMDIR)/tools/$(HAM_PLATFORM)/rm -f Sources/Common/*.o
	$(HAMDIR)/tools/$(HAM_PLATFORM)/rm -f Sources/Common/Adpcm/Decoder/*.o
	$(HAMDIR)/tools/$(HAM_PLATFORM)/rm -f Sources/Intro/*.o
	$(HAMDIR)/tools/$(HAM_PLATFORM)/rm -f Sources/Intro/Bump/*.o
	$(HAMDIR)/tools/$(HAM_PLATFORM)/rm -f Sources/Intro/Voxel/*.o
	$(HAMDIR)/tools/$(HAM_PLATFORM)/rm -f Sources/World/*.o
	$(HAMDIR)/tools/$(HAM_PLATFORM)/rm -f Sources/World/3dIso/*.o
	$(HAMDIR)/tools/$(HAM_PLATFORM)/rm -f Sources/World/AStar/*.o

sfx:

sfx_:
	Sources/Common/Adpcm/Encoder/Adpcm.exe EffectAmbiant01  Sounds/Resources Sounds/Generated -nocompress
	Sources/Common/Adpcm/Encoder/Adpcm.exe EffectAmbiant02  Sounds/Resources Sounds/Generated -nocompress
	Sources/Common/Adpcm/Encoder/Adpcm.exe EffectAmbiant03  Sounds/Resources Sounds/Generated -nocompress
	Sources/Common/Adpcm/Encoder/Adpcm.exe EffectPutBloc    Sounds/Resources Sounds/Generated
	Sources/Common/Adpcm/Encoder/Adpcm.exe EffectRemoveBloc Sounds/Resources Sounds/Generated
	Sources/Common/Adpcm/Encoder/Adpcm.exe EffectStartGame  Sounds/Resources Sounds/Generated -nocompress
	Sources/Common/Adpcm/Encoder/Adpcm.exe MusicAmbiant01   Sounds/Resources Sounds/Generated
	Sources/Common/Adpcm/Encoder/Adpcm.exe MusicAmbiant02   Sounds/Resources Sounds/Generated
	Sources/Common/Adpcm/Encoder/Adpcm.exe MusicAmbiant03   Sounds/Resources Sounds/Generated
	Sources/Common/Adpcm/Encoder/Adpcm.exe MusicAmbiant04   Sounds/Resources Sounds/Generated
	Sources/Common/Adpcm/Encoder/Adpcm.exe MusicTitle       Sounds/Resources Sounds/Generated

gfx:

gfx_:
	gfx2gba -fasm -Z  -t8 -x -oGraphics\\Generated -P                 Graphics\\Resources\\Common\\Font.bmp
	gfx2gba -fasm -Z         -oGraphics\\Generated -P                 Graphics\\Resources\\Intro\\Bump\\Nrx.bmp
	gfx2gba -fasm            -oGraphics\\Generated -P                 Graphics\\Resources\\Intro\\Bump\\HongKong2005.bmp
	gfx2gba -fasm -zp -t8 -x -oGraphics\\Generated -pGOD.pal          Graphics\\Resources\\Intro\\Voxel\\GOD.bmp
	gfx2gba -fasm -zt -t8 -x -oGraphics\\Generated -pSprites3dIso.pal Graphics\\Resources\\World\\3dIso\\Sprites3dIso.bmp
	gfx2gba -fasm -zt -t8 -x -oGraphics\\Generated -pTiles3dIso.pal   Graphics\\Resources\\World\\3dIso\\Tiles3dIso.bmp
	gfx2gba -fasm     -t8 -x -oGraphics\\Generated -P                 Graphics\\Resources\\World\\3dIso\\TilesMenu.bmp

#######
# END #
#######

