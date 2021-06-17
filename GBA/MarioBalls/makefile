##
## Mario Balls - makefile
## Nicolas ROBERT [NRX] - Hong Kong 2005
##

################
# HAM Makefile #
################
include master.mak

#
# Set the name of your desired GBA image name here
#
PROGNAME=MarioBalls

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
	Sources/Boules/Boules.o	\
	Sources/Boules/Niveaux.o	\
	Sources/Bump/Bump.o	\
	Sources/Commun/Commun.o	\
	Sources/Commun/Adpcm/Decoder/Adpcm.o	\
	Sources/Menu/Menu.o	\
Sons/EffetBombeContact.o	\
	Graphismes/Commun/Police.raw.o	\
	Graphismes/Bump/GBAX2005.raw.o	\
	Graphismes/Bump/HongKong2005.raw.o	\
	Graphismes/Menu/SpritesMenu.pal.o	\
	Graphismes/Menu/SpritesMenu.raw.o	\
	Graphismes/Menu/FondsMenu.map.o	\
	Graphismes/Menu/FondsMenu.pal.o	\
	Graphismes/Menu/FondsMenu.raw.o	\
	Graphismes/Boules/SpritesJeu.pal.o	\
	Graphismes/Boules/SpritesJeu.raw.o	\
	Graphismes/Boules/FondVictoire.map.o	\
	Graphismes/Boules/FondVictoire.pal.o	\
	Graphismes/Boules/FondVictoire.raw.o	\
	Graphismes/Boules/FondsJeu/Mario/Boo.map.o	\
	Graphismes/Boules/FondsJeu/Mario/Boo.pal.o	\
	Graphismes/Boules/FondsJeu/Mario/Boo.raw.o	\
	Graphismes/Boules/FondsJeu/Mario/DK.map.o	\
	Graphismes/Boules/FondsJeu/Mario/DK.pal.o	\
	Graphismes/Boules/FondsJeu/Mario/DK.raw.o	\
	Graphismes/Boules/FondsJeu/Mario/Daisy.map.o	\
	Graphismes/Boules/FondsJeu/Mario/Daisy.pal.o	\
	Graphismes/Boules/FondsJeu/Mario/Daisy.raw.o	\
	Graphismes/Boules/FondsJeu/Mario/Mario.map.o	\
	Graphismes/Boules/FondsJeu/Mario/Mario.pal.o	\
	Graphismes/Boules/FondsJeu/Mario/Mario.raw.o	\
	Graphismes/Boules/FondsJeu/Mario/Peach.map.o	\
	Graphismes/Boules/FondsJeu/Mario/Peach.pal.o	\
	Graphismes/Boules/FondsJeu/Mario/Peach.raw.o	\
	Graphismes/Boules/FondsJeu/Mario/SmsButler.map.o	\
	Graphismes/Boules/FondsJeu/Mario/SmsButler.pal.o	\
	Graphismes/Boules/FondsJeu/Mario/SmsButler.raw.o	\
	Graphismes/Boules/FondsJeu/Mario/Toad.map.o	\
	Graphismes/Boules/FondsJeu/Mario/Toad.pal.o	\
	Graphismes/Boules/FondsJeu/Mario/Toad.raw.o	\
	Graphismes/Boules/FondsJeu/Mario/Waluigi.map.o	\
	Graphismes/Boules/FondsJeu/Mario/Waluigi.pal.o	\
	Graphismes/Boules/FondsJeu/Mario/Waluigi.raw.o	\
	Graphismes/Boules/FondsJeu/Mario/Wario.map.o	\
	Graphismes/Boules/FondsJeu/Mario/Wario.pal.o	\
	Graphismes/Boules/FondsJeu/Mario/Wario.raw.o	\
	Graphismes/Boules/FondsJeu/PA/Arcadia.map.o	\
	Graphismes/Boules/FondsJeu/PA/Arcadia.pal.o	\
	Graphismes/Boules/FondsJeu/PA/Arcadia.raw.o	\
	Graphismes/Boules/FondsJeu/PA/CLon.map.o	\
	Graphismes/Boules/FondsJeu/PA/CLon.pal.o	\
	Graphismes/Boules/FondsJeu/PA/CLon.raw.o	\
	Graphismes/Boules/FondsJeu/PA/Foxy.map.o	\
	Graphismes/Boules/FondsJeu/PA/Foxy.pal.o	\
	Graphismes/Boules/FondsJeu/PA/Foxy.raw.o	\
	Graphismes/Boules/FondsJeu/PA/JuyLe.map.o	\
	Graphismes/Boules/FondsJeu/PA/JuyLe.pal.o	\
	Graphismes/Boules/FondsJeu/PA/JuyLe.raw.o	\
	Graphismes/Boules/FondsJeu/PA/Kartapus.map.o	\
	Graphismes/Boules/FondsJeu/PA/Kartapus.pal.o	\
	Graphismes/Boules/FondsJeu/PA/Kartapus.raw.o	\
	Graphismes/Boules/FondsJeu/PA/LaBoule.map.o	\
	Graphismes/Boules/FondsJeu/PA/LaBoule.pal.o	\
	Graphismes/Boules/FondsJeu/PA/LaBoule.raw.o	\
	Graphismes/Boules/FondsJeu/PA/Lanza.map.o	\
	Graphismes/Boules/FondsJeu/PA/Lanza.pal.o	\
	Graphismes/Boules/FondsJeu/PA/Lanza.raw.o	\
	Graphismes/Boules/FondsJeu/PA/Legendaryboy.map.o	\
	Graphismes/Boules/FondsJeu/PA/Legendaryboy.pal.o	\
	Graphismes/Boules/FondsJeu/PA/Legendaryboy.raw.o	\
	Graphismes/Boules/FondsJeu/PA/MrSlip.map.o	\
	Graphismes/Boules/FondsJeu/PA/MrSlip.pal.o	\
	Graphismes/Boules/FondsJeu/PA/MrSlip.raw.o	\
	Graphismes/Boules/FondsJeu/PA/NMaster.map.o	\
	Graphismes/Boules/FondsJeu/PA/NMaster.pal.o	\
	Graphismes/Boules/FondsJeu/PA/NMaster.raw.o	\
	Graphismes/Boules/FondsJeu/PA/Nrx.map.o	\
	Graphismes/Boules/FondsJeu/PA/Nrx.pal.o	\
	Graphismes/Boules/FondsJeu/PA/Nrx.raw.o	\
	Graphismes/Boules/FondsJeu/PA/Phantom.map.o	\
	Graphismes/Boules/FondsJeu/PA/Phantom.pal.o	\
	Graphismes/Boules/FondsJeu/PA/Phantom.raw.o	\
	Graphismes/Boules/FondsJeu/PA/Poppu.map.o	\
	Graphismes/Boules/FondsJeu/PA/Poppu.pal.o	\
	Graphismes/Boules/FondsJeu/PA/Poppu.raw.o	\
	Graphismes/Boules/FondsJeu/PA/Sanctuaire.map.o	\
	Graphismes/Boules/FondsJeu/PA/Sanctuaire.pal.o	\
	Graphismes/Boules/FondsJeu/PA/Sanctuaire.raw.o	\
	Graphismes/Boules/FondsJeu/PA/ShivaEden.map.o	\
	Graphismes/Boules/FondsJeu/PA/ShivaEden.pal.o	\
	Graphismes/Boules/FondsJeu/PA/ShivaEden.raw.o	\
	Graphismes/Boules/FondsJeu/PA/ShockTheDarkMage.map.o	\
	Graphismes/Boules/FondsJeu/PA/ShockTheDarkMage.pal.o	\
	Graphismes/Boules/FondsJeu/PA/ShockTheDarkMage.raw.o	\
	Graphismes/Boules/FondsJeu/PA/TeHashiX.map.o	\
	Graphismes/Boules/FondsJeu/PA/TeHashiX.pal.o	\
	Graphismes/Boules/FondsJeu/PA/TeHashiX.raw.o	\
	Graphismes/Boules/FondsJeu/PA/YannOuxix.map.o	\
	Graphismes/Boules/FondsJeu/PA/YannOuxix.pal.o	\
	Graphismes/Boules/FondsJeu/PA/YannOuxix.raw.o	\
	Graphismes/Boules/FondsJeu/PA/Yodajr.map.o	\
	Graphismes/Boules/FondsJeu/PA/Yodajr.pal.o	\
	Graphismes/Boules/FondsJeu/PA/Yodajr.raw.o	\
	Graphismes/Boules/FondsJeu/PA/ZiapaT.map.o	\
	Graphismes/Boules/FondsJeu/PA/ZiapaT.pal.o	\
	Graphismes/Boules/FondsJeu/PA/ZiapaT.raw.o	\
	Graphismes/Boules/FondsJeu/PA/decamail.map.o	\
	Graphismes/Boules/FondsJeu/PA/decamail.pal.o	\
	Graphismes/Boules/FondsJeu/PA/decamail.raw.o	\
	Graphismes/Boules/FondsJeu/PA/dragonir.map.o	\
	Graphismes/Boules/FondsJeu/PA/dragonir.pal.o	\
	Graphismes/Boules/FondsJeu/PA/dragonir.raw.o	\
	Graphismes/Boules/FondsJeu/PA/geogeo.map.o	\
	Graphismes/Boules/FondsJeu/PA/geogeo.pal.o	\
	Graphismes/Boules/FondsJeu/PA/geogeo.raw.o	\
	Graphismes/Boules/FondsJeu/PA/greeeg.map.o	\
	Graphismes/Boules/FondsJeu/PA/greeeg.pal.o	\
	Graphismes/Boules/FondsJeu/PA/greeeg.raw.o	\
	Graphismes/Boules/FondsJeu/PA/lomig.map.o	\
	Graphismes/Boules/FondsJeu/PA/lomig.pal.o	\
	Graphismes/Boules/FondsJeu/PA/lomig.raw.o	\
	Graphismes/Boules/FondsJeu/PA/lord_pingui.map.o	\
	Graphismes/Boules/FondsJeu/PA/lord_pingui.pal.o	\
	Graphismes/Boules/FondsJeu/PA/lord_pingui.raw.o	\
	Graphismes/Boules/FondsJeu/PA/nes.map.o	\
	Graphismes/Boules/FondsJeu/PA/nes.pal.o	\
	Graphismes/Boules/FondsJeu/PA/nes.raw.o	\
	Graphismes/Boules/FondsJeu/PA/tsZele.map.o	\
	Graphismes/Boules/FondsJeu/PA/tsZele.pal.o	\
	Graphismes/Boules/FondsJeu/PA/tsZele.raw.o	\
	Graphismes/Boules/FondsJeu/PA/gus.map.o	\
	Graphismes/Boules/FondsJeu/PA/gus.pal.o	\
	Graphismes/Boules/FondsJeu/PA/gus.raw.o	\
	Graphismes/Boules/FondsJeu/PA/Lestat.map.o	\
	Graphismes/Boules/FondsJeu/PA/Lestat.pal.o	\
	Graphismes/Boules/FondsJeu/PA/Lestat.raw.o	\
	Graphismes/Boules/FondsJeu/PA/maxlebourrin.map.o	\
	Graphismes/Boules/FondsJeu/PA/maxlebourrin.pal.o	\
	Graphismes/Boules/FondsJeu/PA/maxlebourrin.raw.o	\
	Graphismes/Boules/FondsJeu/PA/jackachi.map.o	\
	Graphismes/Boules/FondsJeu/PA/jackachi.pal.o	\
	Graphismes/Boules/FondsJeu/PA/jackachi.raw.o	\
	Graphismes/Boules/FondsJeu/PA/kinski.map.o	\
	Graphismes/Boules/FondsJeu/PA/kinski.pal.o	\
	Graphismes/Boules/FondsJeu/PA/kinski.raw.o	\
	Graphismes/Boules/FondsJeu/PA/Mirada2000.map.o	\
	Graphismes/Boules/FondsJeu/PA/Mirada2000.pal.o	\
	Graphismes/Boules/FondsJeu/PA/Mirada2000.raw.o	\
	Sons/EffetBombeDispersion.o	\
	Sons/EffetChronoGift.o	\
	Sons/EffetGagne.o	\
	Sons/EffetHeureux.o	\
	Sons/EffetMalheureux.o	\
	Sons/EffetNiveau01.o	\
	Sons/EffetNiveau02.o	\
	Sons/EffetPause.o	\
	Sons/EffetPoints.o	\
	Sons/EffetTir.o	\
	Sons/EffetTwister.o	\
	Sons/MusiqueGagne.o	\
	Sons/MusiqueGenerique.o	\
	Sons/MusiqueJeu.o	\
	Sons/MusiquePerdu.o

