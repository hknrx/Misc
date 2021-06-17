#include <stdlib.h>
#include <math.h>
#include "Commun.h"

MULTIBOOT

////////////////
// initCommun //
////////////////
void initCommun(void)
{
   signed short n;
   unsigned char A;

   // Optimisation du "Wait State Control"
   REG_WSCNT=BEST_WSCNT;

   // Reserve de la memoire pour notre tableau de sinus
   SINUS=(signed short*)malloc(SINNB*sizeof(signed short));

   // Creation du tableau de sinus
   A=0;
   n=0; // Initialise a 0 car sin(0)=0...
   while(A<SINNB/4)
   {
      // On met a jour le tableau en tenant compte des symetries
      SINUS[A]=n;
      SINUS[(SINNB/2)+A]=-n;

      // Angle suivant !
      ++A;

      // Voici la nouvelle valeur du sinus
      n=sin(A*2*PI/SINNB)*VIRGULE;

      // On met a jour le tableau en tenant compte des symetries
      SINUS[(SINNB/2)-A]=n;
      SINUS[SINNB-A]=-n;
   }

   // Reserve de la memoire pour notre tableau d'inverses
   INV=(signed short*)malloc(INVNB*sizeof(signed short));

   // Creation du tableau d'inverses
   INV[0]=1<<15;
   for(n=1;n<INVNB;++n)
      INV[n]=VIRGULE/n;
}

///////////////////
// afficheCommun //
///////////////////
void afficheCommun(void)
{
   // Attente du retour du balayage vertical
   while(!(REG_DISPSTAT&1));

   // Inverse les buffers video
   REG_DISPCNT^=BACKBUFFER;
   (unsigned long)ecran^=BACKVRAM;
}
