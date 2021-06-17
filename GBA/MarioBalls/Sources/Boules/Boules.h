/*
** Mario Balls - Sources\Boules\Boules.h
** Nicolas ROBERT [NRX] - Hong Kong 2005
*/

#ifndef BOULES_H
#define BOULES_H

////////////////
// Inclusions //
////////////////
#include "../Commun/Commun.h"

////////////
// Macros //
////////////
#define LIGNE 0
#define ARC   1

#define BOULES_MAX 120
#define DIAMETRE   15
#define RAYON      ((DIAMETRE+1)>>1)

#define ETAT_RIEN     0
#define ETAT_PERDU    1
#define ETAT_CONTINUE 2
#define ETAT_GAGNE    3
#define ETAT_ABANDON  4

///////////
// Types //
///////////
typedef struct
{
   unsigned short* palette;
   unsigned char* tiles;
   unsigned short tilesSize;
   unsigned char* map;
}
InfoFond;

typedef struct
{
   unsigned char nombre;
   InfoFond infoFonds[];
}
Fonds;

typedef struct
{
   signed short x1,y1;
   signed short x2,y2;
   signed long vx,vy;
}
Ligne;

typedef struct
{
   signed short x,y,r;
   signed short a1,a2;
   signed long va;
}
Arc;

typedef struct
{
   unsigned char type;
   union
   {
      Ligne ligne;
      Arc arc;
   }
   info;
   unsigned short L;
}
Element;

typedef struct
{
   unsigned char debut;
   unsigned char fin;
   signed short xLanceBoule,yLanceBoule,aLanceBoule;
   unsigned char* nom;
}
Parcours;

typedef struct
{
   Parcours* parcours;
   unsigned char couleurs;
   unsigned char nombreBoules;
}
Niveau;

typedef struct
{
   unsigned char courant;
   unsigned char nombre;
   Element* elements;
   Niveau* niveaux;
}
Niveaux;

typedef struct
{
   unsigned char phase;
   unsigned char malus;
   signed short angle;
   unsigned char couleur;
   signed long xBoule,yBoule;
   signed short dxBoule,dyBoule;
}
LanceBoule;

typedef struct
{
   unsigned char couleur;
   signed short L;
   unsigned char avant;
   unsigned char apres;
}
Boule;

typedef struct
{
   unsigned char premiere;
   unsigned char nombre;
   Boule boules[BOULES_MAX];
   unsigned char alloc;
   unsigned char free;
   unsigned char pointeurs[BOULES_MAX];
   unsigned char compteCouleurs[5];
}
Boules;

typedef struct
{
   unsigned short hiScore;
   unsigned char hiLevel;
}
Info;

////////////////////////
// Variables globales //
////////////////////////
Info info;
extern Niveaux niveaux;

////////////////
// Prototypes //
////////////////
void chargeInfo(void);
void sauveInfo(void);
void CODE_IN_IWRAM initBoules(void);
unsigned char CODE_IN_IWRAM affNiveau(void);
unsigned char CODE_IN_IWRAM gereBoules(void);

#endif // BOULES_H
