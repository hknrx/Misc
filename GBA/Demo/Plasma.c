/*
   Le plasma est le truc le plus simple :
   On parcourt tout l'ecran, en remplacant chaque pixel par la moyenne des pixels du dessous...
*/

#include <stdlib.h>
#include "Commun.h"

#define XM (XM4/2)
#define YM (YM4/2)
#define XO (XM/2)
#define YO (YM/2)

////////////////
// initPlasma //
////////////////
void initPlasma(void)
{
   unsigned short xy;
   unsigned short* plasma;

   // On passe en mode 4 (mais nous n'utiliserons qu'un pixel sur 2 en x, et que la 1ere moitie de l'ecran)
   REG_DISPCNT=4|BG2_ENABLE|BACKBUFFER;
   ecran=VRAM;

   // Etire le buffer en hauteur (x2)
   REG_BG2PA=(XM4<<8)/240;
   REG_BG2PB=0;
   REG_BG2PC=0;
   REG_BG2PD=(YM<<8)/160;

   // Creation de la palette
   for(xy=0;xy<256;++xy)
      PALRAM[xy]=xy>>3;

   // Vide le buffer video courant
   plasma=(unsigned short*)((unsigned long)VRAM|BACKVRAM);
   for(xy=0;xy<XM*(YM+2);xy+=2)
      *(unsigned long*)&plasma[xy]=0;
}

///////////////////
// modifiePlasma //
///////////////////
void CODE_IN_IWRAM modifiePlasma(void)
{
   unsigned short xy;
   unsigned short* plasma;

   // On prend comme reference l'autre buffer video (celui qui est affiche !)
   plasma=(unsigned short*)((unsigned long)ecran^BACKVRAM);

   // On met des braises
   for(xy=XM*YM;xy<XM*(YM+2);++xy)
      *(unsigned char*)&ecran[xy]=rand();

   // Le feu monte (note : on force les 2 pixels cote a cote ensemble a la meme valeur)
   for(xy=0;xy<XM*YM;++xy)
      *(unsigned char*)&ecran[xy]=((unsigned char)plasma[xy+XM-1]+
                                   (unsigned char)plasma[xy+XM]+
                                   (unsigned char)plasma[xy+XM+1]+
                                   (unsigned char)plasma[xy+XM+XM])>>2;
}
