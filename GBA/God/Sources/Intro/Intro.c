/*
** God - Sources\Intro\Intro.c
** Nicolas ROBERT [NRX] - Hong Kong 2005
*/

////////////////
// Inclusions //
////////////////
#include "..\Common\Common.h"
#include "Bump\Bump.h"
#include "Voxel\Voxel.h"

////////////
// Macros //
////////////
#define TIME_OUT_FADE  2
#define TIME_OUT_BUMP  70
#define TIME_OUT_INTRO 12
#define BUMP_MOVE      6
#define VOXEL_HEIGHT   10.0

////////////////////////
// Variables globales //
////////////////////////
extern const Sound ADPCM_MusicTitle;

extern const unsigned char Nrx_Bitmap[];
extern const unsigned char HongKong2005_Bitmap[];
extern const unsigned char GOD_Bitmap[];
extern const unsigned short GOD_Palette[];
extern const unsigned char Font_Bitmap[];

unsigned short alphaOBJ,alphaBG; // Les fonctions d'interruptions doivent y acceder...

//////////////////////
// IntroWriteString //
//////////////////////
unsigned char IntroWriteString(unsigned char pointer,unsigned short x,unsigned short y,const unsigned char* string)
{
   unsigned char length;

   // Repositionnement
   for(length=0;string[length]!='\0';++length);
   x-=length<<2;
   y-=4;

   // Affichage de la chaine de caracteres
   while(*string!='\0')
   {
      // Positionne le sprite (sauf pour les espaces ou caracteres inconnus)
      if(*string>' ' && *string<=']')
      {
         sprites[pointer].attribute0=y|(1<<13)|(1<<10); // Sprite 256 couleurs, semi-transparent
         sprites[pointer].attribute1=x;
         sprites[pointer].attribute2=((*string-' ')<<1)+(16384+8192)/32;
         ++pointer;
      }

      // Caractere suivant...
      ++string;
      x+=8;
   }

   // Retourne le pointeur sur le prochain sprite libre
   return(pointer);
}

///////////////
// IntroBump //
///////////////
void IntroBump(void)
{
   unsigned char* bitmap;
   signed long x,y,dx,dy;
   unsigned short fade;
   unsigned char phase,timeOutFade,timeOutBump;
   unsigned short keys;

   // Demarre la musique !
   AdpcmStart(&ADPCM_MusicTitle,-1,0);

   // Preparation du fading
   REG_BLDMOD=BLEND_BG2|BLEND_BLACK;
   fade=16;
   REG_BLD_FAD=fade;

   // Copie le 1er splash screen dans une zone memoire modifiable (pour pouvoir faire la transition)
   bitmap=(unsigned char*)malloc(XO4*(YO4+1));
   CommonUncompressInWRAM((void*)Nrx_Bitmap,(void*)bitmap);

   // Initialisation du moteur
   BumpInit(bitmap);

   // Placement du spot au milieu de l'ecran
   x=XO4/2;
   y=YO4/2;
   dx=5;
   dy=2;

   // C'est parti pour la sequence de bump mapping !
   phase=0;
   timeOutFade=0;
   timeOutBump=TIME_OUT_BUMP;
   do
   {
      // Affichage du bump
      keys=REG_KEYS;
      BumpDisplay(x,y);
      keys&=~REG_KEYS;

      // Deplacement manuel
      if(!(REG_KEYS&KEY_LEFT) && x>=BUMP_MOVE)
         x-=BUMP_MOVE;
      else if(!(REG_KEYS&KEY_RIGHT) && x<XM4/2-BUMP_MOVE)
         x+=BUMP_MOVE;
      if(!(REG_KEYS&KEY_UP) && y>=BUMP_MOVE)
         y-=BUMP_MOVE;
      else if(!(REG_KEYS&KEY_DOWN) && y<YM4/2-BUMP_MOVE)
         y+=BUMP_MOVE;

      // Deplacement automatique ?
      if(~REG_KEYS&(KEY_UP|KEY_DOWN|KEY_LEFT|KEY_RIGHT))
         timeOutBump=TIME_OUT_BUMP;
      else
      {
         --timeOutBump;
         x+=dx;
         y+=dy;

         if((unsigned long)x>=XM4/2)
            dx=-dx;
         if((unsigned long)y>=YM4/2)
            dy=-dy;
      }

      // Gestion de la phase
      switch(phase)
      {
         case 0:
            // Fading in
            if(++timeOutFade>=TIME_OUT_FADE)
            {
               timeOutFade=0;
               if(!--fade)
                  phase=1;
               REG_BLD_FAD=fade;
            }

         case 1:
            // Affichage du 1er splash screen
            if(keys&(KEY_START|KEY_A))
               phase=4;
            else if(!timeOutBump)
            {
               timeOutBump=TIME_OUT_BUMP;
               phase=2;
            }
            break;

         case 2:
            // Transition entre les 2 splash screens
            if(++timeOutFade>=TIME_OUT_FADE)
            {
               timeOutFade=0;
               if(!BumpTransition(HongKong2005_Bitmap))
                  phase=3;
               else
                  ++timeOutBump; // On corrige un peu timeOutBump !
            }

         case 3:
            // Affichage du 2nd splash screen
            if(keys&(KEY_START|KEY_A) || !timeOutBump)
               phase=4;
            break;

         case 4:
            // Fading out
            if(++timeOutFade>=TIME_OUT_FADE)
            {
               timeOutFade=0;
               if(++fade==16)
                  phase=5;
               REG_BLD_FAD=fade;
            }
            break;
      }
   }
   while(phase!=5);

   // Liberation memoire
   BumpDestroy();
   free(bitmap);

   // Attente du retour du balayage vertical
   CommonVwait();

   // Supprime le fading, mais force d'abord l'ecran au noir
   REG_DISPCNT=0;
   REG_BLDMOD=BLEND_NO;
}

