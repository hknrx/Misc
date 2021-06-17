/*
** God - Sources\Intro\Bump\Bump.c
** Nicolas ROBERT [NRX] - Hong Kong 2005
*/

////////////////
// Inclusions //
////////////////
#include "Bump.h"

////////////
// Macros //
////////////
#define XM (XM4/2)
#define YM (YM4/2)
#define XO (XM/2)
#define YO (YM/2)

///////////
// Types //
///////////
typedef struct
{
   unsigned short* screen;
   const unsigned char* image;
}
Bump;

////////////////////////
// Variables globales //
////////////////////////
Bump bump;

//////////////
// BumpInit //
//////////////
void BumpInit(const unsigned char* image)
{
   unsigned short x;

   // Etire le buffer en hauteur (x2)
   REG_BG2PA=(XM4<<8)/XM4;
   REG_BG2PB=0;
   REG_BG2PC=0;
   REG_BG2PD=(YM<<8)/YM4;

   // Il ne faut pas oublier de positionner le buffer au bon endroit !
   REG_BG2X=0;
   REG_BG2Y=0;

   // Creation de la palette
   for(x=0;x<32;++x)
      PALRAM[x]=RGB(x,x,x);

   // Memorise l'adresse de l'image a afficher
   bump.image=image;

   // Termine l'initialisation de INVERSE_TABLE (si besoin est)
   while(CommonInverseInitVbl(0));

   // On passe en mode 4 (mais on n'utilisera qu'un pixel sur 2 en x, et que la 1ere moitie de l'ecran)
   REG_DISPCNT=4|BG2_ENABLE|BACKBUFFER;
   bump.screen=(unsigned short*)VRAM;
}

/////////////////
// BumpDestroy //
/////////////////
void BumpDestroy(void)
{
}

/////////////////
// BumpDisplay //
/////////////////
void CODE_IN_IWRAM BumpDisplay(signed short x,signed short y)
{
   signed short ddistx,ddistx_,ddisty,x_,endx,dx,dy,color;
   signed long dist,dist_;
   unsigned short xy;

   // Les variables locales suivantes ameliorent les performances par rapport a l'utilisation des
   // pointeurs originaux ; le gain mesure est de 13% (3.09 VBL/frame => 2.68 VBL/frame)
   unsigned short* localINVERSE_TABLE=INVERSE_TABLE;
   unsigned short* localScreen=bump.screen;
   const unsigned char* localImage=bump.image;

   ddistx=x+x-1;
   ddisty=y+y-1;
   dist=x*x+y*y+HEIGHT*HEIGHT;

   xy=0;
   do
   {
      dist_=dist;
      ddistx_=ddistx;
      x_=x;
      endx=x_-XM;
      do
      {
         dx=localImage[xy];
         dy=dx-localImage[xy+XM];
         dx-=localImage[xy+1];

         color=x_*dx+y*dy+(HEIGHT<<5); // On considere le bump comme etant en virgule fixe 5 !
         if(color>0)
         {
            color=(color*localINVERSE_TABLE[dist_>>HEIGHT_SHIFT])>>FIXED_POINT_INV_SHIFT;
            if(color>31)
               color=31;
         }
         else
            color=0;

         *(unsigned char*)&localScreen[xy++]=color; // On force les 2 pixels cote a cote ensemble a la meme valeur

         dist_-=ddistx_;
         ddistx_-=2;
         --x_;
      }
      while(x_>endx);

      dist-=ddisty;
      ddisty-=2;
      --y;
   }
   while(xy<XM*YM);

   // Attente du retour du balayage vertical
   CommonVwait();

   // Affichage (inversion des buffers video)
   REG_DISPCNT^=BACKBUFFER;
   (unsigned long)bump.screen^=BACKVRAM;
}

////////////////////
// BumpTransition //
////////////////////
unsigned short CODE_IN_IWRAM BumpTransition(const unsigned char* newImage)
{
   unsigned char* localImage=(unsigned char*)bump.image;
   unsigned short countTotal,countModified;

   countTotal=XM*(YM+1);
   countModified=XM*(YM+1);
   do
   {
      if(*newImage>*localImage)
         ++*localImage;
      else if(*newImage<*localImage)
         --*localImage;
      else
         --countModified;
      ++localImage;
      ++newImage;
   }
   while(--countTotal);

   return(countModified);
}
