///////////////////
//       	 //
// Bibliotheques //
//       	 //
///////////////////
#include <stdio.h>
#include <alloc.h>
#include <math.h>

////////////////
//            //
// Constantes //
//            //
////////////////
#define OBJ_TEXTURES_L 256 // Largeur du buffer "OBJ_TEXTURES".
#define OBJ_TEXTURES_H 256 // Hauteur du buffer "OBJ_TEXTURES".
#define VOX_TEXTURES_L 256 // Largeur du buffer "VOX_TEXTURES".
#define VOX_TEXTURES_H 256 // Hauteur du buffer "VOX_TEXTURES".

///////////////////////////
//       		 //
// Definitions des types //
//       		 //
///////////////////////////
typedef void 	      Vide;
typedef unsigned char Couleur;
typedef unsigned int  Entier;
typedef int  	      EntierS;
typedef float	      Float;

/////////////////////////
//                     //
// Programme principal //
//                     //
/////////////////////////
Vide main(Vide)
{
  FILE*        fichier;
  Couleur far* TEXTURES;
  EntierS far* HAUTEURS;
  Entier       x,y;
  Float        hauteur;

  // Ouvre le fichier :
  fichier=fopen("TEXTURES.DAT","wb");
  if(fichier)
  {
    // Creation des textures des objets :
    TEXTURES=(Couleur far*)farmalloc(OBJ_TEXTURES_L*sizeof(Couleur));
    if(TEXTURES)
    {
      for(y=0;y<OBJ_TEXTURES_H;y++)
      {
	for(x=0;x<OBJ_TEXTURES_L;x++)
	  TEXTURES[x]=(Couleur)(31*sin(x*M_PI/32)*sin(y*M_PI/32))&31;

	fwrite(TEXTURES,sizeof(Couleur),OBJ_TEXTURES_L,fichier);
      }
      farfree(TEXTURES);
      puts("TEXTURES OBJ : OK");
    }

    // Creation des textures du decor (voxel spacing) :
    TEXTURES=(Couleur far*)farmalloc(VOX_TEXTURES_L*sizeof(Couleur));
    if(TEXTURES)
    {
      for(y=0;y<VOX_TEXTURES_H;y++)
      {
	for(x=0;x<VOX_TEXTURES_L;x++)
	  TEXTURES[x]=(x^y)&31;

	fwrite(TEXTURES,sizeof(Couleur),VOX_TEXTURES_L,fichier);
      }
      farfree(TEXTURES);
      puts("TEXTURES VOX : OK");
    }

    // Creation des hauteurs (voxel spacing) :
    HAUTEURS=(EntierS far*)farmalloc(VOX_TEXTURES_L*sizeof(EntierS));
    if(HAUTEURS)
    {
      for(y=0;y<VOX_TEXTURES_H;y++)
      {
	for(x=0;x<VOX_TEXTURES_L;x++)
	{
	  hauteur=3.5*
		  sin(x*M_PI*8.0/VOX_TEXTURES_L)*
		  sin(y*M_PI*8.0/VOX_TEXTURES_H)*
		  sin(x*y*M_PI*12.0/VOX_TEXTURES_L/VOX_TEXTURES_H);

	  HAUTEURS[x]=(EntierS)(hauteur*256L);
	}

	fwrite(HAUTEURS,sizeof(EntierS),VOX_TEXTURES_L,fichier);
      }
      farfree(HAUTEURS);
      puts("HAUTEURS     : OK");
    }

    // Ferme le fichier :
    fclose(fichier);
  }
}