////////////////////////////////
// IntroFadingInterruptNormal //
////////////////////////////////
void IntroFadingInterruptNormal(void)
{
   unsigned short newAlphaOBJ,newAlphaBG;

   // On met en place le fading
   newAlphaOBJ=(alphaBG*alphaOBJ)>>4;
   newAlphaBG=alphaBG-newAlphaOBJ;

   REG_BLD_AB=(newAlphaBG<<8)|newAlphaOBJ;

   // On fait egalement ce que fait le "basicVblInterrupt" !
   AdpcmDecodeVbl(0);
   AdpcmDecodeVbl(1);
   ++vblCounter;
}

////////////////////////////
// IntroFadingInterruptUp //
////////////////////////////
void IntroFadingInterruptUp(void)
{
   // On met en place le fading pour la partie haute de l'ecran
   REG_BLD_AB=(alphaBG<<8)|((alphaOBJ*alphaBG)>>4);

   // On fait egalement ce que fait le "basicVblInterrupt" !
   AdpcmDecodeVbl(0);
   AdpcmDecodeVbl(1);
   ++vblCounter;
}

//////////////////////////////
// IntroFadingInterruptDown //
//////////////////////////////
void IntroFadingInterruptDown(void)
{
   unsigned short newAlphaOBJ,newAlphaBG;

   newAlphaOBJ=vblCounter&15;
   if(vblCounter&16)
      newAlphaOBJ=16-newAlphaOBJ;

   newAlphaOBJ=(alphaBG*alphaOBJ*newAlphaOBJ)>>8;
   newAlphaBG=alphaBG-newAlphaOBJ;

   REG_BLD_AB=(newAlphaBG<<8)|newAlphaOBJ;
}

