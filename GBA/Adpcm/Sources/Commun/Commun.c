/*
** Adpcm - Sources\Commun\Commun.c
** Nicolas ROBERT [NRX] - Hong Kong 2005
*/

////////////////
// Inclusions //
////////////////
#include <math.h>
#include "Commun.h"

////////////////////////
// Variables globales //
////////////////////////
IntrFunction* IntrTable[14]={NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL};

signed short* SINUS=NULL;
unsigned short* INVERSE=NULL;
Sprite* sprites=NULL;
unsigned long zeroDMA;

const unsigned char MAGIC[]="ADPCM050804";
const unsigned char SIGNATURE[]="SRAM_V110";

/////////////////
// CommonVwait //
/////////////////
inline void CommonVwait(void)
{
   asm volatile("swi 0x20000");
}

//////////////////
// setInterrupt //
//////////////////
signed short setInterrupt(unsigned short interruption,IntrFunction* fonction)
{
   signed short numero;

   // Desactive toutes les interruptions...
   REG_IME=0;

   // Certains registres doivent etre modifies
   switch(interruption)
   {
      case IT_VBLANK:
         REG_DISPSTAT|=E_VBLANK; // Met a 1 le "V-Blank Interrupt Request Enable Flag"
         numero=0;
         break;
      case IT_HBLANK:
         REG_DISPSTAT|=E_HBLANK; // Met a 1 le "H-Blank Interrupt Request Enable Flag"
         numero=1;
         break;
      case IT_TIMER0:
         REG_TM0CNT|=0x40; // Met a 1 le "Interrupt Request Enable Flag" (timers 0 a 3)
         numero=3;
         break;
      case IT_TIMER1:
         REG_TM1CNT|=0x40;
         numero=4;
         break;
      case IT_TIMER2:
         REG_TM2CNT|=0x40;
         numero=5;
         break;
      case IT_TIMER3:
         REG_TM3CNT|=0x40;
         numero=6;
         break;
      case IT_DMA0:
         REG_DMA0CNT_H|=0x4000; // Met a 1 le "Interrupt Request Enable Flag" (DMA 0 a 3)
         numero=8;
         break;
      case IT_DMA1:
         REG_DMA1CNT_H|=0x4000;
         numero=9;
         break;
      case IT_DMA2:
         REG_DMA1CNT_H|=0x4000;
         numero=10;
         break;
      case IT_DMA3:
         REG_DMA1CNT_H|=0x4000;
         numero=11;
         break;
      default:
         numero=-1;
         break;
   }

   // Active l'interruption demandee et memorise l'adresse de la fonction a appeler
   if(numero>=0)
   {
      REG_IE|=interruption;
      if(fonction)
         IntrTable[numero]=fonction;
   }

   // Reactive les interruptions !
   REG_IME=1;
   return(numero);
}

///////////////////////
// setYtrigInterrupt //
///////////////////////
void setYtrigInterrupt(unsigned char ligne,IntrFunction* fonction)
{
   // Desactive toutes les interruptions...
   REG_IME=0;

   // Certains registres doivent etre modifies
   REG_DISPSTAT&=255; // Nettoie le "V count setting" (on le renseigne a la ligne suivante)
   REG_DISPSTAT|=E_YTRIG|(ligne<<8); // Met a 1 le "V Counter Match Interrupt Request Enable Flag"
   REG_IE|=IT_YTRIG;

   // Memorise l'adresse de la fonction a appeler
   if(fonction)
      IntrTable[2]=fonction;

   // Reactive les interruptions !
   REG_IME=1;
}

/////////////////////
// enableInterrupt //
/////////////////////
inline signed short enableInterrupt(unsigned short interruption)
{
   return(setInterrupt(interruption,NULL));
}

//////////////////////
// disableInterrupt //
//////////////////////
void disableInterrupt(unsigned short interruption)
{
   REG_IME=0;
   REG_IE&=~interruption;
   REG_IME=1;
}

///////////////////////
// basicVblInterrupt //
///////////////////////
void basicVblInterrupt(void)
{
   AdpcmDecodeVbl(0);
   AdpcmDecodeVbl(1);
   ++compteVBL;
}

