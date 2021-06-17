/*
   TODO:
   - optimiser le ray tracer (utilisation de INV)
   - implementer le moteur de polygones & spheres (avec textures ?)
   - essayer de compiler avec un autre compilateur (ARM SDT ou ADS ?)
   - mettre un sprite au milieu du plasma
*/

#include "Bump.h"
#include "Voxel.h"
#include "RayCaster.h"
#include "Plasma.h"

#define DEPLACE_BUMP 6
#define ROTATION_VOX 2
#define HAUTEUR_VOX  (16*VIRGULE)
#define ROTATION_RC  2
#define VERTICAL_RC  (0.05*VIRGULE)

//////////
// main //
//////////
int main(void)
{
   signed long x,y,z,dx,dy;
   unsigned char A,ok,n;

   // Initialisation
   initCommun();

   // Bump mapping
   initBump();

   x=XO4/2;
   y=YO4/2;
   dx=5;
   dy=2;

   n=0;
   ok=2;
   do
   {
      // Affichage
      modifieBump(x,y);
      afficheCommun();

      // Deplacement manuel
      if(!(REG_TOUCHES&TOUCHE_GAUCHE) && x>=DEPLACE_BUMP)
         x-=DEPLACE_BUMP;
      if(!(REG_TOUCHES&TOUCHE_DROITE) && x<XO4-DEPLACE_BUMP)
         x+=DEPLACE_BUMP;
      if(!(REG_TOUCHES&TOUCHE_HAUT) && y>=DEPLACE_BUMP)
         y-=DEPLACE_BUMP;
      if(!(REG_TOUCHES&TOUCHE_BAS) && y<YO4-DEPLACE_BUMP)
         y+=DEPLACE_BUMP;

      // Deplacement automatique ?
      if(~REG_TOUCHES&(TOUCHE_HAUT|TOUCHE_BAS|TOUCHE_GAUCHE|TOUCHE_DROITE))
         n=8;
      else if(n)
         --n;
      else
      {
         x+=dx;
         y+=dy;

         if((unsigned long)x>=XO4)
            dx=-dx;
         if((unsigned long)y>=YO4)
            dy=-dy;
      }

      // Fin ?
      if(REG_TOUCHES&TOUCHE_START)
         ok=1;
      else if(ok==1)
         ok=0;
   }
   while(ok);

   // Voxel spacing
   initVoxel();

   A=16;
   x=0*VIRGULE;
   z=0*VIRGULE;

   ok=2;
   do
   {
      // Affichage
      y=deplacementVoxel(&x,&z,A+127)+HAUTEUR_VOX;
      voxel(x,y,z,A);
      afficheCommun();

      // Deplacement (manuel)
      if(!(REG_TOUCHES&TOUCHE_GAUCHE))
         A+=ROTATION_VOX;
      if(!(REG_TOUCHES&TOUCHE_DROITE))
         A-=ROTATION_VOX;

      // Fin ?
      if(REG_TOUCHES&TOUCHE_START)
         ok=1;
      else if(ok==1)
         ok=0;
   }
   while(ok);

   // Ray casting
   initRayCaster();

   A=224;
   n=0;
   x=1.5*VIRGULE;
   y=1.25*VIRGULE;
   z=1.5*VIRGULE;

   ok=2;
   do
   {
      // Affichage
      rayCaster(x,y+(SINUS[n]>>3),z,A);
      afficheCommun();

      // Deplacement (manuel)
      if(!(REG_TOUCHES&TOUCHE_GAUCHE))
         A+=ROTATION_RC;
      if(!(REG_TOUCHES&TOUCHE_DROITE))
         A-=ROTATION_RC;
      if(!(REG_TOUCHES&TOUCHE_HAUT))
         deplacementRC(&x,&z,A);
      if(!(REG_TOUCHES&TOUCHE_BAS))
         deplacementRC(&x,&z,A+127);
      if(!(REG_TOUCHES&TOUCHE_A) && y>=0.3*VIRGULE)
         y-=VERTICAL_RC;
      if(!(REG_TOUCHES&TOUCHE_B) && y<1.7*VIRGULE)
         y+=VERTICAL_RC;
      if(!(REG_TOUCHES&TOUCHE_L))
         deplacementRC(&x,&z,A+64);
      if(!(REG_TOUCHES&TOUCHE_R))
         deplacementRC(&x,&z,A-64);
      if(~REG_TOUCHES&(TOUCHE_HAUT|TOUCHE_BAS|TOUCHE_L|TOUCHE_R))
         n+=24; // Saute lorsqu'on marche
      else
         n=0;

      // Fin ?
      if(REG_TOUCHES&TOUCHE_START)
         ok=1;
      else if(ok==1)
         ok=0;
   }
   while(ok);

   // Plasma
   initPlasma();

   while(1)
   {
      modifiePlasma();
      afficheCommun();
   }
}
