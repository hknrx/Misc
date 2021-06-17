/*
** Mister Jelly - Sources\Common\Common.c
** Nicolas ROBERT [NRX] - France 2006
*/

////////////////
// Inclusions //
////////////////
#include <math.h>
#include "Common.h"

////////////
// Macros //
////////////
#define UNCOMPRESS_BUFFER_SIZE 12000

////////////////////////
// Variables globales //
////////////////////////
IntrFunction* IntrTable[14]={NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL};

signed short* commonSineTable=NULL;
unsigned short* commonSqrtTable=NULL;

CommonSprite* commonSprites=NULL;

const unsigned char commonSramMagic[]="Mister Jelly v0.1";
const unsigned char commonSramSignature[]="SRAM_V110";

/////////////////
// CommonVwait //
/////////////////
inline void CommonVwait(unsigned short wait)
{
   unsigned short vblTarget;

   vblTarget=commonVblCounter+wait;
   while(commonVblCounter!=vblTarget)
      asm("swi 0x20000"); // Halt le CPU
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
   // Mise a jour du compteur de VBL
   ++commonVblCounter;
}

///////////////////////
// CommonSineInitVbl //
///////////////////////
unsigned char CODE_IN_IWRAM CommonSineInitVbl(unsigned short wait)
{
   static unsigned short A;
   static signed short sine;
   unsigned short vblTarget;

   // Reserve de la memoire pour notre tableau de sinus
   if(!commonSineTable)
   {
      commonSineTable=(signed short*)malloc(SINNB*sizeof(signed short));
      A=0;
      sine=0; // Initialise a 0 car sin(0)=0...
   }

   // Mise a jour partielle du tableau de sinus...
   vblTarget=commonVblCounter+wait;
   while(commonVblCounter!=vblTarget)
   {
      // C'est termine ?
      if(A==SINNB/4)
      {
         CommonVwait(vblTarget-commonVblCounter);
         return(0);
      }

      // On met a jour le tableau en tenant compte des symetries
      commonSineTable[A]=sine;
      commonSineTable[(SINNB/2)+A]=-sine;

      // Angle suivant !
      ++A;

      // Voici la nouvelle valeur du sinus
      sine=sin(A*2*PI/SINNB)*FIXED_POINT;

      // On met a jour le tableau en tenant compte des symetries
      commonSineTable[(SINNB/2)-A]=sine;
      commonSineTable[SINNB-A]=-sine;
   }

   // Il faudra continuer...
   return(1);
}

////////////////
// CommonSqrt //
////////////////
signed long CODE_IN_IWRAM CommonSqrt(signed long a)
{
   signed long n,m,q,d;

   for(n=0,m=a;m>3;m>>=2,++n);

   for(q=0,m=1<<n;m;--n,m>>=1)
   {
      d=(q|m)<<n;
      if(a>=d)
      {
         a-=d;
         q|=m<<1;
      }
   }
   return(q>>1);
}

///////////////////////
// CommonSqrtInitVbl //
///////////////////////
unsigned char CODE_IN_IWRAM CommonSqrtInitVbl(unsigned short wait)
{
   static unsigned short n;
   unsigned short vblTarget;

   // Reserve de la memoire pour notre tableau de sinus
   if(!commonSqrtTable)
   {
      commonSqrtTable=(unsigned short*)malloc(SQRTNB*sizeof(unsigned short));
      n=0;
   }

   // Mise a jour partielle du tableau de racines carrees...
   vblTarget=commonVblCounter+wait;
   while(commonVblCounter!=vblTarget)
   {
      // C'est termine ?
      if(n==SQRTNB)
      {
         CommonVwait(vblTarget-commonVblCounter);
         return(0);
      }

      // On met a jour le tableau
      commonSqrtTable[n]=CommonSqrt(n);

      // Valeur suivante !
      ++n;
   }

   // Il faudra continuer...
   return(1);
}

///////////////////////
// CommonSpritesInit //
///////////////////////
void CommonSpritesInit(void)
{
   unsigned char pointer;

   // Reserve de la memoire pour les sprites
   if(!commonSprites)
      commonSprites=(CommonSprite*)malloc(128*sizeof(CommonSprite));

   // Initialisation de la liste : tous les sprites sont desactives (taille double mais pas de rotation)
   for(pointer=0;pointer<128;++pointer)
      commonSprites[pointer].attribute0=(1<<9)|(0<<8);
}

