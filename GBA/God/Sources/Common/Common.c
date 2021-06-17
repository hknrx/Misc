/*
** God - Sources\Common\Common.c
** Nicolas ROBERT [NRX] - Hong Kong 2005
*/

////////////////
// Inclusions //
////////////////
#include <math.h>
#include "Common.h"

////////////
// Macros //
////////////
#define UNCOMPRESS_BUFFER_SIZE 16384

////////////////////////
// Variables globales //
////////////////////////
IntrFunction* IntrTable[14]={NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL};

signed short* SINE_TABLE=NULL;
unsigned short* INVERSE_TABLE=NULL;

Sprite* sprites=NULL;
unsigned long dmaZero;

const unsigned char SRAM_MAGIC[]="GOD051117";
const unsigned char SRAM_SIGNATURE[]="SRAM_V110";

/////////////////
// CommonVwait //
/////////////////
inline void CommonVwait(void)
{
   unsigned short vblCurrent;

   vblCurrent=vblCounter;
   do
   {
      asm("swi 0x20000"); // Halt le CPU
   }
   while(vblCurrent==vblCounter);
}

////////////////////////
// CommonInterruptSet //
////////////////////////
signed short CommonInterruptSet(unsigned short interrupt,IntrFunction* function)
{
   signed short number;

   // Desactive toutes les interruptions...
   REG_IME=0;

   // Certains registres doivent etre modifies
   switch(interrupt)
   {
      case IT_VBLANK:
         REG_DISPSTAT|=E_VBLANK; // Met a 1 le "V-Blank Interrupt Request Enable Flag"
         number=0;
         break;
      case IT_HBLANK:
         REG_DISPSTAT|=E_HBLANK; // Met a 1 le "H-Blank Interrupt Request Enable Flag"
         number=1;
         break;
      case IT_TIMER0:
         REG_TM0CNT|=0x40; // Met a 1 le "Interrupt Request Enable Flag" (timers 0 a 3)
         number=3;
         break;
      case IT_TIMER1:
         REG_TM1CNT|=0x40;
         number=4;
         break;
      case IT_TIMER2:
         REG_TM2CNT|=0x40;
         number=5;
         break;
      case IT_TIMER3:
         REG_TM3CNT|=0x40;
         number=6;
         break;
      case IT_DMA0:
         REG_DMA0CNT_H|=0x4000; // Met a 1 le "Interrupt Request Enable Flag" (DMA 0 a 3)
         number=8;
         break;
      case IT_DMA1:
         REG_DMA1CNT_H|=0x4000;
         number=9;
         break;
      case IT_DMA2:
         REG_DMA1CNT_H|=0x4000;
         number=10;
         break;
      case IT_DMA3:
         REG_DMA1CNT_H|=0x4000;
         number=11;
         break;
      default:
         number=-1;
         break;
   }

   // Active l'interruption demandee et memorise l'adresse de la fonction a appeler
   if(number>=0)
   {
      REG_IE|=interrupt;
      if(function)
         IntrTable[number]=function;
   }

   // Reactive les interruptions !
   REG_IME=1;
   return(number);
}

/////////////////////////////
// CommonInterruptSetYTrig //
/////////////////////////////
void CommonInterruptSetYTrig(unsigned char line,IntrFunction* function)
{
   // Desactive toutes les interruptions...
   REG_IME=0;

   // Certains registres doivent etre modifies
   REG_DISPSTAT&=255; // Nettoie le "V count setting" (on le renseigne a la ligne suivante)
   REG_DISPSTAT|=E_YTRIG|(line<<8); // Met a 1 le "V Counter Match Interrupt Request Enable Flag"
   REG_IE|=IT_YTRIG;

   // Memorise l'adresse de la fonction a appeler
   if(function)
      IntrTable[2]=function;

   // Reactive les interruptions !
   REG_IME=1;
}

///////////////////////////
// CommonInterruptEnable //
///////////////////////////
inline signed short CommonInterruptEnable(unsigned short interrupt)
{
   return(CommonInterruptSet(interrupt,NULL));
}

////////////////////////////
// CommonInterruptDisable //
////////////////////////////
void CommonInterruptDisable(unsigned short interrupt)
{
   REG_IME=0;
   REG_IE&=~interrupt;
   REG_IME=1;
}

/////////////////////////////
// CommonInterruptBasicVbl //
/////////////////////////////
void CommonInterruptBasicVbl(void)
{
   AdpcmDecodeVbl(0);
   AdpcmDecodeVbl(1);
   ++vblCounter;
}

///////////////////////
// CommonSineInitVbl //
///////////////////////
unsigned char CODE_IN_IWRAM CommonSineInitVbl(unsigned char wait)
{
   static unsigned short A;
   static signed short sine;
   unsigned short vblCurrent;

   // Reserve de la memoire pour notre tableau de sinus
   if(!SINE_TABLE)
   {
      SINE_TABLE=(signed short*)malloc(SINNB*sizeof(signed short));
      A=0;
      sine=0; // Initialise a 0 car sin(0)=0...
   }

   // Mise a jour partielle du tableau de sinus...
   vblCurrent=vblCounter;
   while(vblCurrent==vblCounter)
   {
      // C'est termine ?
      if(A==SINNB/4)
      {
         if(wait)
            CommonVwait();
         return(0);
      }

      // On met a jour le tableau en tenant compte des symetries
      SINE_TABLE[A]=sine;
      SINE_TABLE[(SINNB/2)+A]=-sine;

      // Angle suivant !
      ++A;

      // Voici la nouvelle valeur du sinus
      sine=sin(A*2*PI/SINNB)*FIXED_POINT;

      // On met a jour le tableau en tenant compte des symetries
      SINE_TABLE[(SINNB/2)-A]=sine;
      SINE_TABLE[SINNB-A]=-sine;
   }

   // Il faudra continuer...
   return(1);
}

