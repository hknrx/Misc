#------------------------------------------------------------
# HAM Master.mak
#
# Standard Makefile header for HAM compliant makefiles
# by Emanuel Schleussinger - http://www.ngine.de
#
# GAMEBOY ADVANCE version
#
#------------------------------------------------------------

#
# Initial HAM flag, do not change
#
# HAM_CFLAGS += -DHAM_HAM

# This selects the type of libraries you want to link. Use 
# - thumb (thumb only library)
# - interwork (arm thumb interworking capable library)
HAM_LIBGCC_STYLE = interwork

# Set this to the directory in which you installed
# the HAM system
#
HAMDIR = e:/Coding/GBA

# Set this dir to the one that contains your
# compiler and linker and stuff (gcc.exe)
#
GCCARM = $(HAMDIR)/gcc-arm

# Standard .o files needed for all HAM programs
# do not change
#
# [NRX: DO NOT USE THE DEFAULT crt0.o]
# OFILES     =  crt0.o

# This is the software platform you are running HAM on.
# usually "win32" for windows, and "linux" for Linux systems
# Used for locating tools and scripts specific to your platform.
#
HAM_PLATFORM = win32

# This variable can hold additional UNIX style directories that will
# be scanned for source code to routines you might want to debug in your
# code (for example the sources of the standard C library). Use the following
# format to enter directories (under Win32):
# /cygdrive/drive/dir1:/cygdrive/drive/dir2:etcetc:/cygdrive/drive/dirn
#
ADD_GDB_SOURCE_DIRS =

# This reflects the toolchain versions used. Important for the library paths
# do not forget to set to new value once you upgrade the toolchain yourself.
#
HAM_VERSION_MAJOR = 2
HAM_VERSION_MINOR = 8
HAM_VERSION_BINUTILS = 2.14
HAM_VERSION_GCC = 3.3.2
HAM_VERSION_INSIGHT = 6.0
HAM_VERSION_NEWLIB = 1.11.0

# make Multiboot the standard, comment out
# normal Cart booting
#
# HAM_CFLAGS += -DHAM_MULTIBOOT 

# Enable MBV2Lib support
#
# HAM_CFLAGS += -DHAM_ENABLE_MBV2LIB

# Enable debugger support
#
# HAM_CFLAGS += -DHAM_DEBUGGER 

# Enable GDB symbol support, optional. This will also reduce 
# optimization levels to allow correct in-source debugging
ifeq ($(HAMLIBCOMPILE),1)
else
ifeq ($(MAKECMDGOALS),gdb)
HAM_CFLAGS += -O0 -g  
else
HAM_CFLAGS += -O2
endif
endif

#
# Flag MBV2 as used if make command was appropiate (this will
# redirect HAMs VBAText messaging to the MBV2 text transfer system)
#
ifeq ($(MAKECMDGOALS),mbv2)
HAM_CFLAGS += -DHAM_MBV2_USED -DHAM_DEBUGGER
endif
ifeq ($(MAKECMDGOALS),flambv2)
HAM_CFLAGS += -DHAM_MBV2_USED -DHAM_DEBUGGER
endif

# [NRX: DO NOT] Enable libHAM support
#
# HAM_CFLAGS += -DHAM_WITH_LIBHAM

#
# Emulator of choice
#
HAM_EMUPATH = 

#
# Libs to link into your binaries (remove -lham to link without HAMlib)
# (note that the double appearance of lgcc is on purpose to deal with sprintf)
#
# LD_LIBS = -lham -lm -lstdc++ -lsupc++ -lgcc -lc -lgcc
LD_LIBS = -lm -lgcc -lc

# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------

# These options are for setting up the compiler
# You should usually not need to change them.
# Unless you want to tinker with the compiler
# options. 
#

PREFIX      = bin
EXEC_PREFIX = arm-thumb-elf-

ifeq ($(HAM_PLATFORM),win32)
EXEC_POSTFIX = .exe
else
EXEC_POSTFIX = 
endif

INCDIR      = -I $(GCCARM)/include -I $(GCCARM)/arm-thumb-elf/include -I $(HAMDIR)/include -I $(HAMDIR)/system 
LIBDIR      = -L $(GCCARM)/lib/gcc-lib/arm-thumb-elf/$(HAM_VERSION_GCC)/$(HAM_LIBGCC_STYLE) \
              -L $(GCCARM)/lib/gcc-lib/arm-thumb-elf/$(HAM_VERSION_GCC) \
              -L $(GCCARM)/arm-thumb-elf/lib/$(HAM_LIBGCC_STYLE) \
              -L $(GCCARM)/arm-thumb-elf/lib \
              -L $(GCCARM)/lib 
CFLAGS      = $(INCDIR) -c $(HAM_CFLAGS) -mthumb-interwork -mlong-calls -Wall -save-temps -fverbose-asm -nostartfiles
LDFLAGS     = 
ASFLAGS     = -mthumb-interwork 
PATH       +=;$(GCCARM) 
CC          = $(GCCARM)/$(PREFIX)/$(EXEC_PREFIX)gcc$(EXEC_POSTFIX) 
GDB         = $(HAMDIR)/gcc-arm/bin/$(EXEC_PREFIX)insight$(EXEC_POSTFIX) 
AS          = $(GCCARM)/$(PREFIX)/$(EXEC_PREFIX)as$(EXEC_POSTFIX)
LD          = $(GCCARM)/$(PREFIX)/$(EXEC_PREFIX)ld$(EXEC_POSTFIX) 
OBJCOPY     = $(GCCARM)/$(PREFIX)/$(EXEC_PREFIX)objcopy$(EXEC_POSTFIX) 
EXT         = gba 
ifeq ($(HAM_PLATFORM),win32)
SHELL       = $(HAMDIR)/tools/$(HAM_PLATFORM)/sh$(EXEC_POSTFIX) 
endif
PATH       := $(GCCARM)/$(PREFIX):$(PATH)
GDB_SOURCE_DIRS = $cdir:$cwd:$(ADD_GDB_SOURCE_DIRS)
