##########################################################################################
# HAM Makefile
#
# Created by VisualHAM - www.console-dev.de
#
##########################################################################################
include $(HAMDIR)/system/master.mak

#
# Set the name of your desired GBA image name here
#
PROGNAME=Nrx

#
# Compile using Krawall software (set to yes or no) ?
# Also specify if Krawall is registered (yes or no)
#
USE_KRAWALL=no
KRAWALL_IS_REGISTERED=no
KRAWALL_FILES=

#
# Set a list of files you want to compile
#
OFILES += main.o	\
	RayCaster.o	\
	Bump.o	\
	Commun.o	\
	Plasma.o	\
	Graphismes/playeradvance.raw.o	\
	Voxel.o	\
	Graphismes/TexturesRC.raw.o	












#
# Set a list of libraries you want to link
#
ADD_LIBS +=


##########################################################################################
# Standard Makefile targets start here
##########################################################################################
all : $(PROGNAME).$(EXT)

#
# Most Makefile targets are predefined for you, suchas
# vba, clean ... in the following file
#
include $(HAMDIR)/system/standard-targets.mak

##########################################################################################
# Custom  Makefile targets start here
##########################################################################################

gfx: makefile
#	gfx2gba -t8 -m -fsrc -ogfx gfx\\bitmap.bmp
#	gfx2gba -t8 -m -fsrc -rs -ogfx gfx\\bi