//////////////////////////
// CommonInverseInitVbl //
//////////////////////////
unsigned char CODE_IN_IWRAM CommonInverseInitVbl(unsigned char wait)
{
   static unsigned short A;
   unsigned short vblCurrent;

   // Reserve de la memoire pour notre tableau d'inverses
   if(!INVERSE_TABLE)
   {
      INVERSE_TABLE=(unsigned short*)malloc(INVNB*sizeof(unsigned short));
      INVERSE_TABLE[0]=0xFFFF;
      A=1;
   }

   // Mise a jour partielle du tableau d'inverses...
   vblCurrent=vblCounter;
   while(vblCurrent==vblCounter)
   {
      // C'est termine ?
      if(A==INVNB)
      {
         if(wait)
            CommonVwait();
         return(0);
      }

      // On met a jour le tableau
      INVERSE_TABLE[A]=FIXED_POINT_INV/A;

      // Valeur suivante !
      ++A;
   }

   // Il faudra continuer...
   return(1);
}

////////////////
// CommonSqrt //
////////////////
unsigned short CODE_IN_IWRAM CommonSqrt(unsigned short x)
{
   unsigned short sqrt,precision;

   // Calcul de la racine carree (algorithme de Heron d'Alexandrie)
   sqrt=x;
   do
   {
      precision=sqrt;
      sqrt=(sqrt+x/sqrt)>>1; // Note : on n'utilise pas INVERSE_TABLE[sqrt] car sqrt peut etre superieur a INVNB...
      precision-=sqrt;
   }
   while(precision>1);
   return(sqrt);
}

///////////////////////
// CommonSpritesInit //
///////////////////////
void CommonSpritesInit(void)
{
   unsigned char pointer;

   // Reserve de la memoire pour les sprites
   if(!sprites)
      sprites=(Sprite*)malloc(128*sizeof(Sprite));

   // Initialisation de la liste : tous les sprites sont desactives (taille double mais pas de rotation)
   for(pointer=0;pointer<128;++pointer)
      sprites[pointer].attribute0=(1<<9)|(0<<8);
}

//////////////////////////
// CommonSpritesDisplay //
//////////////////////////
inline void CommonSpritesDisplay(void)
{
   // Copie le buffer de sprites dans l'OAM
   CommonDmaCopy((void*)sprites,(void*)OAM,128*sizeof(Sprite)/4,DMA_32NOW);
}

///////////////////
// CommonDmaCopy //
///////////////////
void CommonDmaCopy(void* source,void* dest,unsigned short size,unsigned short type)
{
   REG_DMA3SAD=(unsigned long)source;
   REG_DMA3DAD=(unsigned long)dest;
   REG_DMA3CNT_L=size;
   REG_DMA3CNT_H=type;
}

////////////////////
// CommonDmaForce //
////////////////////
void CommonDmaForce(unsigned long value,void* dest,unsigned short size,unsigned short type)
{
   dmaZero=value;

   REG_DMA3SAD=(unsigned long)&dmaZero;
   REG_DMA3DAD=(unsigned long)dest;
   REG_DMA3CNT_L=size;
   REG_DMA3CNT_H=type|DMA_SRC_FIXED;
}

////////////////////////////
// CommonUncompressInWRAM //
////////////////////////////
inline void CommonUncompressInWRAM(void* source,void* dest)
{
   asm
   (
      "mov r0,%0\n"
      "mov r1,%1\n"
      "swi 0x110000"
      :
      :"r"(source),"r"(dest)
      :"r0","r1"
   );
}

////////////////////////////
// CommonUncompressInVRAM //
////////////////////////////
inline void CommonUncompressInVRAM(void* source,void* dest)
{
   // There is a bug in the compression done by gfx2gba: it doesn't care the VRAM specificities!
   /*
   asm
   (
      "mov r0,%0\n"
      "mov r1,%1\n"
      "swi 0x120000"
      :
      :"r"(source),"r"(dest)
      :"r0","r1"
   );
   */

   // Here is a version that uses the WRAM...
   unsigned char buffer[UNCOMPRESS_BUFFER_SIZE];
   unsigned long size;

   size=CommonUncompressSize(source);
   if(size<=UNCOMPRESS_BUFFER_SIZE)
   {
      CommonUncompressInWRAM(source,buffer);
      CommonDmaCopy(buffer,dest,size>>2,DMA_32NOW);
   }
}

//////////////////////////
// CommonUncompressSize //
//////////////////////////
inline unsigned long CommonUncompressSize(void* source)
{
   return((*(unsigned long*)source)>>8);
}

////////////////////
// CommonSramRead //
////////////////////
unsigned char CommonSramRead(unsigned char* dest,unsigned short size)
{
   unsigned short index;

   // Verifie le "magic"
   for(index=0;index<sizeof(SRAM_MAGIC);++index)
      if(SRAM[index]!=SRAM_MAGIC[index])
         return(1);

   // Lit les donnees
   while(size--)
      *dest++=SRAM[index++];

   // Ok
   return(0);
}

/////////////////////
// CommonSramWrite //
/////////////////////
void CommonSramWrite(unsigned char* source,unsigned short size)
{
   unsigned short index;

   // Ecrit le "magic"
   for(index=0;index<sizeof(SRAM_MAGIC);++index)
      SRAM[index]=SRAM_MAGIC[index];

   // Ecrit les donnees
   while(size--)
      SRAM[index++]=*source++;
}