/////////////////
// initSIN_VBL //
/////////////////
unsigned char CODE_IN_IWRAM initSIN_VBL(unsigned char wait)
{
   static unsigned short A;
   static signed short sinus;
   unsigned short VBLcourant;

   // Reserve de la memoire pour notre tableau de sinus
   if(!SINUS)
   {
      SINUS=(signed short*)malloc(SINNB*sizeof(signed short));
      A=0;
      sinus=0; // Initialise a 0 car sin(0)=0...
   }

   // Mise a jour partielle du tableau de sinus...
   VBLcourant=compteVBL;
   while(VBLcourant==compteVBL)
   {
      // C'est termine ?
      if(A==SINNB/4)
      {
         if(wait)
            while(VBLcourant==compteVBL);
         return(0);
      }

      // On met a jour le tableau en tenant compte des symetries
      SINUS[A]=sinus;
      SINUS[(SINNB/2)+A]=-sinus;

      // Angle suivant !
      ++A;

      // Voici la nouvelle valeur du sinus
      sinus=sin(A*2*PI/SINNB)*VIRGULE;

      // On met a jour le tableau en tenant compte des symetries
      SINUS[(SINNB/2)-A]=sinus;
      SINUS[SINNB-A]=-sinus;
   }

   // Il faudra continuer...
   return(1);
}

/////////////////
// initINV_VBL //
/////////////////
unsigned char CODE_IN_IWRAM initINV_VBL(unsigned char wait)
{
   static unsigned short A;
   unsigned short VBLcourant;

   // Reserve de la memoire pour notre tableau d'inverses
   if(!INVERSE)
   {
      INVERSE=(unsigned short*)malloc(INVNB*sizeof(unsigned short));
      INVERSE[0]=0xFFFF;
      A=1;
   }

   // Mise a jour partielle du tableau d'inverses...
   VBLcourant=compteVBL;
   while(VBLcourant==compteVBL)
   {
      // C'est termine ?
      if(A==INVNB)
      {
         if(wait)
            while(VBLcourant==compteVBL);
         return(0);
      }

      // On met a jour le tableau
      INVERSE[A]=VIRGULE_INV/A;

      // Valeur suivante !
      ++A;
   }

   // Il faudra continuer...
   return(1);
}

////////////
// mySqrt //
////////////
unsigned short CODE_IN_IWRAM mySqrt(unsigned short x)
{
   unsigned short sqrt,precision;

   // Calcul de la racine carree (algorithme de Héron d'Alexandrie)
   sqrt=x;
   do
   {
      precision=sqrt;
      sqrt=(sqrt+x/sqrt)>>1; // Note : on n'utilise pas INVERSE[sqrt] car sqrt peut etre superieur a INVNB...
      precision-=sqrt;
   }
   while(precision>1);
   return(sqrt);
}

/////////////////
// initSprites //
/////////////////
void initSprites(void)
{
   unsigned char pointeur;

   // Reserve de la memoire pour les sprites
   if(!sprites)
      sprites=(Sprite*)malloc(128*sizeof(Sprite));

   // Initialisation de la liste : tous les sprites sont desactives (taille double mais pas de rotation)
   for(pointeur=0;pointeur<128;++pointeur)
      sprites[pointeur].attribut1=(1<<9)|(0<<8);
}

////////////////
// affSprites //
////////////////
inline void CODE_IN_IWRAM affSprites(void)
{
   // Copie le buffer de sprites dans l'OAM
   copieDMA((void*)sprites,(void*)OAM,128*4*sizeof(unsigned short)/4,DMA_32NOW);
}

//////////////
// copieDMA //
//////////////
void CODE_IN_IWRAM copieDMA(void* source,void* dest,unsigned short taille,unsigned short type)
{
   REG_DMA3SAD=(unsigned long)source;
   REG_DMA3DAD=(unsigned long)dest;
   REG_DMA3CNT_L=taille;
   REG_DMA3CNT_H=type;
}

//////////////
// forceDMA //
//////////////
void CODE_IN_IWRAM forceDMA(unsigned long valeur,void* dest,unsigned short taille,unsigned short type)
{
   zeroDMA=valeur;

   REG_DMA3SAD=(unsigned long)&zeroDMA;
   REG_DMA3DAD=(unsigned long)dest;
   REG_DMA3CNT_L=taille;
   REG_DMA3CNT_H=type|DMA_SRC_FIXED;
}

/////////////
// litSRAM //
/////////////
unsigned char litSRAM(unsigned char* dest,unsigned short taille)
{
   unsigned short index;

   // Verifie le "magic"
   for(index=0;index<sizeof(MAGIC);++index)
      if(SRAM[index]!=MAGIC[index])
         return(1);

   // Lit les donnees
   while(taille--)
      *dest++=SRAM[index++];

   // Ok
   return(0);
}

///////////////
// ecritSRAM //
///////////////
void ecritSRAM(unsigned char* source,unsigned short taille)
{
   unsigned short index;

   // Ecrit le "magic"
   for(index=0;index<sizeof(MAGIC);++index)
      SRAM[index]=MAGIC[index];

   // Ecrit les donnees
   while(taille--)
      SRAM[index++]=*source++;
}
