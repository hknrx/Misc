/*
** Mister Jelly - Sources\Main.c
** Nicolas ROBERT [NRX] - France 2006
*/

////////////////
// Inclusions //
////////////////
#include "Common\Common.h"
#include "Game\Game.h"

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

   // Initialisation de l'accelerometre
   GBAccelerometerInit();

   // Initialisation du jeu
   GameInit();

   // Boucle principale du jeu
   while(1)
      GameMain();
}
