/*
** Bomb Jack - Sources\Common\Common.c
** Nicolas ROBERT [NRX] - Hong Kong 2005 / France 2006
*/

////////////////
// Inclusions //
////////////////
#include "Common.h"

////////////
// Macros //
////////////
#ifdef ADPCM_ENABLED
#define ROM_SIZE 53372
#endif // ADPCM_ENABLED

#define UNCOMPRESS_BUFFER_SIZE 12000

////////////////////////
// Variables globales //
////////////////////////
IntrFunction* IntrTable[14]={NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL};

CommonSprite* commonSprites=NULL;

const unsigned char commonSramMagic[]="BJ v1.3";
const unsigned char commonSramSignature[]="SRAM_V110";

unsigned short commonCpcPalette[27];

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
   #ifdef ADPCM_ENABLED
   static unsigned short keys=0;
   const AdpcmSound* current;
   const AdpcmSound* previous;
   const AdpcmSound* next;

   // Gestion du son : verifie si les touches [L] ou [R] sont pressees, ou si la musique est arretee
   keys&=~REG_KEYS;
   if(keys&KEY_L)
   {
      // Recherche la piste precedente
      current=AdpcmGetSound(0);
      next=(const AdpcmSound*)(0x8000000+((ROM_SIZE+3)&~3));
      do
      {
         previous=next;
         next=(const AdpcmSound*)(((unsigned long)next+sizeof(AdpcmSound)+next->length+3)&~3);
      }
      while(next<current);

      // Lance la musique
      AdpcmStart(0,previous,1);
   }
   else if(keys&KEY_R || !AdpcmGetRepeat(0))
   {
      // Recherche la piste suivante
      current=AdpcmGetSound(0);
      next=(const AdpcmSound*)(((unsigned long)current+sizeof(AdpcmSound)+current->length+3)&~3);

      // Lance la musique
      if(AdpcmStart(0,next,1))
      {
         // Joue la 1ere piste
         AdpcmStart(0,(const AdpcmSound*)(0x8000000+((ROM_SIZE+3)&~3)),1);
      }
   }
   keys=REG_KEYS;

   // Decodage du son...
   AdpcmDecodeVbl(0);
   #endif // ADPCM_ENABLED

   // Mise a jour du compteur de VBL
   ++commonVblCounter;
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

/////////////////////
// CommonCpcPenSet //
/////////////////////
inline void CommonCpcPenSet(unsigned char pen,unsigned char ink,volatile unsigned short* dest)
{
   dest[pen]=commonCpcPalette[ink];
}

//////////////////////////
// CommonCpcPaletteInit //
//////////////////////////
void CommonCpcPaletteInit(void)
{
   unsigned char ink;
   unsigned char R,G,B;
   const unsigned short value[]={0,24,31}; // 24 = gamma correction(3) de 15 = 31*((15/31)^(1/3))

   ink=0;
   for(G=0;G<3;++G)
      for(R=0;R<3;++R)
         for(B=0;B<3;++B)
            commonCpcPalette[ink++]=RGB(value[R],value[G],value[B]);
}

/////////////////////////
// CommonCpcPaletteSet //
/////////////////////////
void CommonCpcPaletteSet(const unsigned char* source,volatile unsigned short* dest)
{
   unsigned char pen;

   for(pen=0;pen<16;++pen)
      CommonCpcPenSet(pen,source[pen],dest);
}

////////////////////////////
// CommonCpcPaletteRotate //
////////////////////////////
void CommonCpcPaletteRotate(CommonCpcColorSequences* sequences,unsigned char mode)
{
   unsigned char pen;
   unsigned char sequenceIdx;
   unsigned char inkIdx;

   for(sequenceIdx=0;sequenceIdx<sequences->count;++sequenceIdx)
   {
      pen=sequences->info[sequenceIdx].pen;
      if(mode)
      {
         inkIdx=++sequences->info[sequenceIdx].count>>sequences->info[sequenceIdx].shift;
         if(inkIdx>=sequences->info[sequenceIdx].length)
         {
            inkIdx=0;
            sequences->info[sequenceIdx].count=0;
         }
         CommonCpcPenSet(pen,sequences->info[sequenceIdx].inks[inkIdx],PALRAM);
      }
      else
         PALRAM[pen]=0;
   }
}

