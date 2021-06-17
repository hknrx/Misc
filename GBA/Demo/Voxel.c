/*
   Pour le voxel spacing on parcourt l'ecran en largeur (xe), et pour chaque verticale de
   l'ecran on parcourt une partie de la carte (z) ; on recupere les hauteurs pour chaque
   morceau de la carte trouve et on en trace une tranche de montagne.

   Equations de base de la 3D (dans le repere de la camera) :
   xe = XO + Dcam * x / z
   ye = YO - Dcam * y / z

   On connait xe et z, donc on trouve x :
   x = (xe-XO) * z / Dcam

   On a x et z, il faut faire le changement de repere (rotation et deplacement de la camera) :
   Vo = (x , z)

          |COS -SIN|
   Mrot = |        |
          |SIN  COS|

   V = Mrot.Vo = (x*COS-z*SIN , x*SIN+z*COS)

   Si on simplifie tout ca on trouve :
   x' = xcam+z*((xe-XO)*COS/Dcam-SIN)
   z' = zcam+z*((xe-XO)*SIN/Dcam+COS)

   Quand on a x' et z', on connait la hauteur de la montagne grace a la carte ; la hauteur a
   l'ecran est alors :
   ye = YO - Dcam * (hauteur - ycam) / z

   Pour aller plus vite on travaille par increments :
   (ici on parle de x, z et dist a la place de x', z' et z)

   ddx = COS/Dcam
   dx = -XO*ddx-SIN
   ddz = SIN/Dcam
   dz = -XO*ddz+COS
   Boucle(xe : de 0 a XM)
      x = xcam+dx*Dmin
      z = zcam+dz*Dmin
      Boucle(dist : de Dmin a Dmax)
         ye=YO-Dcam*(hauteur[x,y]-ycam)/dist
         // affichage de la tranche de montagne
         x+ = dx
         z+ = dz
      FinBoucle
      dx+ = ddx
      dz+ = ddz
   FinBoucle
*/

#include <stdlib.h>
#include "Commun.h"

#define DMIN      4
#define DMAX      90
#define DCAM_     5
#define CARTE_    7
#define CARTE     (1<<CARTE_)
#define DEFCARTE_ 1
#define VITESSE_  1

#define XM (XM4/3)
#define YM YM5
#define XO (XM/2)
#define YO (YM/2)

signed char* hauteur;

///////////////
// initVoxel //
///////////////
void initVoxel(void)
{
   unsigned short xy;
   unsigned short x,y;
   signed short sinx,siny,sinxy;

   // Vide le buffer video courant
   ecran=(unsigned short*)((unsigned long)VRAM|BACKVRAM);
   for(xy=0;xy<XM*YM;xy+=2)
      *(unsigned long*)&ecran[xy]=0;

   // On passe en mode 5
   REG_DISPCNT=5|BG2_ENABLE|BACKBUFFER;
   ecran=VRAM;

   // Etire le buffer pour prendre tout l'ecran
   REG_BG2PA=(XM<<8)/240;
   REG_BG2PB=0;
   REG_BG2PC=0;
   REG_BG2PD=(YM<<8)/160;

   // Reserve de la memoire pour la carte des hauteurs
   hauteur=(signed char*)malloc(CARTE*CARTE*sizeof(signed char));
   
   // Initialisation de la carte des hauteurs
   xy=0;
   for(y=0;y<CARTE;++y)
   {
      siny=SINUS[(unsigned char)(y<<(8-CARTE_))]; // CARTE : de 0 a 2*PI
      for(x=0;x<CARTE;++x)
      {
         sinx=SINUS[(unsigned char)(x<<(8-CARTE_))];
         sinxy=SINUS[(unsigned char)((x*y)>>(CARTE_*2-8))];
         hauteur[xy]=(((sinx*siny)>>VIRGULE_)*sinxy)>>(VIRGULE_+VIRGULE_-7);
         ++xy;
      }
   }
}

//////////////////////
// deplacementVoxel //
//////////////////////
signed long deplacementVoxel(signed long* xcam,signed long* zcam,unsigned char A)
{
   unsigned short xy_carte;
   
   // Deplacement en fonction de l'angle
   *xcam-=SINUS[A]<<VITESSE_;
   *zcam+=SINUS[(unsigned char)(A+64)]<<VITESSE_;

   // Repositionne la camera par rapport au sol
   xy_carte=((*xcam>>VIRGULE_)&(CARTE-1))|((*zcam>>(VIRGULE_-CARTE_))&((CARTE-1)<<CARTE_));
   return(hauteur[xy_carte]<<(VIRGULE_-DEFCARTE_));
}

///////////
// voxel //
///////////
void CODE_IN_IWRAM voxel(signed long xcam,signed long ycam,signed long zcam,unsigned char A)
{
   unsigned short xy_ecran,xy_carte,dist;
   signed long sin,cos,x,dx,ddx,z,dz,ddz,h;
   signed short xe,ye,he;
   unsigned short nuance,dnuance,coul;

   // Retrouve le sinus & cosinus
   sin=SINUS[A];
   cos=SINUS[(unsigned char)(A+64)];

   // Preparation des variables...
   ddx=cos>>DCAM_;
   dx=sin+XO*ddx;
   ddz=sin>>DCAM_;
   dz=cos-XO*ddz;

   dnuance=INV[DMAX-DMIN]>>(VIRGULE_-8);
   
   // On parcourt l'ecran en horizontal
   for(xe=0;xe<XM;++xe)
   {
      x=xcam-dx*DMIN;
      z=zcam+dz*DMIN;

      xy_ecran=xe+XM5*(YM-1);
      ye=YM;

      nuance=256;

      // On affiche plusieurs voxels
      for(dist=DMIN;dist<=DMAX;++dist)
      {
         // Voici notre position sur la carte...
         xy_carte=((x>>VIRGULE_)&(CARTE-1))|((z>>(VIRGULE_-CARTE_))&((CARTE-1)<<CARTE_));

         // ...et la hauteur a cet endroit
         h=hauteur[xy_carte]<<(VIRGULE_-DEFCARTE_);

         // Calcule la hauteur du voxel a l'ecran
         he=YO-(((h-ycam)*INV[dist])>>(VIRGULE_+VIRGULE_-DCAM_));
         if(he<0)
            he=0;
         ye-=he;

         // Calcule la couleur du voxel
         coul=(nuance*(((x^z)>>VIRGULE_)&31))>>8;

         // Affiche le voxel
         while(ye>0)
         {
            ecran[xy_ecran]=coul;
            xy_ecran-=XM5;
            --ye;
         }

         // Voxel suivant !
         ye+=he;
         x-=dx;
         z+=dz;
         nuance-=dnuance;
      }

      // On complete par le ciel
      while(ye>0)
      {
         ecran[xy_ecran]=RGB(0,0,0);
         xy_ecran-=XM5;
         --ye;
      }

      // Position suivante !
      dx-=ddx;
      dz+=ddz;
   }
}
