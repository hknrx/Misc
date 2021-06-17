/*
** God - Sources\Intro\Voxel\Voxel.c
** Nicolas ROBERT [NRX] - Hong Kong 2005
*/

////////////////
// Inclusions //
////////////////
#include "Voxel.h"

////////////
// Macros //
////////////
#define XM (XM4/3)
#define YM YM5
#define XO (XM/2)
#define YO (YM/2)

///////////
// Types //
///////////
typedef struct
{
   unsigned short* screen;
   signed char* height;
}
Voxel;

////////////////////////
// Variables globales //
////////////////////////
Voxel voxel;

///////////////
// VoxelInit //
///////////////
void VoxelInit(void)
{
   unsigned short xy;
   unsigned short x,y;
   signed short sinx,siny,sinxy;

   // Etire le buffer pour prendre tout l'ecran
   REG_BG2PA=(XM<<8)/240;
   REG_BG2PB=0;
   REG_BG2PC=0;
   REG_BG2PD=(YM<<8)/160;

   // Il ne faut pas oublier de positionner le buffer au bon endroit !
   REG_BG2X=0;
   REG_BG2Y=0;

   // Termine l'initialisation de SINE_TABLE (si besoin est)
   while(CommonSineInitVbl(0));

   // Termine l'initialisation de INVERSE_TABLE (si besoin est)
   while(CommonInverseInitVbl(0));

   // Reserve de la memoire pour la carte des hauteurs
   voxel.height=(signed char*)malloc(MAP_SIZE*MAP_SIZE*sizeof(signed char));

   // Initialisation de la carte des hauteurs
   xy=0;
   for(y=0;y<MAP_SIZE;++y)
   {
      siny=SIN(y<<(SINNB_SHIFT-MAP_SIZE_SHIFT)); // On va de 0 a 2*PI...

      for(x=0;x<MAP_SIZE;++x)
      {
         sinx=SIN(x<<(SINNB_SHIFT-MAP_SIZE_SHIFT));
         sinxy=SIN((x*y)>>(MAP_SIZE_SHIFT+MAP_SIZE_SHIFT-SINNB_SHIFT));

         voxel.height[xy++]=(((sinx*siny)>>FIXED_POINT_SHIFT)*sinxy)>>(FIXED_POINT_SHIFT+FIXED_POINT_SHIFT-7);
      }
   }

   // On passe en mode 5
   REG_DISPCNT=5|BG2_ENABLE|BACKBUFFER;
   voxel.screen=(unsigned short*)VRAM;
}

//////////////////
// VoxelDestroy //
//////////////////
void VoxelDestroy(void)
{
   free(voxel.height);
}

///////////////
// VoxelMove //
///////////////
signed long VoxelMove(signed long* x,signed long* z,unsigned char Ry)
{
   unsigned short xyMap;

   // Deplacement : on recule...
   *x+=SIN(Ry)<<SPEED_SHIFT;
   *z-=COS(Ry)<<SPEED_SHIFT;

   // Repositionne la camera par rapport au sol
   xyMap=((*x>>FIXED_POINT_SHIFT)&MAP_SIZE_MASK)|((*z>>(FIXED_POINT_SHIFT-MAP_SIZE_SHIFT))&(MAP_SIZE_MASK<<MAP_SIZE_SHIFT));
   return(voxel.height[xyMap]<<(FIXED_POINT_SHIFT-7+MAP_DEF_SHIFT));
}

//////////////////
// VoxelDisplay //
//////////////////
void CODE_IN_IWRAM VoxelDisplay(signed long x,signed long y,signed long z,unsigned char Ry)
{
   signed long sinRy,cosRy;
   signed long xMap,xMapInc,zMap,zMapInc;
   signed long heightMap;
   signed short xScreen,yScreen,heightScreen;
   unsigned short xyScreen,xyMap,dist;
   unsigned short color,fade,fadeInc;

   // Les variables locales suivantes ameliorent les performances par rapport a l'utilisation des
   // pointeurs originaux ; le gain mesure est de 8% (3.24 VBL/frame => 2.97 VBL/frame)
   unsigned short* localINVERSE_TABLE=INVERSE_TABLE;
   unsigned short* localScreen=voxel.screen;
   signed char* localHeight=voxel.height;

   // Retrouve le sinus & cosinus
   sinRy=SIN(Ry);
   cosRy=COS(Ry);

   // Preparation des variables...
   x<<=DIST_CAM_SHIFT;
   z<<=DIST_CAM_SHIFT;

   xMapInc=(sinRy<<DIST_CAM_SHIFT)+XO*cosRy;
   zMapInc=(cosRy<<DIST_CAM_SHIFT)-XO*sinRy;

   fadeInc=localINVERSE_TABLE[DIST_MAX-DIST_MIN];

   // On parcourt l'ecran en horizontal
   for(xScreen=0;xScreen<XM;++xScreen)
   {
      xMap=x-xMapInc*DIST_MIN;
      zMap=z+zMapInc*DIST_MIN;

      xyScreen=xScreen+XM5*(YM-1);
      yScreen=YM;

      fade=FIXED_POINT_INV;

      // On affiche plusieurs voxels
      for(dist=DIST_MIN;dist<DIST_MAX;++dist)
      {
         // Voici notre position sur la carte...
         xyMap=((xMap>>(FIXED_POINT_SHIFT+DIST_CAM_SHIFT))&MAP_SIZE_MASK)|
               ((zMap>>(FIXED_POINT_SHIFT+DIST_CAM_SHIFT-MAP_SIZE_SHIFT))&(MAP_SIZE_MASK<<MAP_SIZE_SHIFT));

         // ...et la hauteur a cet endroit
         heightMap=localHeight[xyMap]<<(FIXED_POINT_SHIFT-7+MAP_DEF_SHIFT);

         // Calcule la hauteur du voxel a l'ecran
         heightScreen=YO-(((heightMap-y)*localINVERSE_TABLE[dist])>>(FIXED_POINT_SHIFT+FIXED_POINT_INV_SHIFT-DIST_CAM_SHIFT));
         if(heightScreen<0)
            heightScreen=0;
         yScreen-=heightScreen;

         // Calcule la couleur du voxel : la composante rouge depend de la position sur la carte (ou
         // exclusif entre x et z), la bleue est forcee a 26 ; on tient egalement compte de la
         // distance (parametre "fade")
         color=((fade*(((xMap^zMap)>>(FIXED_POINT_SHIFT+DIST_CAM_SHIFT))&31))>>FIXED_POINT_INV_SHIFT)|
               (((fade*26)>>(FIXED_POINT_INV_SHIFT-10))&(31<<10));

         // Affiche le voxel
         while(yScreen>0)
         {
            localScreen[xyScreen]=color;
            xyScreen-=XM5;
            --yScreen;
         }

         // Voxel suivant !
         yScreen+=heightScreen;
         xMap-=xMapInc;
         zMap+=zMapInc;
         fade-=fadeInc;
      }

      // On complete par le ciel
      while(yScreen>0)
      {
         localScreen[xyScreen]=RGB(0,0,4);
         xyScreen-=XM5;
         --yScreen;
      }

      // Position suivante !
      xMapInc-=cosRy;
      zMapInc+=sinRy;
   }

   // Attente du retour du balayage vertical
   CommonVwait();

   // Affichage (inversion des buffers video)
   REG_DISPCNT^=BACKBUFFER;
   (unsigned long)voxel.screen^=BACKVRAM;
}
