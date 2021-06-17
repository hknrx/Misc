/*
** Sudoku - Sources\Main.c
** Nicolas ROBERT [NRX] - France 2006
*/

////////////////
// Inclusions //
////////////////
#include "Common\Common.h"
#include "Game\Game.h"

////////////////////////
// Variables globales //
////////////////////////
extern const unsigned char GameFont_Bitmap[];

//////////
// main //
//////////
int main(void)
{
   // Force l'ecran au noir
   PALRAM[0]=0;
   REG_DISPCNT=0;

   // Optimisation du "Wait State Control"
   REG_WSCNT=BEST_WSCNT;

   // Mise en place l'interruption sur le retour de balayage (VBL)
   CommonInterruptSet(IT_VBLANK,(IntrFunction*)&CommonInterruptBasicVbl);

   // Initialisation de la palette
   PALRAM[0]=RGB(0,0,15);
   PALRAM[1]=RGB(31,31,31);

   // Mise en place des backgrounds
   REG_BG0CNT=BG_COLORS_16|TXTBG_SIZE_256x256|(0<<CHAR_SHIFT)|(28<<SCREEN_SHIFT)|0;

   // Chargement de la police
   CommonUncompressInVRAM((void*)GameFont_Bitmap,(void*)CHAR_BASE_BLOCK(0));

   // Boucle principale du jeu
   while(1)
      GameMain();
}
