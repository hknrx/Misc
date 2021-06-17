/*
** Mario Balls - Sources\Menu\Menu.c
** Nicolas ROBERT [NRX] - Hong Kong 2005
*/

////////////////
// Inclusions //
////////////////
#include "Menu.h"
#include "../Boules/Boules.h"

////////////
// Macros //
////////////
#define XM XM4
#define YM YM4

///////////
// Types //
///////////
typedef struct
{
   signed short y;
   signed short ymax;
   signed short vitesse;
}
Lettre;

////////////////////////
// Variables globales //
////////////////////////
extern const Sound ADPCM_MusiqueGenerique;
extern const Sound ADPCM_EffetBombeContact;

extern const unsigned char Police_Bitmap[];
extern const unsigned short SpritesMenu_Palette[];
extern const unsigned char SpritesMenu_Bitmap[];
extern const unsigned short FondsMenu_Palette[];
extern const unsigned char FondsMenu_Tiles[];
extern const unsigned short FondsMenu_Map[];

/////////////////////
// affChaineSprite //
/////////////////////
unsigned char affChaineSprite(unsigned char pointeur,unsigned short x,unsigned short y,const unsigned char* chaine,unsigned short mode)
{
   unsigned char tile;

   while(*chaine!='\0')
   {
      // Recherche de la tile appropriee
      tile=0;
      if(*chaine>=',' && *chaine<=':')
         tile=(*chaine-','+14)<<1;
      else if(*chaine>='A' && *chaine<='Z')
         tile=(*chaine-'A'+29)<<1;
      else if(*chaine=='!')
         tile=55<<1;

      // Positionne le sprite (sauf pour les espaces ou characteres inconnus)
      if(tile)
      {
         sprites[pointeur].attribut1=y|(1<<13)|mode; // Sprite 256 couleurs
         sprites[pointeur].attribut2=x;
         sprites[pointeur].attribut3=tile+80;
         ++pointeur;
      }

      // Charactere suivant...
      ++chaine;
      x+=8;
   }

   // Retourne le pointeur sur le prochain sprite libre
   return(pointeur);
}

/////////////////////
// affNombreSprite //
/////////////////////
unsigned char affNombreSprite(unsigned char pointeur,unsigned short x,unsigned short y,unsigned short nombre)
{
   unsigned char chiffre;

   do
   {
      // Extrait le chiffre des unites
      chiffre=nombre%10;

      // Positionne le sprite
      sprites[pointeur].attribut1=y|(1<<13); // Sprite 256 couleurs
      sprites[pointeur].attribut2=x;
      sprites[pointeur].attribut3=((chiffre+18)<<1)+80;
      ++pointeur;

      // Chiffre suivant...
      nombre=(nombre-chiffre)/10;
      x-=8;
   }
   while(nombre);

   // Retourne le pointeur sur le prochain sprite libre
   return(pointeur);
}

/////////////
// affFond //
/////////////
void affFond(unsigned char tempo)
{
   static signed short anim=0;

   while(tempo--)
   {
      // Bouge le background 2 (fond)
      REG_BG2HOFS=-anim;
      REG_BG2VOFS=anim>>1;

      // Scrolling
      ++anim;

      // Attente du retour de balayage vertical et initialisation de la table de sinus
      initSIN_VBL(1);
   }
}