////////////////
// IntroVoxel //
////////////////
void IntroVoxel(void)
{
   signed long x,y,z;
   unsigned char Ry;
   static unsigned char phaseIntro=0;
   unsigned char phaseFade,timeOutFade,timeOutIntro;
   unsigned char pointerSprite;
   unsigned short keys;

   // (Re-)demarre la musique !
   if(!AdpcmStatus(0))
      AdpcmStart(&ADPCM_MusicTitle,-1,0);

   // Preparation du fading
   REG_BLDMOD=(BLEND_BG2<<8)|BLEND_BG2|BLEND_OBJ|BLEND_BLACK;
   alphaBG=0;
   alphaOBJ=0;
   REG_BLD_FAD=16;

   // Chargement des sprites du titre ("GOD" - 2 sprites de 64x64) et de la police de caracteres
   // Rappel : dans les modes 3 a 5 les sprites sont situes 16Ko plus loin...
   CommonDmaCopy((void*)GOD_Bitmap,(void*)OBJ_TILES+16384,8192/4,DMA_32NOW);
   CommonUncompressInVRAM((void*)GOD_Palette,(void*)OBJ_PALRAM);
   CommonUncompressInVRAM((void*)Font_Bitmap,(void*)OBJ_TILES+16384+8192);

   // Initialisation du moteur
   VoxelInit();

   // On prepare l'affichage des sprites
   CommonSpritesInit();
   CommonSpritesDisplay();
   REG_DISPCNT|=OBJ_ENABLE|OBJ_2D;

   // C'est parti pour la sequence de voxel spacing !
   Ry=SINNB/16;
   x=0;
   z=0;

   if(phaseIntro<12)
      phaseIntro=0;
   else
      phaseIntro=12;
   timeOutIntro=0;

   phaseFade=0;
   timeOutFade=0;
   do
   {
      // Affichage du voxel
      keys=REG_KEYS;
      y=VoxelMove(&x,&z,Ry)+VOXEL_HEIGHT*FIXED_POINT;
      VoxelDisplay(x,y,z,Ry);
      keys&=~REG_KEYS;

      // Deplacement(automatique)
      switch(vblCounter&(3<<8))
      {
         case 1<<8:
            ++Ry;
            break;
         case 3<<8:
            --Ry;
            break;
      }

      // Gestion de la phase (intro)
      switch(phaseIntro)
      {
         case 1:
         case 5:
         case 9:
         case 13:
            // Fading in
            if(++timeOutIntro>=TIME_OUT_FADE)
            {
               timeOutIntro=0;
               if(++alphaOBJ==16)
                  ++phaseIntro;
            }
            break;

         case 2:
         case 6:
         case 10:
            // Temporisation...
            if(++timeOutIntro>=TIME_OUT_INTRO)
            {
               timeOutIntro=0;
               ++phaseIntro;
            }
            break;

         case 3:
         case 7:
         case 11:
            // Fading out
            if(++timeOutIntro>=TIME_OUT_FADE)
            {
               timeOutIntro=0;
               if(!--alphaOBJ)
                  ++phaseIntro;
            }
            break;

         case 0:
            // Greetingz #1
            CommonInterruptSet(IT_VBLANK,(IntrFunction*)&IntroFadingInterruptNormal);
            IntroWriteString(0,XO4,YO4,"NRX");
            CommonSpritesDisplay();
            phaseIntro=1;
            break;

         case 4:
            // Greetingz #2
            pointerSprite=IntroWriteString(0,XO4,YO4-8,"PROUD MEMBER OF");
            IntroWriteString(pointerSprite,XO4,YO4+8,"WWW.PLAYERADVANCE.ORG");
            CommonSpritesDisplay();
            phaseIntro=5;
            break;

         case 8:
            // Greetingz #3
            CommonSpritesInit();
            IntroWriteString(0,XO4,YO4,"PRESENTS");
            CommonSpritesDisplay();
            phaseIntro=9;
            break;

         case 12:
            // Mise en place du titre "GOD" (2 sprites de 64x64)
            sprites[0].attribute0=(YO4-48)|(1<<13)|(0<<14)|(1<<10); // 256 colors, square, semi-transparent
            sprites[0].attribute1=(XO4-64)|(3<<14); // Size 64x64
            sprites[0].attribute2=(512)|(0<<10); // Priority 0
            sprites[1].attribute0=(YO4-48)|(1<<13)|(0<<14)|(1<<10); // 256 colors, square, semi-transparent
            sprites[1].attribute1=(XO4)|(3<<14); // Size 64x64
            sprites[1].attribute2=(528)|(0<<10); // Priority 0

            // On complete le titre
            pointerSprite=IntroWriteString(2,XO4,YO4+24,"GAMEBOY ORDINARY DUNGEON");
            IntroWriteString(pointerSprite,XO4,YM4-12,"PRESS START");

            // Mise en place des interruptions VBL et YTRIG pour modifier dynamiquement le fading
            CommonInterruptSet(IT_VBLANK,(IntrFunction*)&IntroFadingInterruptUp);
            CommonInterruptSetYTrig(YM4-20,(IntrFunction*)&IntroFadingInterruptDown);

            // Affichage des sprites
            CommonSpritesDisplay();
            phaseIntro=13;
            break;
      }

      // Gestion de la phase (fading)
      switch(phaseFade)
      {
         case 0:
            // Fading in
            if(++timeOutFade>=TIME_OUT_FADE)
            {
               timeOutFade=0;
               if(++alphaBG==16)
                  phaseFade=1;
               REG_BLD_FAD=16-alphaBG;
            }

         case 1:
            // Attente...
            if(keys&(KEY_START|KEY_A))
               phaseFade=2;
            break;

         case 2:
            // Fading out
            if(++timeOutFade>=TIME_OUT_FADE)
            {
               timeOutFade=0;
               if(!--alphaBG)
                  phaseFade=3;
               REG_BLD_FAD=16-alphaBG;
            }
            break;
      }
   }
   while(phaseFade!=3);

   // Arret de la musique
   AdpcmStop(0);

   // Desactive l'interruption sur YTRIG et remet en place celle sur VBL
   CommonInterruptDisable(IT_YTRIG);
   CommonInterruptSet(IT_VBLANK,(IntrFunction*)&CommonInterruptBasicVbl);

   // Liberation memoire
   VoxelDestroy();

   // Attente du retour du balayage vertical
   CommonVwait();

   // Supprime le fading, mais force d'abord l'ecran au noir
   REG_DISPCNT=0;
   REG_BLDMOD=BLEND_NO;
}
