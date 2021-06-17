##
## Adpcm - makefile
## Nicolas ROBERT [NRX] - Hong Kong 2005
##

################
# HAM Makefile #
################
include master.mak

#
# Set the name of your desired GBA image name here
#
PROGNAME=Adpcm

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
	Sources/Commun/Commun.o	\
	Sources/Commun/Adpcm/Decoder/Adpcm.o   \
	Sons/Music.o  \
	Sons/Effect.o  \

#
# Set a list of libraries you want to link
#
ADD_LIBS +=

########################################
# Standard Makefile targets start here #
########################################
all: clean	\
	sfx	\
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
	$(HAMDIR)/tools/$(HAM_PLATFORM)/rm -f Sources/Commun/*.o
	$(HAMDIR)/tools/$(HAM_PLATFORM)/rm -f Sources/Commun/Adpcm/Decoder/*.o

sfx_:

sfx:
	cd $(VHAM_CURPROJECT);Sources/Commun/Adpcm/Encoder/Adpcm.exe Music Sons/Ressources Sons
	cd $(VHAM_CURPROJECT);Sources/Commun/Adpcm/Encoder/Adpcm.exe Effect Sons/Ressources Sons -nocompress

#######
# END #
#######

