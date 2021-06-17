/*
** Z80 - Sources\Main.c
** Nicolas ROBERT [NRX] - Hong Kong 2005
*/

////////////////
// Inclusions //
////////////////
#include "Common\Common.h"
#include "CPU\z80.h"

////////////////////////
// Variables globales //
////////////////////////
extern unsigned char SNA_FF[0x100+0x10000];
extern unsigned char SNA_BJ1[0x100+0x10000];
extern unsigned char SNA_BJ2[0x100+0x10000];
extern unsigned char SNA_BJrun[0x100+0x10000];
extern unsigned char SNA_BJIIrun[0x100+0x10000];
extern unsigned char SNA_CRAFTONrun[0x100+0x10000];

struct
{
   unsigned char* SNA;
   unsigned short start;
}
games[]=
{
   {SNA_FF,0x1B00},
   {SNA_BJ1,0xa628},
   //{SNA_BJ2,6000},
   {SNA_BJrun,0},
   //{SNA_BJIIrun,0},
   {SNA_CRAFTONrun,0}
};

//////////
// main //
//////////
int main(void)
{
   unsigned char game;

   // Force l'ecran au noir
   PALRAM[0]=0;
   REG_DISPCNT=0;

   // Optimisation du "Wait State Control"
   REG_WSCNT=BEST_WSCNT;

   // Mise en place l'interruption sur le retour de balayage (VBL)
   CommonInterruptSet(IT_VBLANK,(IntrFunction*)&CommonCpcVblInterrupt);

   // On passe en mode 4
   REG_DISPCNT=4|BG2_ENABLE;//|BACKBUFFER;

   // Etire le buffer
   REG_BG2PA=(160<<8)/240;
   REG_BG2PB=0;
   REG_BG2PC=0;
   REG_BG2PD=256;

   // Boucle principale
   game=0;
   z80_init();
   while(1)
   {
      // Initialisation du CPC
      CommonCpcInit(games[game].SNA);

      // Chargement de la palette contenue dans le snapshot
      CommonCpcHardPaletteSet(games[game].SNA+0x2F,PALRAM);

      // Reset du CPU
      if(games[game].start)
         z80_reset(games[game].start);
      else
         z80_loadSNA(games[game].SNA);

      // Emulation
      while(REG_KEYS&KEY_SELECT)
         z80_execute();

      // Attente du relachement de la touche START
      while(!(REG_KEYS&KEY_SELECT))
         CommonVwait();

      // Changement de snapshot
      if(game==3)
         game=0;
      else
         ++game;
   }
}
