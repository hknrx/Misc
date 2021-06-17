/*
** Mario Balls - Sources\Bump\Bump.c
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
extern const Sound ADPCM_MusiqueGenerique;

extern const unsigned char GBAX2005_Bitmap[];
extern const unsigned char HongKong2005_Bitmap[];

Bump bump;

//////////////
// BumpInit //
//////////////
void CODE_IN_IWRAM BumpInit(const unsigned char* image)
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

   // Termine l'initialisation de INV (si besoin est)
   while(initINV_VBL(0));

   // On passe en mode 4 (mais on n'utilisera qu'un pixel sur 2 en x, et que la 1ere moitie de l'ecran)
   REG_DISPCNT=4|BG2_ENABLE|BACKBUFFER;
   bump.screen=(unsigned short*)VRAM;
}

/////////////////
// BumpDestroy //
/////////////////
void CODE_IN_IWRAM BumpDestroy(void)
{
}

/////////////////
// BumpDisplay //
/////////////////
void CODE_IN_IWRAM BumpDisplay(signed short x,signed short y)
{
   signed short ddistx,ddistx_,ddisty,x_,finx,dx,dy,coul;
   signed long dist,dist_;
   unsigned short xy;
   unsigned short VBLcourant;

   // Les variables locales suivantes ameliorent les performances par rapport a l'utilisation des
   // pointeurs originaux ; le gain mesure est de 13% (3.09 VBL/frame => 2.68 VBL/frame)
   unsigned short* localINVERSE=INVERSE;
   unsigned short* localScreen=bump.screen;
   const unsigned char* localImage=bump.image;

   ddistx=x+x-1;
   ddisty=y+y-1;
   dist=x*x+y*y+HAUTEUR*HAUTEUR;

   xy=0;
   do
   {
      dist_=dist;
      ddistx_=ddistx;
      x_=x;
      finx=x_-XM;
      do
      {
         dx=localImage[xy];
         dy=dx-localImage[xy+XM];
         dx-=localImage[xy+1];

         coul=x_*dx+y*dy+(HAUTEUR<<5); // On considere le bump comme etant en virgule fixe 5 !
         if(coul>0)
         {
            coul=(coul*localINVERSE[dist_>>HAUTEUR_])>>VIRGULE_INV_;
            if(coul>31)
               coul=31;
         }
         else
            coul=0;

         *(unsigned char*)&localScreen[xy++]=coul; // On force les 2 pixels cote a cote ensemble a la meme valeur

         dist_-=ddistx_;
         ddistx_-=2;
         --x_;
      }
      while(x_>finx);

      dist-=ddisty;
      ddisty-=2;
      --y;
   }
   while(xy<XM*YM);

   // Attente du retour du balayage vertical
   VBLcourant=compteVBL;
   while(VBLcourant==compteVBL);

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

//////////////////
// BumpSequence //
//////////////////
void CODE_IN_IWRAM BumpSequence(void)
{
   unsigned char* bitmap;
   signed long x,y,dx,dy;
   unsigned short fade;
   unsigned char phase,tempoFade,tempoBump;
   unsigned short VBLcourant;

   // Demarre la musique !
   AdpcmStart(&ADPCM_MusiqueGenerique,-1,0);

   // Preparation du fading
   REG_BLDMOD=BLEND_BG2|BLEND_BLACK;
   fade=16;
   REG_BLD_FAD=fade;

   // Copie le 1er splash screen dans une zone memoire modifiable (pour pouvoir faire la transition)
   bitmap=(unsigned char*)malloc(XO4*(YO4+1));
   copieDMA((void*)GBAX2005_Bitmap,(void*)bitmap,XO4*(YO4+1)/4,DMA_32NOW);

   // Initialisation du moteur
   BumpInit(bitmap);

   // Placement du spot au milieu de l'ecran
   x=XO4/2;
   y=YO4/2;
   dx=5;
   dy=2;

   // C'est parti pour la sequence de bump mapping !
   phase=0;
   tempoFade=0;
   tempoBump=TEMPO_BUMP;
   do
   {
      // Affichage du bump
      BumpDisplay(x,y);

      // Deplacement manuel
      if(!(REG_TOUCHES&TOUCHE_GAUCHE) && x>=BUMP_MOVE)
         x-=BUMP_MOVE;
      else if(!(REG_TOUCHES&TOUCHE_DROITE) && x<XM4/2-BUMP_MOVE)
         x+=BUMP_MOVE;
      if(!(REG_TOUCHES&TOUCHE_HAUT) && y>=BUMP_MOVE)
         y-=BUMP_MOVE;
      else if(!(REG_TOUCHES&TOUCHE_BAS) && y<YM4/2-BUMP_MOVE)
         y+=BUMP_MOVE;

      // Deplacement automatique ?
      if(~REG_TOUCHES&(TOUCHE_HAUT|TOUCHE_BAS|TOUCHE_GAUCHE|TOUCHE_DROITE))
         tempoBump=TEMPO_BUMP;
      else
      {
         --tempoBump;
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
            if(++tempoFade>=TEMPO_FADE)
            {
               tempoFade=0;
               if(!--fade)
                  phase=1;
               REG_BLD_FAD=fade;
            }

         case 1:
            // Affichage du 1er splash screen
            if(~REG_TOUCHES&(TOUCHE_START|TOUCHE_A))
               phase=4;
            else if(!tempoBump)
            {
               tempoBump=TEMPO_BUMP;
               phase=2;
            }
            break;

         case 2:
            // Transition entre les 2 splash screens
            if(++tempoFade>=TEMPO_FADE)
            {
               tempoFade=0;
               if(!BumpTransition(HongKong2005_Bitmap))
                  phase=3;
               else
                  ++tempoBump; // On corrige un peu tempoBump !
            }

         case 3:
            // Affichage du 2nd splash screen
            if(~REG_TOUCHES&(TOUCHE_START|TOUCHE_A) || !tempoBump)
               phase=4;
            break;

         case 4:
            // Fading out
            if(++tempoFade>=TEMPO_FADE)
            {
               tempoFade=0;
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
   VBLcourant=compteVBL;
   while(VBLcourant==compteVBL);

   // Supprime le fading, mais force d'abord l'ecran au noir
   REG_DISPCNT=0;
   REG_BLDMOD=BLEND_NO;

   // On ne continue que si les touches start et A ont ete relachees
   while(~REG_TOUCHES&(TOUCHE_START|TOUCHE_A));
}