/////////////
// affMenu //
/////////////
void affMenu(void)
{
   signed char fade;
   unsigned char animation,indexHi,timerBras;
   Lettre lettres[10];
   Lettre* lettre;
   unsigned char pointeur,pointeursHi[3];
   signed short x,y;

   // (Re-)demarre la musique !
   if(!AdpcmStatus(0))
      AdpcmStart(&ADPCM_MusiqueGenerique,-1,0);

   // Initialisation du titre
   initSprites();
   affSprites();

   srand(compteVBL);
   for(pointeur=0;pointeur<10;++pointeur)
   {
      x=(pointeur%5)*20+16-RAYON;
      sprites[pointeur].attribut2=(x&511)|(1<<14); // Sprite de 16x16
      sprites[pointeur].attribut3=(pointeur<<3);

      y=(pointeur/5)*20+60;
      lettres[pointeur].y=(y-80-RAYON-(rand()&31))<<PRECISION_;
      lettres[pointeur].ymax=y<<PRECISION_;
      lettres[pointeur].vitesse=0;
   }

   // Chargement des sprites
   copieDMA((void*)SpritesMenu_Bitmap,(void*)OBJ_TILES,2560/4,DMA_32NOW);
   copieDMA((void*)Police_Bitmap,(void*)OBJ_TILES+2560,3584/4,DMA_32NOW);
   copieDMA((void*)SpritesMenu_Palette,(void*)OBJ_PALRAM,256/2,DMA_32NOW);

   // Preparation des backgrounds
   REG_BG0CNT=BG_COLORS_256|TXTBG_SIZE_256x256|(0<<CHAR_SHIFT)|(29<<SCREEN_SHIFT); // Corps de Mario
   REG_BG1CNT=BG_COLORS_256|TXTBG_SIZE_256x256|(0<<CHAR_SHIFT)|(30<<SCREEN_SHIFT); // Bras de Mario
   REG_BG2CNT=BG_COLORS_256|TXTBG_SIZE_256x256|(0<<CHAR_SHIFT)|(31<<SCREEN_SHIFT); // Fond etoile

   // Chargement de l'ecran titre (les 3 backgrounds sont a la suite)
   copieDMA((void*)FondsMenu_Tiles,(void*)CHAR_BASE_BLOCK(0),20480/4,DMA_32NOW);
   copieDMA((void*)FondsMenu_Map,(void*)SCREEN_BASE_BLOCK(29),3*32*32/2,DMA_32NOW);

   // Attente du retour du balayage vertical, puis chargement de la palette
   // (il faut etre synchronise pour eviter un artefact du au changement de la couleur 0)
   initSIN_VBL(1);
   copieDMA((void*)FondsMenu_Palette,(void*)PALRAM,256/2,DMA_32NOW);

   // On passe en mode 0
   REG_DISPCNT=BG0_ENABLE|BG1_ENABLE|BG2_ENABLE|OBJ_ENABLE|OBJ_1D;

   // Fade-in & debut de l'initialisation de SIN pour Boules
   REG_BLDMOD=BLEND_BG0|BLEND_BG1|BLEND_BG2|BLEND_OBJ|BLEND_BD|BLEND_BLACK;
   for(fade=16;fade>=0;--fade)
   {
      REG_BLD_FAD=fade;
      affFond(3);
   }

   // Mise en place du "PRESS START!" (avec transparence)
   REG_BLDMOD=BLEND_ALPHA|((BLEND_BG0|BLEND_BG1|BLEND_BG2|BLEND_BD)<<8);
   pointeur=affChaineSprite(10,40+16-20,120,"PRESS",1<<10); // Avec transparence
   pointeursHi[0]=affChaineSprite(pointeur,40+16-24,128,"START!",1<<10); // Avec transparence

   // Mise en place du "HI-SCORE" et "HI-LEVEL" (sans transparence)
   pointeur=affNombreSprite(pointeursHi[0],232,160,info.hiScore);
   pointeursHi[1]=affChaineSprite(pointeur,168-((pointeur-pointeursHi[0])<<3),160,"HI-SCORE:",0);
   if(info.hiLevel<niveaux.nombre)
      pointeur=affNombreSprite(pointeursHi[1],232,160,info.hiLevel+1);
   else
      pointeur=affChaineSprite(pointeursHi[1],216,160,"END",0);
   pointeursHi[2]=affChaineSprite(pointeur,168-((pointeur-pointeursHi[1])<<3),160,"HI-LEVEL:",0);

   // Animation du titre (continue l'initialisation de SIN)
   compteVBL=0;
   timerBras=0;
   do
   {
      // Bouge chacune des lettres
      animation=0;
      for(pointeur=0;pointeur<10;++pointeur)
      {
         // Gestion des rebonds
         lettre=&lettres[pointeur];
         lettre->y+=lettre->vitesse;
         if(lettre->y<lettre->ymax)
            lettre->vitesse+=GRAVITE;
         else
         {
            lettre->y=lettre->ymax;
            if(lettre->vitesse>ABSORPTION)
               lettre->vitesse=ABSORPTION-lettre->vitesse;
         }

         // Mise en place du sprite
         y=(lettre->y>>PRECISION_)-RAYON;
         if(y<YM)
         {
            animation=1;
            if(y>-DIAMETRE)
            {
               sprites[pointeur].attribut1=(y&255)|(1<<13); // Sprite 256 couleurs
               continue;
            }
         }
         sprites[pointeur].attribut1=YM4;
      }

      // Animation du "PRESS START!" (modifie la transparence)
      if(lettres[0].ymax!=32767 || fade)
      {
         fade=compteVBL&15;
         if(compteVBL&16)
            fade=16-fade;
         REG_BLD_AB=fade|((16-fade)<<8);
      }

      // Animation du "HI-SCORE" et "HI-LEVEL" (affichage en alternance)
      switch(compteVBL&(15<<3))
      {
         case 0:
            y=160-(compteVBL&7);
            break;

         case 15<<3:
            y=153+(compteVBL&7);
            break;

         default:
            y=152;
      }
      if(compteVBL&(1<<7))
         indexHi=2;
      else
         indexHi=1;
      for(pointeur=pointeursHi[indexHi-1];pointeur<pointeursHi[indexHi];++pointeur)
         sprites[pointeur].attribut1=(y&255)|(1<<13); // Sprite 256 couleurs

      // Affichage des sprites
      affSprites();

      // Appuie sur start ou A ?
      if(~REG_TOUCHES&(TOUCHE_START|TOUCHE_A) && lettres[0].ymax!=32767)
      {
         // Petite explosion (qui arrete la musique !)...
         AdpcmStart(&ADPCM_EffetBombeContact,1,0);

         // Bouge le bras de Mario
         REG_BG1VOFS=-8;
         timerBras=4;

         // Force les lettres a sauter en bas de l'ecran
         for(pointeur=0;pointeur<10;++pointeur)
         {
            lettres[pointeur].ymax=32767;
            lettres[pointeur].vitesse=-(rand()&31);
         }
      }
      else if(!--timerBras)
      {
         // Remet le bras dans sa position initiale (important pour la suite du jeu !)
         REG_BG1VOFS=0;
      }

      // Animation du fond
      affFond(1);
   }
   while(animation);

   // Suppression du "PRESS START!" (sinon il va reapparaitre lors du fade-out !)
   for(pointeur=10;pointeur<pointeursHi[0];++pointeur)
      sprites[pointeur].attribut1=YM4;
   affSprites();

   // Fade-out
   REG_BLDMOD=BLEND_BG0|BLEND_BG1|BLEND_BG2|BLEND_OBJ|BLEND_BD|BLEND_WHITE;
   for(fade=0;fade<=16;++fade)
   {
      REG_BLD_FAD=fade;
      affFond(3);
   }

   // On ne continue que si les touches start et A ont ete relachees
   while(~REG_TOUCHES&(TOUCHE_START|TOUCHE_A));

   // Attente du retour du balayage vertical
   initSIN_VBL(1);

   // Supprime le fading, mais vide d'abord l'ecran (ecran blanc)
   REG_DISPCNT=FORCE_BLANK;
   REG_BLDMOD=BLEND_NO;
}
