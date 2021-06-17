/*
** Z80 - Sources\Common\Common.c
** Nicolas ROBERT [NRX] - Hong Kong 2005
*/

////////////////
// Inclusions //
////////////////
#include "Common.h"

////////////
// Macros //
////////////
#define UNCOMPRESS_BUFFER_SIZE 12000

////////////////////////
// Variables globales //
////////////////////////
IntrFunction* IntrTable[14]={NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL};

Sprite* sprites=NULL;
unsigned char* cpcMemory=NULL;
unsigned long dmaZero;

const unsigned char SRAM_MAGIC[]="Z80";
const unsigned char SRAM_SIGNATURE[]="SRAM_V110";

unsigned short* cpcPixelConvert;
unsigned short cpcPalette[27];
unsigned char cpcPaletteConvert[32]={13,0,19,25,1,7,10,16,0,0,24,26,6,8,15,17,0,0,18,20,0,2,9,11,4,22,21,23,3,5,12,14};

/////////////////
// CommonVwait //
/////////////////
inline void CommonVwait(void)
{
   asm volatile("swi 0x20000");
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
   ++vblCounter;
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
void CommonUncompressInWRAM(void* source,void* dest)
{
   asm volatile("swi 0x110000");
}

//////////////////////
// CommonUncompress //
//////////////////////
unsigned long CommonUncompress(void* source,void* dest)
{
   unsigned long size;
   unsigned char buffer[UNCOMPRESS_BUFFER_SIZE];

   size=(*(unsigned long*)source)>>8;
   if(size>UNCOMPRESS_BUFFER_SIZE)
      return(0);

   CommonUncompressInWRAM(source,buffer);
   CommonDmaCopy(buffer,dest,size>>2,DMA_32NOW);
   return(size);
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

///////////////////
// CommonCpcInit //
///////////////////
void CommonCpcInit(unsigned char* SNA)
{
   unsigned short byte;
   unsigned char R,G,B;
   const unsigned short value[]={0,24,31}; // 24 = gamma correction(3) of 15 = 31*((15/31)^(1/3))
   unsigned char pixels[2];

   // Memorise le snapshot
   if(!cpcMemory)
      cpcMemory=(unsigned char*)malloc(0x10000*sizeof(unsigned char));
   CommonDmaCopy(SNA+0x100,cpcMemory,0x10000>>2,DMA_32NOW);

   // Initialisation de la palette (palette software du CPC)
   byte=0;
   for(G=0;G<3;++G)
      for(R=0;R<3;++R)
         for(B=0;B<3;++B)
            cpcPalette[byte++]=RGB(value[R],value[G],value[B]);

   // Creation du tableau de conversion pixels CPC -> pixels GBA
   cpcPixelConvert=(unsigned short*)malloc(256*sizeof(unsigned short));
   for(byte=0;byte<256;++byte)
   {
      pixels[0]=((byte&2)<<2)|((byte&8)>>2)|((byte&32)>>3)|((byte&128)>>7);
      pixels[1]=((byte&1)<<3)|((byte&4)>>1)|((byte&16)>>2)|((byte&64)>>6);
      cpcPixelConvert[byte]=*(unsigned short*)pixels;
   }
}

///////////////////////////
// CommonCpcVblInterrupt //
///////////////////////////
void CODE_IN_IWRAM CommonCpcVblInterrupt(void)
{
   unsigned short* gbaMemory;
   unsigned short cpcPointer;
   unsigned char doScale;
   unsigned char x,y;

   // Incremente aussi le compteur de VBL
   ++vblCounter;

   // Rafraichit l'ecran de la GBA
   if(vblCounter&3)
      return;

   gbaMemory=(unsigned short*)VRAM;
   cpcPointer=cpcScreen;
   doScale=0;
   for(y=0;y<160;++y)
   {
      for(x=0;x<80;++x)
         *gbaMemory++=cpcPixelConvert[cpcMemory[cpcPointer++]];
      gbaMemory+=40; // 80 pixels de plus par ligne sur la GBA
      if(doScale<3)
      {
         ++doScale;
         cpcPointer+=(80*24)+48;
      }
      else
      {
         doScale=0;
         cpcPointer+=(80*24)+48+(80*25)+48;
      }
      if((cpcPointer&0xC000)!=cpcScreen)
         cpcPointer+=0xC050;
   }
}

/////////////////////////
// CommonCpcSoftPenSet //
/////////////////////////
inline void CommonCpcSoftPenSet(unsigned char pen,unsigned char ink,volatile unsigned short* dest)
{
   dest[pen]=cpcPalette[ink];
}

/////////////////////////
// CommonCpcHardPenSet //
/////////////////////////
inline void CommonCpcHardPenSet(unsigned char pen,unsigned char ink,volatile unsigned short* dest)
{
   dest[pen]=cpcPalette[cpcPaletteConvert[ink]];
}

/////////////////////////////
// CommonCpcSoftPaletteSet //
/////////////////////////////
void CommonCpcSoftPaletteSet(const unsigned char* source,volatile unsigned short* dest)
{
   unsigned char pen;

   for(pen=0;pen<16;++pen)
      CommonCpcSoftPenSet(pen,source[pen],dest);
}

/////////////////////////////
// CommonCpcHardPaletteSet //
/////////////////////////////
void CommonCpcHardPaletteSet(const unsigned char* source,volatile unsigned short* dest)
{
   unsigned char pen;

   for(pen=0;pen<16;++pen)
      CommonCpcHardPenSet(pen,source[pen],dest);
}