#
# Set a list of libraries you want to link
#
ADD_LIBS +=

########################################
# Standard Makefile targets start here #
########################################
all: clean	\
	gfx	\
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
	$(HAMDIR)/tools/$(HAM_PLATFORM)/rm -f Sources/Boules/*.o
	$(HAMDIR)/tools/$(HAM_PLATFORM)/rm -f Sources/Bump/*.o
	$(HAMDIR)/tools/$(HAM_PLATFORM)/rm -f Sources/Commun/*.o
	$(HAMDIR)/tools/$(HAM_PLATFORM)/rm -f Sources/Commun/Adpcm/Decoder/*.o
	$(HAMDIR)/tools/$(HAM_PLATFORM)/rm -f Sources/Menu/*.o

gfx:

gfx_:
	gfx2gba -fsrc -P -t8 -x -oGraphismes\\Commun Graphismes\\Commun\\Police.bmp
	gfx2gba -fsrc -P -oGraphismes\\Bump Graphismes\\Bump\\GBAX2005.bmp
	gfx2gba -fsrc -P -oGraphismes\\Bump Graphismes\\Bump\\HongKong2005.bmp
	gfx2gba -fsrc -t8 -x -oGraphismes\\Menu -pSpritesMenu.pal Graphismes\\Menu\\SpritesMenu.bmp
	gfx2gba -fsrc -t8 -m -x -oGraphismes\\Menu -pFondsMenu.pal Graphismes\\Menu\\FondsMenu.bmp
	gfx2gba -fsrc -t8 -x -oGraphismes\\Boules -pSpritesJeu.pal Graphismes\\Boules\\SpritesJeu.bmp
	gfx2gba -fsrc -t8 -m -x -oGraphismes\\Boules -pFondVictoire.pal Graphismes\\Boules\\FondVictoire.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\Mario Graphismes\\Boules\\FondsJeu\\Mario\\Boo.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\Mario Graphismes\\Boules\\FondsJeu\\Mario\\DK.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\Mario Graphismes\\Boules\\FondsJeu\\Mario\\Daisy.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\Mario Graphismes\\Boules\\FondsJeu\\Mario\\Mario.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\Mario Graphismes\\Boules\\FondsJeu\\Mario\\Peach.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\Mario Graphismes\\Boules\\FondsJeu\\Mario\\SmsButler.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\Mario Graphismes\\Boules\\FondsJeu\\Mario\\Toad.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\Mario Graphismes\\Boules\\FondsJeu\\Mario\\Waluigi.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\Mario Graphismes\\Boules\\FondsJeu\\Mario\\Wario.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\Arcadia.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\CLon.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\Foxy.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\JuyLe.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\Kartapus.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\LaBoule.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\Lanza.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\Legendaryboy.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\MrSlip.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\NMaster.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\Nrx.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\Phantom.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\Poppu.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\Sanctuaire.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\ShivaEden.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\ShockTheDarkMage.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\TeHashiX.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\YannOuxix.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\Yodajr.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\ZiapaT.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\decamail.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\dragonir.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\geogeo.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\greeeg.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\lomig.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\lord_pingui.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\nes.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\tsZele.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\gus.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\Lestat.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\maxlebourrin.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\jackachi.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\kinski.bmp
	gfx2gba -fsrc -t8 -rs -m -F -x -oGraphismes\\Boules\\FondsJeu\\PA Graphismes\\Boules\\FondsJeu\\PA\\Mirada2000.bmp

sfx_:

sfx:
	cd $(VHAM_CURPROJECT);Sources/Commun/Adpcm/Encoder/Adpcm.exe EffetBombeContact Sons/Ressources Sons -nocompress
	cd $(VHAM_CURPROJECT);Sources/Commun/Adpcm/Encoder/Adpcm.exe EffetBombeDispersion Sons/Ressources Sons -nocompress
	cd $(VHAM_CURPROJECT);Sources/Commun/Adpcm/Encoder/Adpcm.exe EffetChronoGift Sons/Ressources Sons -nocompress
	cd $(VHAM_CURPROJECT);Sources/Commun/Adpcm/Encoder/Adpcm.exe EffetGagne Sons/Ressources Sons -nocompress
	cd $(VHAM_CURPROJECT);Sources/Commun/Adpcm/Encoder/Adpcm.exe EffetHeureux Sons/Ressources Sons -nocompress
	cd $(VHAM_CURPROJECT);Sources/Commun/Adpcm/Encoder/Adpcm.exe EffetMalheureux Sons/Ressources Sons -nocompress
	cd $(VHAM_CURPROJECT);Sources/Commun/Adpcm/Encoder/Adpcm.exe EffetNiveau01 Sons/Ressources Sons -nocompress
	cd $(VHAM_CURPROJECT);Sources/Commun/Adpcm/Encoder/Adpcm.exe EffetNiveau02 Sons/Ressources Sons -nocompress
	cd $(VHAM_CURPROJECT);Sources/Commun/Adpcm/Encoder/Adpcm.exe EffetPause Sons/Ressources Sons -nocompress
	cd $(VHAM_CURPROJECT);Sources/Commun/Adpcm/Encoder/Adpcm.exe EffetPoints Sons/Ressources Sons -nocompress
	cd $(VHAM_CURPROJECT);Sources/Commun/Adpcm/Encoder/Adpcm.exe EffetTir Sons/Ressources Sons -nocompress
	cd $(VHAM_CURPROJECT);Sources/Commun/Adpcm/Encoder/Adpcm.exe EffetTwister Sons/Ressources Sons -nocompress
	cd $(VHAM_CURPROJECT);Sources/Commun/Adpcm/Encoder/Adpcm.exe MusiqueGagne Sons/Ressources Sons
	cd $(VHAM_CURPROJECT);Sources/Commun/Adpcm/Encoder/Adpcm.exe MusiqueGenerique Sons/Ressources Sons
	cd $(VHAM_CURPROJECT);Sources/Commun/Adpcm/Encoder/Adpcm.exe MusiqueJeu Sons/Ressources Sons
	cd $(VHAM_CURPROJECT);Sources/Commun/Adpcm/Encoder/Adpcm.exe MusiquePerdu Sons/Ressources Sons

#######
# End #
#######