//////////////////////////
// CommonSpritesDisplay //
//////////////////////////
inline void CommonSpritesDisplay(void)
{
   // Copie le buffer de sprites dans l'OAM
   CommonDmaCopy((void*)commonSprites,(void*)OAM,128*sizeof(CommonSprite)/4,DMA_32NOW);
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
   static unsigned long forcedValue;

   forcedValue=value;

   REG_DMA3SAD=(unsigned long)&forcedValue;
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
void CommonUncompressInVRAM(void* source,void* dest)
{
   // La compression realisee par gfx2gba ne tient pas compte des specificites de la VRAM !
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

   // Voici donc une version qui utilise la WRAM...
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
unsigned char CommonSramRead(unsigned char slotId,unsigned char* dest)
{
   volatile unsigned char* sram;
   unsigned short index;
   unsigned char numSlots;
   unsigned short sizeCurrentSlot;

   // Verifie le "magic"
   sram=SRAM;
   for(index=0;index<sizeof(commonSramMagic);++index)
      if(*sram++!=commonSramMagic[index])
         return(0);

   // Cherche les donnees
   numSlots=*sram++;
   while(numSlots)
   {
      // Recupere la taille de la structure sauvegardee
      sizeCurrentSlot=*sram++;
      sizeCurrentSlot|=(*sram++)<<8;

      // Verifie le "slotId"
      if(*sram++==slotId)
      {
         // Verifie la validite des donnees
         if(!*sram++)
            return(0);

         // Lit les donnees
         while(sizeCurrentSlot--)
            *dest++=*sram++;
         return(1);
      }

      // On passe au slot suivant...
      --numSlots;
      sram+=1+sizeCurrentSlot;
   }
   return(0);
}

/////////////////////
// CommonSramWrite //
/////////////////////
unsigned char CommonSramWrite(unsigned char slotId,unsigned char* source,unsigned short size)
{
   volatile unsigned char* sram;
   unsigned short index;
   unsigned char numSlots;
   unsigned short sizeCurrentSlot;

   // Verifie le "magic"
   sram=SRAM;
   for(index=0;index<sizeof(commonSramMagic);++index)
      if(*sram++!=commonSramMagic[index])
         break;

   if(index!=sizeof(commonSramMagic))
   {
      // Ecrit le "magic"
      sram=SRAM;
      for(index=0;index<sizeof(commonSramMagic);++index)
         *sram++=commonSramMagic[index];

      // On cree le premier slot
      *sram++=1;
   }
   else
   {
      // Cherche le slot
      numSlots=*sram++;
      while(numSlots)
      {
         // Recupere la taille de la structure sauvegardee
         sizeCurrentSlot=sram[0]+(sram[1]<<8);

         // Verifie le "slotId"
         if(sram[2]==slotId)
         {
            if(sizeCurrentSlot!=size)
               return(0);
            break;
         }

         // On passe au slot suivant...
         --numSlots;
         sram+=4+sizeCurrentSlot;
      }

      // Si le slot n'existe pas encore, alors on en ajoute un
      if(!numSlots)
         ++SRAM[index];
   }

   // Ecrit les donnees
   *sram++=size;
   *sram++=size>>8;
   *sram++=slotId;
   *sram++=1;
   while(size--)
      *sram++=*source++;
   return(1);
}

/////////////////////
// CommonSramClear //
/////////////////////
unsigned char CommonSramClear(unsigned char slotId)
{
   volatile unsigned char* sram;
   unsigned short index;
   unsigned char numSlots;

   // Verifie le "magic"
   sram=SRAM;
   for(index=0;index<sizeof(commonSramMagic);++index)
      if(*sram++!=commonSramMagic[index])
         return(0);

   // Cherche les donnees
   numSlots=*sram++;
   while(numSlots)
   {
      // Verifie le "slotId"
      if(sram[2]==slotId)
      {
         // On invalide le slot
         sram[3]=0;
         return(1);
      }

      // On passe au slot suivant...
      --numSlots;
      sram+=4+sram[0]+(sram[1]<<8);
   }
   return(0);
}
