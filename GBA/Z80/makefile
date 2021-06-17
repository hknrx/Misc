##
## Z80 - makefile
## Nicolas ROBERT [NRX] - Hong Kong 2005
##

################
# HAM Makefile #
################
include master.mak

#
# Set the name of your desired GBA image name here
#
PROGNAME=Z80

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
	Sources/Common/Common.o \
	Sources/CPU/z80.o	\
	Snapshots/FF.o \
	Snapshots/BJ1.o \
	Snapshots/BJrun.o	\
	Snapshots/CRAFTONrun.o

#
# Set a list of libraries you want to link
#
ADD_LIBS +=

########################################
# Standard Makefile targets start here #
########################################
all: clean	\
	loader	\
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
	$(HAMDIR)/tools/$(HAM_PLATFORM)/rm -f Sources/CPU/*.o
	$(HAMDIR)/tools/$(HAM_PLATFORM)/rm -f Snapshots/*.o Snapshots/*.s

loader:
	cd $(VHAM_CURPROJECT)/Sources/Loader;./Loader.bat
	cd $(VHAM_CURPROJECT);Sources/Loader/Loader.exe FF Snapshots Snapshots
	cd $(VHAM_CURPROJECT);Sources/Loader/Loader.exe BJ1 Snapshots Snapshots
	cd $(VHAM_CURPROJECT);Sources/Loader/Loader.exe BJ2 Snapshots Snapshots
	cd $(VHAM_CURPROJECT);Sources/Loader/Loader.exe BJrun Snapshots Snapshots
	cd $(VHAM_CURPROJECT);Sources/Loader/Loader.exe BJIIrun Snapshots Snapshots
	cd $(VHAM_CURPROJECT);Sources/Loader/Loader.exe CRAFTONrun Snapshots Snapshots

#######
# END #
#######