///////////////////////
// CommonCpcMaskInit //
///////////////////////
void CommonCpcMaskInit(void)
{
   unsigned short tile,specialTile,x,y;
   unsigned short* screen;

   CommonDmaForce(0,(void*)CHAR_BASE_BLOCK(2),32/4,DMA_32NOW);

   specialTile=2;
   screen=(unsigned short*)SCREEN_BASE_BLOCK(30);
   for(x=0;x<30;++x)
   {
      for(y=0;y<20;++y)
      {
         if(x<2 || x>=28 || y<2 || y>=18)
            tile=0;
         else if(y<7)
            tile=1;
         else
            tile=specialTile++;
         *screen=tile;
         screen+=32;
      }
      screen-=32*20-1;
   }
}

///////////////////////////
// CommonCpcMaskCleanAll //
///////////////////////////
void CommonCpcMaskCleanAll(unsigned char pen)
{
   unsigned long eightPixels;

   eightPixels=pen|(pen<<4);
   eightPixels|=eightPixels<<8;
   eightPixels|=eightPixels<<16;
   CommonDmaForce(eightPixels,(void*)CHAR_BASE_BLOCK(2)+32,(1+26*11)*32/4,DMA_32NOW);
}

////////////////////////////
// CommonCpcMaskCleanChar //
////////////////////////////
void CommonCpcMaskCleanChar(unsigned char x,unsigned char y,unsigned char pen)
{
   unsigned short* destAddressFour;
   unsigned long* destAddressEight;
   unsigned short fourPixels;
   unsigned long eightPixels;

   x=x*3+1;
   destAddressFour=(unsigned short*)CHAR_BASE_BLOCK(2)+(16*2)+(y<<4)+(x&1)+(x>>1)*(11*16);

   if((unsigned long)destAddressFour&2)
      destAddressEight=(unsigned long*)(destAddressFour+11*16-1);
   else
   {
      destAddressEight=(unsigned long*)destAddressFour;
      destAddressFour+=11*16;
   }

   fourPixels=pen|(pen<<4);
   fourPixels|=fourPixels<<8;
   eightPixels=fourPixels|(fourPixels<<16);

   for(y=0;y<8;++y)
   {
      *destAddressFour=fourPixels;
      destAddressFour+=2;

      *destAddressEight=eightPixels;
      ++destAddressEight;
   }
}

//////////////////////////////
// CommonCpcMaskWriteString //
//////////////////////////////
void CommonCpcMaskWriteString(unsigned char x,unsigned char y,const unsigned char* string,unsigned char pen)
{
   unsigned char character;
   unsigned short* destAddress;
   unsigned long* sourceAddress;
   unsigned char destValue[2];
   unsigned long sourceValue0,sourceValue1,mask;

   x=x*3+1;
   destAddress=(unsigned short*)CHAR_BASE_BLOCK(2)+(16*2)+(y<<4)+(x&1)+(x>>1)*(11*16);

   pen|=pen<<4;

   while((character=*string++)!='\0')
      if(character==' ')
      {
         if((unsigned long)destAddress&2)
            destAddress+=11*16*2-1;
         else
            destAddress+=11*16+1;
      }
      else
      {
         sourceAddress=(unsigned long*)CHAR_BASE_BLOCK(2)+(2+26*11)*32/4+(character-' ')*6;
         for(x=0;x<6;x+=2)
         {
            sourceValue0=*sourceAddress++;
            sourceValue1=*sourceAddress++;

            mask=15;
            for(y=0;y<8;++y)
            {
               *(unsigned short*)destValue=*destAddress;
               if(sourceValue0&mask)
                  destValue[0]=pen;
               if(sourceValue1&mask)
                  destValue[1]=pen;
               *destAddress=*(unsigned short*)destValue;

               destAddress+=2;
               mask<<=4;
            }
            if((unsigned long)destAddress&2)
               destAddress+=10*16-1;
            else
               destAddress-=16-1;
         }
      }
}
