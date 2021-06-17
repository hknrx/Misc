/*
** Adpcm - Sources\Main.c
** Nicolas ROBERT [NRX] - Hong Kong 2005
*/

////////////////
// Inclusions //
////////////////
#include "Commun\Commun.h"

////////////////////////
// Variables globales //
////////////////////////
extern const Sound ADPCM_Music;
extern const Sound ADPCM_Effect;

//////////
// main //
//////////
int main(void)
{
   unsigned char toucheRelachee;

   // Force l'ecran au noir
   PALRAM[0]=0;
   REG_DISPCNT=0;

   // Optimisation du "Wait State Control"
   REG_WSCNT=BEST_WSCNT;

   // Initialisation du decodeur ADPCM
   AdpcmInit(2);

   // Mise en place l'interruption sur le retour de balayage (VBL)
   setInterrupt(IT_VBLANK,(IntrFunction*)&basicVblInterrupt);

   // Boucle principale
   toucheRelachee=0;
   while(1)
   {
      // Joue une musique lorsqu'on appuie sur A, et un son lorsqu'on appuie sur B
      if(REG_TOUCHES&TOUCHE_A)
         toucheRelachee=1;
      else if(toucheRelachee)
      {
         if(AdpcmStatus(0))
            AdpcmStop(0);
         else
            AdpcmStart(&ADPCM_Music,-1,0);
         toucheRelachee=0;
      }
      if(!(REG_TOUCHES&TOUCHE_B) && !AdpcmStatus(1))
         AdpcmStart(&ADPCM_Effect,1,1);

      // Attente du retour du balayage vertical
      CommonVwait();
   }
}
