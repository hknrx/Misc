/*
** Mario Balls - Sources\Main.c
** Nicolas ROBERT [NRX] - Hong Kong 2005
*/

////////////////
// Inclusions //
////////////////
#include "Commun/Commun.h"
#include "Bump/Bump.h"
#include "Menu/Menu.h"
#include "Boules/Boules.h"

//////////
// main //
//////////
int main(void)
{
   unsigned char etat;

   // Force l'ecran au noir
   PALRAM[0]=0;
   REG_DISPCNT=0;

   // Optimisation du "Wait State Control"
   REG_WSCNT=BEST_WSCNT;

   // Recupere la sauvegarde
   chargeInfo();

   // Initialisation du decodeur ADPCM
   AdpcmInit(2);

   // Mise en place l'interruption sur le retour de balayage (VBL)
   setInterrupt(IT_VBLANK,(IntrFunction*)&basicVblInterrupt);

   // Bump mapping
   BumpSequence();

   // Boucle principale du jeu
   while(1)
   {
      // Menu (note : initialise SIN pour Boules)
      affMenu();

      // Boules
      initBoules();
      do
      {
         // Affiche le niveau courant
         etat=affNiveau();

         // Joue !
         while(etat==ETAT_RIEN)
            etat=gereBoules();
      }
      while(etat==ETAT_CONTINUE);

      // Stop la musique et les sons
      AdpcmStop(0);
      AdpcmStop(1);

      // Sauvegarde le score et le niveau
      if(etat!=ETAT_ABANDON)
         sauveInfo();
   }
}
