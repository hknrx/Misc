/*
   L'idee du bump est de calculer la lumiere en fonction de l'angle entre le soleil (S) et
   la surface au sol. On considere chaque pixel comme etant un polygone.

   On prend 3 points A, B and C (A est le pixel considere, B et C ses voisins a droite et en bas).
   On a les vecteurs suivants :
   U = AB = (xB-xA , yB-yA , zB-zA)
   V = AC = (xC-xA , yC-yA , zC-zA)

   La normale a la surface est :
   Z = U v V = (zA-zB , zA-zC , 1)

   Le vecteur pointant vers le soleil est :
   S = AS = (xS-xA , yS-yA , zS-zA) = (xs-xA , yS-yA , H)   (car H=zS and zS>>zA)

   La couleur (luminosite) est donnee par :

           Z.S     (zA-zB)(xS-xA)+(zA-zC)(yS-yA)+H
   coul = ------ = -------------------------------
          |Z||S|               |Z||S|

   Les normes |Z| et |S| sont donnees par :
   |Z|2 = (zA-zB)2 + (zA-zC)2 + 1
   |S|2 = (xS-xA)2 + (yS-yA)2 + H2

   On fait quelques approximations pour s'en sortir :
   - Approximation |Z| = 1 car les hauteurs zA, zB et zC sont petites par rapport a l'unite de base
   de la surface (on peut considerer ok si delta(z)<0.3). On a alors :
   |Z||S| = SQRT((xS-xA)2+(yS-yA)2+H2)
   - Autre approximation (vraie si H est tres tres grand) :
   |Z||S| = ((xS-xA)2+(yS-yA)2+H2)/H

   Au final on a donc :

          ((zA-zB)(xS-xA)+(zA-zC)(yS-yA)+H)*H
   coul = -----------------------------------
                 (xS-xA)2+(yS-yA)2+H2
*/

#include "Commun.h"

#define HAUTEUR_ 6
#define HAUTEUR  (1<<HAUTEUR_)

#define XM (XM4/2)
#define YM (YM4/2)
#define XO (XM/2)
#define YO (YM/2)

extern signed char bump[];

//////////////
// initBump //
//////////////
void initBump(void)
{
   unsigned short xy;

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
      PALRAM[xy]=(xy>>3)*RGB(1,1,1);
}

/////////////////
// modifieBump //
/////////////////
void CODE_IN_IWRAM modifieBump(signed short x,signed short y)
{
   signed short ddistx,ddistx_,ddisty,x_,finx,dx,dy,coul;
   signed long dist,dist_;
   unsigned short xy;

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
         dx=bump[xy];
         dy=dx-bump[xy+XM];
         dx-=bump[xy+1];

         coul=x_*dx+y*dy+(HAUTEUR<<8); // On considere le bump comme etant en virgule fixe 8 !
         if(coul>0)
         {
            coul=(coul*INV[dist_>>HAUTEUR_])>>(VIRGULE_);
            if(coul>255)
               coul=255;
         }
         else
            coul=0;

         *(unsigned char*)&ecran[xy++]=coul; // On force les 2 pixels cote a cote ensemble a la meme valeur

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
}
