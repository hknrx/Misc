/*
** God - Sources\Main.c
** Nicolas ROBERT [NRX] - Hong Kong 2005
*/

////////////////
// Inclusions //
////////////////
#include "Common\Common.h"
#include "Intro\Intro.h"
#include "World\World.h"

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

   // Initialisation du decodeur ADPCM
   AdpcmInit(2);

   // Mise en place l'interruption sur le retour de balayage (VBL)
   CommonInterruptSet(IT_VBLANK,(IntrFunction*)&CommonInterruptBasicVbl);

   // Intro (bump mapping)
   IntroBump();

   // Boucle principale du jeu
   while(1)
   {
      // Menu (voxel spacing)
      IntroVoxel();

      // Jeu
      WorldMain();
   }
}
